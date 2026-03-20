import 'package:flutter/material.dart';

import '../screens/category/category_list_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/amount_text.dart';
import '../utils/date_formatter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../screens/transaction/transaction_list_screen.dart';

import '../../services/transaction_service.dart';
import '../../models/category.dart';

class TransactionSection extends StatelessWidget {
  final int? walletId;
  final List<TransactionWithItems> transactions;
  final Map<int, Category> categoryMap; // Map categoryId -> Category

  final Future<void> Function() onAddTransaction;
  final Future<void> Function(TransactionWithItems transaction) onTapTransaction;
  final Future<void> Function(TransactionWithItems transaction) onDeleteTransaction;

  const TransactionSection({
    super.key,
    this.walletId,
    required this.transactions,
    required this.categoryMap,
    required this.onAddTransaction,
    required this.onTapTransaction,
    required this.onDeleteTransaction,
  });

  static Map<int, IconData> iconMap = {
    0: Icons.fastfood,
    1: Icons.directions_car,
    2: Icons.shopping_cart,
    3: Icons.home,
    4: Icons.sports_soccer,
    5: Icons.movie,
    6: Icons.local_cafe,
    7: Icons.health_and_safety,
    8: Icons.phone_iphone,
    9: Icons.school,
    10: Icons.pets,
    11: Icons.flight,
    12: Icons.music_note,
    13: Icons.local_hospital,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Title + Xem tất cả
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Thu chi gần đây", style: AppTextStyles.title),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionListScreen(walletId: walletId),
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
        Row(
          children: [
            SizedBox(width: 120, child: Text("Ngày", style: AppTextStyles.body)),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryListScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      "Danh mục",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlack,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_outward, size: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              child: Text(
                "Số tiền",
                textAlign: TextAlign.right,
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
        Divider(color: AppColors.divider, thickness: 1.2),

        /// Nội dung giao dịch
        if (transactions.isEmpty)
          const EmptyState(message: "Không có thu chi nào"),
        if (transactions.isNotEmpty)
          ...transactions.map((transaction) {
            final category = categoryMap[transaction.transaction.categoryId];
            return InkWell(
              onTap: () async => await onTapTransaction(transaction),
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Xóa thu chi"),
                    content: const Text("Bạn có chắc muốn xóa thu chi này?"),
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
                  await onDeleteTransaction(transaction);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        DateFormatter.short(transaction.transaction.date),
                        style: AppTextStyles.body,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (category?.icon != null) ...[
                            Icon(
                            // Dùng map để lấy IconData constant, nếu index hợp lệ
                            (category?.icon != null && iconMap.containsKey(category!.icon))
                                ? iconMap[category.icon]!
                                : Icons.category,
                            size: 20,
                            color: AppColors.inkBlue,
                          ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            category?.name ?? "Khác",
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      child: AmountText(
                        amount: transaction.transaction.amount,
                        type: transaction.transaction.type,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        /// Nút Thêm ở dưới
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              "Thêm thu chi",
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