import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/widgets/key_value_editor.dart';

void main() {
  test('converts populated rows and ignores empty keys', () {
    const entries = [
      KeyValueEntry(key: ' page ', value: '2'),
      KeyValueEntry(key: '', value: 'ignored'),
      KeyValueEntry(key: '   ', value: 'also ignored'),
      KeyValueEntry(key: 'Authorization', value: 'Bearer token'),
    ];

    expect(
      keyValueEntriesToMap(entries),
      {'page': '2', 'Authorization': 'Bearer token'},
    );
  });
}
