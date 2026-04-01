import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/ledger_list_tile.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/error_snackbar.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

import 'wallet_form_screen.dart';

class WalletListScreen extends StatelessWidget {
  const WalletListScreen({super.key});

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDeleteConfirmation(
      context,
      titleKey: 'deleteWallet',
      contentKey: 'deleteWalletConfirm',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'myWalletsTitle'),
      body: StreamBuilder<List<Wallet>>(
        stream: sl.walletService.watchWallets(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final wallets = snap.data ?? [];

          return wallets.isEmpty
              ? EmptyState(message: S.of(context, 'noWalletsFound'))
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    ...wallets.map((w) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SwipeListItem(
                        itemKey: Key(w.id!),
                        onTap: () => context.pushScreen(WalletFormScreen(wallet: w)),
                        confirmDelete: () => _confirmDelete(context),
                        onDelete: () async {
                          try {
                            await sl.walletService.deleteWallet(w.id!);
                          } catch (e) {
                            if (!context.mounted) return;
                            showErrorSnackBar(context, e);
                          }
                        },
                        child: LedgerListTile(
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 28, color: AppColors.inkBlue),
                              const SizedBox(width: 16),
                              Expanded(child: Text(w.name, style: AppTextStyles.bodyBold)),
                              AmountText.fromBalance(balance: w.balance, currency: w.currency),
                            ],
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.pushScreen(const WalletFormScreen()),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(S.of(context, 'addWallet')),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
