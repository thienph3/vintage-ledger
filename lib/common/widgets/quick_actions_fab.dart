import 'package:flutter/material.dart';
import 'package:vintage_ledger/common/widgets/quick_actions_visibility.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/transfer/screens/funding_form_screen.dart';
import 'package:vintage_ledger/features/transfer/screens/transfer_form_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_payment_screen.dart';
import 'package:vintage_ledger/features/goal/screens/goal_contribution_screen.dart';

class QuickActionsFab extends StatefulWidget {
  final double bottomOffset;
  final QuickActionsInput actionsInput;

  const QuickActionsFab({
    super.key,
    this.bottomOffset = 16,
    required this.actionsInput,
  });

  @override
  State<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends State<QuickActionsFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

  String _labelFor(BuildContext context, QuickActionType type) {
    switch (type) {
      case QuickActionType.funding:
        return S.of(context, 'fabFunding');
      case QuickActionType.transfer:
        return S.of(context, 'fabTransfer');
      case QuickActionType.goalContribution:
        return S.of(context, 'fabSavings');
      case QuickActionType.debtPayment:
        return S.of(context, 'fabPayDebt');
    }
  }

  IconData _iconFor(QuickActionType type) {
    switch (type) {
      case QuickActionType.funding:
        return Icons.account_balance;
      case QuickActionType.transfer:
        return Icons.swap_horiz;
      case QuickActionType.goalContribution:
        return Icons.savings;
      case QuickActionType.debtPayment:
        return Icons.payment;
    }
  }

  Color _colorFor(QuickActionType type) {
    switch (type) {
      case QuickActionType.funding:
        return AppColors.accent;
      case QuickActionType.transfer:
        return AppColors.primary;
      case QuickActionType.goalContribution:
        return AppColors.income;
      case QuickActionType.debtPayment:
        return AppColors.expense;
    }
  }

  void _onTap(QuickActionType type) {
    _close();
    switch (type) {
      case QuickActionType.funding:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FundingFormScreen()),
        );
      case QuickActionType.transfer:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransferFormScreen()),
        );
      case QuickActionType.goalContribution:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalContributionScreen()),
        );
      case QuickActionType.debtPayment:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DebtPaymentScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = QuickActionsVisibility.resolve(widget.actionsInput);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: widget.bottomOffset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isExpanded) ...[
                for (int i = 0; i < actions.length; i++) ...[
                  ScaleTransition(
                    scale: _expandAnimation,
                    child: _buildActionButton(
                      label: _labelFor(context, actions[i]),
                      icon: _iconFor(actions[i]),
                      color: _colorFor(actions[i]),
                      onTap: () => _onTap(actions[i]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              FloatingActionButton(
                onPressed: _toggle,
                child: AnimatedRotation(
                  turns: _isExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(_isExpanded ? Icons.close : Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(label, style: AppTextStyles.body),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
