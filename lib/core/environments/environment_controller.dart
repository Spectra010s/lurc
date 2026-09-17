import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/environments/environment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final environmentRepositoryProvider = FutureProvider<EnvironmentRepository>(
  (ref) async =>
      LocalEnvironmentRepository(await SharedPreferences.getInstance()),
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
  String? build() => null;

  void select(String? id) => state = id;
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
      ref.read(activeEnvironmentIdProvider.notifier).select(null);
    }
  }
}
