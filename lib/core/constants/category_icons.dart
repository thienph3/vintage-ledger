import 'package:flutter/material.dart';

const kCategoryIcons = [
  Icons.fastfood,
  Icons.directions_car,
  Icons.shopping_cart,
  Icons.home,
  Icons.health_and_safety,
  Icons.school,
  Icons.movie,
  Icons.local_cafe,
  Icons.receipt_long,
  Icons.more_horiz,
  Icons.account_balance_wallet,
  Icons.star,
  Icons.trending_up,
  Icons.sports_soccer,
  Icons.phone_iphone,
  Icons.pets,
  Icons.flight,
  Icons.music_note,
  Icons.local_hospital,
];

IconData? getCategoryIcon(int? codePoint) {
  if (codePoint == null) return null;
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}
