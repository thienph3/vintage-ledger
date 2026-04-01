import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/error_snackbar.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class QuickAddBar extends StatefulWidget {
  final String? walletId;
  final VoidCallback onAdded;

  const QuickAddBar({super.key, this.walletId, required this.onAdded});

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Category> _categories = [];
  QuickAddResult _result = QuickAddResult(amount: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await sl.categoryService.getCategories();
    setState(() => _categories = cats);
  }

  void _onChanged() {
    setState(() => _result = QuickAddParser.parse(_ctrl.text, _categories));
  }

  Future<void> _submit() async {
    if (!_result.hasAmount) return;

    // Fallback: no category or fuzzy-only match → open full form
    if (!_result.hasCategory || QuickAddParser.lastMatchWasFuzzy) {
      _openFullForm();
      return;
    }

    final walletId = widget.walletId ?? (await sl.walletService.getWallets()).firstOrNull?.id;
    if (walletId == null) return;

    setState(() => _saving = true);
    try {
      final txnId = await sl.transactionService.createTransaction(
        walletId: walletId,
        categoryId: _result.matchedCategoryId!,
        type: _result.type,
        amount: _result.amount,
        note: _result.keyword,
        date: DateTime.now().millisecondsSinceEpoch,
      );

      if (_result.keyword != null && _result.keyword!.isNotEmpty) {
        QuickAddParser.learn(_result.keyword!, _result.matchedCategoryId!);
      }

      final catName = _categories.where((c) => c.id == _result.matchedCategoryId).firstOrNull?.name ?? '';

      _ctrl.clear();
      _focusNode.unfocus();
      widget.onAdded();
      if (!mounted) return;

      final locale = Localizations.localeOf(context).languageCode;
      final amountStr = AmountFormatter.formatCompactCurrency(_result.amount, locale);

      // Undo snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ $amountStr $catName'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: S.of(context, 'undo'),
          onPressed: () async {
            await sl.transactionService.deleteTransaction(txnId);
            widget.onAdded();
          },
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openFullForm() {
    final prefill = _result.hasAmount
        ? TransactionWithItems(
            transaction: TransactionModel(
              walletId: widget.walletId ?? '',
              categoryId: _result.matchedCategoryId ?? '',
              type: _result.type,
              amount: _result.amount,
              note: _result.keyword,
              date: DateTime.now().millisecondsSinceEpoch,
            ),
          )
        : null;

    _ctrl.clear();
    _focusNode.unfocus();

    context.pushScreen(TransactionFormScreen(
      walletId: widget.walletId,
      existing: prefill,
    )).then((result) {
      if (result == true) widget.onAdded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final hasInput = _ctrl.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            if (hasInput && _result.hasAmount)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _buildPreview(locale),
              ),
            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: S.of(context, 'quickAddHint'),
                      hintStyle: AppTextStyles.hint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                      suffixIcon: hasInput
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () { _ctrl.clear(); _focusNode.unfocus(); },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _saving
                    ? const SizedBox(width: 40, height: 40, child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                    : IconButton(
                        onPressed: hasInput ? _submit : _openFullForm,
                        icon: Icon(
                          hasInput && _result.isComplete ? Icons.check_circle : Icons.add_circle,
                          color: AppColors.inkBlue,
                          size: 32,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(String locale) {
    final amountStr = AmountFormatter.formatCurrency(_result.amount, locale);
    final catName = _result.hasCategory
        ? _categories.where((c) => c.id == _result.matchedCategoryId).firstOrNull?.name
        : null;
    final isIncome = _result.type == TransactionType.income;

    return Row(
      children: [
        Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          size: 14,
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
        const SizedBox(width: 4),
        Text(
          amountStr,
          style: AppTextStyles.bodyBold.copyWith(
            color: isIncome ? AppColors.income : AppColors.expense,
          ),
        ),
        if (catName != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.inkBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(catName, style: AppTextStyles.caption),
          ),
        ],
        if (!_result.hasCategory && _result.keyword != null && _result.keyword!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Text('?', style: AppTextStyles.caption.copyWith(color: AppColors.divider)),
        ],
      ],
    );
  }
}
