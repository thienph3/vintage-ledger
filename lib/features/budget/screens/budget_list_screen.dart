import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/error_snackbar.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/widgets/budget_progress_tile.dart';
import 'package:vintage_ledger/features/budget/screens/budget_form_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  List<BudgetStatus> _statuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final statuses = await sl.budgetService.getBudgetStatuses();
      if (!mounted) return;
      setState(() { _statuses = statuses; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'budgets'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
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
                            final result = await context.pushScreen(BudgetFormScreen(budget: s.budget));
                            if (result == true) _load();
                          },
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await context.pushScreen(const BudgetFormScreen());
                        if (result == true) _load();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(S.of(context, 'setBudget')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
