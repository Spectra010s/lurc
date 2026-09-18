import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/environments/environment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _activeEnvironmentKey = 'active_environment_id_v1';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final environmentRepositoryProvider = FutureProvider<EnvironmentRepository>(
  (ref) async => LocalEnvironmentRepository(
    await ref.watch(sharedPreferencesProvider.future),
  ),
);

final environmentsControllerProvider =
    AsyncNotifierProvider<EnvironmentsController, List<Environment>>(
      EnvironmentsController.new,
    );

final activeEnvironmentIdProvider =
    NotifierProvider<ActiveEnvironmentIdController, String?>(
      ActiveEnvironmentIdController.new,
    );

final activeEnvironmentProvider = Provider<Environment?>((ref) {
  final id = ref.watch(activeEnvironmentIdProvider);
  final environments = ref.watch(environmentsControllerProvider).value;
  if (id == null || environments == null) return null;
  for (final environment in environments) {
    if (environment.id == id) return environment;
  }
  return null;
});

class ActiveEnvironmentIdController extends Notifier<String?> {
  @override
  String? build() {
    unawaited(_restore());
    return null;
  }

  String? get selectedId => state;

  set selectedId(String? id) {
    state = id;
    unawaited(_persist(id));
  }

  Future<void> _restore() async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    if (!ref.mounted) return;
    final savedId = preferences.getString(_activeEnvironmentKey);
    final environments = await ref.read(environmentsControllerProvider.future);
    if (!ref.mounted || savedId == null) return;
    if (environments.any((environment) => environment.id == savedId)) {
      state = savedId;
    } else {
      await preferences.remove(_activeEnvironmentKey);
    }
  }

  Future<void> _persist(String? id) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    if (id == null) {
      await preferences.remove(_activeEnvironmentKey);
    } else {
      await preferences.setString(_activeEnvironmentKey, id);
    }
  }
}

class EnvironmentsController extends AsyncNotifier<List<Environment>> {
  @override
  Future<List<Environment>> build() async {
    final repository = await ref.watch(environmentRepositoryProvider.future);
    return await repository.load();
  }

  Future<void> save(Environment environment) async {
    await future;
    final repository = await ref.read(environmentRepositoryProvider.future);
    final next = await repository.save(environment);
    if (ref.mounted) state = AsyncData(next);
  }

  Future<void> delete(String id) async {
    await future;
    final repository = await ref.read(environmentRepositoryProvider.future);
    final next = await repository.delete(id);
    if (ref.mounted) state = AsyncData(next);
    if (ref.read(activeEnvironmentIdProvider) == id) {
      ref.read(activeEnvironmentIdProvider.notifier).selectedId = null;
    }
  }
}
