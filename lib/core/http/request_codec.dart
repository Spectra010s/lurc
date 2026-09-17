import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/http/request_snapshot.dart';

Map<String, Object?> requestRecordToJson(RequestRecord record) => {
      'id': record.id,
      'sentAt': record.sentAt.toIso8601String(),
      'method': record.request.method.name,
      'url': record.request.url,
      'headers': record.request.headers,
      'queryParameters': record.request.queryParameters,
      'body': record.request.body,
      'bodyType': record.request.bodyType,
      'statusCode': record.statusCode,
      'durationMs': record.durationMs,
    };

RequestRecord requestRecordFromJson(Map<String, Object?> json) {
  final methodName = json['method'] as String? ?? HttpMethod.get.name;
  final method = HttpMethod.values.firstWhere(
    (value) => value.name == methodName,
    orElse: () => HttpMethod.get,
  );

  return RequestRecord(
    id: json['id'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    request: RequestSnapshot(
      method: method,
      url: json['url'] as String? ?? '',
      headers: _stringMap(json['headers']),
      queryParameters: _stringMap(json['queryParameters']),
      body: json['body'] as String?,
      bodyType: json['bodyType'] as String? ?? 'none',
    ),
    statusCode: json['statusCode'] as int?,
    durationMs: json['durationMs'] as int?,
  );
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, item) => MapEntry(key.toString(), item.toString()),
  );
}
