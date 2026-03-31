import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/ledger_list_tile.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

import 'wallet_form_screen.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  final WalletService walletService = WalletService();
  List<Wallet> wallets = [];

  @override
  void initState() {
    super.initState();
    loadWallets();
  }

  Future<void> loadWallets() async {
    final list = await walletService.getWallets();
    setState(() => wallets = list);
  }

  Future<void> deleteWallet(int id) async {
    await walletService.deleteWallet(id);
    loadWallets();
  }

  Future<void> openForm({Wallet? wallet}) async {
    final result = await context.pushScreen(WalletFormScreen(wallet: wallet));
    if (result == true) loadWallets();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'myWalletsTitle'),
      body: RefreshIndicator(
        onRefresh: loadWallets,
        child: wallets.isEmpty
            ? EmptyState(message: S.of(context, 'noWalletsFound'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...wallets.map((w) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SwipeListItem(
                        itemKey: Key(w.id.toString()),
                        onTap: () => openForm(wallet: w),
                        confirmDelete: () => showDeleteConfirmation(
                          context,
                          titleKey: 'deleteWallet',
                          contentKey: 'deleteWalletConfirm',
                        ),
                        onDelete: () => deleteWallet(w.id!),
                        child: LedgerListTile(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 28,
                                color: AppColors.inkBlue,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(w.name, style: AppTextStyles.bodyBold),
                              ),
                              AmountText(
                                amount: w.balance.abs(),
                                type: w.balance >= 0 ? "income" : "expense",
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => openForm(),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(S.of(context, 'addWallet')),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
