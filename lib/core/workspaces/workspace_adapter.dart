import 'package:lurc/core/workspaces/lurc_workspace.dart';

abstract interface class WorkspaceAdapter {
  String get id;
  Future<bool> canOpen(String rootPath);
  Future<LurcWorkspace> read(String rootPath);
  Future<void> write(String rootPath, LurcWorkspace workspace);
}

class WorkspaceFormatException implements Exception {
  const new(this.message);
  final String message;

  @override
  String toString() => 'WorkspaceFormatException: $message';
}
