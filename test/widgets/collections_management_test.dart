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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalSavedRequestsRepository repository;
  late SavedRequest original;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = LocalSavedRequestsRepository(
      await SharedPreferences.getInstance(),
    );
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
  });

  Future<void> open(
    WidgetTester tester, {
    LocalSavedRequestsRepository? storage,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedRequestsRepositoryProvider.overrideWith(
            (ref) => storage ?? repository,
          ),
        ],
        child: const MaterialApp(home: CollectionsScreen()),
      ),
    );
    // The loading view contains an indeterminate progress indicator, so
    // pumpAndSettle can wait forever while the repository initializes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> action(WidgetTester tester, String item, String action) async {
    await tester.tap(find.byTooltip('Actions for $item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets('rename and move preserve all request fields', (tester) async {
    await open(tester);
    await action(tester, 'Create user', 'Rename request');
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Create account');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await action(tester, 'Create account', 'Move request');
    await tester.tap(find.text('Billing').last);
    await tester.pumpAndSettle();
    expect(
      (await repository.load()).requests.single.toJson(),
      original.copyWith(name: 'Create account', collectionId: 'b').toJson(),
    );
    await action(tester, 'Create account', 'Move request');
    await tester.tap(find.text('Unfiled').last);
    await tester.pumpAndSettle();
    expect(
      (await repository.load()).requests.single.toJson(),
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
    await tester.pumpAndSettle();
    await action(tester, 'People', 'Delete collection');
    expect(find.textContaining('No requests will be deleted'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await repository.load()).collections.length, 2);
    await action(tester, 'People', 'Delete collection');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Unfiled'), findsOneWidget);
    expect(
      (await repository.load()).requests.single.toJson(),
      original.copyWith(clearCollection: true).toJson(),
    );
  });

  testWidgets('request deletion requires confirmation', (tester) async {
    await open(tester);
    await action(tester, 'Create user', 'Delete request');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await repository.load()).requests.length, 1);
    await action(tester, 'Create user', 'Delete request');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect((await repository.load()).requests, isEmpty);
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
    await tester.pumpAndSettle();
    expect(find.byType(SavedRequestEditorScreen), findsNothing);
    expect(
      (await repository.load()).requests.single.toJson(),
      original.copyWith(name: 'Updated').toJson(),
    );
  });

  testWidgets('editor keeps parameter changes when collapsed', (tester) async {
    await open(tester);
    await action(tester, 'Create user', 'Edit request');
    await tester.tap(find.text('Query parameters'));
    await tester.pumpAndSettle();
    final queryValue = find.widgetWithText(TextField, '2');
    await tester.ensureVisible(queryValue);
    await tester.enterText(queryValue, '3');
    await tester.tap(find.text('Query parameters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Query parameters'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '3'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      (await repository.load()).requests.single.toJson(),
      original.copyWith(queryParameters: {'page': '3'}).toJson(),
    );
  });

  testWidgets('failed edits retain the draft and can be retried', (
    tester,
  ) async {
    final failing = _RetryRepository(await SharedPreferences.getInstance());
    await open(tester, storage: failing);
    await action(tester, 'Create user', 'Edit request');
    await tester.enterText(find.byType(TextFormField).first, 'Retry draft');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save request. Please retry.'), findsOneWidget);
    expect(find.text('Retry draft'), findsOneWidget);
    expect(
      (await repository.load()).requests.single.toJson(),
      original.toJson(),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedRequestEditorScreen), findsNothing);
    expect((await repository.load()).requests.single.name, 'Retry draft');
  });

  testWidgets('opening a saved request returns the full request', (
    tester,
  ) async {
    SavedRequest? result;
    await tester.pumpWidget(
      ProviderScope(
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create user'));
    await tester.pumpAndSettle();
    expect(result?.toJson(), original.toJson());
  });
}

class _RetryRepository extends LocalSavedRequestsRepository {
  new(super.preferences);

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
