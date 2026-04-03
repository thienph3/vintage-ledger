import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/network_status_banner.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';
import 'package:vintage_ledger/features/feed/widgets/feed_item.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/utils/transaction_story.dart';
import 'package:vintage_ledger/features/transaction/widgets/reaction_picker.dart';
import 'package:vintage_ledger/features/transaction/widgets/reaction_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> _categoryNames = {};
  Map<String, int?> _categoryIcons = {};
  bool _loading = true;
  String? _accountName;
  String? _defaultWalletId;

  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = _todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await sl.categoryService.getCategories();
      final account = await sl.accountService.getAccount(sl.appState.currentAccountId);
      final walletId = await sl.settingService.getLastWalletId();
      sl.settingService.recordDailyUsage();

      if (!mounted) return;
      setState(() {
        _categoryNames = {for (var c in cats) if (c.id != null) c.id!: c.name};
        _categoryIcons = {for (var c in cats) if (c.id != null) c.id!: c.icon};
        _accountName = account?.name;
        _defaultWalletId = walletId;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Stream<List<TransactionWithItems>> get _todayStream =>
      TransactionRepository().watchByDateRange(
        _todayStart.millisecondsSinceEpoch,
        _todayEnd.millisecondsSinceEpoch,
      );

  int _todayExpense(List<TransactionWithItems> txns) => txns
      .where((t) => t.transaction.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.transaction.amount);

  String? _resolveDefaultWallet(List<Wallet> wallets) {
    if (_defaultWalletId != null && wallets.any((w) => w.id == _defaultWalletId)) {
      return _defaultWalletId;
    }
    return wallets.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: sl.walletService.watchWallets(),
      builder: (context, walletSnap) {
        final wallets = walletSnap.data ?? [];

        return AppScaffold(
          title: _accountName ?? S.of(context, 'homeTitle'),
          showBackButton: false,
          body: Column(
            children: [
              const NetworkStatusBanner(),
              Expanded(
                child: _loading
                    ? const ShimmerPlaceholder()
                    : StreamBuilder<List<TransactionWithItems>>(
                        stream: _todayStream,
                        builder: (context, txnSnap) {
                          final todayTxns = txnSnap.data ?? [];
                          return RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              children: [
                                _buildTodayTotal(todayTxns),
                                const SizedBox(height: AppSpacing.lg),
                                _buildFeed(todayTxns),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (wallets.isNotEmpty)
                QuickAddBar(
                  walletId: _resolveDefaultWallet(wallets),
                  wallets: wallets,
                  onWalletChanged: (id) {
                    sl.settingService.setLastWalletId(id);
                    setState(() => _defaultWalletId = id);
                  },
                  onAdded: _load,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(S.of(context, 'firstRunHint'), style: AppTextStyles.hint, textAlign: TextAlign.center),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTotal(List<TransactionWithItems> todayTxns) {
    final locale = Localizations.localeOf(context).languageCode;
    final expense = _todayExpense(todayTxns);
    final hasExpense = expense > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
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
            hasExpense
                ? S.of(context, 'todaySpent').replaceAll('{amount}', AmountFormatter.formatCompactCurrency(expense, locale))
                : S.of(context, 'noTransactions'),
            style: hasExpense
                ? AppTextStyles.title.copyWith(fontSize: 20)
                : AppTextStyles.hint,
            textAlign: TextAlign.center,
          ),
          if (todayTxns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${todayTxns.length} ${S.of(context, 'transactionCount')}',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeed(List<TransactionWithItems> todayTxns) {
    if (todayTxns.isEmpty) {
      return EmptyState(
        emoji: '📝',
        message: S.of(context, 'emptyTransactionHint'),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context, 'recentTransactions'), style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...todayTxns.map((t) => _buildFeedItem(t)),
        ],
      ),
    );
  }

  Widget _buildFeedItem(TransactionWithItems txn) {
    final catName = _categoryNames[txn.transaction.categoryId] ?? S.of(context, 'other');
    final time = DateFormatter.time(txn.transaction.date);
    final locale = Localizations.localeOf(context).languageCode;
    final actor = FeedHelper.resolveName(txn.transaction.createdBy, S.of(context, 'youActor'));
    final story = TransactionStory.format(
      actorName: actor,
      categoryName: catName,
      amount: txn.transaction.amount,
      type: txn.transaction.type,
      locale: locale,
      note: txn.transaction.note,
    );

    return Column(
      children: [
        FeedItem(
          actorName: actor,
          text: story,
          time: time,
          onTap: () async {
            final result = await context.pushScreen(TransactionFormScreen(
              walletId: txn.transaction.walletId,
              existing: txn,
            ));
            if (result == true) _load();
          },
        ),
        if (txn.transaction.id != null)
          StreamBuilder<Map<String, String>>(
            stream: sl.reactionService.watchReactions(txn.transaction.id!),
            builder: (context, snap) {
              final reactions = snap.data ?? {};
              return GestureDetector(
                onLongPress: () async {
                  final emoji = await ReactionPicker.show(context);
                  if (emoji != null) {
                    sl.reactionService.addReaction(txn.transaction.id!, emoji);
                  }
                },
                child: ReactionBar(reactions: reactions),
              );
            },
          ),
      ],
    );
  }
}
