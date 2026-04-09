import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/features/budget/models/budget.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/widgets/budget_progress_tile.dart';
import 'package:vintage_ledger/features/budget/screens/budget_form_screen.dart';
import 'package:vintage_ledger/features/budget/screens/budget_detail_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  List<BudgetStatus> _statuses = [];
  bool _loading = true;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final statuses = await sl.budgetService.getBudgetStatuses(anchor: _anchor);
      if (!mounted) return;
      setState(() { _statuses = statuses; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _goPrev() {
    // Use monthly as default for navigation
    final period = _statuses.firstOrNull?.budget.period ?? BudgetPeriod.monthly;
    setState(() {
      _anchor = sl.budgetService.previousPeriod(period, _anchor);
      _loading = true;
    });
    _load();
  }

  void _goNext() {
    final period = _statuses.firstOrNull?.budget.period ?? BudgetPeriod.monthly;
    final next = sl.budgetService.nextPeriod(period, _anchor);
    if (next.isAfter(DateTime.now().add(const Duration(days: 1)))) return;
    setState(() {
      _anchor = next;
      _loading = true;
    });
    _load();
  }

  String _periodLabel() {
    final period = _statuses.firstOrNull?.budget.period ?? BudgetPeriod.monthly;
    if (period == BudgetPeriod.weekly) {
      final start = _statuses.firstOrNull?.periodStart ?? _anchor;
      final end = _statuses.firstOrNull?.periodEnd ?? _anchor;
      return '${start.day}/${start.month} – ${end.day}/${end.month}';
    }
    return '${_anchor.month}/${_anchor.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'budgets'),
      fab: Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await context.pushScreen(const BudgetFormScreen());
            if (result == true) _load();
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: _loading
          ? const ShimmerPlaceholder()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildPeriodNav(),
                  const SizedBox(height: AppSpacing.md),
                  if (_statuses.isEmpty)
                    EmptyState(message: S.of(context, 'noBudgets')),
                  ..._statuses.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: LedgerCard(
                      child: Dismissible(
                        key: Key(s.budget.id!),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => showDeleteConfirmation(context, titleKey: 'delete', contentKey: 'deleteCategoryConfirm'),
                        onDismissed: (_) => sl.budgetService.deleteBudget(s.budget.id!).then((_) => _load()),
                        child: BudgetProgressTile(
                          status: s,
                          onTap: () async {
                            await context.pushScreen(BudgetDetailScreen(status: s));
                          },
                          onEdit: () async {
                            final result = await context.pushScreen(BudgetFormScreen(budget: s.budget));
                            if (result == true) _load();
                          },
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 72),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _goPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(_periodLabel(), style: AppTextStyles.titleSmall),
        IconButton(
          onPressed: _goNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
