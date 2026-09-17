import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request_history_repository.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

final requestHistoryRepositoryProvider = FutureProvider<RequestHistoryRepository>(
  (ref) async => RequestHistoryRepository(await SharedPreferences.getInstance()),
);

final requestHistoryProvider =
    AsyncNotifierProvider<RequestHistoryController, List<RequestRecord>>(
  RequestHistoryController.new,
);

class RequestHistoryController extends AsyncNotifier<List<RequestRecord>> {
  @override
  Future<List<RequestRecord>> build() async {
    final repository = await ref.watch(requestHistoryRepositoryProvider.future);
    return repository.load();
  }

  Future<void> refresh() async {
    final repository = await ref.read(requestHistoryRepositoryProvider.future);
    state = AsyncData(repository.load());
  }

  Future<void> delete(String id) async {
    final repository = await ref.read(requestHistoryRepositoryProvider.future);
    await repository.delete(id);
    state = AsyncData(repository.load());
  }

  Future<void> clear() async {
    final repository = await ref.read(requestHistoryRepositoryProvider.future);
    await repository.clear();
    state = const AsyncData([]);
  }
}
