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
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

import 'wallet_form_screen.dart';
import 'wallet_detail_screen.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  String? _defaultWalletId;

  @override
  void initState() {
    super.initState();
    _loadDefault();
  }

  Future<void> _loadDefault() async {
    final id = await sl.settingService.getLastWalletId();
    if (mounted) setState(() => _defaultWalletId = id);
  }

  bool _isDefault(Wallet w, List<Wallet> wallets) {
    if (_defaultWalletId != null) return w.id == _defaultWalletId;
    return w.id == wallets.firstOrNull?.id;
  }

  Future<void> _setDefault(Wallet w) async {
    await sl.settingService.setLastWalletId(w.id!);
    setState(() => _defaultWalletId = w.id);
    if (!mounted) return;
    showAppSnackBar(context, '${w.name} → ${S.of(context, 'defaultWallet')}');
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(S.of(context, 'longPressToSetDefault'), style: AppTextStyles.caption),
                    ),
                    ...wallets.map((w) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SwipeListItem(
                        itemKey: Key(w.id!),
                        onTap: () => context.pushScreen(WalletDetailScreen(wallet: w)),
                        confirmDelete: () => showDeleteConfirmation(context, titleKey: 'deleteWallet', contentKey: 'deleteWalletConfirm'),
                        onDelete: () async {
                          try {
                            await sl.walletService.deleteWallet(w.id!);
                            _loadDefault();
                          } catch (e) {
                            if (!context.mounted) return;
                            showAppSnackBar(context, e.toString(), backgroundColor: const Color(0xFF8B1E1E));
                          }
                        },
                        child: GestureDetector(
                          onLongPress: () => _setDefault(w),
                          child: LedgerListTile(
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, size: 28, color: AppColors.inkBlue),
                                    if (_isDefault(w, wallets))
                                      const Positioned(
                                        right: -2, bottom: -2,
                                        child: Icon(Icons.star, size: 14, color: Color(0xFFE6A817)),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Text(w.name, style: AppTextStyles.bodyBold)),
                                AmountText.fromBalance(balance: w.balance, currency: w.currency),
                              ],
                            ),
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
