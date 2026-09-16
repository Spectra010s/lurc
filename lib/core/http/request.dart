enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

class HttpRequest {
  const new({
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParameters = const {},
    this.body,
  });

  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final String? body;
}
