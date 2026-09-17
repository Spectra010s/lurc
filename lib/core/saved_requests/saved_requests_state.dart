import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';

/// A consistent snapshot of the local library.
class SavedRequestsState {
  SavedRequestsState({
    List<Collection> collections = const [],
    List<SavedRequest> requests = const [],
  }) : collections = List.unmodifiable(collections),
       requests = List.unmodifiable(requests) {
    final collectionIds = <String>{};
    for (final collection in collections) {
      if (collection.id.trim().isEmpty ||
          collection.name.trim().isEmpty ||
          !collectionIds.add(collection.id)) {
        throw const FormatException('Invalid or duplicate collection');
      }
    }
    final requestIds = <String>{};
    for (final request in requests) {
      if (request.id.trim().isEmpty ||
          request.name.trim().isEmpty ||
          !requestIds.add(request.id) ||
          (request.collectionId != null &&
              !collectionIds.contains(request.collectionId))) {
        throw const FormatException('Invalid request or collection reference');
      }
    }
  }

  factory SavedRequestsState.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported saved requests version');
    }
    try {
      return SavedRequestsState(
        collections: (json['collections'] as List<dynamic>)
            .map((value) => Collection.fromJson(value as Map<String, dynamic>))
            .toList(),
        requests: (json['requests'] as List<dynamic>)
            .map(
              (value) => SavedRequest.fromJson(value as Map<String, dynamic>),
            )
            .toList(),
      );
    } on TypeError {
      throw const FormatException('Invalid saved requests data');
    } on ArgumentError {
      throw const FormatException('Invalid saved request enum value');
    }
  }

  final List<Collection> collections;
  final List<SavedRequest> requests;

  /// A null collection ID selects unfiled requests.
  List<SavedRequest> requestsInCollection(String? collectionId) =>
      List.unmodifiable(
        requests.where((request) => request.collectionId == collectionId),
      );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'collections': collections.map((value) => value.toJson()).toList(),
    'requests': requests.map((value) => value.toJson()).toList(),
  };
}
