import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';

import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/ledger_header.dart';

enum TransactionFilter { day, week, month }

class TransactionListScreen extends StatefulWidget {
  final int? walletId;

  const TransactionListScreen({super.key, this.walletId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService transactionService = TransactionService();
  final CategoryService categoryService = CategoryService();

  late Future<List<TransactionWithItems>> _futureTransactions;
  late Future<Map<int, String>> _futureCategoryMap;
  TransactionFilter _currentFilter = TransactionFilter.week;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureTransactions = widget.walletId != null
        ? transactionService.getByWalletWithItems(widget.walletId!)
        : transactionService.getTransactionsWithItems();

    _futureCategoryMap = categoryService.getCategories().then((categories) {
      final map = <int, String>{};
      for (var cat in categories) {
        if (cat.id != null) map[cat.id!] = cat.name;
      }
      return map;
    });
  }

  Map<String, List<TransactionWithItems>> _groupByDate(
    List<TransactionWithItems> transactions,
  ) {
    final map = <String, List<TransactionWithItems>>{};
    for (var t in transactions) {
      final date = DateFormatter.date(t.transaction.date);
      map.putIfAbsent(date, () => []).add(t);
    }
    return map;
  }

  List<TransactionWithItems> _applyFilter(
    List<TransactionWithItems> transactions,
  ) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case TransactionFilter.day:
        return transactions.where((t) {
          final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        }).toList();
      case TransactionFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return transactions.where((t) {
          final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
          return !dt.isBefore(weekStart) && !dt.isAfter(weekEnd);
        }).toList();
      case TransactionFilter.month:
        return transactions.where((t) {
          final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
          return dt.year == now.year && dt.month == now.month;
        }).toList();
    }
  }

  Widget _buildFilterButtons() {
    final labels = {
      TransactionFilter.day: S.of(context, 'today'),
      TransactionFilter.week: S.of(context, 'thisWeek'),
      TransactionFilter.month: S.of(context, 'thisMonth'),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TransactionFilter.values.map((filter) {
        final isSelected = filter == _currentFilter;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentFilter = filter;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? AppColors.inkBlue : AppColors.paper,
              foregroundColor: isSelected ? Colors.white : AppColors.inkBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.divider),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              labels[filter]!,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.inkBlack,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "",
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([_futureTransactions, _futureCategoryMap]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('${S.of(context, 'error')}: ${snapshot.error}'),
              );
            }

            var transactions = snapshot.data![0] as List<TransactionWithItems>;
            final categoryMap = snapshot.data![1] as Map<int, String>;

            transactions = _applyFilter(transactions);
            final grouped = _groupByDate(transactions);

            if (transactions.isEmpty) {
              return Center(child: Text(S.of(context, 'noTransactions')));
            }

            return ListView(
              children: [
                LedgerHeader(
                  title: S.of(context, 'transactionLedger'),
                  showBackButton: true,
                ),
                _buildFilterButtons(),
                const SizedBox(height: AppSpacing.md),

                ...grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          entry.key,
                          style: AppTextStyles.title.copyWith(fontSize: 16),
                        ),
                      ),
                      ...entry.value.map((t) {
                        return LedgerCard(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  DateFormatter.time(t.transaction.date),
                                  style: AppTextStyles.body,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  categoryMap[t.transaction.categoryId] ??
                                      S.of(context, 'other'),
                                  style: AppTextStyles.body,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: AmountText(
                                  amount: t.transaction.amount,
                                  type: t.transaction.type,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
