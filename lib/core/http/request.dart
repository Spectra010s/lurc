enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

class HttpRequest {
  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final String? body;

  const HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParameters = const {},
    this.body,
  });
}
