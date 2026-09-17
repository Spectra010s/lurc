import 'package:lurc/core/http/request_snapshot.dart';

class RequestRecord {
  const new({
    required this.id,
    required this.sentAt,
    required this.request,
    this.statusCode,
    this.durationMs,
  });

  final String id;
  final DateTime sentAt;
  final RequestSnapshot request;
  final int? statusCode;
  final int? durationMs;
}
