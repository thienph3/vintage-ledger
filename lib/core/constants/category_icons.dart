import 'package:flutter/material.dart';

const Map<int, IconData> kCategoryIconMap = {
  0: Icons.fastfood,
  1: Icons.directions_car,
  2: Icons.shopping_cart,
  3: Icons.home,
  4: Icons.sports_soccer,
  5: Icons.movie,
  6: Icons.local_cafe,
  7: Icons.health_and_safety,
  8: Icons.phone_iphone,
  9: Icons.school,
  10: Icons.pets,
  11: Icons.flight,
  12: Icons.music_note,
  13: Icons.local_hospital,
};

List<IconData> get kCategoryIconList => kCategoryIconMap.values.toList();
