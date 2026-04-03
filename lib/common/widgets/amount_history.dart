import 'dart:async';
import 'package:vintage_ledger/core/service_locator.dart';

class AmountHistory {
  static const _settingKey = 'amount_history';
  static const _maxEntries = 20;

  static final Map<int, int> _counts = {}; // amount → count
  static bool _loaded = false;
  static Timer? _persistTimer;
  static bool _dirty = false;

  static Future<void> init() async {
    if (_loaded) return;
    try {
      final raw = await sl.settingService.getSetting(_settingKey);
      if (raw != null && raw.isNotEmpty) {
        for (final pair in raw.split(',')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final amount = int.tryParse(parts[0]);
            final count = int.tryParse(parts[1]);
            if (amount != null && count != null) _counts[amount] = count;
          }
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  static void record(int amount) {
    if (amount <= 0) return;
    _counts[amount] = (_counts[amount] ?? 0) + 1;

    // LRU: keep top entries by count
    if (_counts.length > _maxEntries) {
      final sorted = _counts.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
      _counts.remove(sorted.first.key);
    }

    _dirty = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 3), _persist);
  }

  /// Top 3 most used amounts
  static List<int> topAmounts({int limit = 3}) {
    if (_counts.isEmpty) return const [];
    final sorted = _counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  static Future<void> flush() async {
    if (_dirty) await _persist();
  }

  static Future<void> _persist() async {
    final encoded = _counts.entries.map((e) => '${e.key}:${e.value}').join(',');
    try {
      await sl.settingService.setSetting(_settingKey, encoded);
    } catch (_) {}
    _dirty = false;
  }
}
