# Saved requests and collections

This foundation lives in `lib/core/saved_requests/`. UI and navigation integration
are intentionally left to the request-workspace worktree.

## Integration

- Watch `savedRequestsControllerProvider` for loading, error, and library state.
- Watch `collectionsProvider` for collections, or
  `savedRequestsInCollectionProvider(collectionId)` for a collection's requests.
  Pass `null` for unfiled requests.
- Use the controller's `saveCollection` and `saveRequest` methods to create or
  update records. IDs are supplied by the caller and remain stable on updates.
- Use `SavedRequest.copyWith(collectionId: id)` to move a request, or
  `copyWith(clearCollection: true)` to unfile it.
- `SavedRequest.toSnapshot()` restores the existing `RequestSnapshot`, including
  `RequestBodyType`. Query parameters, headers, raw body text, and empty values
  are preserved. `toHttpRequest()` provides transport data directly.
- Await mutations and handle their errors in the UI. State is published only
  after persistence succeeds; failed mutations leave the last successful state
  visible. Invalidate the controller provider to retry a failed initial load.

## Persistence contract

The default repository uses the existing SharedPreferences dependency under
`saved_requests_collections_v1`. It does not read or change request history.
Collections and requests share a versioned JSON snapshot so collection deletion
and request reassignment are written together. Deleting a collection unfiles its
requests; deleting a request leaves its collection intact.

Use the provider's single repository instance: operations on that instance are
queued to prevent lost updates. Independent writers from other isolates are not
supported. SharedPreferences is local storage, not encrypted secret storage or a
database with guaranteed crash durability.

Malformed data, unknown schema versions, duplicate IDs, empty IDs/names, and
orphaned collection references fail explicitly. They are not reset or overwritten.
The request URL may be empty so unfinished drafts can be saved; execution-time
validation remains the request workspace's responsibility.

## Verification

```sh
dart format --output=none --set-exit-if-changed lib/core/saved_requests test/core/saved_requests
flutter analyze
flutter test test/core/saved_requests
```

Tests cover round trips, restoration, immutable metadata, CRUD, collection
deletion, concurrent writes, corrupt data, history isolation, and provider state.
