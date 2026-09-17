import 'package:dio/dio.dart';
import 'package:lurc/core/http/http_error.dart';
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
      final type = _typeFor(error);
      throw LurcHttpException(
        message: _messageFor(type, error),
        duration: stopwatch.elapsed,
        type: type,
      );
    }
  }

  HttpErrorType _typeFor(DioException error) {
    return switch (error.type) {
      DioExceptionType.cancel => HttpErrorType.cancelled,
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => HttpErrorType.timeout,
      DioExceptionType.connectionError => HttpErrorType.connection,
      DioExceptionType.badCertificate => HttpErrorType.certificate,
      _ => HttpErrorType.other,
    };
  }

  String _messageFor(HttpErrorType type, DioException error) {
    return switch (type) {
      HttpErrorType.cancelled => 'Request cancelled',
      HttpErrorType.timeout => 'Request timed out',
      HttpErrorType.connection =>
        'Could not connect to the server. Check the address and your network.',
      HttpErrorType.certificate => 'The server certificate is not trusted.',
      HttpErrorType.other => error.message ?? 'Request failed',
    };
  }
}

class LurcHttpException implements Exception {
  const new({
    required this.message,
    required this.duration,
    required this.type,
  });

  final String message;
  final Duration duration;
  final HttpErrorType type;

  @override
  String toString() => message;
}
