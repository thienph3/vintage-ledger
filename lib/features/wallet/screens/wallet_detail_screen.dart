import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/core/service_locator.dart';

import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_section.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dashboard = await sl.transactionService.getDashboard(
        walletId: widget.wallet.id!,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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
              StreamBuilder<Wallet?>(
                stream: sl.walletService.watchWallets().map(
                  (wallets) => wallets.where((w) => w.id == widget.wallet.id).firstOrNull,
                ),
                initialData: widget.wallet,
                builder: (context, snap) {
                  final balance = snap.data?.balance ?? widget.wallet.balance;
                  return LedgerCard(
                    child: Row(
                      children: [
                        Text("${S.of(context, 'balance')}:", style: AppTextStyles.body),
                        const SizedBox(width: AppSpacing.md),
                        AmountText.fromBalance(balance: balance),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (_dashboard != null)
                LedgerCard(child: ChartSection(dashboard: _dashboard!)),
              const SizedBox(height: AppSpacing.md),
              LedgerCard(
                child: TransactionSection(
                  walletId: widget.wallet.id!,
                  transactions: _dashboard?.recent ?? [],
                  categoryMap: _dashboard?.categoryMap ?? {},
                  onDataChanged: _loadData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
