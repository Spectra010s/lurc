import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/http_client.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/response.dart';
import 'package:lurc/screens/request/request_controller.dart';

class FakeHttpClient extends LurcHttpClient {
  HttpRequest? lastRequest;

  @override
  Future<HttpResponse> execute(HttpRequest request) async {
    lastRequest = request;
    return const HttpResponse(
      statusCode: 200,
      headers: {},
      body: 'ok',
      duration: Duration(milliseconds: 1),
    );
  }
}

void main() {
  test('starts with GET and no request result', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(requestControllerProvider);

    expect(state.method, HttpMethod.get);
    expect(state.loading, isFalse);
    expect(state.response, isNull);
    expect(state.error, isNull);
  });

  test('updates the selected HTTP method', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(requestControllerProvider.notifier)
        .setMethod(HttpMethod.post);

    expect(container.read(requestControllerProvider).method, HttpMethod.post);
  });

  test('rejects an empty URL before transport execution', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(requestControllerProvider.notifier).send(url: '   ');

    final state = container.read(requestControllerProvider);
    expect(state.loading, isFalse);
    expect(state.response, isNull);
    expect(state.error, 'Enter a URL');
  });

  test('passes query parameters and headers to transport', () async {
    final client = FakeHttpClient();
    final container = ProviderContainer(
      overrides: [httpClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);

    await container.read(requestControllerProvider.notifier).send(
      url: 'https://example.com/users',
      queryParameters: const {'page': '2', 'sort': 'name'},
      headers: const {'Authorization': 'Bearer token'},
      body: '{"active":true}',
    );

    expect(client.lastRequest, isNotNull);
    expect(client.lastRequest!.queryParameters, {'page': '2', 'sort': 'name'});
    expect(client.lastRequest!.headers, {'Authorization': 'Bearer token'});
    expect(client.lastRequest!.body, '{"active":true}');
  });
}
