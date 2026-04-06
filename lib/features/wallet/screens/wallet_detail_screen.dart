import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/core/service_locator.dart';

import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/income_expense_summary_row.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_feed_item.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_form_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late String _walletName;
  Map<String, String> _categoryNames = {};
  bool _loading = true;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _walletName = widget.wallet.name;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = sl.cache.categories;
    if (!mounted) return;
    setState(() {
      _categoryNames = {for (var c in cats) if (c.id != null) c.id!: c.name};
      _loading = false;
    });
  }

  Future<void> _renameWallet() async {
    final ctrl = TextEditingController(text: _walletName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'walletName')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTextStyles.body,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(S.of(ctx, 'save'))),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == _walletName) return;
    await sl.walletService.renameWallet(widget.wallet.id!, newName);
    if (mounted) setState(() => _walletName = newName);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _walletName,
      onTitleTap: _renameWallet,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () async {
            final result = await context.pushScreen(WalletFormScreen(wallet: widget.wallet));
            if (result == true) _loadCategories();
          },
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const ShimmerPlaceholder()
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _buildBalanceCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFeedSection(),
                      ],
                    ),
                  ),
          ),
          QuickAddBar(
            walletId: widget.wallet.id!,
            onAdded: _loadCategories,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final locale = Localizations.localeOf(context).languageCode;

    return StreamBuilder<Wallet?>(
      stream: sl.walletService.watchWallets().map(
        (wallets) => wallets.where((w) => w.id == widget.wallet.id).firstOrNull,
      ),
      initialData: widget.wallet,
      builder: (context, snap) {
        final balance = snap.data?.balance ?? widget.wallet.balance;
        final balanceStr = AmountFormatter.formatCurrency(balance, locale);

        return GestureDetector(
          onTap: () => setState(() => _balanceVisible = !_balanceVisible),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _balanceVisible ? balanceStr : '••••••',
                  style: AppTextStyles.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _walletName,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context, 'recentTransactions'), style: AppTextStyles.titleSmall),
            GestureDetector(
              onTap: () => context.pushScreen(TransactionListScreen(walletId: widget.wallet.id)),
              child: Text(S.of(context, 'viewAll'), style: AppTextStyles.link),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<TransactionWithItems>>(
          stream: sl.transactionService.watchRecent(20, walletId: widget.wallet.id!),
          builder: (context, snap) {
            final txns = snap.data ?? [];
            if (txns.isEmpty) {
              return EmptyState(emoji: '📝', message: S.of(context, 'emptyTransactionHint'));
            }
            final monthIncome = txns.where((t) => t.transaction.type == TransactionType.income).fold(0, (s, t) => s + t.transaction.amount);
            final monthExpense = txns.where((t) => t.transaction.type == TransactionType.expense).fold(0, (s, t) => s + t.transaction.amount);
            return Column(
              children: [
                IncomeExpenseSummaryRow(income: monthIncome, expense: monthExpense),
                const SizedBox(height: AppSpacing.md),
                ...txns.map((txn) => TransactionFeedItem(
                txn: txn,
                categoryName: _categoryNames[txn.transaction.categoryId] ?? S.of(context, 'other'),
                onChanged: _loadCategories,
              )),
              ],
            );
          },
        ),
      ],
    );
  }
}
