import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/services/goal_service.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';
import 'package:vintage_ledger/features/debt/screens/debt_detail_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_form_screen.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';

import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/income_expense_summary_row.dart';
import 'package:vintage_ledger/common/widgets/expandable_fab.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_feed_item.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_form_screen.dart';
import 'package:vintage_ledger/features/goal/screens/goal_contribution_screen.dart';
import 'package:vintage_ledger/features/goal/screens/goal_detail_screen.dart';
import 'package:vintage_ledger/features/goal/screens/goal_form_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_payment_screen.dart';
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
  final _goalService = GoalService();
  final _debtService = DebtService();
  Map<String, String> _categoryNames = {};
  Map<String, String> _walletNameMap = {};
  bool _loading = true;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _walletName = widget.wallet.name;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await sl.categoryService.getCategories();
    final wallets = await sl.walletService.getWallets();
    if (!mounted) return;
    setState(() {
      _categoryNames = {for (var c in cats) if (c.id != null) c.id!: c.name};
      _walletNameMap = {for (var w in wallets) if (w.id != null) w.id!: w.name};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _walletName,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () async {
            final result = await context.pushScreen(WalletFormScreen(wallet: widget.wallet));
            if (result == true) _loadCategories();
          },
        ),
      ],
      fab: _buildFab(),
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
                        _buildGoalSection(),
                        _buildDebtSection(),
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

  // ── FAB based on wallet type ──

  Widget? _buildFab() {
    if (widget.wallet.type == WalletType.saving) {
      return ExpandableFab(
        bottomOffset: 80,
        actions: [
          ExpandableFabAction(
            icon: Icons.flag,
            label: S.of(context, 'addGoal'),
            color: AppColors.primary,
            onTap: () async {
              await context.pushScreen(const GoalFormScreen());
              _loadCategories();
            },
          ),
          ExpandableFabAction(
            icon: Icons.savings,
            label: S.of(context, 'contributeGoal'),
            color: AppColors.income,
            onTap: () => context.pushScreen(const GoalContributionScreen()),
          ),
        ],
      );
    }
    if (widget.wallet.type == WalletType.debt) {
      return ExpandableFab(
        bottomOffset: 80,
        actions: [
          ExpandableFabAction(
            icon: Icons.person_add,
            label: S.of(context, 'addDebt'),
            color: AppColors.primary,
            onTap: () async {
              await context.pushScreen(const DebtFormScreen());
              _loadCategories();
            },
          ),
          ExpandableFabAction(
            icon: Icons.payment,
            label: S.of(context, 'payDebt'),
            color: AppColors.expense,
            onTap: () => context.pushScreen(const DebtPaymentScreen()),
          ),
        ],
      );
    }
    return null;
  }

  // ── Balance Card ──

  Widget _buildBalanceCard() {
    final locale = Localizations.localeOf(context).languageCode;

    return StreamBuilder<Wallet?>(
      stream: sl.walletService.watchWallets().map(
        (wallets) => wallets.where((w) => w.id == widget.wallet.id).firstOrNull,
      ),
      initialData: widget.wallet,
      builder: (context, walletSnap) {
        final wallet = walletSnap.data ?? widget.wallet;
        final balance = wallet.balance;

        // Debt wallet: show debt-specific balance card
        if (wallet.type == WalletType.debt) {
          return _buildDebtBalanceCard(wallet, locale);
        }

        // Normal/saving wallet: check for earmarked goals
        return StreamBuilder<int>(
          stream: _goalService.watchEarmarkedAmount(widget.wallet.id!),
          initialData: 0,
          builder: (context, earmarkSnap) {
            final earmarked = earmarkSnap.data ?? 0;
            final hasGoals = earmarked > 0;

            return GestureDetector(
              onTap: () => setState(() => _balanceVisible = !_balanceVisible),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                  boxShadow: [AppColors.cardShadow],
                ),
                child: Column(
                  children: [
                    if (hasGoals)
                      Text(
                        S.of(context, 'walletTotalBalance'),
                        style: AppTextStyles.caption,
                      ),
                    Text(
                      _balanceVisible
                          ? AmountFormatter.formatCurrency(balance, locale)
                          : '••••••',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (!hasGoals)
                      Text(_walletName, style: AppTextStyles.caption),
                    if (hasGoals) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  S.of(context, 'earmarkedAmount'),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _balanceVisible
                                      ? AmountFormatter.formatCurrency(earmarked, locale)
                                      : '••••••',
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  S.of(context, 'availableBalance'),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _balanceVisible
                                      ? AmountFormatter.formatCurrency(
                                          balance - earmarked, locale)
                                      : '••••••',
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Debt Balance Card ──

  Widget _buildDebtBalanceCard(Wallet wallet, String locale) {
    final initialDebt = wallet.initialBalance.abs();
    final currentBalance = wallet.balance;
    // For debt wallet: initialBalance is negative, balance increases as payments are made
    // paidAmount = initialBalance.abs() - remaining debt
    // remaining = abs(balance) if balance is negative, or 0 if paid off
    final remaining = currentBalance < 0 ? currentBalance.abs() : 0;
    final paid = initialDebt - remaining;

    return GestureDetector(
      onTap: () => setState(() => _balanceVisible = !_balanceVisible),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          boxShadow: [AppColors.cardShadow],
        ),
        child: Column(
          children: [
            Text(S.of(context, 'initialDebt'), style: AppTextStyles.caption),
            Text(
              _balanceVisible
                  ? AmountFormatter.formatCurrency(initialDebt, locale)
                  : '••••••',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(S.of(context, 'paidDebt'), style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _balanceVisible
                            ? AmountFormatter.formatCurrency(paid, locale)
                            : '••••••',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(S.of(context, 'remainingDebt'), style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _balanceVisible
                            ? AmountFormatter.formatCurrency(remaining, locale)
                            : '••••••',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Goal Section (only when wallet has active goals) ──

  Widget _buildGoalSection() {
    return StreamBuilder<List<Goal>>(
      stream: _goalService.watchGoalsByWallet(widget.wallet.id!),
      initialData: const [],
      builder: (context, snapshot) {
        final goals = snapshot.data ?? [];
        if (goals.isEmpty) return const SizedBox.shrink();

        final locale = Localizations.localeOf(context).languageCode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context, 'linkedGoals'), style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () async {
                  await context.pushScreen(GoalDetailScreen(goalId: goal.id));
                  _loadCategories();
                },
                child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Text(goal.category.emoji, style: AppTextStyles.emoji),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.name, style: AppTextStyles.bodyBold),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: goal.progressPercentage.clamp(0.0, 1.0),
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation(AppColors.income),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AmountFormatter.formatCompactCurrency(goal.currentAmount, locale),
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.income),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
              ),
            )),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  // ── Debt Section (only when debt wallet has linked debts) ──

  Widget _buildDebtSection() {
    if (widget.wallet.type != WalletType.debt) return const SizedBox.shrink();

    return StreamBuilder<List<Debt>>(
      stream: _debtService.watchDebtsByWallet(widget.wallet.id!),
      initialData: const [],
      builder: (context, snapshot) {
        final debts = snapshot.data ?? [];
        if (debts.isEmpty) return const SizedBox.shrink();

        final locale = Localizations.localeOf(context).languageCode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context, 'debts'), style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...debts.map((debt) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () async {
                  await context.pushScreen(DebtDetailScreen(debtId: debt.id));
                  _loadCategories();
                },
                child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      debt.type == DebtType.lend ? Icons.trending_up : Icons.trending_down,
                      color: debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debt.partyName, style: AppTextStyles.bodyBold),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: debt.progressPercentage.clamp(0.0, 1.0),
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AmountFormatter.formatCompactCurrency(debt.remainingAmount, locale),
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.expense),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
              ),
            )),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  // ── Feed Section ──

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
            final monthIncome = txns.where((t) => t.transaction.type == TransactionType.income || t.transaction.type == TransactionType.transferIn).fold(0, (s, t) => s + t.transaction.amount);
            final monthExpense = txns.where((t) => t.transaction.type == TransactionType.expense || t.transaction.type == TransactionType.transferOut).fold(0, (s, t) => s + t.transaction.amount);
            return Column(
              children: [
                IncomeExpenseSummaryRow(income: monthIncome, expense: monthExpense),
                const SizedBox(height: AppSpacing.md),
                ...txns.map((txn) => TransactionFeedItem(
                txn: txn,
                categoryName: _categoryNames[txn.transaction.categoryId] ?? S.of(context, 'other'),
                onChanged: _loadCategories,
                walletNames: _walletNameMap,
              )),
              ],
            );
          },
        ),
      ],
    );
  }
}
