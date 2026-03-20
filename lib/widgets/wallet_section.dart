import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'amount_text.dart';
import '../screens/wallet/wallet_list_screen.dart';

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
        /// Title + Xem tất cả
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Ví của tôi", style: AppTextStyles.title),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WalletListScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Xem tất cả",
                    style: TextStyle(
                      color: AppColors.inkBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.inkBlack),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        /// Header cột
        const Row(
          children: [
            Expanded(
              child: Text(
                "Ví",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                "Số dư",
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        Divider(color: AppColors.divider, thickness: 1.2),

        /// Danh sách ví
        if (wallets.isEmpty)
          const Text("Chưa có ví nào"),
        if (wallets.isNotEmpty)
          ...wallets.map((wallet) {
            return InkWell(
              onTap: () => onTapWallet(wallet),
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Xóa ví"),
                    content: const Text("Bạn có chắc muốn xóa ví này?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Hủy"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Xóa"),
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

        /// Nút thêm ví full-width ở dưới
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddWallet,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              "Thêm ví",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
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