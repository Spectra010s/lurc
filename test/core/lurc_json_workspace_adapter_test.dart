import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/workspaces/lurc_json_workspace_adapter.dart';
import 'package:lurc/core/workspaces/lurc_workspace.dart';

void main() {
  test('native adapter round trips without exporting secrets', () async {
    final root = await Directory.systemTemp.createTemp('lurc-workspace-');
    addTearDown(() => root.delete(recursive: true));
    const adapter = LurcJsonWorkspaceAdapter();
    final workspace = LurcWorkspace(
      name: 'Example API',
      collections: const [Collection(id: 'api', name: 'API')],
      requests: [
        SavedRequest(
          id: 'users',
          name: 'Users',
          method: HttpMethod.get,
          url: 'https://example.com/users',
          collectionId: 'api',
        ),
      ],
      environments: const [
        Environment(
          id: 'dev',
          name: 'Development',
          variables: [
            EnvironmentVariable(key: 'baseUrl', value: 'https://example.com'),
            EnvironmentVariable(
              key: 'token',
              value: 'do-not-export',
              secret: true,
            ),
          ],
        ),
      ],
    );

    await adapter.write(root.path, workspace);
    expect(await adapter.canOpen(root.path), isTrue);
    final raw = await File(
      root.path + '/.lurc/environments.json',
    ).readAsString();
    expect(raw, isNot(contains('do-not-export')));

    final restored = await adapter.read(root.path);
    expect(restored.name, 'Example API');
    expect(restored.requests.single.name, 'Users');
    expect(restored.environments.single.variables.last.secret, isTrue);
    expect(restored.environments.single.variables.last.value, isEmpty);
  });
}
