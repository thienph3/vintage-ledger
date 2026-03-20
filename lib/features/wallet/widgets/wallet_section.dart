import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_list_screen.dart';

class WalletSection extends StatelessWidget {
  final List<Wallet> wallets;
  final VoidCallback onAddWallet;
  final Function(Wallet) onTapWallet;
  final Function(Wallet) onDeleteWallet;

  const WalletSection({
    super.key,
    required this.wallets,
    required this.onAddWallet,
    required this.onTapWallet,
    required this.onDeleteWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context, 'myWallets'), style: AppTextStyles.title),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletListScreen()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context, 'viewAll'),
                    style: const TextStyle(
                      color: AppColors.inkBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.inkBlack,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: Text(
                S.of(context, 'wallet'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(S.of(context, 'balance'), textAlign: TextAlign.right),
            ),
          ],
        ),
        Divider(color: AppColors.divider, thickness: 1.2),

        if (wallets.isEmpty) Text(S.of(context, 'noWallets')),
        if (wallets.isNotEmpty)
          ...wallets.map((wallet) {
            return InkWell(
              onTap: () => onTapWallet(wallet),
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(S.of(context, 'deleteWallet')),
                    content: Text(S.of(context, 'deleteWalletConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.of(context, 'cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(S.of(context, 'delete')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  onDeleteWallet(wallet);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(wallet.name, style: AppTextStyles.body),
                    ),
                    AmountText(
                      amount: wallet.balance.abs(),
                      type: wallet.balance >= 0 ? "income" : "expense",
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddWallet,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              S.of(context, 'addWallet'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: AppColors.inkBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
