import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';

import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';
import 'package:vintage_ledger/common/widgets/inline_selector.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_feed_item.dart';
import 'package:vintage_ledger/features/transaction/widgets/calendar_grid.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';

enum TimeRangeMode { day, week, month }
enum ViewMode { list, calendar }

class TransactionListScreen extends StatefulWidget {
  final String? walletId;
  final bool isTab;

  const TransactionListScreen({super.key, this.walletId, this.isTab = false});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {

  List<TransactionWithItems> _allTransactions = [];
  List<Wallet> _wallets = [];
  List<Category> _categories = [];
  Map<String, String> _categoryNameMap = {};

  bool _loading = false;
  String? _error;
  int? _expandedDay;

  // Time range & view mode
  TimeRangeMode _timeRange = TimeRangeMode.month;
  ViewMode _viewMode = ViewMode.list;
  late DateTime _rangeAnchor;
  late DateTime _selectedDate;

  // Filters
  String? _filterWalletId;
  String? _filterCategoryId;
  String? _filterUserId;
  String? _defaultWalletId;
  List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeAnchor = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _filterWalletId = widget.walletId;
    _initFromCache();
  }

  // ── Data loading ──

  void _initFromCache() {
    _categories = sl.cache.categories;
    _categoryNameMap = sl.cache.categoryNameMap;
    _defaultWalletId = sl.cache.lastWalletId;
    _members = sl.cache.memberProfiles;
    _loadWalletsAndRange();
  }

  Future<void> _loadWalletsAndRange() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.walletId == null) {
        _wallets = await sl.walletService.getWallets();
        if (_defaultWalletId != null && !_wallets.any((w) => w.id == _defaultWalletId)) {
          _defaultWalletId = _wallets.firstOrNull?.id;
        }
      }
      await _loadRange();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  (DateTime, DateTime) get _dateRange {
    switch (_timeRange) {
      case TimeRangeMode.day:
        final start = _rangeAnchor;
        final end = DateTime(start.year, start.month, start.day, 23, 59, 59, 999);
        return (start, end);
      case TimeRangeMode.week:
        final start = _rangeAnchor;
        final end = start.add(const Duration(days: 6));
        return (start, DateTime(end.year, end.month, end.day, 23, 59, 59, 999));
      case TimeRangeMode.month:
        final start = _rangeAnchor;
        final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59, 999);
        return (start, end);
    }
  }

  Future<void> _loadRange() async {
    final (start, end) = _dateRange;
    final txns = await sl.transactionService.getByDateRange(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
      walletId: widget.walletId,
    );
    final userIds = txns.map((t) => t.transaction.createdBy).whereType<String>().toSet().toList();
    await FeedHelper.preloadNames(userIds);
    if (!mounted) return;
    setState(() { _allTransactions = txns; _expandedDay = null; });
  }

  List<TransactionWithItems> get _filtered {
    var list = _allTransactions;
    if (_filterWalletId != null) {
      list = list.where((t) => t.transaction.walletId == _filterWalletId).toList();
    }
    if (_filterCategoryId != null) {
      list = list.where((t) => t.transaction.categoryId == _filterCategoryId).toList();
    }
    if (_filterUserId != null) {
      list = list.where((t) => t.transaction.createdBy == _filterUserId).toList();
    }
    return list;
  }

  // ── Range navigation ──

  void _changeRange(int delta) {
    setState(() {
      switch (_timeRange) {
        case TimeRangeMode.day:
          _rangeAnchor = _rangeAnchor.add(Duration(days: delta));
        case TimeRangeMode.week:
          _rangeAnchor = _rangeAnchor.add(Duration(days: 7 * delta));
        case TimeRangeMode.month:
          _rangeAnchor = DateTime(_rangeAnchor.year, _rangeAnchor.month + delta);
      }
      _loading = true;
    });
    _loadRange().then((_) { if (mounted) setState(() => _loading = false); });
  }

  void _setTimeRange(TimeRangeMode mode) {
    if (mode == _timeRange) return;
    final now = DateTime.now();
    setState(() {
      _timeRange = mode;
      if (mode == TimeRangeMode.month) {
        _viewMode = ViewMode.list; // reset view mode when leaving month
      }
      switch (mode) {
        case TimeRangeMode.day:
          _rangeAnchor = DateTime(now.year, now.month, now.day);
          _viewMode = ViewMode.list;
        case TimeRangeMode.week:
          final weekday = now.weekday; // 1=Mon
          _rangeAnchor = DateTime(now.year, now.month, now.day - (weekday - 1));
          _viewMode = ViewMode.list;
        case TimeRangeMode.month:
          _rangeAnchor = DateTime(now.year, now.month);
      }
      _loading = true;
    });
    _loadRange().then((_) { if (mounted) setState(() => _loading = false); });
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
    return days.map((d) {
      final date = _timeRange == TimeRangeMode.month
          ? DateTime(_rangeAnchor.year, _rangeAnchor.month, d)
          : DateTime.fromMillisecondsSinceEpoch(map[d]!.first.transaction.date);
      return _DayGroup(day: d, date: DateTime(date.year, date.month, d), items: map[d]!);
    }).toList();
  }

  Map<int, int> _buildDailyExpenseMap() {
    final map = <int, int>{};
    for (var t in _filtered) {
      if (!t.transaction.type.isExpense) continue;
      final day = DateTime.fromMillisecondsSinceEpoch(t.transaction.date).day;
      map[day] = (map[day] ?? 0) + t.transaction.amount;
    }
    return map;
  }

  List<TransactionWithItems> _txnsForSelectedDay() {
    return _filtered.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
    }).toList();
  }

  Map<String, String> get _walletNameMap => sl.cache.walletNameMap;

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
          // Time range chips + view toggle
          _buildTimeRangeRow(),

          // Range picker
          _buildRangePicker(),

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

          // Content
          Expanded(
            child: _loading
                ? const ShimmerPlaceholder()
                : _error != null
                    ? Center(child: Text(_error!, style: AppTextStyles.error))
                    : txns.isEmpty
                        ? EmptyState(emoji: '📝', message: S.of(context, 'noTransactions'))
                        : RefreshIndicator(
                            onRefresh: _loadRange,
                            child: _viewMode == ViewMode.calendar
                                ? _buildCalendarView(locale)
                                : _buildListView(),
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
            onAdded: _loadRange,
          ),
        ],
      ),
    );
  }

  // ── Time Range Chips ──

  Widget _buildTimeRangeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _buildChip(S.of(context, 'viewDay'), TimeRangeMode.day),
          const SizedBox(width: AppSpacing.sm),
          _buildChip(S.of(context, 'viewWeek'), TimeRangeMode.week),
          const SizedBox(width: AppSpacing.sm),
          _buildChip(S.of(context, 'viewMonth'), TimeRangeMode.month),
          const Spacer(),
          if (_timeRange == TimeRangeMode.month) _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildChip(String label, TimeRangeMode mode) {
    final active = _timeRange == mode;
    return GestureDetector(
      onTap: () => _setTimeRange(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withAlpha(25) : null,
          border: Border.all(color: active ? AppColors.primary : AppColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: active ? FontWeight.w600 : null,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleIcon(Icons.view_list_rounded, ViewMode.list),
        const SizedBox(width: 4),
        _buildToggleIcon(Icons.calendar_month_rounded, ViewMode.calendar),
      ],
    );
  }

  Widget _buildToggleIcon(IconData icon, ViewMode mode) {
    final active = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Icon(
        icon,
        size: 20,
        color: active ? AppColors.primary : AppColors.textSecondary.withAlpha(120),
      ),
    );
  }

  // ── Range Picker ──

  Widget _buildRangePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: () => _changeRange(-1),
            visualDensity: VisualDensity.compact,
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Text(_rangeLabel, style: AppTextStyles.titleSmall),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () => _changeRange(1),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String get _rangeLabel {
    switch (_timeRange) {
      case TimeRangeMode.day:
        return DateFormatter.dayFull(_rangeAnchor);
      case TimeRangeMode.week:
        return DateFormatter.weekRange(_rangeAnchor);
      case TimeRangeMode.month:
        return DateFormatter.monthYearLong(_rangeAnchor);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeAnchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: _timeRange == TimeRangeMode.month ? DatePickerMode.year : DatePickerMode.day,
    );
    if (picked == null || !mounted) return;
    setState(() {
      switch (_timeRange) {
        case TimeRangeMode.day:
          _rangeAnchor = DateTime(picked.year, picked.month, picked.day);
        case TimeRangeMode.week:
          final weekday = picked.weekday;
          _rangeAnchor = DateTime(picked.year, picked.month, picked.day - (weekday - 1));
        case TimeRangeMode.month:
          _rangeAnchor = DateTime(picked.year, picked.month);
      }
      _loading = true;
    });
    _loadRange().then((_) { if (mounted) setState(() => _loading = false); });
  }

  // ── Summary ──

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

  // ── Filters ──

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (widget.walletId == null && _wallets.length > 1) ...[
            InlineSelector(
              icon: Icons.account_balance_wallet_outlined,
              label: _filterWalletId == null
                  ? S.of(context, 'allWallets')
                  : _wallets.where((w) => w.id == _filterWalletId).firstOrNull?.name ?? '',
              onTap: () async {
                final selected = await showSelectionSheet<String>(
                  context: context,
                  title: S.of(context, 'selectWallet'),
                  items: [
                    SelectionItem(value: '_all', label: S.of(context, 'allWallets')),
                    ..._wallets.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.account_balance_wallet_outlined)),
                  ],
                  selected: _filterWalletId ?? '_all',
                );
                if (selected != null) setState(() => _filterWalletId = selected == '_all' ? null : selected);
              },
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          InlineSelector(
            icon: _filterCategoryId != null
                ? getCategoryIcon(_categories.where((c) => c.id == _filterCategoryId).firstOrNull?.icon)
                : Icons.category_outlined,
            label: _filterCategoryId == null
                ? S.of(context, 'allCategories')
                : _categoryNameMap[_filterCategoryId] ?? '',
            color: _filterCategoryId != null
                ? (_categories.where((c) => c.id == _filterCategoryId).firstOrNull?.type == TransactionType.income
                    ? AppColors.income : AppColors.expense)
                : null,
            onTap: () async {
              final selected = await showSelectionSheet<String>(
                context: context,
                title: S.of(context, 'category'),
                items: [
                  SelectionItem(value: '_all', label: S.of(context, 'allCategories')),
                  ..._categories.map((c) => SelectionItem(
                    value: c.id!, label: c.name, icon: getCategoryIcon(c.icon),
                    color: c.type == TransactionType.income ? AppColors.income : AppColors.expense,
                  )),
                ],
                selected: _filterCategoryId ?? '_all',
              );
              if (selected != null) setState(() => _filterCategoryId = selected == '_all' ? null : selected);
            },
          ),
          if (_members.length > 1) ...[
            const SizedBox(width: AppSpacing.md),
            InlineSelector(
              icon: Icons.person_outline,
              label: _filterUserId == null
                  ? S.of(context, 'everyone')
                  : _members.where((m) => m['id'] == _filterUserId).firstOrNull?['name'] ?? '',
              onTap: () async {
                final selected = await showSelectionSheet<String>(
                  context: context,
                  title: S.of(context, 'member'),
                  items: [
                    SelectionItem(value: '_all', label: S.of(context, 'everyone'), icon: Icons.people_outline),
                    ..._members.map((m) => SelectionItem(value: m['id']!, label: m['name'] ?? '?', icon: Icons.person_outline)),
                  ],
                  selected: _filterUserId ?? '_all',
                );
                if (selected != null) setState(() => _filterUserId = selected == '_all' ? null : selected);
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── List View ──

  Widget _buildListView() {
    if (_timeRange == TimeRangeMode.day) return _buildFlatList();
    return _buildGroupedList();
  }

  Widget _buildFlatList() {
    final txns = _filtered;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: txns.length,
      itemBuilder: (context, index) => TransactionFeedItem(
        txn: txns[index],
        categoryName: _categoryNameMap[txns[index].transaction.categoryId] ?? S.of(context, 'other'),
        onChanged: _loadRange,
        timeFormatter: DateFormatter.time,
        walletNames: _walletNameMap,
      ),
    );
  }

  Widget _buildGroupedList() {
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
    final isExpanded = _expandedDay == group.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expandedDay = isExpanded ? null : group.day),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text('${group.day}', style: AppTextStyles.titleSmall),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(weekday, style: AppTextStyles.bodySmall),
                      Text(
                        '${group.items.length} ${S.of(context, 'transactionCount')}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${net >= 0 ? '+' : '-'}${AmountFormatter.formatCompactCurrency(net.abs(), locale)}',
                  style: AppTextStyles.caption.copyWith(
                    color: net >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...group.items.map((t) => TransactionFeedItem(
            txn: t,
            categoryName: _categoryNameMap[t.transaction.categoryId] ?? S.of(context, 'other'),
            onChanged: _loadRange,
            timeFormatter: DateFormatter.time,
            walletNames: _walletNameMap,
          )),
        const Divider(height: 1),
      ],
    );
  }

  // ── Calendar View ──

  Widget _buildCalendarView(String locale) {
    final now = DateTime.now();
    final todayDay = (_rangeAnchor.year == now.year && _rangeAnchor.month == now.month) ? now.day : null;
    final dailyExpense = _buildDailyExpenseMap();
    final selectedTxns = _txnsForSelectedDay();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        CalendarGrid(
          month: _rangeAnchor,
          dailyExpense: dailyExpense,
          selectedDay: _selectedDate.month == _rangeAnchor.month && _selectedDate.year == _rangeAnchor.year
              ? _selectedDate.day : null,
          todayDay: todayDay,
          onDayTap: (day) => setState(() {
            _selectedDate = DateTime(_rangeAnchor.year, _rangeAnchor.month, day);
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        // Detail header
        Center(
          child: Text(
            DateFormatter.dayFull(_selectedDate),
            style: AppTextStyles.bodySmall,
          ),
        ),
        const Divider(),
        // Detail list
        if (selectedTxns.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: EmptyState(emoji: '📝', message: S.of(context, 'noTransactions')),
          )
        else
          ...selectedTxns.map((t) => TransactionFeedItem(
            txn: t,
            categoryName: _categoryNameMap[t.transaction.categoryId] ?? S.of(context, 'other'),
            onChanged: _loadRange,
            timeFormatter: DateFormatter.time,
            walletNames: _walletNameMap,
          )),
      ],
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
