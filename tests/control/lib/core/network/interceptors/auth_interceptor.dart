import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  // TODO: inject your token source (e.g. secure storage) and read it here.
 String? _token;

  String? get token => _token;
  set token(String? value) => _token = value;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: handle token refresh or sign-out.
    }
    handler.next(err);
  }
}
