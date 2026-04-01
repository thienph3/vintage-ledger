import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/income_expense_summary_row.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';

import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';

enum GroupMode { day, week, month }

class TransactionListScreen extends StatefulWidget {
  final String? walletId;

  const TransactionListScreen({super.key, this.walletId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TransactionRepository _txnRepo = TransactionRepository();

  final List<TransactionWithItems> _transactions = [];
  Map<String, String> _categoryNameMap = {};
  Map<String, int?> _categoryIconMap = {};
  GroupMode _groupMode = GroupMode.day;

  late DateTime _cursor;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _initialLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _loadCategories();
      await _loadMonth();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    final cats = await sl.categoryService.getCategories();
    _categoryNameMap = {for (var c in cats) if (c.id != null) c.id!: c.name};
    _categoryIconMap = {for (var c in cats) if (c.id != null) c.id!: c.icon};
  }

  Future<void> _loadMonth() async {
    final start = _cursor;
    final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59, 999);
    try {
      final txns = await _txnRepo.getByDateRange(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
        walletId: widget.walletId,
      );
      if (!mounted) return;
      setState(() {
        _transactions.addAll(txns);
        _cursor = DateTime(start.year, start.month - 1, 1);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadMore() async {
    setState(() { _loadingMore = true; _error = null; });
    await _loadMonth();
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    _cursor = DateTime(now.year, now.month, 1);
    _transactions.clear();
    await _initialLoad();
  }

  // ── Grouping ──

  String _groupKey(TransactionWithItems t) {
    final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
    switch (_groupMode) {
      case GroupMode.day:
        return DateFormatter.fullDate(t.transaction.date);
      case GroupMode.week:
        final monday = dt.subtract(Duration(days: dt.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormatter.fullDate(monday.millisecondsSinceEpoch)} - ${DateFormatter.fullDate(sunday.millisecondsSinceEpoch)}';
      case GroupMode.month:
        return DateFormatter.monthYear(DateTime(dt.year, dt.month));
    }
  }

  List<_Group> _buildGroups() {
    final map = <String, List<TransactionWithItems>>{};
    final order = <String>[];
    for (var t in _transactions) {
      final key = _groupKey(t);
      if (!map.containsKey(key)) { map[key] = []; order.add(key); }
      map[key]!.add(t);
    }
    return order.map((key) => _Group(key, map[key]!)).toList();
  }

  int get _totalIncome => _transactions.where((t) => t.transaction.type.isIncome).fold(0, (s, t) => s + t.transaction.amount);
  int get _totalExpense => _transactions.where((t) => t.transaction.type.isExpense).fold(0, (s, t) => s + t.transaction.amount);

  // ── Actions ──

  Future<void> _openForm({TransactionWithItems? txn}) async {
    final result = await context.pushScreen(TransactionFormScreen(
      walletId: txn?.transaction.walletId ?? widget.walletId,
      existing: txn,
    ));
    if (result == true) _refresh();
  }

  Future<bool?> _confirmDelete() => showDeleteConfirmation(context, titleKey: 'deleteTransaction', contentKey: 'deleteTransactionConfirm');

  Future<void> _deleteTransaction(String id) async {
    await sl.transactionService.deleteTransaction(id);
    _refresh();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'transactionLedger'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: _buildGroupModeRow(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: LedgerCard(child: IncomeExpenseSummaryRow(income: _totalIncome, expense: _totalExpense)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: AppTextStyles.error))
                    : _transactions.isEmpty
                        ? Center(child: Text(S.of(context, 'noTransactions')))
                        : RefreshIndicator(onRefresh: _refresh, child: _buildList()),
          ),
          QuickAddBar(
            walletId: widget.walletId,
            onAdded: _refresh,
          ),
        ],
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
              onPressed: () => setState(() => _groupMode = m),
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

  Widget _buildList() {
    final groups = _buildGroups();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return _loadingMore
              ? const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Center(child: CircularProgressIndicator()))
              : const SizedBox(height: 80);
        }
        return _buildGroupSection(groups[index]);
      },
    );
  }

  Widget _buildGroupSection(_Group group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: Text(group.label, style: AppTextStyles.titleSmall)),
            if (group.income > 0) AmountText(amount: group.income, type: TransactionType.income, compact: true),
            if (group.income > 0 && group.expense > 0) const SizedBox(width: AppSpacing.sm),
            if (group.expense > 0) AmountText(amount: group.expense, type: TransactionType.expense, compact: true),
          ],
        ),
        const Divider(),
        ...group.items.map((t) => _buildTransactionTile(t)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionWithItems txn) {
    final catName = _categoryNameMap[txn.transaction.categoryId] ?? S.of(context, 'other');
    final catIcon = _categoryIconMap[txn.transaction.categoryId];

    return SwipeListItem(
      itemKey: Key(txn.transaction.id!),
      onTap: () => _openForm(txn: txn),
      confirmDelete: _confirmDelete,
      onDelete: () => _deleteTransaction(txn.transaction.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(getCategoryIcon(catIcon), size: 22, color: AppColors.inkBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catName, style: AppTextStyles.bodyBold),
                  if (txn.transaction.note != null && txn.transaction.note!.isNotEmpty)
                    Text(txn.transaction.note!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(amount: txn.transaction.amount, type: txn.transaction.type),
                Text(DateFormatter.short(txn.transaction.date), style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Group {
  final String label;
  final List<TransactionWithItems> items;
  _Group(this.label, this.items);
  int get income => items.where((t) => t.transaction.type.isIncome).fold(0, (s, t) => s + t.transaction.amount);
  int get expense => items.where((t) => t.transaction.type.isExpense).fold(0, (s, t) => s + t.transaction.amount);
}
