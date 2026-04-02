import 'dart:async';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/quick_add/models/quick_add_entry.dart';

class QuickAddHistory {
  static const _settingKey = 'quick_add_history';
  static const _maxEntries = 20;

  static final List<QuickAddEntry> _entries = [];
  static Timer? _persistTimer;
  static bool _dirty = false;

  static List<QuickAddEntry> get entries => _entries;

  static Future<void> init() async {
    try {
      final raw = await sl.settingService.getSetting(_settingKey);
      if (raw == null || raw.isEmpty) return;
      _entries.clear();
      for (final line in raw.split('\n')) {
        final entry = QuickAddEntry.decode(line);
        if (entry != null) _entries.add(entry);
      }
    } catch (_) {}
  }

  static void record(String text, String categoryId, int amount) {
    final key = text.toLowerCase().trim();
    if (key.isEmpty) return;

    final existing = _entries.where((e) => e.key == key).firstOrNull;
    if (existing != null) {
      existing.count++;
      existing.lastUsed = DateTime.now().millisecondsSinceEpoch;
    } else {
      if (_entries.length >= _maxEntries) {
        _entries.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
        _entries.removeAt(0);
      }
      _entries.add(QuickAddEntry(
        text: text.trim(),
        categoryId: categoryId,
        amount: amount,
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    _schedulePersist();
  }

  static List<QuickAddEntry> suggest({String? filter, int limit = 5}) {
    final sorted = List<QuickAddEntry>.from(_entries)
      ..sort((a, b) => b.count.compareTo(a.count));

    if (filter == null || filter.trim().isEmpty) {
      return sorted.take(limit).toList();
    }

    final f = filter.toLowerCase().trim();
    return sorted.where((e) => e.key.contains(f)).take(limit).toList();
  }

  static void _schedulePersist() {
    _dirty = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 3), _persist);
  }

  static Future<void> flush() async {
    if (_dirty) await _persist();
  }

  static Future<void> _persist() async {
    final encoded = _entries.map((e) => e.encode()).join('\n');
    try {
      await sl.settingService.setSetting(_settingKey, encoded);
    } catch (_) {}
    _dirty = false;
  }

  static Future<void> clear() async {
    _entries.clear();
    _dirty = false;
    _persistTimer?.cancel();
    try {
      await sl.settingService.setSetting(_settingKey, '');
    } catch (_) {}
  }
}
