import 'dart:convert';

import 'package:lurc/core/http/request_codec.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestHistoryRepository {
  const new(this.preferences);

  static const _storageKey = 'request_history_v1';
  static const maxEntries = 100;

  final SharedPreferences preferences;

  List<RequestRecord> load() {
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return const [];
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) => requestRecordFromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(RequestRecord record) async {
    final records = [record, ...load().where((item) => item.id != record.id)];
    final limited = records.take(maxEntries).map(requestRecordToJson).toList();
    await preferences.setString(_storageKey, jsonEncode(limited));
  }

  Future<void> delete(String id) async {
    final records = load().where((record) => record.id != id);
    await preferences.setString(
      _storageKey,
      jsonEncode(records.map(requestRecordToJson).toList()),
    );
  }

  Future<void> clear() => preferences.remove(_storageKey);
}
