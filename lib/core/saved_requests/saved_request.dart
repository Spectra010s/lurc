import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_snapshot.dart';

class SavedRequest {
  new({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.collectionId,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    this.body,
    this.bodyType = RequestBodyType.none,
  }) : queryParameters = Map.unmodifiable(queryParameters),
       headers = Map.unmodifiable(headers);

  factory fromJson(Map<String, dynamic> json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'method': final String methodName,
      'url': final String url,
      'bodyType': final String bodyTypeName,
    }) {
      final collectionId = json['collectionId'];
      final body = json['body'];
      if ((collectionId != null && collectionId is! String) ||
          (body != null && body is! String)) {
        throw const FormatException('Invalid saved request text');
      }
      final methods = HttpMethod.values.where(
        (value) => value.name == methodName,
      );
      final bodyTypes = RequestBodyType.values.where(
        (value) => value.name == bodyTypeName,
      );
      if (methods.isEmpty || bodyTypes.isEmpty) {
        throw const FormatException('Unknown request method or body type');
      }
      return SavedRequest(
        id: id,
        name: name,
        method: methods.single,
        url: url,
        collectionId: collectionId as String?,
        queryParameters: _stringMap(json['queryParameters']),
        headers: _stringMap(json['headers']),
        body: body as String?,
        bodyType: bodyTypes.single,
      );
    }
    throw const FormatException('Invalid saved request data');
  }

  final String id;
  final String name;
  final HttpMethod method;
  final String url;
  final String? collectionId;
  final Map<String, String> queryParameters;
  final Map<String, String> headers;
  final String? body;
  final RequestBodyType bodyType;

  SavedRequest copyWith({
    String? name,
    HttpMethod? method,
    String? url,
    String? collectionId,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    String? body,
    RequestBodyType? bodyType,
    bool clearCollection = false,
    bool clearBody = false,
  }) => SavedRequest(
    id: id,
    name: name ?? this.name,
    method: method ?? this.method,
    url: url ?? this.url,
    collectionId: clearCollection ? null : collectionId ?? this.collectionId,
    queryParameters: queryParameters ?? this.queryParameters,
    headers: headers ?? this.headers,
    body: clearBody ? null : body ?? this.body,
    bodyType: bodyType ?? this.bodyType,
  );

  RequestSnapshot toSnapshot() => RequestSnapshot(
    method: method,
    url: url,
    queryParameters: queryParameters,
    headers: headers,
    body: body,
    bodyType: bodyType,
  );

  HttpRequest toHttpRequest() => toSnapshot().toHttpRequest();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'method': method.name,
    'url': url,
    'collectionId': collectionId,
    'queryParameters': queryParameters,
    'headers': headers,
    'body': body,
    'bodyType': bodyType.name,
  };
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid request metadata');
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    final text = entry.value;
    if (text is! String) throw const FormatException('Invalid metadata value');
    result[entry.key] = text;
  }
  return result;
}
