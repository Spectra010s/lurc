import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_state.dart';

void main() {
  SavedRequest request() => SavedRequest(
    id: 'request',
    name: 'Create user',
    method: HttpMethod.post,
    url: 'https://example.com/users',
    collectionId: 'collection',
    queryParameters: {'search': 'a & b', 'empty': ''},
    headers: {'Authorization': 'Bearer token'},
    body: '{"name":"Tayo"}',
    bodyType: RequestBodyType.json,
  );

  test(
    'JSON round trip preserves every field and reconstructs the request',
    () {
      final original = request();
      final restored = SavedRequest.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), original.toJson());
      final http = restored.toHttpRequest();
      expect(http.method, original.method);
      expect(http.url, original.url);
      expect(http.headers, original.headers);
      expect(http.queryParameters, original.queryParameters);
      expect(http.body, original.body);
    },
  );

  test('round trips all methods, body types and null versus empty bodies', () {
    for (final method in HttpMethod.values) {
      for (final type in RequestBodyType.values) {
        for (final body in <String?>[null, '', 'hello']) {
          final value = request().copyWith(
            method: method,
            bodyType: type,
            body: body,
            clearBody: body == null,
          );
          expect(
            SavedRequest.fromJson(value.toJson()).toJson(),
            value.toJson(),
          );
        }
      }
    }
  });

  test(
    'copy can explicitly remove collection and body without changing source',
    () {
      final original = request();
      final copy = original.copyWith(clearCollection: true, clearBody: true);
      expect(copy.collectionId, isNull);
      expect(copy.body, isNull);
      expect(copy.id, original.id);
      expect(original.collectionId, 'collection');
      expect(original.body, isNotNull);
    },
  );

  test('request metadata is defensively copied and immutable', () {
    final headers = {'x-test': 'before'};
    final value = SavedRequest(
      id: 'r',
      name: 'Request',
      method: HttpMethod.get,
      url: '',
      headers: headers,
      queryParameters: headers,
    );
    headers['x-test'] = 'after';
    expect(value.headers['x-test'], 'before');
    expect(value.queryParameters['x-test'], 'before');
    expect(() => value.headers['x-test'] = 'changed', throwsUnsupportedError);
  });

  test('snapshot round trips and filters collection membership', () {
    final state = SavedRequestsState(
      collections: [const Collection(id: 'collection', name: 'Users')],
      requests: [request()],
    );
    final restored = SavedRequestsState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), state.toJson());
    expect(restored.requestsInCollection('collection').single.id, 'request');
    expect(restored.requestsInCollection(null), isEmpty);
    expect(() => restored.requests.clear(), throwsUnsupportedError);
  });

  test('snapshot rejects unknown versions and malformed records', () {
    expect(
      () => SavedRequestsState.fromJson({'version': 2}),
      throwsFormatException,
    );
    for (final invalid in <Object?>[
      null,
      'wrong',
      [
        {'id': 4},
      ],
    ]) {
      expect(
        () => SavedRequestsState.fromJson({
          'version': 1,
          'collections': [],
          'requests': invalid,
        }),
        throwsFormatException,
      );
    }
  });

  test('snapshot rejects duplicates and orphaned collection references', () {
    const collection = Collection(id: 'collection', name: 'Users');
    expect(
      () => SavedRequestsState(collections: [collection, collection]),
      throwsFormatException,
    );
    expect(
      () => SavedRequestsState(requests: [request()]),
      throwsFormatException,
    );
    expect(
      () => SavedRequestsState(
        collections: [collection],
        requests: [request(), request()],
      ),
      throwsFormatException,
    );
  });
}
