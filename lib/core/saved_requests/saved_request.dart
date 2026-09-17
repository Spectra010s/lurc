import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_snapshot.dart';

class SavedRequest {
  SavedRequest({
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

  factory SavedRequest.fromJson(Map<String, dynamic> json) {
    return SavedRequest(
      id: json['id'] as String,
      name: json['name'] as String,
      method: HttpMethod.values.byName(json['method'] as String),
      url: json['url'] as String,
      collectionId: json['collectionId'] as String?,
      queryParameters: Map<String, String>.from(json['queryParameters'] as Map),
      headers: Map<String, String>.from(json['headers'] as Map),
      body: json['body'] as String?,
      bodyType: RequestBodyType.values.byName(json['bodyType'] as String),
    );
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
