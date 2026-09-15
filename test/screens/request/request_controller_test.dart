import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/screens/request/request_controller.dart';

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

    container.read(requestControllerProvider.notifier).setMethod(HttpMethod.post);

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
}
