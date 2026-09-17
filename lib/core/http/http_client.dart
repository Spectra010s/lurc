import 'package:dio/dio.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/response.dart';

class LurcHttpClient {
  new({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<HttpResponse> execute(
    HttpRequest request, {
    CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.request<String>(
        request.url,
        cancelToken: cancelToken,
        options: Options(
          method: request.method.name.toUpperCase(),
          headers: request.headers,
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
        ),
        queryParameters: request.queryParameters,
        data: request.body,
      );

      stopwatch.stop();

      return HttpResponse(
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map.map(
          (key, values) => MapEntry(key, values.join(', ')),
        ),
        body: response.data ?? '',
        duration: stopwatch.elapsed,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      throw LurcHttpException(
        message: _messageFor(error),
        duration: stopwatch.elapsed,
        cancelled: error.type == DioExceptionType.cancel,
      );
    }
  }

  String _messageFor(DioException error) {
    return switch (error.type) {
      DioExceptionType.cancel => 'Request cancelled',
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Request timed out',
      DioExceptionType.connectionError =>
        'Could not connect to the server. Check the address and your network.',
      DioExceptionType.badCertificate => 'The server certificate is not trusted.',
      _ => error.message ?? 'Request failed',
    };
  }
}

class LurcHttpException implements Exception {
  const new({
    required this.message,
    required this.duration,
    this.cancelled = false,
  });

  final String message;
  final Duration duration;
  final bool cancelled;

  @override
  String toString() => message;
}
