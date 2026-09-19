import 'dart:convert';
import 'dart:io';

import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/workspaces/lurc_workspace.dart';
import 'package:lurc/core/workspaces/workspace_adapter.dart';

class LurcJsonWorkspaceAdapter implements WorkspaceAdapter {
  const new();

  @override
  String get id => 'lurc-json-v1';

  Directory _directory(String rootPath) => Directory(
    rootPath.endsWith('.lurc')
        ? rootPath
        : '$rootPath${Platform.pathSeparator}.lurc',
  );

  @override
  Future<bool> canOpen(String rootPath) => Future.value(
    File(
      '${_directory(rootPath).path}${Platform.pathSeparator}workspace.json',
    ).existsSync(),
  );

  @override
  Future<LurcWorkspace> read(String rootPath) async {
    final directory = _directory(rootPath);
    final metadata = await _readObject(directory, 'workspace.json');
    if (metadata['version'] != 1 || metadata['name'] is! String) {
      throw const WorkspaceFormatException('Unsupported Lurc workspace');
    }
    return LurcWorkspace(
      name: metadata['name'] as String,
      collections: (await _readList(directory, 'collections.json'))
          .map(Collection.fromJson)
          .toList(growable: false),
      requests: (await _readList(directory, 'requests.json'))
          .map(SavedRequest.fromJson)
          .toList(growable: false),
      environments: (await _readList(directory, 'environments.json'))
          .map(
            (value) => Environment.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> write(String rootPath, LurcWorkspace workspace) async {
    final directory = _directory(rootPath);
    await directory.create(recursive: true);
    await _writeJson(directory, 'workspace.json', {
      'version': 1,
      'name': workspace.name,
    });
    await _writeJson(directory, 'collections.json',
        workspace.collections.map((value) => value.toJson()).toList());
    await _writeJson(directory, 'requests.json',
        workspace.requests.map((value) => value.toJson()).toList());
    await _writeJson(directory, 'environments.json',
        workspace.environments.map(_shareableEnvironment).toList());
  }

  Map<String, Object> _shareableEnvironment(Environment environment) => {
    'id': environment.id,
    'name': environment.name,
    'variables': environment.variables.map((variable) => {
      'key': variable.key,
      'value': variable.secret ? '' : variable.value,
      if (variable.secret) 'secret': true,
    }).toList(),
  };

  Future<Map<String, dynamic>> _readObject(
    Directory directory,
    String name,
  ) async {
    final decoded = jsonDecode(
      File(
        '${directory.path}${Platform.pathSeparator}$name',
      ).readAsStringSync(),
    );
    if (decoded is! Map<String, dynamic>) {
      throw WorkspaceFormatException('$name must contain a JSON object');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> _readList(
    Directory directory,
    String name,
  ) async {
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    if (!file.existsSync()) return const [];
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      throw WorkspaceFormatException('$name must contain a JSON array');
    }
    return decoded.map((value) {
      if (value is! Map<String, dynamic>) {
        throw WorkspaceFormatException('$name contains an invalid record');
      }
      return value;
    }).toList(growable: false);
  }

  Future<void> _writeJson(
    Directory directory,
    String name,
    Object value,
  ) {
    final content = const JsonEncoder.withIndent('  ').convert(value);
    return File('${directory.path}${Platform.pathSeparator}$name')
        .writeAsString('$content\\n');
  }
}
