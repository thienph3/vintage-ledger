import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? fab;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (title != "")
          ? AppBar(title: Text(title), actions: actions)
          : null,
      body: SafeArea(child: body),
      floatingActionButton: fab,
    );
  }
}
