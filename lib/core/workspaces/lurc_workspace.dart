import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';

class LurcWorkspace {
  const new({
    required this.name,
    this.collections = const [],
    this.requests = const [],
    this.environments = const [],
  });

  final String name;
  final List<Collection> collections;
  final List<SavedRequest> requests;
  final List<Environment> environments;
}
