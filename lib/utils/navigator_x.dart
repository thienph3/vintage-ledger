import 'package:flutter/material.dart';

extension NavigatorX on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) {
    return Navigator.push<T>(this, MaterialPageRoute(builder: (_) => screen));
  }
}
