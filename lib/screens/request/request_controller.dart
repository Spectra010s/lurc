import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/http_client.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/response.dart';

class RequestState {
  const new({
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

  Future<void> send({
    required String url,
    String? body,
    bool validateJsonBody = false,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final trimmedUrl = url.trim();
    final uri = Uri.tryParse(trimmedUrl);

    if (trimmedUrl.isEmpty) {
      state = state.copyWith(error: 'Enter a URL', clearResponse: true);
      return;
    }

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      state = state.copyWith(
        error: 'Enter a valid HTTP or HTTPS URL',
        clearResponse: true,
      );
      return;
    }

    final requestBody = body == null || body.isEmpty ? null : body;
    if (validateJsonBody && requestBody != null) {
      try {
        jsonDecode(requestBody);
      } on FormatException {
        state = state.copyWith(
          error: 'Request body is not valid JSON',
          clearResponse: true,
        );
        return;
      }
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
              queryParameters: queryParameters,
              headers: headers,
              body: requestBody,
            ),
          );
      state = state.copyWith(
        response: response,
        loading: false,
        clearError: true,
      );
    } on Exception catch (error) {
      state = state.copyWith(
        error: error.toString(),
        loading: false,
        clearResponse: true,
      );
    }
  }
}
