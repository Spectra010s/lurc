import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/environments/variable_resolver.dart';

void main() {
  group('resolveVariables', () {
    test('replaces known variables and preserves unknown variables', () {
      expect(
        resolveVariables(
          '{{baseUrl}}/users/{{userId}}/{{missing}}',
          const {'baseUrl': 'https://api.example.com', 'userId': '42'},
        ),
        'https://api.example.com/users/42/{{missing}}',
      );
    });

    test('allows whitespace around variable names', () {
      expect(
        resolveVariables('Bearer {{ token }}', const {'token': 'secret'}),
        'Bearer secret',
      );
    });
  });

  test('resolveVariableMap resolves keys and values', () {
    expect(
      resolveVariableMap(
        const {'X-{{name}}': '{{value}}'},
        const {'name': 'Client', 'value': 'lurc'},
      ),
      const {'X-Client': 'lurc'},
    );
  });
}
