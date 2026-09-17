import 'dart:convert';

import 'package:lurc/core/environments/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class EnvironmentRepository {
  Future<List<Environment>> load();
  Future<List<Environment>> save(Environment environment);
  Future<List<Environment>> delete(String id);
}

class LocalEnvironmentRepository implements EnvironmentRepository {
  LocalEnvironmentRepository(this._preferences);

  static const _storageKey = 'environments_v1';
  final SharedPreferences _preferences;

  @override
  Future<List<Environment>> load() async {
    await _preferences.reload();
    final raw = _preferences.getString(_storageKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('Invalid environments');
    return decoded
        .map(
          (item) => Environment.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Environment>> save(Environment environment) async {
    final environments = [...await load()];
    final index = environments.indexWhere((item) => item.id == environment.id);
    if (index == -1) {
      environments.add(environment);
    } else {
      environments[index] = environment;
    }
    await _persist(environments);
    return List.unmodifiable(environments);
  }

  @override
  Future<List<Environment>> delete(String id) async {
    final environments = [...await load()]..removeWhere((item) => item.id == id);
    await _persist(environments);
    return List.unmodifiable(environments);
  }

  Future<void> _persist(List<Environment> environments) async {
    final encoded = jsonEncode(
      environments.map((environment) => environment.toJson()).toList(),
    );
    final saved = await _preferences.setString(_storageKey, encoded);
    if (!saved) throw StateError('Could not persist environments');
  }
}
