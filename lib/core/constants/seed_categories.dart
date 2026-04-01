import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

class SeedCategory {
  final String name;
  final TransactionType type;
  final int iconIndex;
  final List<String> keywords;

  const SeedCategory(this.name, this.type, this.iconIndex, this.keywords);

  int get iconCodePoint => kCategoryIcons[iconIndex].codePoint;
}

/// Single source of truth for default categories + quick add keywords.
const kSeedCategories = [
  // Expense
  SeedCategory('Ăn uống', TransactionType.expense, 0,
      ['ăn', 'cơm', 'phở', 'bún', 'food', 'eat', 'lunch', 'dinner', 'breakfast']),
  SeedCategory('Cà phê', TransactionType.expense, 7,
      ['cf', 'cafe', 'coffee', 'trà', 'tea']),
  SeedCategory('Di chuyển', TransactionType.expense, 1,
      ['grab', 'taxi', 'xăng', 'gas', 'gửi xe', 'parking']),
  SeedCategory('Mua sắm', TransactionType.expense, 2,
      ['mua', 'shop', 'shopping']),
  SeedCategory('Nhà ở', TransactionType.expense, 3,
      ['tiền nhà', 'rent']),
  SeedCategory('Hóa đơn', TransactionType.expense, 8,
      ['điện', 'nước', 'internet', 'bill']),
  SeedCategory('Sức khỏe', TransactionType.expense, 4,
      ['thuốc', 'bệnh viện', 'doctor', 'medicine']),
  SeedCategory('Giải trí', TransactionType.expense, 6,
      ['phim', 'game', 'movie', 'entertainment']),
  SeedCategory('Khác', TransactionType.expense, 9, []),
  // Income
  SeedCategory('Lương', TransactionType.income, 10,
      ['lương', 'salary']),
  SeedCategory('Thưởng', TransactionType.income, 11,
      ['thưởng', 'bonus']),
  SeedCategory('Đầu tư', TransactionType.income, 12,
      ['đầu tư', 'invest', 'investment']),
  SeedCategory('Khác', TransactionType.income, 9, []),
];
