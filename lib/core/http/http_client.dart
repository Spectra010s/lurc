import 'package:dio/dio.dart';

import 'request.dart';
import 'response.dart';

class LurcHttpClient {
  final Dio _dio;

  LurcHttpClient({Dio? dio}) : _dio = dio ?? Dio();

  Future<HttpResponse> execute(HttpRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.request<String>(
        request.url,
        options: Options(
          method: request.method.name.toUpperCase(),
          headers: request.headers,
          responseType: ResponseType.plain,
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
        message: error.message ?? 'Request failed',
        duration: stopwatch.elapsed,
      );
    }
  }
}

class LurcHttpException implements Exception {
  final String message;
  final Duration duration;

  const LurcHttpException({
    required this.message,
    required this.duration,
  });

  @override
  String toString() => message;
}
