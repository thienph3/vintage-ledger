import 'package:flutter/material.dart';

import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class AsyncContent extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  const AsyncContent({
    super.key,
    required this.loading,
    this.error,
    this.isEmpty = false,
    this.emptyMessage = '',
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ShimmerPlaceholder();
    }
    if (error != null) {
      return Center(child: Text(error!, style: AppTextStyles.error));
    }
    if (isEmpty) {
      return EmptyState(message: emptyMessage);
    }
    return child;
  }
}
