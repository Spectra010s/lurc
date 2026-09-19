import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late LocalSavedRequestsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = LocalSavedRequestsRepository(preferences);
  });

  SavedRequest request(String id, {String? collectionId}) => SavedRequest(
    id: id,
    name: id,
    method: HttpMethod.get,
    url: 'https://example.com',
    collectionId: collectionId,
  );

  test('first load is empty and does not create a file', () async {
    expect((await repository.load()).requests, isEmpty);
    expect(
      preferences.containsKey(LocalSavedRequestsRepository.storageKey),
      isFalse,
    );
  });

  test(
    'persists create, update, move, rename and delete across instances',
    () async {
      const collection = Collection(id: 'c', name: 'Original');
      await repository.saveCollection(collection);
      await repository.saveCollection(collection.copyWith(name: 'Renamed'));
      final original = request('r');
      await repository.saveRequest(original);
      await repository.saveRequest(
        original.copyWith(collectionId: 'c', name: 'New'),
      );
      final restored = await LocalSavedRequestsRepository(preferences).load();
      expect(restored.collections.single.name, 'Renamed');
      expect(restored.requests.single.name, 'New');
      expect(restored.requestsInCollection('c').single.id, 'r');
      await repository.deleteRequest('r');
      expect(
        (await LocalSavedRequestsRepository(preferences).load()).requests,
        isEmpty,
      );
    },
  );

  test(
    'deleting a collection unfiles requests without losing payloads',
    () async {
      await repository.saveCollection(
        const Collection(id: 'c', name: 'Collection'),
      );
      final original = request(
        'r',
        collectionId: 'c',
      ).copyWith(body: 'payload');
      await repository.saveRequest(original);
      final state = await repository.deleteCollection('c');
      expect(state.collections, isEmpty);
      expect(
        state.requests.single.toJson(),
        original.copyWith(clearCollection: true).toJson(),
      );
      expect((await repository.load()).requests.single.collectionId, isNull);
    },
  );

  test('concurrent writes retain every request', () async {
    await Future.wait(
      List.generate(20, (index) => repository.saveRequest(request('$index'))),
    );
    expect((await repository.load()).requests.length, 20);
  });

  test('invalid mutation preserves disk and queue remains usable', () async {
    await repository.saveRequest(request('valid'));
    final before = preferences.getString(
      LocalSavedRequestsRepository.storageKey,
    );
    await expectLater(
      repository.saveRequest(request('bad', collectionId: 'missing')),
      throwsFormatException,
    );
    expect(
      preferences.getString(LocalSavedRequestsRepository.storageKey),
      before,
    );
    await repository.saveRequest(request('next'));
    expect((await repository.load()).requests.length, 2);
  });

  test('corrupt and newer data are never overwritten by a mutation', () async {
    for (final data in ['broken JSON', '[]', '{"version":2}']) {
      await preferences.setString(
        LocalSavedRequestsRepository.storageKey,
        data,
      );
      await expectLater(repository.load(), throwsFormatException);
      await expectLater(
        repository.saveRequest(request('r')),
        throwsFormatException,
      );
      expect(
        preferences.getString(LocalSavedRequestsRepository.storageKey),
        data,
      );
    }
  });

  test('history key remains untouched', () async {
    await preferences.setString('request_history_v1', 'history');
    await repository.saveRequest(request('r'));
    await repository.deleteRequest('r');
    expect(preferences.getString('request_history_v1'), 'history');
  });

  test(
    'rename and move round-trip every payload field without duplication',
    () async {
      await repository.saveCollection(const Collection(id: 'a', name: 'First'));
      await repository.saveCollection(
        const Collection(id: 'b', name: 'Second'),
      );
      final original = SavedRequest(
        id: 'complete',
        name: 'Original',
        method: HttpMethod.patch,
        url: '{{host}}/users',
        collectionId: 'a',
        queryParameters: const {'search': 'two words', 'page': '{{page}}'},
        headers: const {'Authorization': 'Bearer {{token}}'},
        body: '{"active":true}',
        bodyType: RequestBodyType.json,
      );
      await repository.saveRequest(original);
      var updated = original.copyWith(name: 'Renamed', collectionId: 'b');
      await repository.saveRequest(updated);
      var restored = await LocalSavedRequestsRepository(preferences).load();
      expect(restored.requests.single.toJson(), updated.toJson());
      updated = updated.copyWith(clearCollection: true);
      await repository.saveRequest(updated);
      restored = await LocalSavedRequestsRepository(preferences).load();
      expect(restored.requests.single.toJson(), updated.toJson());
      expect(restored.requestsInCollection('a'), isEmpty);
      expect(restored.requestsInCollection('b'), isEmpty);
      await repository.deleteRequest(updated.id);
      expect((await repository.load()).collections.length, 2);
    },
  );
}
