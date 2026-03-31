import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/core/service_locator.dart';

import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_section.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';

import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  DashboardData? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final dashboard = await sl.transactionService.getDashboard(
        walletId: widget.wallet.id!,
      );
      setState(() {
        _dashboard = dashboard;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openForm() async {
    final result = await context.pushScreen(
      TransactionFormScreen(walletId: widget.wallet.id!),
    );
    if (result == true) await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.wallet.name,
      body: AsyncContent(
        loading: _loading,
        error: _error,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            children: [
              LedgerCard(
                child: Row(
                  children: [
                    Text(
                      "${S.of(context, 'balance')}:",
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AmountText(
                      amount: (_dashboard?.balance ?? 0).abs(),
                      type: (_dashboard?.balance ?? 0) >= 0 ? "income" : "expense",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              LedgerCard(child: ChartSection(
                transactions: _dashboard?.monthly ?? [],
                categoryMap: _dashboard?.categoryMap ?? {},
              )),
              const SizedBox(height: AppSpacing.md),

              LedgerCard(
                child: TransactionSection(
                  walletId: widget.wallet.id!,
                  transactions: _dashboard?.recent ?? [],
                  categoryMap: _dashboard?.categoryMap ?? {},
                  onDataChanged: loadData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
