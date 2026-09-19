import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';

/// A consistent snapshot of the local library.
class SavedRequestsState {
  new({
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
    for (final collection in collections) {
      if (collection.parentId == collection.id ||
          (collection.parentId != null &&
              !collectionIds.contains(collection.parentId))) {
        throw const FormatException('Invalid collection parent');
      }
      final seen = <String>{collection.id};
      var parentId = collection.parentId;
      while (parentId != null) {
        if (!seen.add(parentId)) {
          throw const FormatException('Collection hierarchy contains a cycle');
        }
        final parent = collections.firstWhere(
          (value) => value.id == parentId,
        );
        parentId = parent.parentId;
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

  factory fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported saved requests version');
    }
    final collections = json['collections'];
    final requests = json['requests'];
    if (collections is! List<dynamic> || requests is! List<dynamic>) {
      throw const FormatException('Invalid saved requests data');
    }
    return SavedRequestsState(
      collections: collections
          .map((value) => Collection.fromJson(_object(value)))
          .toList(),
      requests: requests
          .map((value) => SavedRequest.fromJson(_object(value)))
          .toList(),
    );
  }

  final List<Collection> collections;
  final List<SavedRequest> requests;

  List<SavedRequest> requestsInCollection(String? collectionId) =>
      List.unmodifiable(
        requests.where((request) => request.collectionId == collectionId),
      );

  List<Collection> childCollections(String? parentId) => List.unmodifiable(
    collections.where((collection) => collection.parentId == parentId),
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'collections': collections.map((value) => value.toJson()).toList(),
    'requests': requests.map((value) => value.toJson()).toList(),
  };
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid saved library record');
  }
  return value;
}
