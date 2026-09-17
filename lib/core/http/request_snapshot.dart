import 'package:lurc/core/http/request.dart';

class RequestSnapshot {
  const new({
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParameters = const {},
    this.body,
    this.bodyType = 'none',
  });

  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final String? body;
  final String bodyType;

  HttpRequest toHttpRequest() => HttpRequest(
        method: method,
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
      );
}
