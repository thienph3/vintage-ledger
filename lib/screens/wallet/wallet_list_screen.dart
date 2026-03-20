import 'package:flutter/material.dart';

import '../../l10n/s.dart';
import '../../models/wallet.dart';
import '../../services/wallet_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ledger_header.dart';
import '../../widgets/swipe_list_item.dart';
import '../../widgets/amount_text.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

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
    setState(() {
      wallets = list;
    });
  }

  Future<void> deleteWallet(int id) async {
    await walletService.deleteWallet(id);
    loadWallets();
  }

  Future<bool?> confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context, 'deleteWallet')),
        content: Text(S.of(context, 'deleteWalletConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.of(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(S.of(context, 'delete'))),
        ],
      ),
    );
  }

  Future<void> openForm({Wallet? wallet}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WalletFormScreen(wallet: wallet)),
    );
    if (result == true) {
      loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "",

      body: RefreshIndicator(
        onRefresh: loadWallets,
        child: wallets.isEmpty
            ? EmptyState(message: S.of(context, 'noWalletsFound'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  LedgerHeader(
                    title: S.of(context, 'myWalletsTitle'),
                    showBackButton: true,
                  ),
                  ...wallets.map((w) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SwipeListItem(
                        itemKey: Key(w.id.toString()),
                        onTap: () => openForm(wallet: w),
                        confirmDelete: confirmDelete,
                        onDelete: () => deleteWallet(w.id!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 28, color: AppColors.inkBlue),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  w.name,
                                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                                ),
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
                      label: Text(
                        S.of(context, 'addWallet'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        backgroundColor: AppColors.inkBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
