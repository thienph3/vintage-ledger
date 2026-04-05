import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';
import 'package:vintage_ledger/common/widgets/inline_selector.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/core/constants/category_emojis.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_history.dart';
import 'package:vintage_ledger/features/quick_add/models/quick_add_entry.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class QuickAddBar extends StatefulWidget {
  final String? walletId;
  final List<Wallet> wallets;
  final ValueChanged<String>? onWalletChanged;
  final VoidCallback onAdded;

  const QuickAddBar({
    super.key,
    this.walletId,
    this.wallets = const [],
    this.onWalletChanged,
    required this.onAdded,
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Category> _categories = [];
  QuickAddResult _result = QuickAddResult(amount: 0);
  bool _saving = false;
  bool _focused = false;
  bool _userPickedCategory = false;
  List<QuickAddEntry> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _categories = sl.cache.categories;
    _ctrl.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
    _suggestions = QuickAddHistory.suggest();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final text = _ctrl.text.trim();
    setState(() {
      _result = QuickAddParser.parse(_ctrl.text, _categories);
      _userPickedCategory = false;
      _suggestions = text.isEmpty
          ? QuickAddHistory.suggest()
          : QuickAddHistory.suggest(filter: text);
    });
  }

  void _onFocusChanged() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _applySuggestion(QuickAddEntry entry) {
    _ctrl.text = entry.text;
    _ctrl.selection = TextSelection.collapsed(offset: entry.text.length);
    _submit();
  }

  String? get _currentWalletName {
    if (widget.walletId == null) return null;
    return widget.wallets.where((w) => w.id == widget.walletId).firstOrNull?.name;
  }

  void _showWalletPicker() async {
    if (widget.wallets.length <= 1) return;
    final selected = await showSelectionSheet<String>(
      context: context,
      title: S.of(context, 'selectWallet'),
      items: widget.wallets.map((w) => SelectionItem(
        value: w.id!,
        label: w.name,
        icon: Icons.account_balance_wallet_outlined,
      )).toList(),
      selected: widget.walletId,
    );
    if (selected != null) widget.onWalletChanged?.call(selected);
  }

  Future<void> _submit() async {
    if (!_result.hasAmount) return;

    if (!_result.hasCategory || QuickAddParser.lastMatchWasFuzzy) {
      _openFullForm();
      return;
    }

    final walletId = widget.walletId ?? widget.wallets.firstOrNull?.id;
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

      if (_userPickedCategory && _result.keyword != null && _result.keyword!.isNotEmpty) {
        QuickAddParser.learn(_result.keyword!, _result.matchedCategoryId!);
      }

      QuickAddHistory.record(_ctrl.text.trim(), _result.matchedCategoryId!, _result.amount);
      AmountHistory.record(_result.amount);

      // Persist as last used wallet
      sl.settingService.setLastWalletId(walletId);

      final savedAmount = _result.amount;
      final catName = _categories.where((c) => c.id == _result.matchedCategoryId).firstOrNull?.name ?? '';

      _ctrl.clear();
      _focusNode.unfocus();
      widget.onAdded();
      if (!mounted) return;

      final locale = Localizations.localeOf(context).languageCode;
      final amountStr = AmountFormatter.formatCompactCurrency(savedAmount, locale);

      final emoji = getCategoryEmoji(catName);

      showAppSnackBar(context, '✓ $catName $amountStr $emoji',
        action: SnackBarAction(
          label: S.of(context, 'undo'),
          onPressed: () async {
            await sl.transactionService.deleteTransaction(txnId);
            widget.onAdded();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
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
      prefill: prefill,
    )).then((result) {
      if (result == true) widget.onAdded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = _ctrl.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Suggestion chips (above input, like quick replies)
            if (_focused && _suggestions.isNotEmpty && !_result.hasAmount)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final e = _suggestions[i];
                      return ActionChip(
                        label: Text(e.text, style: AppTextStyles.caption),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _applySuggestion(e),
                      );
                    },
                  ),
                ),
              ),
            // Wallet chip (compact, only when multiple wallets + no input)
            if (!hasInput && widget.wallets.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _buildWalletChip(),
              ),
            // Parse preview
            if (hasInput && _result.hasAmount)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _buildParsePreview(),
              ),
            // Chat-like input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: S.of(context, 'quickAddHint'),
                        hintStyle: AppTextStyles.hint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                        suffixIcon: hasInput
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                                onPressed: () { _ctrl.clear(); _focusNode.unfocus(); },
                              )
                            : null,
                      ),
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
                        onPressed: _result.isComplete ? _submit : (hasInput ? null : _openFullForm),
                        icon: Icon(
                          hasInput ? Icons.send_rounded : Icons.add_circle_outline,
                          color: hasInput && !_result.isComplete ? AppColors.textSecondary : AppColors.primary,
                          size: 28,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsePreview() {
    final locale = Localizations.localeOf(context).languageCode;
    final amountStr = AmountFormatter.formatCompactCurrency(_result.amount, locale);
    final matchedCat = _result.hasCategory
        ? _categories.where((c) => c.id == _result.matchedCategoryId).firstOrNull
        : null;
    final catName = matchedCat?.name;
    final catIcon = getCategoryIcon(matchedCat?.icon);
    final isIncome = _result.type == TransactionType.income;

    return Row(
      children: [
        // Wallet (tap to change)
        if (widget.wallets.length > 1) ...[
          InlineSelector(
            icon: Icons.account_balance_wallet_outlined,
            label: _currentWalletName ?? '',
            onTap: _showWalletPicker,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        // Amount
        Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          size: 14,
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
        const SizedBox(width: 4),
        Text(amountStr, style: AppTextStyles.bodySmall.copyWith(
          color: isIncome ? AppColors.income : AppColors.expense,
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(width: AppSpacing.sm),
        // Category (always tappable)
        InlineSelector(
          icon: catIcon,
          label: catName ?? '?',
          isPlaceholder: catName == null,
          color: catName != null ? (isIncome ? AppColors.income : AppColors.expense) : null,
          onTap: _pickCategory,
        ),
      ],
    );
  }

  Color _catColor(TransactionType? type) =>
      type == TransactionType.income ? AppColors.income : AppColors.expense;

  void _pickCategory() async {
    final selected = await showSelectionSheet<String>(
      context: context,
      title: S.of(context, 'category'),
      items: _categories.map((c) => SelectionItem(
        value: c.id!,
        label: c.name,
        icon: getCategoryIcon(c.icon),
        color: _catColor(c.type),
      )).toList(),
      selected: _result.matchedCategoryId,
    );
    if (selected != null) {
      final cat = _categories.where((c) => c.id == selected).firstOrNull;
      setState(() {
        _userPickedCategory = true;
        _result = QuickAddResult(
          amount: _result.amount,
          keyword: _result.keyword,
          matchedCategoryId: selected,
          type: cat?.type ?? _result.type,
        );
      });
    }
  }

  Widget _buildWalletChip() {
    final name = _currentWalletName ?? '';
    return GestureDetector(
      onTap: _showWalletPicker,
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(name, style: AppTextStyles.caption),
          if (widget.wallets.length > 1) ...[
            const SizedBox(width: 2),
            const Icon(Icons.unfold_more, size: 12, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }
}
