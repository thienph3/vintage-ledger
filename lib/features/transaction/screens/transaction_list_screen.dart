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
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';

class TransactionListScreen extends StatefulWidget {
  final String? walletId;
  final bool isTab;

  const TransactionListScreen({super.key, this.walletId, this.isTab = false});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionRepository _txnRepo = TransactionRepository();

  List<TransactionWithItems> _transactions = [];
  Map<String, String> _categoryNameMap = {};
  Map<String, int?> _categoryIconMap = {};

  late DateTime _currentMonth;
  bool _loading = false;
  String? _error;
  int? _expandedDay;

  List<Wallet> _wallets = [];
  String? _defaultWalletId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _loadCategories();
      if (widget.walletId == null) await _loadWallets();
      await _loadMonth();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadWallets() async {
    _wallets = await sl.walletService.getWallets();
    _defaultWalletId = await sl.settingService.getLastWalletId();
    if (_defaultWalletId != null && !_wallets.any((w) => w.id == _defaultWalletId)) {
      _defaultWalletId = _wallets.firstOrNull?.id;
    }
  }

  Future<void> _loadCategories() async {
    final cats = await sl.categoryService.getCategories();
    _categoryNameMap = {for (var c in cats) if (c.id != null) c.id!: c.name};
    _categoryIconMap = {for (var c in cats) if (c.id != null) c.id!: c.icon};
  }

  Future<void> _loadMonth() async {
    final start = _currentMonth;
    final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59, 999);
    try {
      final txns = await _txnRepo.getByDateRange(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
        walletId: widget.walletId,
      );
      if (!mounted) return;
      setState(() {
        _transactions = txns;
        _expandedDay = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _refresh() async {
    await _loadMonth();
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

  // ── Grouping by day ──

  List<_DayGroup> _buildDayGroups() {
    final map = <int, List<TransactionWithItems>>{};
    for (var t in _transactions) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      final day = dt.day;
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
      showBackButton: !widget.isTab,
      body: Column(
        children: [
          _buildMonthPicker(),
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
                        ? Center(child: Text(S.of(context, 'noTransactions'), style: AppTextStyles.hint))
                        : RefreshIndicator(onRefresh: _refresh, child: _buildTimeline()),
          ),
          QuickAddBar(
            walletId: widget.walletId ?? _defaultWalletId,
            wallets: widget.walletId != null ? const [] : _wallets,
            onWalletChanged: widget.walletId != null ? null : (id) {
              sl.settingService.setLastWalletId(id);
              setState(() => _defaultWalletId = id);
            },
            onAdded: _refresh,
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
            icon: const Icon(Icons.chevron_left, color: AppColors.inkBlue),
            onPressed: () => _changeMonth(-1),
          ),
          GestureDetector(
            onTap: _pickMonth,
            child: Text(
              DateFormatter.monthYearLong(_currentMonth),
              style: AppTextStyles.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.inkBlue),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _currentMonth = DateTime(picked.year, picked.month);
      _loading = true;
    });
    _loadMonth().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Widget _buildTimeline() {
    final groups = _buildDayGroups();
    final locale = Localizations.localeOf(context).languageCode;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: groups.length,
      itemBuilder: (context, index) => _buildDayEntry(groups[index], locale),
    );
  }

  Widget _buildDayEntry(_DayGroup group, String locale) {
    final isExpanded = _expandedDay == group.day;
    final net = group.income - group.expense;
    final netStr = AmountFormatter.formatCompactCurrency(net.abs(), locale);
    final dayLabel = '${group.day}';
    final weekday = DateFormatter.dayOfWeek(group.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header — tappable
        InkWell(
          onTap: () => setState(() => _expandedDay = isExpanded ? null : group.day),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                // Day number
                SizedBox(
                  width: 36,
                  child: Text(dayLabel, style: AppTextStyles.title.copyWith(fontSize: 22)),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Weekday + txn count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(weekday, style: AppTextStyles.bodySmall),
                      Text(
                        '${group.items.length} ${S.of(context, 'transactionCount').toLowerCase()}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                // Net amount
                Text(
                  '${net >= 0 ? '+' : '-'}$netStr',
                  style: AppTextStyles.amount.copyWith(
                    color: net >= 0 ? AppColors.income : AppColors.expense,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20, color: AppColors.divider,
                ),
              ],
            ),
          ),
        ),
        // Expanded transactions
        if (isExpanded)
          ...group.items.map((t) => _buildTransactionTile(t)),
        const Divider(height: 1),
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
        padding: const EdgeInsets.only(left: 44, right: 12, top: 6, bottom: 6),
        child: Row(
          children: [
            Icon(getCategoryIcon(catIcon), size: 18, color: AppColors.inkBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catName, style: AppTextStyles.body),
                  if (txn.transaction.note != null && txn.transaction.note!.isNotEmpty)
                    Text(txn.transaction.note!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            AmountText(amount: txn.transaction.amount, type: txn.transaction.type, compact: true),
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
