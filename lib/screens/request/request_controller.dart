import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/core/environments/variable_resolver.dart';
import 'package:lurc/core/http/client.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_history_repository.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/http/request_snapshot.dart';
import 'package:lurc/core/http/response.dart';
import 'package:lurc/screens/history/history_controller.dart';

final requestControllerProvider =
    NotifierProvider<RequestController, RequestState>(RequestController.new);

class RequestState {
  const new({
    this.method = HttpMethod.get,
    this.loading = false,
    this.response,
    this.error,
  });

  final HttpMethod method;
  final bool loading;
  final HttpResponse? response;
  final String? error;

  RequestState copyWith({
    HttpMethod? method,
    bool? loading,
    HttpResponse? response,
    String? error,
    bool clearResponse = false,
    bool clearError = false,
  }) => RequestState(
    method: method ?? this.method,
    loading: loading ?? this.loading,
    response: clearResponse ? null : response ?? this.response,
    error: clearError ? null : error ?? this.error,
  );
}

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
    final variables =
        ref.read(activeEnvironmentProvider)?.variables ?? const {};
    final resolvedUrl = resolveVariables(url.trim(), variables);
    final resolvedBody = body == null
        ? null
        : resolveVariables(body, variables);
    final resolvedQuery = resolveVariableMap(queryParameters, variables);
    final resolvedHeaders = resolveVariableMap(headers, variables);
    final uri = Uri.tryParse(resolvedUrl);

    if (resolvedUrl.isEmpty) {
      state = state.copyWith(error: 'Enter a URL', clearResponse: true);
      return;
    }

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      state = state.copyWith(
        error: 'Enter a valid http:// or https:// URL',
        clearResponse: true,
      );
      return;
    }

    if (validateJsonBody && resolvedBody != null && resolvedBody.isNotEmpty) {
      try {
        jsonDecode(resolvedBody);
      } on FormatException {
        state = state.copyWith(
          error: 'Enter valid JSON before sending',
          clearResponse: true,
        );
        return;
      }
    }

    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearResponse: true,
    );

    final request = HttpRequest(
      method: state.method,
      url: resolvedUrl,
      queryParameters: resolvedQuery,
      headers: resolvedHeaders,
      body: resolvedBody,
    );

    try {
      final response = await ref.read(httpClientProvider).send(
        request,
        cancelToken: cancelToken,
      );
      if (cancelToken.isCancelled) return;
      state = state.copyWith(
        loading: false,
        response: response,
        clearError: true,
      );
      await _recordRequest(request, bodyType, response.statusCode);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        state = state.copyWith(
          loading: false,
          error: 'Request cancelled',
          clearResponse: true,
        );
        return;
      }
      state = state.copyWith(
        loading: false,
        error: _messageFor(error),
        clearResponse: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        loading: false,
        error: 'Request failed: $error',
        clearResponse: true,
      );
    } finally {
      if (identical(_cancelToken, cancelToken)) _cancelToken = null;
    }
  }

  Future<void> _recordRequest(
    HttpRequest request,
    RequestBodyType bodyType,
    int statusCode,
  ) async {
    try {
      final repository = await ref.read(requestHistoryRepositoryProvider.future);
      await repository.add(
        RequestRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sentAt: DateTime.now().toUtc(),
          statusCode: statusCode,
          request: RequestSnapshot(
            method: request.method,
            url: request.url,
            queryParameters: request.queryParameters,
            headers: request.headers,
            body: request.body,
            bodyType: bodyType,
          ),
        ),
      );
      ref.invalidate(requestHistoryProvider);
    } on Object {
      // A successful HTTP request must not become a failed request because
      // local history persistence failed.
    }
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out';
      case DioExceptionType.sendTimeout:
        return 'Sending the request timed out';
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server';
      case DioExceptionType.badCertificate:
        return 'The server certificate is not trusted';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.badResponse:
        return 'The server returned an invalid response';
      case DioExceptionType.unknown:
        return error.message ?? 'Request failed';
    }
  }
}
