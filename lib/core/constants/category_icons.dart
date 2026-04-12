import 'package:flutter/material.dart';

const kCategoryIcons = [
  // Food & Drink
  Icons.fastfood,
  Icons.local_cafe,
  Icons.restaurant,
  Icons.local_bar,
  Icons.icecream,
  Icons.local_pizza,

  // Transport
  Icons.directions_car,
  Icons.directions_bus,
  Icons.two_wheeler,
  Icons.local_gas_station,
  Icons.flight,

  // Shopping
  Icons.shopping_cart,
  Icons.shopping_bag,
  Icons.checkroom,

  // Home & Bills
  Icons.home,
  Icons.receipt_long,
  Icons.electrical_services,
  Icons.water_drop,
  Icons.wifi,

  // Health
  Icons.health_and_safety,
  Icons.local_hospital,
  Icons.medication,
  Icons.fitness_center,
  Icons.spa,

  // Education
  Icons.school,
  Icons.menu_book,
  Icons.auto_stories,

  // Entertainment
  Icons.movie,
  Icons.music_note,
  Icons.sports_soccer,
  Icons.sports_esports,
  Icons.theater_comedy,

  // Family & Social
  Icons.favorite,
  Icons.card_giftcard,
  Icons.celebration,
  Icons.cake,
  Icons.family_restroom,
  Icons.child_friendly,
  Icons.people,
  Icons.volunteer_activism,
  Icons.handshake,

  // Finance
  Icons.account_balance_wallet,
  Icons.trending_up,
  Icons.savings,
  Icons.payments,
  Icons.attach_money,

  // Tech & Work
  Icons.phone_iphone,
  Icons.laptop,
  Icons.work,
  Icons.business_center,

  // Lifestyle
  Icons.pets,
  Icons.local_florist,
  Icons.brush,
  Icons.camera_alt,
  Icons.self_improvement,

  // Other
  Icons.star,
  Icons.more_horiz,
];

final Map<int, IconData> kCategoryIconMap = {
  for (final icon in kCategoryIcons) icon.codePoint: icon,
};

const IconData kDefaultCategoryIcon = Icons.help_outline;

IconData getCategoryIcon(int? codePoint) {
  if (codePoint == null) return kDefaultCategoryIcon;
  return kCategoryIconMap[codePoint] ?? kDefaultCategoryIcon;
}
