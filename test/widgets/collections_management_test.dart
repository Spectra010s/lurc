import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';
import 'package:lurc/core/saved_requests/saved_requests_repository.dart';
import 'package:lurc/core/saved_requests/saved_requests_state.dart';
import 'package:lurc/screens/collections/collections_screen.dart';
import 'package:lurc/screens/collections/saved_request_editor_screen.dart';

void main() {
  late _MemoryRepository repository;
  late SavedRequest original;
  late _MemoryRepository activeRepository;
  late ProviderContainer container;

  setUp(() async {
    repository = _MemoryRepository();
    await repository.saveCollection(
      const Collection(id: 'a', name: 'Accounts'),
    );
    await repository.saveCollection(const Collection(id: 'b', name: 'Billing'));
    original = SavedRequest(
      id: 'r',
      name: 'Create user',
      method: HttpMethod.post,
      url: '{{host}}/users',
      collectionId: 'a',
      queryParameters: const {'page': '2'},
      headers: const {'Authorization': 'Bearer {{token}}'},
      body: '{"name":"Tayo"}',
      bodyType: RequestBodyType.json,
    );
    await repository.saveRequest(original);
    activeRepository = repository;
    container = ProviderContainer(
      overrides: [
        savedRequestsRepositoryProvider.overrideWith(
          (ref) => activeRepository,
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<SavedRequestsState> read(WidgetTester tester) => repository.load();

  Future<void> settle(WidgetTester tester) async {
    await container.read(savedRequestsControllerProvider.future);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    _MemoryRepository? storage,
  }) async {
    activeRepository = storage ?? repository;
    await container.read(savedRequestsControllerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CollectionsScreen()),
      ),
    );
    await settle(tester);
    expect(find.byTooltip('Actions for Create user'), findsOneWidget);
  }

  Future<void> action(WidgetTester tester, String item, String action) async {
    await tester.tap(find.byTooltip('Actions for $item'));
    await settle(tester);
    await tester.tap(find.text(action));
    await settle(tester);
  }

  testWidgets('rename and move preserve all request fields', (tester) async {
    await open(tester);
    await action(tester, 'Create user', 'Rename request');
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Enter a name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Create account');
    await tester.tap(find.text('Save'));
    await settle(tester);
    await action(tester, 'Create account', 'Move request');
    await tester.tap(find.text('Billing').last);
    await settle(tester);
    expect(
      (await read(tester)).requests.single.toJson(),
      original.copyWith(name: 'Create account', collectionId: 'b').toJson(),
    );
    await action(tester, 'Create account', 'Move request');
    await tester.tap(find.text('Unfiled').last);
    await settle(tester);
    expect(
      (await read(tester)).requests.single.toJson(),
      original.copyWith(name: 'Create account', clearCollection: true).toJson(),
    );
  });

  testWidgets('collection rename and confirmed deletion retain requests', (
    tester,
  ) async {
    await open(tester);
    await action(tester, 'Accounts', 'Rename collection');
    await tester.enterText(find.byType(TextFormField), 'People');
    await tester.tap(find.text('Save'));
    await settle(tester);
    await action(tester, 'People', 'Delete collection');
    expect(find.textContaining('No requests will be deleted'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect((await read(tester)).collections.length, 2);
    await action(tester, 'People', 'Delete collection');
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Unfiled'), findsOneWidget);
    expect(
      (await read(tester)).requests.single.toJson(),
      original.copyWith(clearCollection: true).toJson(),
    );
  });

  testWidgets('request deletion requires confirmation', (tester) async {
    await open(tester);
    await action(tester, 'Create user', 'Delete request');
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect((await read(tester)).requests.length, 1);
    await action(tester, 'Create user', 'Delete request');
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect((await read(tester)).requests, isEmpty);
    expect(find.text('No saved requests'), findsNWidgets(2));
  });

  testWidgets('editor retains payload when only the name changes', (
    tester,
  ) async {
    await open(tester);
    await action(tester, 'Create user', 'Edit request');
    expect(find.byType(SavedRequestEditorScreen), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Updated');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.byType(SavedRequestEditorScreen), findsNothing);
    expect(
      (await read(tester)).requests.single.toJson(),
      original.copyWith(name: 'Updated').toJson(),
    );
  });

  testWidgets('editor keeps parameter changes when collapsed', (tester) async {
    await open(tester);
    await action(tester, 'Create user', 'Edit request');
    await tester.tap(find.text('Query parameters'));
    await settle(tester);
    final queryValue = find.widgetWithText(TextField, '2');
    await tester.ensureVisible(queryValue);
    await tester.enterText(queryValue, '3');
    await tester.tap(find.text('Query parameters'));
    await settle(tester);
    await tester.tap(find.text('Query parameters'));
    await settle(tester);
    expect(find.widgetWithText(TextField, '3'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(
      (await read(tester)).requests.single.toJson(),
      original.copyWith(queryParameters: {'page': '3'}).toJson(),
    );
  });

  testWidgets('failed edits retain the draft and can be retried', (
    tester,
  ) async {
    final failing = _RetryRepository(repository.snapshot);
    await open(tester, storage: failing);
    await action(tester, 'Create user', 'Edit request');
    await tester.enterText(find.byType(TextFormField).first, 'Retry draft');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Could not save request. Please retry.'), findsOneWidget);
    expect(find.text('Retry draft'), findsOneWidget);
    expect(
      (await read(tester)).requests.single.toJson(),
      original.toJson(),
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.byType(SavedRequestEditorScreen), findsNothing);
    expect((await activeRepository.load()).requests.single.name, 'Retry draft');
  });

  testWidgets('opening a saved request returns the full request', (
    tester,
  ) async {
    SavedRequest? result;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<SavedRequest>(
                    MaterialPageRoute(
                      builder: (_) => const CollectionsScreen(),
                    ),
                  );
                },
                child: const Text('Open collections'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open collections'));
    await settle(tester);
    await tester.tap(find.text('Create user'));
    await settle(tester);
    expect(result?.toJson(), original.toJson());
  });
}

class _MemoryRepository implements SavedRequestsRepository {
  new([SavedRequestsState? initial])
    : snapshot = initial ?? SavedRequestsState();

  SavedRequestsState snapshot;

  @override
  Future<SavedRequestsState> load() async => snapshot;

  @override
  Future<SavedRequestsState> saveCollection(Collection collection) async {
    return snapshot = SavedRequestsState(
      collections: [
        for (final current in snapshot.collections)
          if (current.id != collection.id) current,
        collection,
      ],
      requests: snapshot.requests,
    );
  }

  @override
  Future<SavedRequestsState> saveRequest(SavedRequest request) async {
    return snapshot = SavedRequestsState(
      collections: snapshot.collections,
      requests: [
        for (final current in snapshot.requests)
          if (current.id != request.id) current,
        request,
      ],
    );
  }

  @override
  Future<SavedRequestsState> deleteCollection(String id) async {
    return snapshot = SavedRequestsState(
      collections: snapshot.collections.where((item) => item.id != id).toList(),
      requests: snapshot.requests.map((request) {
        return request.collectionId == id
            ? request.copyWith(clearCollection: true)
            : request;
      }).toList(),
    );
  }

  @override
  Future<SavedRequestsState> deleteRequest(String id) async {
    return snapshot = SavedRequestsState(
      collections: snapshot.collections,
      requests: snapshot.requests.where((request) => request.id != id).toList(),
    );
  }
}

class _RetryRepository extends _MemoryRepository {
  new(super.initial);

  var _failNext = true;

  @override
  Future<SavedRequestsState> saveRequest(SavedRequest request) async {
    if (_failNext) {
      _failNext = false;
      throw StateError('Storage unavailable');
    }
    return await super.saveRequest(request);
  }
}
