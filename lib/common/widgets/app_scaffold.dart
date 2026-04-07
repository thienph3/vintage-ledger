import 'package:flutter/material.dart';

import 'package:vintage_ledger/common/widgets/ledger_header.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? fab;
  final bool showBackButton;
  final VoidCallback? onTitleTap;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.fab,
    this.showBackButton = true,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title.isNotEmpty
          ? LedgerHeader(title: title, showBackButton: showBackButton, actions: actions, onTitleTap: onTitleTap)
          : null,
      body: SafeArea(child: body),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
