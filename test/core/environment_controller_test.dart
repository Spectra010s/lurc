import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/core/environments/environment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _first = Environment(id: 'first', name: 'First');
const _second = Environment(id: 'second', name: 'Second');
const _activeKey = 'active_environment_id_v1';

class _DelayedRepository implements EnvironmentRepository {
  final Completer<List<Environment>> loaded = Completer<List<Environment>>();
  final Completer<List<Environment>> changed = Completer<List<Environment>>();
  final Completer<void> started = Completer<void>();

  @override
  Future<List<Environment>> load() => loaded.future;

  @override
  Future<List<Environment>> save(Environment environment) {
    started.complete();
    return changed.future;
  }

  @override
  Future<List<Environment>> delete(String id) {
    started.complete();
    return changed.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('selection persists, restores, and clears across containers', () async {
    final preferences = await SharedPreferences.getInstance();
    await LocalEnvironmentRepository(preferences).save(_first);
    final container = ProviderContainer();
    final controller = container.read(activeEnvironmentIdProvider.notifier);
    await controller.ready;
    controller.selectedId = _first.id;
    await controller.persisted;
    container.dispose();

    final restored = ProviderContainer();
    addTearDown(restored.dispose);
    final selection = restored.read(activeEnvironmentIdProvider.notifier);
    await selection.ready;
    expect(selection.selectedId, _first.id);
    expect(restored.read(activeEnvironmentProvider)?.name, 'First');
    selection.selectedId = null;
    await selection.persisted;
    expect(preferences.getString(_activeKey), isNull);
  });

  test('stale persisted selection is removed', () async {
    SharedPreferences.setMockInitialValues({_activeKey: 'missing'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(activeEnvironmentIdProvider.notifier);
    await controller.ready;
    expect(controller.selectedId, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_activeKey), isNull);
  });

  test('disposal before preferences complete is safe', () async {
    final preferences = await SharedPreferences.getInstance();
    final pending = Completer<SharedPreferences>();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => pending.future),
      ],
    );
    final ready = container.read(activeEnvironmentIdProvider.notifier).ready;
    container.dispose();
    pending.complete(preferences);
    await ready;
  });

  test('disposal while environments load is safe', () async {
    SharedPreferences.setMockInitialValues({_activeKey: _first.id});
    final repository = _DelayedRepository();
    final container = ProviderContainer(
      overrides: [
        environmentRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    final ready = container.read(activeEnvironmentIdProvider.notifier).ready;
    await container.read(sharedPreferencesProvider.future);
    await container.pump();
    container.dispose();
    repository.loaded.complete([_first]);
    await ready;
  });

  test('new selection wins over delayed restoration', () async {
    SharedPreferences.setMockInitialValues({_activeKey: _first.id});
    final repository = _DelayedRepository();
    final container = ProviderContainer(
      overrides: [
        environmentRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(activeEnvironmentIdProvider.notifier);
    await container.read(sharedPreferencesProvider.future);
    await container.pump();
    controller.selectedId = _second.id;
    repository.loaded.complete([_first, _second]);
    await controller.ready;
    await controller.persisted;
    expect(controller.selectedId, _second.id);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_activeKey), _second.id);
  });

  test('rapid selections persist in order', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(activeEnvironmentIdProvider.notifier)
      ..selectedId = _first.id
      ..selectedId = _second.id
      ..selectedId = null;
    await controller.ready;
    await controller.persisted;
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_activeKey), isNull);
  });

  test('create edit and delete update active environment', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final selection = container.read(activeEnvironmentIdProvider.notifier);
    await selection.ready;
    final controller = container.read(environmentsControllerProvider.notifier);
    await controller.save(_first);
    selection.selectedId = _first.id;
    await controller.save(_first.copyWith(name: 'Updated'));
    expect(container.read(activeEnvironmentProvider)?.name, 'Updated');
    await controller.delete(_first.id);
    await selection.persisted;
    expect(container.read(activeEnvironmentIdProvider), isNull);
    expect(
      await container.read(environmentsControllerProvider.future),
      isEmpty,
    );
  });

  for (final deleting in [false, true]) {
    test('dispose during ${deleting ? 'delete' : 'save'} is safe', () async {
      final repository = _DelayedRepository();
      final container = ProviderContainer(
        overrides: [
          environmentRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      repository.loaded.complete([_first]);
      await container.read(environmentsControllerProvider.future);
      final controller = container.read(
        environmentsControllerProvider.notifier,
      );
      final operation = deleting
          ? controller.delete(_first.id)
          : controller.save(_second);
      await repository.started.future;
      container.dispose();
      repository.changed.complete([]);
      await operation;
    });
  }

  test(
    'repository migrates legacy variables and persists secret metadata',
    () async {
    SharedPreferences.setMockInitialValues({
      'environments_v1':
          '[{"id":"legacy","name":"Legacy","variables":{"token":"abc"}}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalEnvironmentRepository(preferences);
    final legacy = (await repository.load()).single;
    expect(legacy.resolvedVariables, {'token': 'abc'});
    expect(legacy.variables.single.secret, isFalse);

    await repository.save(
      legacy.copyWith(
        variables: const [
          EnvironmentVariable(key: 'token', value: 'abc', secret: true),
        ],
      ),
    );
    final restored = (await repository.load()).single;
      expect(restored.variables.single.secret, isTrue);
    },
  );

  test('concurrent repository writes retain every environment', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalEnvironmentRepository(preferences);
    await Future.wait([repository.save(_first), repository.save(_second)]);
    expect((await repository.load()).map((item) => item.id), [
      'first',
      'second',
    ]);
  });
}
