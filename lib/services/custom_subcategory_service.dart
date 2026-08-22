import 'package:shared_preferences/shared_preferences.dart';

class CustomSubcategoryService {
  static const String _keyPrefix = 'custom_subcategories_';
  static const String _snapshotKey = 'custom_subcategories_snapshot';

  static Future<List<String>> load(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_keyPrefix$category') ?? const [];
    return raw.where((item) => item.trim().isNotEmpty).toList();
  }

  static Future<Map<String, List<String>>> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = <String, List<String>>{};
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

    for (final key in keys) {
      final category = key.substring(_keyPrefix.length);
      final values = prefs.getStringList(key) ?? const [];
      final cleaned = values
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
      if (cleaned.isNotEmpty) {
        snapshot[category] = cleaned;
      }
    }

    return snapshot;
  }

  static Future<void> restore(Map<String, List<String>> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in snapshot.entries) {
      final cleaned = entry.value
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
      await prefs.setStringList('$_keyPrefix${entry.key}', cleaned);
    }
    await prefs.setString(
      _snapshotKey,
      snapshot.entries
          .map((entry) => '${entry.key}:${entry.value.join('|')}')
          .join(';'),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
    await prefs.remove(_snapshotKey);
  }

  static Future<void> save(String category, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_keyPrefix$category',
      values.where((item) => item.trim().isNotEmpty).toList(),
    );
  }

  static Future<void> add(String category, String value) async {
    final existing = await load(category);
    final clean = value.trim();
    if (clean.isEmpty) return;
    if (existing.contains(clean)) return;
    await save(category, [...existing, clean]);
  }

  static Future<void> remove(String category, String value) async {
    final existing = await load(category);
    await save(category, existing.where((item) => item != value).toList());
  }

  static Future<void> update(
      String category, String oldValue, String newValue) async {
    final existing = await load(category);
    final clean = newValue.trim();
    if (clean.isEmpty) return;
    final updated =
        existing.map((item) => item == oldValue ? clean : item).toList();
    if (!updated.contains(clean) && oldValue != clean) {
      final deduped = <String>[];
      for (final item in updated) {
        if (item == clean && deduped.contains(clean)) continue;
        deduped.add(item);
      }
      await save(category, deduped);
      return;
    }
    await save(category, updated);
  }
}
