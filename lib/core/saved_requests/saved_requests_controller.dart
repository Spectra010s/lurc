import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_repository.dart';
import 'package:lurc/core/saved_requests/saved_requests_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final savedRequestsRepositoryProvider = FutureProvider<SavedRequestsRepository>(
  (ref) async =>
      LocalSavedRequestsRepository(await SharedPreferences.getInstance()),
);

final savedRequestsControllerProvider =
    AsyncNotifierProvider<SavedRequestsController, SavedRequestsState>(
      SavedRequestsController.new,
    );

final collectionsProvider = Provider<AsyncValue<List<Collection>>>(
  (ref) => ref
      .watch(savedRequestsControllerProvider)
      .whenData((value) => value.collections),
);

final ProviderFamily<AsyncValue<List<SavedRequest>>, String?>
savedRequestsInCollectionProvider =
    Provider.family<AsyncValue<List<SavedRequest>>, String?>(
      (ref, collectionId) => ref
          .watch(savedRequestsControllerProvider)
          .whenData((value) => value.requestsInCollection(collectionId)),
    );

class SavedRequestsController extends AsyncNotifier<SavedRequestsState> {
  @override
  Future<SavedRequestsState> build() async {
    final repository = await ref.watch(savedRequestsRepositoryProvider.future);
    return await repository.load();
  }

  /// Publish only persisted snapshots; callers receive write failures while the
  /// previous state remains available for retrying.
  Future<void> _write(
    Future<SavedRequestsState> Function(SavedRequestsRepository) operation,
  ) async {
    await future;
    final repository = await ref.read(savedRequestsRepositoryProvider.future);
    final next = await operation(repository);
    if (ref.mounted) state = AsyncData(next);
  }

  Future<void> saveCollection(Collection collection) =>
      _write((repository) => repository.saveCollection(collection));

  Future<void> saveRequest(SavedRequest request) =>
      _write((repository) => repository.saveRequest(request));

  Future<void> deleteCollection(String id) =>
      _write((repository) => repository.deleteCollection(id));

  Future<void> deleteRequest(String id) =>
      _write((repository) => repository.deleteRequest(id));
}
