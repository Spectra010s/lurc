import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_history_repository.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/http/request_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('caps persisted history at 100 newest entries', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = RequestHistoryRepository(preferences);

    for (var index = 0; index < 101; index++) {
      await repository.save(
        RequestRecord(
          id: '$index',
          sentAt: DateTime.utc(2026, 9, 17).add(Duration(seconds: index)),
          request: RequestSnapshot(
            method: HttpMethod.get,
            url: 'https://example.com/$index',
          ),
        ),
      );
    }

    final records = repository.load();
    expect(records, hasLength(RequestHistoryRepository.maxEntries));
    expect(records.first.id, '100');
    expect(records.last.id, '1');
  });

  test('saves, loads, deletes, and clears history', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = RequestHistoryRepository(preferences);
    final record = RequestRecord(
      id: '1',
      sentAt: DateTime.utc(2026, 9, 17),
      request: const RequestSnapshot(
        method: HttpMethod.get,
        url: 'https://example.com',
      ),
      statusCode: 200,
      durationMs: 10,
    );

    await repository.save(record);
    expect(repository.load().single.request.url, 'https://example.com');

    await repository.delete(record.id);
    expect(repository.load(), isEmpty);

    await repository.save(record);
    await repository.clear();
    expect(repository.load(), isEmpty);
  });
}
