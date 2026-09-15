import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/http_client.dart';
import '../../core/http/request.dart';
import '../../core/http/response.dart';

class RequestState {
  const RequestState({
    this.method = HttpMethod.get,
    this.response,
    this.error,
    this.loading = false,
  });

  final HttpMethod method;
  final HttpResponse? response;
  final String? error;
  final bool loading;

  RequestState copyWith({
    HttpMethod? method,
    HttpResponse? response,
    String? error,
    bool? loading,
    bool clearResponse = false,
    bool clearError = false,
  }) {
    return RequestState(
      method: method ?? this.method,
      response: clearResponse ? null : response ?? this.response,
      error: clearError ? null : error ?? this.error,
      loading: loading ?? this.loading,
    );
  }
}

final httpClientProvider = Provider<LurcHttpClient>((ref) => LurcHttpClient());

final requestControllerProvider =
    NotifierProvider<RequestController, RequestState>(RequestController.new);

class RequestController extends Notifier<RequestState> {
  @override
  RequestState build() => const RequestState();

  void setMethod(HttpMethod method) {
    state = state.copyWith(method: method);
  }

  Future<void> send({required String url, String? body}) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      state = state.copyWith(error: 'Enter a URL', clearResponse: true);
      return;
    }

    state = state.copyWith(
      loading: true,
      clearError: true,
      clearResponse: true,
    );

    try {
      final response = await ref.read(httpClientProvider).execute(
            HttpRequest(
              method: state.method,
              url: trimmedUrl,
              body: body == null || body.isEmpty ? null : body,
            ),
          );
      state = state.copyWith(response: response, loading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        loading: false,
        clearResponse: true,
      );
    }
  }
}
