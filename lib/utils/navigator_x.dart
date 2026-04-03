import 'package:flutter/material.dart';

extension NavigatorX on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) {
    return Navigator.push<T>(this, _SoftPageRoute(builder: (_) => screen));
  }
}

class _SoftPageRoute<T> extends MaterialPageRoute<T> {
  _SoftPageRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}
