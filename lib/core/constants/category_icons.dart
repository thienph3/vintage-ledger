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

const Map<int, IconData> kCategoryIconMap = {
  0xe57a: Icons.fastfood,
  0xe530: Icons.directions_car,
  0xe8cc: Icons.shopping_cart,
  0xe88a: Icons.home,
  0xe575: Icons.health_and_safety,
  0xe80c: Icons.school,
  0xe02c: Icons.movie,
  0xe261: Icons.local_cafe,
  0xe8b3: Icons.receipt_long,
  0xe5d2: Icons.more_horiz,
  0xe0b0: Icons.account_balance_wallet,
  0xe838: Icons.star,
  0xe8dc: Icons.trending_up,
  0xe1e3: Icons.sports_soccer,
  0xe324: Icons.phone_iphone,
  0xe91d: Icons.pets,
  0xe539: Icons.flight,
  0xe405: Icons.music_note,
  0xe574: Icons.local_hospital,
};

const IconData kDefaultCategoryIcon = Icons.help_outline;

IconData getCategoryIcon(int? codePoint) {
  if (codePoint == null) return kDefaultCategoryIcon;
  return kCategoryIconMap[codePoint] ?? kDefaultCategoryIcon;
}
