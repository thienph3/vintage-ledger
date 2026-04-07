import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transfer/screens/transfer_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_form_screen_v2.dart';
import 'package:vintage_ledger/features/goal/screens/goal_form_screen.dart';

class QuickActionsFab extends StatefulWidget {
  const QuickActionsFab({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isExpanded)
          GestureDetector(
            onTap: _close,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 140),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ScaleTransition(
                scale: _expandAnimation,
                child: _buildActionButton(
                  label: 'Thêm giao dịch',
                  icon: Icons.receipt_long,
                  color: AppColors.primary,
                  onTap: () {
                    _close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ScaleTransition(
                scale: _expandAnimation,
                child: _buildActionButton(
                  label: 'Chuyển tiền',
                  icon: Icons.swap_horiz,
                  color: AppColors.accent,
                  onTap: () {
                    _close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ScaleTransition(
                scale: _expandAnimation,
                child: _buildActionButton(
                  label: 'Thêm nợ',
                  icon: Icons.trending_up,
                  color: AppColors.income,
                  onTap: () {
                    _close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DebtFormScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ScaleTransition(
                scale: _expandAnimation,
                child: _buildActionButton(
                  label: 'Tạo mục tiêu',
                  icon: Icons.flag,
                  color: AppColors.expense,
                  onTap: () {
                    _close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_isExpanded ? Icons.close : Icons.add),
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
