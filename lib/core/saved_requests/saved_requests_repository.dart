import 'dart:convert';

import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SavedRequestsRepository {
  Future<SavedRequestsState> load();
  Future<SavedRequestsState> saveCollection(Collection collection);
  Future<SavedRequestsState> saveRequest(SavedRequest request);
  Future<SavedRequestsState> deleteCollection(String id);
  Future<SavedRequestsState> deleteRequest(String id);
}

/// Use one repository instance for the saved library within the application.
/// Mutations serialize the complete snapshot under a separate preferences key.
/// Invalid data is never silently reset.
class LocalSavedRequestsRepository implements SavedRequestsRepository {
  new(this.preferences);

  static const storageKey = 'saved_requests_collections_v1';
  final SharedPreferences preferences;
  Future<void> _pending = Future<void>.value();

  Future<SavedRequestsState> _enqueue(
    Future<SavedRequestsState> Function() operation,
  ) {
    final result = _pending.then((_) => operation());
    // A failed operation must not prevent subsequent reads or writes.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<SavedRequestsState> load() => _enqueue(_read);

  Future<SavedRequestsState> _read() async {
    // Reload also discards any cached value left by a failed platform write.
    await preferences.reload();
    final raw = preferences.getString(storageKey);
    if (raw == null) return SavedRequestsState();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a saved requests object');
    }
    return SavedRequestsState.fromJson(decoded);
  }

  Future<SavedRequestsState> _change(
    SavedRequestsState Function(SavedRequestsState) update,
  ) => _enqueue(() async {
    final next = update(await _read());
    final saved = await preferences.setString(
      storageKey,
      jsonEncode(next.toJson()),
    );
    if (!saved) throw StateError('Could not persist saved requests');
    return next;
  });

  @override
  Future<SavedRequestsState> saveCollection(Collection collection) => _change((
    current,
  ) {
    final collections = [...current.collections];
    final index = collections.indexWhere((value) => value.id == collection.id);
    if (index < 0) {
      collections.add(collection);
    } else {
      collections[index] = collection;
    }
    return SavedRequestsState(
      collections: collections,
      requests: current.requests,
    );
  });

  @override
  Future<SavedRequestsState> saveRequest(SavedRequest request) =>
      _change((current) {
        final requests = [...current.requests];
        final index = requests.indexWhere((value) => value.id == request.id);
        if (index < 0) {
          requests.add(request);
        } else {
          requests[index] = request;
        }
        return SavedRequestsState(
          collections: current.collections,
          requests: requests,
        );
      });

  /// Removing a collection keeps its requests and child folders.
  /// Requests move to Unfiled and direct children move to the deleted
  /// collection's parent.
  @override
  Future<SavedRequestsState> deleteCollection(String id) => _change((current) {
    final removed = current.collections.firstWhere((value) => value.id == id);
    return SavedRequestsState(
      collections: current.collections
          .where((value) => value.id != id)
          .map(
            (value) => value.parentId == id
                ? value.copyWith(
                    parentId: removed.parentId,
                    clearParent: removed.parentId == null,
                  )
                : value,
          )
          .toList(),
      requests: current.requests
          .map(
            (value) => value.collectionId == id
                ? value.copyWith(clearCollection: true)
                : value,
          )
          .toList(),
    );
  });

  @override
  Future<SavedRequestsState> deleteRequest(String id) => _change(
    (current) => SavedRequestsState(
      collections: current.collections,
      requests: current.requests.where((value) => value.id != id).toList(),
    ),
  );
}
