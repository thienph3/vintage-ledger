import 'package:vintage_ledger/core/enums/transaction_type.dart';
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
  // ── Amount regex: matches "50k", "10tr", "1.5tr", "2 tỷ", "50000", "1.5m" ──
  static final _amountRegex = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(tỷ|ty|tr|triệu|trieu|k|nghìn|nghin|m|b)?',
    caseSensitive: false,
  );

  /// User-learned mappings: keyword → categoryId
  static final Map<String, String> _learnedMap = {};

  /// Record a successful mapping for future use
  static void learn(String keyword, String categoryId) {
    if (keyword.trim().isEmpty) return;
    _learnedMap[keyword.trim().toLowerCase()] = categoryId;
  }

  // ── Keyword → category name mapping (vi + en) ──
  static const _keywordMap = <String, _CategoryMatch>{
    // Ăn uống
    'ăn': _CategoryMatch('Ăn uống', TransactionType.expense),
    'cơm': _CategoryMatch('Ăn uống', TransactionType.expense),
    'phở': _CategoryMatch('Ăn uống', TransactionType.expense),
    'bún': _CategoryMatch('Ăn uống', TransactionType.expense),
    'food': _CategoryMatch('Ăn uống', TransactionType.expense),
    'eat': _CategoryMatch('Ăn uống', TransactionType.expense),
    'lunch': _CategoryMatch('Ăn uống', TransactionType.expense),
    'dinner': _CategoryMatch('Ăn uống', TransactionType.expense),
    'breakfast': _CategoryMatch('Ăn uống', TransactionType.expense),
    // Cà phê
    'cf': _CategoryMatch('Cà phê', TransactionType.expense),
    'cafe': _CategoryMatch('Cà phê', TransactionType.expense),
    'coffee': _CategoryMatch('Cà phê', TransactionType.expense),
    'trà': _CategoryMatch('Cà phê', TransactionType.expense),
    'tea': _CategoryMatch('Cà phê', TransactionType.expense),
    // Di chuyển
    'grab': _CategoryMatch('Di chuyển', TransactionType.expense),
    'taxi': _CategoryMatch('Di chuyển', TransactionType.expense),
    'xăng': _CategoryMatch('Di chuyển', TransactionType.expense),
    'gas': _CategoryMatch('Di chuyển', TransactionType.expense),
    'gửi xe': _CategoryMatch('Di chuyển', TransactionType.expense),
    'parking': _CategoryMatch('Di chuyển', TransactionType.expense),
    // Mua sắm
    'mua': _CategoryMatch('Mua sắm', TransactionType.expense),
    'shop': _CategoryMatch('Mua sắm', TransactionType.expense),
    'shopping': _CategoryMatch('Mua sắm', TransactionType.expense),
    // Nhà ở
    'tiền nhà': _CategoryMatch('Nhà ở', TransactionType.expense),
    'rent': _CategoryMatch('Nhà ở', TransactionType.expense),
    'điện': _CategoryMatch('Hóa đơn', TransactionType.expense),
    'nước': _CategoryMatch('Hóa đơn', TransactionType.expense),
    'internet': _CategoryMatch('Hóa đơn', TransactionType.expense),
    'bill': _CategoryMatch('Hóa đơn', TransactionType.expense),
    // Income
    'lương': _CategoryMatch('Lương', TransactionType.income),
    'salary': _CategoryMatch('Lương', TransactionType.income),
    'thưởng': _CategoryMatch('Thưởng', TransactionType.income),
    'bonus': _CategoryMatch('Thưởng', TransactionType.income),
  };

  /// Parse input string → QuickAddResult
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
    // Remove amount part, keep the rest as keyword
    return input.replaceAll(_amountRegex, '').trim();
  }

  static _MatchResult? _matchCategory(String keyword, List<Category> categories) {
    if (keyword.isEmpty) return null;

    // 1. Check learned mappings first
    final learnedId = _learnedMap[keyword];
    if (learnedId != null) {
      final cat = categories.where((c) => c.id == learnedId).firstOrNull;
      if (cat != null) {
        return _MatchResult(categoryId: cat.id!, type: cat.type ?? TransactionType.expense);
      }
    }

    // 2. Exact keyword match from built-in map
    for (final entry in _keywordMap.entries) {
      if (keyword.contains(entry.key)) {
        final cat = categories.where((c) =>
            c.name.toLowerCase() == entry.value.categoryName.toLowerCase()).firstOrNull;
        if (cat != null) {
          return _MatchResult(categoryId: cat.id!, type: entry.value.type);
        }
      }
    }

    // Fuzzy: check if keyword is substring of any category name
    for (final cat in categories) {
      if (cat.name.toLowerCase().contains(keyword) || keyword.contains(cat.name.toLowerCase())) {
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
