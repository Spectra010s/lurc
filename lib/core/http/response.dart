class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.duration,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final Duration duration;
}
