import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';
import 'package:lurc/core/saved_requests/saved_requests_repository.dart';
import 'package:lurc/core/saved_requests/saved_requests_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  SavedRequest request(String id) => SavedRequest(
    id: id,
    name: id,
    method: HttpMethod.get,
    url: 'https://example.com',
    collectionId: 'c',
  );

  test(
    'providers publish persisted mutations and collection membership',
    () async {
      await container.read(savedRequestsControllerProvider.future);
      final controller = container.read(
        savedRequestsControllerProvider.notifier,
      );
      await controller.saveCollection(const Collection(id: 'c', name: 'Users'));
      await controller.saveRequest(request('r'));
      expect(
        container.read(collectionsProvider).requireValue.single.name,
        'Users',
      );
      expect(
        container
            .read(savedRequestsInCollectionProvider('c'))
            .requireValue
            .single
            .id,
        'r',
      );
      await controller.deleteCollection('c');
      expect(container.read(collectionsProvider).requireValue, isEmpty);
      expect(
        container
            .read(savedRequestsInCollectionProvider(null))
            .requireValue
            .single
            .id,
        'r',
      );
      await controller.deleteRequest('r');
      expect(
        container.read(savedRequestsControllerProvider).requireValue.requests,
        isEmpty,
      );
    },
  );

  test('writes during initial loading wait for initialization', () async {
    final controller = container.read(savedRequestsControllerProvider.notifier);
    await controller.saveCollection(const Collection(id: 'c', name: 'Users'));
    await Future.wait(
      List.generate(10, (index) => controller.saveRequest(request('$index'))),
    );
    expect(
      container
          .read(savedRequestsControllerProvider)
          .requireValue
          .requests
          .length,
      10,
    );
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(
      (await second.read(savedRequestsControllerProvider.future))
          .requests
          .length,
      10,
    );
  });

  test(
    'invalid writes surface to caller while preserving successful state',
    () async {
      await container.read(savedRequestsControllerProvider.future);
      final controller = container.read(
        savedRequestsControllerProvider.notifier,
      );
      await expectLater(
        controller.saveRequest(request('orphan')),
        throwsFormatException,
      );
      expect(
        container.read(savedRequestsControllerProvider).requireValue.requests,
        isEmpty,
      );
      await controller.saveCollection(const Collection(id: 'c', name: 'Users'));
      await controller.saveRequest(request('valid'));
      expect(
        container
            .read(savedRequestsControllerProvider)
            .requireValue
            .requests
            .single
            .id,
        'valid',
      );
    },
  );

  test('repository errors do not publish unsaved changes', () async {
    final failed = ProviderContainer(
      overrides: [
        savedRequestsRepositoryProvider.overrideWith(
          (ref) async => _FailingRepository(),
        ),
      ],
    );
    addTearDown(failed.dispose);
    await failed.read(savedRequestsControllerProvider.future);
    await expectLater(
      failed
          .read(savedRequestsControllerProvider.notifier)
          .saveRequest(request('r')),
      throwsStateError,
    );
    expect(
      failed.read(savedRequestsControllerProvider).requireValue.requests,
      isEmpty,
    );
  });

  test('load errors are exposed and can be retried by invalidation', () async {
    final repository = _LoadFailingRepository();
    final failed = ProviderContainer(
      overrides: [
        savedRequestsRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(failed.dispose);
    final subscription = failed.listen(
      savedRequestsControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await expectLater(
      failed.read(savedRequestsControllerProvider.future),
      throwsFormatException,
    );
    expect(failed.read(savedRequestsControllerProvider).hasError, isTrue);

    repository.shouldFail = false;
    failed.invalidate(savedRequestsControllerProvider);
    expect(
      (await failed.read(savedRequestsControllerProvider.future)).requests,
      isEmpty,
    );
  });
}

class _FailingRepository implements SavedRequestsRepository {
  @override
  Future<SavedRequestsState> load() async => SavedRequestsState();

  @override
  Future<SavedRequestsState> saveRequest(SavedRequest request) async =>
      throw StateError('write failed');

  @override
  Future<SavedRequestsState> saveCollection(Collection collection) async =>
      throw StateError('write failed');

  @override
  Future<SavedRequestsState> deleteRequest(String id) async =>
      throw StateError('write failed');

  @override
  Future<SavedRequestsState> deleteCollection(String id) async =>
      throw StateError('write failed');
}

class _LoadFailingRepository implements SavedRequestsRepository {
  bool shouldFail = true;

  @override
  Future<SavedRequestsState> load() async {
    if (shouldFail) throw const FormatException('bad saved requests');
    return SavedRequestsState();
  }

  @override
  Future<SavedRequestsState> saveRequest(SavedRequest request) async =>
      throw UnimplementedError();

  @override
  Future<SavedRequestsState> saveCollection(Collection collection) async =>
      throw UnimplementedError();

  @override
  Future<SavedRequestsState> deleteRequest(String id) async =>
      throw UnimplementedError();

  @override
  Future<SavedRequestsState> deleteCollection(String id) async =>
      throw UnimplementedError();
}
