import 'package:dio/dio.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/response.dart';

class LurcHttpClient {
  LurcHttpClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<HttpResponse> execute(HttpRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.request<String>(
        request.url,
        options: Options(
          method: request.method.name.toUpperCase(),
          headers: request.headers,
          responseType: ResponseType.plain,
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
        message: error.message ?? 'Request failed',
        duration: stopwatch.elapsed,
      );
    }
  }
}

class LurcHttpException implements Exception {
  const LurcHttpException({
    required this.message,
    required this.duration,
  });

  final String message;
  final Duration duration;

  @override
  String toString() => message;
}
