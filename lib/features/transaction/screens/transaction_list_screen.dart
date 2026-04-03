import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';

import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';
import 'package:vintage_ledger/utils/transaction_story.dart';

class TransactionListScreen extends StatefulWidget {
  final String? walletId;
  final bool isTab;

  const TransactionListScreen({super.key, this.walletId, this.isTab = false});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionRepository _txnRepo = TransactionRepository();

  List<TransactionWithItems> _allTransactions = [];
  List<Wallet> _wallets = [];
  List<Category> _categories = [];
  Map<String, String> _categoryNameMap = {};

  late DateTime _currentMonth;
  bool _loading = false;
  String? _error;

  String? _filterWalletId;
  String? _filterCategoryId;
  String? _defaultWalletId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _filterWalletId = widget.walletId;
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      _categories = await sl.categoryService.getCategories();
      _categoryNameMap = {for (var c in _categories) if (c.id != null) c.id!: c.name};
      if (widget.walletId == null) {
        _wallets = await sl.walletService.getWallets();
        _defaultWalletId = await sl.settingService.getLastWalletId();
        if (_defaultWalletId != null && !_wallets.any((w) => w.id == _defaultWalletId)) {
          _defaultWalletId = _wallets.firstOrNull?.id;
        }
      }
      await _loadMonth();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMonth() async {
    final start = _currentMonth;
    final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59, 999);
    final txns = await _txnRepo.getByDateRange(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
      walletId: widget.walletId,
    );
    final userIds = txns.map((t) => t.transaction.createdBy).whereType<String>().toSet().toList();
    await FeedHelper.preloadNames(userIds);
    if (!mounted) return;
    setState(() => _allTransactions = txns);
  }

  List<TransactionWithItems> get _filtered {
    var list = _allTransactions;
    if (_filterWalletId != null) {
      list = list.where((t) => t.transaction.walletId == _filterWalletId).toList();
    }
    if (_filterCategoryId != null) {
      list = list.where((t) => t.transaction.categoryId == _filterCategoryId).toList();
    }
    return list;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
      _loading = true;
    });
    _loadMonth().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  // ── Day groups ──

  List<_DayGroup> _buildDayGroups() {
    final txns = _filtered;
    final map = <int, List<TransactionWithItems>>{};
    for (var t in txns) {
      final day = DateTime.fromMillisecondsSinceEpoch(t.transaction.date).day;
      map.putIfAbsent(day, () => []);
      map[day]!.add(t);
    }
    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return days.map((d) => _DayGroup(
      day: d,
      date: DateTime(_currentMonth.year, _currentMonth.month, d),
      items: map[d]!,
    )).toList();
  }

  // ── Actions ──

  Future<void> _openForm({TransactionWithItems? txn}) async {
    final result = await context.pushScreen(TransactionFormScreen(
      walletId: txn?.transaction.walletId ?? widget.walletId ?? _filterWalletId,
      existing: txn,
    ));
    if (result == true) _loadMonth();
  }

  Future<void> _deleteTransaction(String id) async {
    await sl.transactionService.deleteTransaction(id);
    _loadMonth();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final txns = _filtered;
    final locale = Localizations.localeOf(context).languageCode;
    final totalExpense = txns.where((t) => t.transaction.type.isExpense).fold<int>(0, (s, t) => s + t.transaction.amount);
    final totalIncome = txns.where((t) => t.transaction.type.isIncome).fold<int>(0, (s, t) => s + t.transaction.amount);

    return AppScaffold(
      title: S.of(context, 'transactionLedger'),
      showBackButton: !widget.isTab,
      body: Column(
        children: [
          // Month picker
          _buildMonthPicker(),

          // Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryChip(S.of(context, 'income'), totalIncome, AppColors.income, locale),
                _buildSummaryChip(S.of(context, 'expense'), totalExpense, AppColors.expense, locale),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Filter chips
          _buildFilterRow(),
          const SizedBox(height: AppSpacing.sm),

          // Timeline
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: AppTextStyles.error))
                    : txns.isEmpty
                        ? EmptyState(emoji: '📝', message: S.of(context, 'noTransactions'))
                        : RefreshIndicator(
                            onRefresh: _loadMonth,
                            child: _buildTimeline(),
                          ),
          ),

          // Quick Add
          QuickAddBar(
            walletId: widget.walletId ?? _filterWalletId ?? _defaultWalletId,
            wallets: widget.walletId != null ? const [] : _wallets,
            onWalletChanged: widget.walletId != null ? null : (id) {
              sl.settingService.setLastWalletId(id);
              setState(() => _defaultWalletId = id);
            },
            onAdded: _loadMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: () => _changeMonth(-1),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _currentMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked == null || !mounted) return;
              setState(() { _currentMonth = DateTime(picked.year, picked.month); _loading = true; });
              _loadMonth().then((_) { if (mounted) setState(() => _loading = false); });
            },
            child: Text(DateFormatter.monthYearLong(_currentMonth), style: AppTextStyles.titleSmall),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int amount, Color color, String locale) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(
          AmountFormatter.formatCompactCurrency(amount, locale),
          style: AppTextStyles.bodyBold.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          // Wallet filter
          if (widget.walletId == null && _wallets.length > 1) ...[
            _buildFilterChip(
              label: _filterWalletId == null
                  ? S.of(context, 'allWallets')
                  : _wallets.where((w) => w.id == _filterWalletId).firstOrNull?.name ?? '',
              active: _filterWalletId != null,
              onTap: _showWalletFilter,
            ),
            const SizedBox(width: 8),
          ],
          // Category filter
          _buildFilterChip(
            label: _filterCategoryId == null
                ? S.of(context, 'allCategories')
                : _categoryNameMap[_filterCategoryId] ?? '',
            active: _filterCategoryId != null,
            onTap: _showCategoryFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showWalletFilter() {
    if (_filterWalletId != null) {
      setState(() => _filterWalletId = null);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(S.of(ctx, 'selectWallet'), style: AppTextStyles.titleSmall),
            ),
            ..._wallets.map((w) => ListTile(
              title: Text(w.name, style: AppTextStyles.body),
              trailing: _filterWalletId == w.id ? const Icon(Icons.check, color: AppColors.primary, size: 20) : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _filterWalletId = w.id);
              },
            )),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    if (_filterCategoryId != null) {
      setState(() => _filterCategoryId = null);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(S.of(ctx, 'category'), style: AppTextStyles.titleSmall),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _categories.map((c) => ListTile(
                  title: Text(c.name, style: AppTextStyles.body),
                  trailing: _filterCategoryId == c.id ? const Icon(Icons.check, color: AppColors.primary, size: 20) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _filterCategoryId = c.id);
                  },
                )).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  // ── Timeline ──

  Widget _buildTimeline() {
    final groups = _buildDayGroups();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: groups.length,
      itemBuilder: (context, index) => _buildDayEntry(groups[index]),
    );
  }

  Widget _buildDayEntry(_DayGroup group) {
    final locale = Localizations.localeOf(context).languageCode;
    final net = group.income - group.expense;
    final weekday = DateFormatter.dayOfWeek(group.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('${group.day}', style: AppTextStyles.title.copyWith(fontSize: 20)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(weekday, style: AppTextStyles.bodySmall),
              ),
              Text(
                '${net >= 0 ? '+' : '-'}${AmountFormatter.formatCompactCurrency(net.abs(), locale)}',
                style: AppTextStyles.caption.copyWith(
                  color: net >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
        ),
        // Transactions
        ...group.items.map((t) => _buildTile(t, locale)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildTile(TransactionWithItems txn, String locale) {
    final catName = _categoryNameMap[txn.transaction.categoryId] ?? S.of(context, 'other');
    final actor = FeedHelper.resolveName(txn.transaction.createdBy, S.of(context, 'youActor'));
    final story = TransactionStory.format(
      actorName: actor,
      categoryName: catName,
      amount: txn.transaction.amount,
      type: txn.transaction.type,
      locale: locale,
      note: txn.transaction.note,
    );
    final time = DateFormatter.time(txn.transaction.date);

    return SwipeListItem(
      itemKey: Key(txn.transaction.id!),
      onTap: () => _openForm(txn: txn),
      confirmDelete: () => showDeleteConfirmation(context, titleKey: 'deleteTransaction', contentKey: 'deleteTransactionConfirm'),
      onDelete: () => _deleteTransaction(txn.transaction.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md2, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(child: Text(story, style: AppTextStyles.body)),
            Text(time, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _DayGroup {
  final int day;
  final DateTime date;
  final List<TransactionWithItems> items;
  _DayGroup({required this.day, required this.date, required this.items});
  int get income => items.where((t) => t.transaction.type.isIncome).fold(0, (s, t) => s + t.transaction.amount);
  int get expense => items.where((t) => t.transaction.type.isExpense).fold(0, (s, t) => s + t.transaction.amount);
}
