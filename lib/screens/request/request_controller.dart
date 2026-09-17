import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/core/environments/variable_resolver.dart';
import 'package:lurc/core/http/http_client.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/http/request_snapshot.dart';
import 'package:lurc/core/http/response.dart';
import 'package:lurc/screens/history/history_controller.dart';

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
  CancelToken? _cancelToken;

  @override
  RequestState build() => const RequestState();

  void setMethod(HttpMethod method) {
    state = state.copyWith(method: method);
  }

  void cancel() {
    _cancelToken?.cancel();
  }

  Future<void> send({
    required String url,
    String? body,
    RequestBodyType bodyType = RequestBodyType.none,
    bool validateJsonBody = false,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final variables = ref.read(activeEnvironmentProvider)?.variables ?? const {};
    final resolvedUrl = resolveVariables(url.trim(), variables);
    final resolvedBody = body == null ? null : resolveVariables(body, variables);
    final resolvedQuery = resolveVariableMap(queryParameters, variables);
    final resolvedHeaders = resolveVariableMap(headers, variables);
    final uri = Uri.tryParse(resolvedUrl);

    if (resolvedUrl.isEmpty) {
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

    final requestBody =
        resolvedBody == null || resolvedBody.isEmpty ? null : resolvedBody;
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

    final request = HttpRequest(
      method: state.method,
      url: resolvedUrl,
      queryParameters: resolvedQuery,
      headers: resolvedHeaders,
      body: requestBody,
    );

    _cancelToken = CancelToken();
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearResponse: true,
    );

    try {
      final response = await ref.read(httpClientProvider).execute(
            request,
            cancelToken: _cancelToken,
          );
      state = state.copyWith(
        response: response,
        loading: false,
        clearError: true,
      );
      await _recordRequest(request, response, bodyType);
    } on LurcHttpException catch (error) {
      state = state.copyWith(
        error: error.message,
        loading: false,
        clearResponse: true,
      );
    } on Exception catch (error) {
      state = state.copyWith(
        error: error.toString(),
        loading: false,
        clearResponse: true,
      );
    } finally {
      _cancelToken = null;
    }
  }

  Future<void> _recordRequest(
    HttpRequest request,
    HttpResponse response,
    RequestBodyType bodyType,
  ) async {
    try {
      final now = DateTime.now();
      final repository =
          await ref.read(requestHistoryRepositoryProvider.future);
      await repository.save(
        RequestRecord(
          id: now.microsecondsSinceEpoch.toString(),
          sentAt: now,
          request: RequestSnapshot(
            method: request.method,
            url: request.url,
            headers: request.headers,
            queryParameters: request.queryParameters,
            body: request.body,
            bodyType: bodyType,
          ),
          statusCode: response.statusCode,
          durationMs: response.duration.inMilliseconds,
        ),
      );
      ref.invalidate(requestHistoryProvider);
    } on Exception {
      // History must never turn a successful HTTP request into a failed one.
    }
  }
}
