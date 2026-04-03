import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';

class ShimmerPlaceholder extends StatefulWidget {
  final int lines;

  const ShimmerPlaceholder({super.key, this.lines = 4});

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = 0.04 + _ctrl.value * 0.06;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: List.generate(widget.lines, (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
