import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';

class RequestSnapshot {
  const new({
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParameters = const {},
    this.body,
    this.bodyType = RequestBodyType.none,
  });

  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final String? body;
  final RequestBodyType bodyType;

  HttpRequest toHttpRequest() => HttpRequest(
        method: method,
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
      );
}
