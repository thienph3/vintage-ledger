class QuickAddEntry {
  final String text;
  final String categoryId;
  final int amount;
  int count;
  int lastUsed;

  QuickAddEntry({
    required this.text,
    required this.categoryId,
    required this.amount,
    this.count = 1,
    required this.lastUsed,
  });

  String get key => text.toLowerCase().trim();

  String encode() => '$text|$categoryId|$amount|$count|$lastUsed';

  static QuickAddEntry? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 5) return null;
    return QuickAddEntry(
      text: parts[0],
      categoryId: parts[1],
      amount: int.tryParse(parts[2]) ?? 0,
      count: int.tryParse(parts[3]) ?? 1,
      lastUsed: int.tryParse(parts[4]) ?? 0,
    );
  }
}
