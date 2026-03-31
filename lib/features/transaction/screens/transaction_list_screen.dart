import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/income_expense_summary_row.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';

import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

enum GroupMode { day, week, month }

class TransactionListScreen extends StatefulWidget {
  final int? walletId;

  const TransactionListScreen({super.key, this.walletId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<TransactionWithItems> _transactions = [];
  Map<int, String> _categoryNameMap = {};
  Map<int, int?> _categoryIconMap = {};
  GroupMode _groupMode = GroupMode.day;

  /// The month cursor: next _loadMonth will load this month's data.
  late DateTime _cursor;
  bool _loading = false;
  bool _loadingMore = false;
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _cursor = DateTime(now.year, now.month, 1);
    _scrollController.addListener(_onScroll);
    _initialLoad();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _initialLoad() async {
    setState(() => _loading = true);
    await _loadCategories();
    await _loadMonth();
    setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    if (_categoriesLoaded) return;
    final cats = await sl.categoryService.getCategories();
    _categoryNameMap = {for (var c in cats) if (c.id != null) c.id!: c.name};
    _categoryIconMap = {for (var c in cats) if (c.id != null) c.id!: c.icon};
    _categoriesLoaded = true;
  }

  /// Load one month of data at [_cursor], then move cursor back one month.
  Future<void> _loadMonth() async {
    final start = _cursor;
    final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59, 999);

    final txns = await sl.transactionService.getByDateRangeWithItems(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
      walletId: widget.walletId,
    );

    setState(() {
      _transactions.addAll(txns);
      // Move cursor to previous month
      _cursor = DateTime(start.year, start.month - 1, 1);
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await _loadMonth();
    setState(() => _loadingMore = false);
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    _cursor = DateTime(now.year, now.month, 1);
    _transactions.clear();
    _categoriesLoaded = false;
    await _initialLoad();
  }

  void _changeGroupMode(GroupMode mode) {
    setState(() => _groupMode = mode);
  }

  // ========================
  // GROUPING LOGIC
  // ========================

  /// Returns a key for grouping based on the current mode.
  String _groupKey(TransactionWithItems t) {
    final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
    switch (_groupMode) {
      case GroupMode.day:
        return DateFormatter.fullDate(t.transaction.date);
      case GroupMode.week:
        // ISO week: Monday-based
        final monday = dt.subtract(Duration(days: dt.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormatter.fullDate(monday.millisecondsSinceEpoch)}'
            ' - ${DateFormatter.fullDate(sunday.millisecondsSinceEpoch)}';
      case GroupMode.month:
        return DateFormatter.monthYear(DateTime(dt.year, dt.month));
    }
  }

  List<_Group> _buildGroups() {
    final map = <String, List<TransactionWithItems>>{};
    final order = <String>[];
    for (var t in _transactions) {
      final key = _groupKey(t);
      if (!map.containsKey(key)) {
        map[key] = [];
        order.add(key);
      }
      map[key]!.add(t);
    }
    return order.map((key) => _Group(key, map[key]!)).toList();
  }

  int get _totalIncome => _transactions
      .where((t) => t.transaction.type.isIncome)
      .fold(0, (sum, t) => sum + t.transaction.amount);

  int get _totalExpense => _transactions
      .where((t) => t.transaction.type.isExpense)
      .fold(0, (sum, t) => sum + t.transaction.amount);

  // ========================
  // ACTIONS
  // ========================

  Future<void> _openForm({TransactionWithItems? txn}) async {
    final result = await context.pushScreen(
      TransactionFormScreen(
        walletId: txn?.transaction.walletId ?? widget.walletId,
        transaction: txn?.transaction,
      ),
    );
    if (result == true) _refresh();
  }

  Future<bool?> _confirmDelete() {
    return showDeleteConfirmation(
      context,
      titleKey: 'deleteTransaction',
      contentKey: 'deleteTransactionConfirm',
    );
  }

  Future<void> _deleteTransaction(int id) async {
    await sl.transactionService.deleteTransaction(id);
    _refresh();
  }

  // ========================
  // BUILD
  // ========================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'transactionLedger'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: _buildGroupModeRow(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildSummaryCard(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(child: Text(S.of(context, 'noTransactions')))
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: _buildList(),
                      ),
          ),
        ],
      ),
      fab: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.inkBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupModeRow() {
    final labels = {
      GroupMode.day: S.of(context, 'byDay'),
      GroupMode.week: S.of(context, 'byWeek'),
      GroupMode.month: S.of(context, 'byMonth'),
    };

    return Row(
      children: GroupMode.values.map((m) {
        final selected = m == _groupMode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => _changeGroupMode(m),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? AppColors.inkBlue : AppColors.paper,
                foregroundColor: selected ? Colors.white : AppColors.inkBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AppColors.divider),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(labels[m]!),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    return LedgerCard(
      child: IncomeExpenseSummaryRow(
        income: _totalIncome,
        expense: _totalExpense,
      ),
    );
  }

  Widget _buildList() {
    final groups = _buildGroups();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      // +1 for the loading indicator at the bottom
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return _loadingMore
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox(height: 80);
        }

        final group = groups[index];
        return _buildGroupSection(group);
      },
    );
  }

  Widget _buildGroupSection(_Group group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Group header
        Row(
          children: [
            Expanded(
              child: Text(group.label, style: AppTextStyles.titleSmall),
            ),
            if (group.income > 0)
              AmountText(amount: group.income, type: 'income', compact: true),
            if (group.income > 0 && group.expense > 0)
              const SizedBox(width: AppSpacing.sm),
            if (group.expense > 0)
              AmountText(amount: group.expense, type: 'expense', compact: true),
          ],
        ),
        const Divider(),
        ...group.items.map((t) => _buildTransactionTile(t)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionWithItems txn) {
    final catName = _categoryNameMap[txn.transaction.categoryId] ??
        S.of(context, 'other');
    final catIcon = _categoryIconMap[txn.transaction.categoryId];

    return SwipeListItem(
      itemKey: Key(txn.transaction.id.toString()),
      onTap: () => _openForm(txn: txn),
      confirmDelete: _confirmDelete,
      onDelete: () => _deleteTransaction(txn.transaction.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              getCategoryIcon(catIcon),
              size: 22,
              color: AppColors.inkBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catName, style: AppTextStyles.bodyBold),
                  if (txn.transaction.note != null &&
                      txn.transaction.note!.isNotEmpty)
                    Text(
                      txn.transaction.note!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  amount: txn.transaction.amount,
                  type: txn.transaction.type.value,
                ),
                Text(
                  DateFormatter.short(txn.transaction.date),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to hold a group of transactions with pre-computed totals.
class _Group {
  final String label;
  final List<TransactionWithItems> items;

  _Group(this.label, this.items);

  int get income => items
      .where((t) => t.transaction.type.isIncome)
      .fold(0, (sum, t) => sum + t.transaction.amount);

  int get expense => items
      .where((t) => t.transaction.type.isExpense)
      .fold(0, (sum, t) => sum + t.transaction.amount);
}
