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
  var _revision = 0;
  late Future<void> _ready;
  Future<void> _pending = Future<void>.value();

  @override
  String? build() {
    final lifecycle = ref;
    final revision = ++_revision;
    _ready = _restore(lifecycle, revision);
    return null;
  }

  Future<void> get ready => _ready;

  Future<void> get persisted => _pending;

  String? get selectedId => state;

  set selectedId(String? id) {
    _revision++;
    state = id;
    final preferences = ref.read(sharedPreferencesProvider.future);
    final write = _pending.then((_) => _persist(preferences, id));
    _pending = write;
    unawaited(write);
  }

  Future<void> _restore(Ref lifecycle, int revision) async {
    final preferences = await lifecycle.read(sharedPreferencesProvider.future);
    if (!lifecycle.mounted || revision != _revision) return;
    final savedId = preferences.getString(_activeEnvironmentKey);
    if (savedId == null) return;
    final environments = await lifecycle.read(
      environmentsControllerProvider.future,
    );
    if (!lifecycle.mounted || revision != _revision) return;
    if (environments.any((environment) => environment.id == savedId)) {
      state = savedId;
    } else {
      await preferences.remove(_activeEnvironmentKey);
    }
  }

  Future<void> _persist(
    Future<SharedPreferences> preferencesFuture,
    String? id,
  ) async {
    final preferences = await preferencesFuture;
    final saved = id == null
        ? await preferences.remove(_activeEnvironmentKey)
        : await preferences.setString(_activeEnvironmentKey, id);
    if (!saved) throw StateError('Could not persist active environment');
  }
}

class EnvironmentsController extends AsyncNotifier<List<Environment>> {
  @override
  Future<List<Environment>> build() async {
    final repository = await ref.watch(environmentRepositoryProvider.future);
    return await repository.load();
  }

  Future<void> save(Environment environment) async {
    final lifecycle = ref;
    await future;
    if (!lifecycle.mounted) return;
    final repository = await lifecycle.read(
      environmentRepositoryProvider.future,
    );
    if (!lifecycle.mounted) return;
    final next = await repository.save(environment);
    if (!lifecycle.mounted) return;
    state = AsyncData(next);
  }

  Future<void> delete(String id) async {
    final lifecycle = ref;
    await future;
    if (!lifecycle.mounted) return;
    final repository = await lifecycle.read(
      environmentRepositoryProvider.future,
    );
    if (!lifecycle.mounted) return;
    final next = await repository.delete(id);
    if (!lifecycle.mounted) return;
    state = AsyncData(next);
    if (ref.read(activeEnvironmentIdProvider) == id) {
      ref.read(activeEnvironmentIdProvider.notifier).selectedId = null;
    }
  }
}
