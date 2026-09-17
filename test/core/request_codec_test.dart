import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_codec.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/http/request_snapshot.dart';

void main() {
  test('round trips a request history record', () {
    final record = RequestRecord(
      id: '1',
      sentAt: DateTime.utc(2026, 9, 17, 8),
      request: const RequestSnapshot(
        method: HttpMethod.post,
        url: 'https://example.com/users',
        headers: {'Authorization': 'Bearer token'},
        queryParameters: {'page': '2'},
        body: '{"name":"Tayo"}',
        bodyType: RequestBodyType.json,
      ),
      statusCode: 201,
      durationMs: 42,
    );

    final restored = requestRecordFromJson(requestRecordToJson(record));

    expect(restored.id, record.id);
    expect(restored.sentAt, record.sentAt);
    expect(restored.request.method, HttpMethod.post);
    expect(restored.request.url, record.request.url);
    expect(restored.request.headers, record.request.headers);
    expect(restored.request.queryParameters, record.request.queryParameters);
    expect(restored.request.body, record.request.body);
    expect(restored.request.bodyType, RequestBodyType.json);
    expect(restored.statusCode, 201);
    expect(restored.durationMs, 42);
  });
}
