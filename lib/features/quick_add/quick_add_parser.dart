import 'dart:async';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/constants/seed_categories.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class QuickAddResult {
  final int amount;
  final String? keyword;
  final String? matchedCategoryId;
  final TransactionType type;

  QuickAddResult({
    required this.amount,
    this.keyword,
    this.matchedCategoryId,
    this.type = TransactionType.expense,
  });

  bool get hasAmount => amount > 0;
  bool get hasCategory => matchedCategoryId != null;
  bool get isComplete => hasAmount && hasCategory;
}

class QuickAddParser {
  static final _amountRegex = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(tỷ|ty|tr|triệu|trieu|k|nghìn|nghin|m|b)?',
    caseSensitive: false,
  );

  static const _maxLearnedEntries = 100;
  static final Map<String, String> _learnedMap = {};
  static Timer? _persistTimer;
  static bool _dirty = false;

  // ── Lifecycle (#2, #3) ──

  /// Load learned keywords from Firestore on app startup
  static Future<void> init() async {
    try {
      final raw = await sl.settingService.getSetting('quick_add_keywords');
      if (raw == null || raw.isEmpty) return;
      // Stored as "key1:val1,key2:val2"
      for (final pair in raw.split(',')) {
        final parts = pair.split(':');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          _learnedMap[parts[0]] = parts[1];
        }
      }
    } catch (_) {}
  }

  /// Record a successful mapping (#1, #6 LRU)
  static void learn(String keyword, String categoryId) {
    if (keyword.trim().isEmpty) return;
    final key = keyword.trim().toLowerCase();

    if (!_learnedMap.containsKey(key) && _learnedMap.length >= _maxLearnedEntries) {
      _learnedMap.remove(_learnedMap.keys.first);
    }

    _learnedMap.remove(key);
    _learnedMap[key] = categoryId;

    // Persist immediately — user may close app right after
    _persist();
  }

  /// Clear all learned keywords (#5)
  static Future<void> clearLearned() async {
    _learnedMap.clear();
    _dirty = false;
    _persistTimer?.cancel();
    try {
      await sl.settingService.setSetting('quick_add_keywords', '');
    } catch (_) {}
  }

  static int get learnedCount => _learnedMap.length;

  // ── Debounced persist (#4) ──

  static void _schedulePersist() {
    _dirty = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 5), _persist);
  }

  /// Call on app pause (WidgetsBindingObserver) to flush pending writes
  static Future<void> flush() async {
    if (_dirty) await _persist();
  }

  static Future<void> _persist() async {
    if (_learnedMap.isEmpty) {
      try { await sl.settingService.setSetting('quick_add_keywords', ''); } catch (_) {}
      _dirty = false;
      return;
    }
    // Serialize as "key1:val1,key2:val2"
    final encoded = _learnedMap.entries.map((e) => '${e.key}:${e.value}').join(',');
    try {
      await sl.settingService.setSetting('quick_add_keywords', encoded);
    } catch (_) {}
    _dirty = false;
  }

  // ── Keyword → category mapping (generated from kSeedCategories) ──

  static final _keywordMap = <String, _CategoryMatch>{
    for (final seed in kSeedCategories)
      for (final kw in seed.keywords)
        kw: _CategoryMatch(seed.name, seed.type),
  };

  // ── Parse ──

  static QuickAddResult parse(String input, List<Category> categories) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return QuickAddResult(amount: 0);

    final amount = _parseAmount(trimmed);
    final keyword = _extractKeyword(trimmed);
    final match = _matchCategory(keyword, categories);

    return QuickAddResult(
      amount: amount,
      keyword: keyword,
      matchedCategoryId: match?.categoryId,
      type: match?.type ?? TransactionType.expense,
    );
  }

  static int _parseAmount(String input) {
    final match = _amountRegex.firstMatch(input);
    if (match == null) return 0;

    final numStr = match.group(1)!.replaceAll(',', '.');
    final num = double.tryParse(numStr) ?? 0;
    final suffix = match.group(2)?.toLowerCase() ?? '';

    return switch (suffix) {
      'tỷ' || 'ty' => (num * 1000000000).toInt(),
      'tr' || 'triệu' || 'trieu' || 'm' => (num * 1000000).toInt(),
      'k' || 'nghìn' || 'nghin' => (num * 1000).toInt(),
      'b' => (num * 1000000000).toInt(),
      _ => num.toInt(),
    };
  }

  static String _extractKeyword(String input) {
    return input.replaceAll(_amountRegex, '').trim();
  }

  static bool _lastFuzzy = false;
  static bool get lastMatchWasFuzzy => _lastFuzzy;

  static _MatchResult? _matchCategory(String keyword, List<Category> categories) {
    if (keyword.isEmpty) return null;
    _lastFuzzy = false;

    // 1. Learned mappings (highest priority)
    final learnedId = _learnedMap[keyword];
    if (learnedId != null) {
      final cat = categories.where((c) => c.id == learnedId).firstOrNull;
      if (cat != null) {
        return _MatchResult(categoryId: cat.id!, type: cat.type ?? TransactionType.expense);
      }
    }

    // 2. Built-in keyword map
    for (final entry in _keywordMap.entries) {
      if (keyword.contains(entry.key)) {
        final cat = categories.where((c) =>
            c.name.toLowerCase() == entry.value.categoryName.toLowerCase()).firstOrNull;
        if (cat != null) {
          return _MatchResult(categoryId: cat.id!, type: entry.value.type);
        }
      }
    }

    // 3. Fuzzy match
    for (final cat in categories) {
      if (cat.name.toLowerCase().contains(keyword) || keyword.contains(cat.name.toLowerCase())) {
        _lastFuzzy = true;
        return _MatchResult(categoryId: cat.id!, type: cat.type ?? TransactionType.expense);
      }
    }

    return null;
  }
}

class _CategoryMatch {
  final String categoryName;
  final TransactionType type;
  const _CategoryMatch(this.categoryName, this.type);
}

class _MatchResult {
  final String categoryId;
  final TransactionType type;
  _MatchResult({required this.categoryId, required this.type});
}
