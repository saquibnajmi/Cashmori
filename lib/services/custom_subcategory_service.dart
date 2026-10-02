import 'package:shared_preferences/shared_preferences.dart';

// Stores user-defined sub-categories separately from the built-in defaults.
// These values are saved in SharedPreferences so custom options persist across app sessions.
class CustomSubcategoryService {
  static const String _keyPrefix = 'custom_subcategories_';
  static const String _snapshotKey = 'custom_subcategories_snapshot';

  /// Loads all saved sub-categories for a given main category.
  static Future<List<String>> load(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_keyPrefix$category') ?? const [];
    return raw.where((item) => item.trim().isNotEmpty).toList();
  }

  /// Creates a map of all saved custom category values for backup/restore operations.
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

  /// Restores custom category data back into SharedPreferences from a snapshot map.
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

  /// Removes all custom sub-categories from persistent storage.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
    await prefs.remove(_snapshotKey);
  }

  /// Persists a category's custom subcategory list into local storage.
  static Future<void> save(String category, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_keyPrefix$category',
      values.where((item) => item.trim().isNotEmpty).toList(),
    );
  }

  /// Adds one new custom item to a category while ignoring duplicates and blank values.
  static Future<void> add(String category, String value) async {
    final existing = await load(category);
    final clean = value.trim();
    if (clean.isEmpty) return;
    if (existing.contains(clean)) return;
    await save(category, [...existing, clean]);
  }

  /// Removes one custom sub-category from a category list.
  static Future<void> remove(String category, String value) async {
    final existing = await load(category);
    await save(category, existing.where((item) => item != value).toList());
  }

  /// Replaces an existing custom sub-category value with a new cleaned version.
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
