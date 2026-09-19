import 'package:lurc/core/workspaces/lurc_workspace.dart';
import 'package:lurc/core/workspaces/workspace_adapter.dart';

class WorkspaceAdapterRegistry {
  const new(this.adapters);
  final List<WorkspaceAdapter> adapters;

  Future<WorkspaceAdapter?> detect(String rootPath) async {
    for (final adapter in adapters) {
      if (await adapter.canOpen(rootPath)) return adapter;
    }
    return null;
  }

  Future<LurcWorkspace> open(String rootPath) async {
    final adapter = await detect(rootPath);
    if (adapter == null) {
      throw const WorkspaceFormatException('Unsupported workspace format');
    }
    return adapter.read(rootPath);
  }
}
