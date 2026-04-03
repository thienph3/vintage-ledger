const Map<String, String> kCategoryEmojis = {
  'Ăn uống': '🍜',
  'Ăn sáng': '🥐',
  'Ăn trưa': '🍜',
  'Ăn tối': '🍽️',
  'Cà phê': '☕',
  'Trà sữa': '🧋',
  'Di chuyển': '🚗',
  'Grab': '🛵',
  'Xăng': '⛽',
  'Mua sắm': '🛍️',
  'Giải trí': '🎬',
  'Sức khỏe': '💊',
  'Giáo dục': '📚',
  'Tiền nhà': '🏠',
  'Điện nước': '⚡',
  'Internet': '📶',
  'Điện thoại': '📱',
  'Lương': '💰',
  'Thưởng': '🎁',
  'Đầu tư': '📈',
  'Tiết kiệm': '🏦',
  'Khác': '💸',
};

String getCategoryEmoji(String categoryName) {
  for (final entry in kCategoryEmojis.entries) {
    if (categoryName.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return '💸';
}
