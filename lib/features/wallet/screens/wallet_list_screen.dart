import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/common/mixins/crud_list_mixin.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/ledger_list_tile.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'wallet_form_screen.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen>
    with CrudListMixin<Wallet> {
  @override
  String get deleteTitle => 'deleteWallet';
  @override
  String get deleteContent => 'deleteWalletConfirm';

  @override
  Future<List<Wallet>> fetchItems() => sl.walletService.getWallets();
  @override
  Future<void> removeItem(Wallet item) => sl.walletService.deleteWallet(item.id!);
  @override
  int itemId(Wallet item) => item.id!;
  @override
  Widget formScreen({Wallet? item}) => WalletFormScreen(wallet: item);

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'myWalletsTitle'),
      body: RefreshIndicator(
        onRefresh: loadItems,
        child: items.isEmpty
            ? EmptyState(message: S.of(context, 'noWalletsFound'))
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ...items.map((w) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SwipeListItem(
                      itemKey: Key(w.id.toString()),
                      onTap: () => openForm(item: w),
                      confirmDelete: confirmDelete,
                      onDelete: () => deleteItem(w),
                      child: LedgerListTile(
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                size: 28, color: AppColors.inkBlue),
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
                  )),
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
