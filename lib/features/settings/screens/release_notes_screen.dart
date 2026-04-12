import 'package:flutter/material.dart';

import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class _ReleaseNote {
  final String version;
  final String date;
  final List<String> changes;

  const _ReleaseNote({required this.version, required this.date, required this.changes});
}

const _releases = [
  _ReleaseNote(
    version: '0.1.0',
    date: '12/04/2026',
    changes: [
      '🔗 Nợ liên kết: tạo khoản nợ chung giữa 2 người dùng trong app, cả hai đều thấy và theo dõi được',
      'Tìm người dùng qua email trên form tạo nợ (toggle giữa nhập tên / tìm email)',
      'Đồng bộ thanh toán: khi một bên trả nợ, bên kia tự động cập nhật paidAmount + status',
      'Hủy/xóa nợ liên kết: bên kia được gỡ liên kết (chuyển thành nợ tự do) + nhận thông báo',
      'Push notification cho tạo nợ, thanh toán, hoàn tất, hủy liên kết',
      'Badge "Đang liên kết" / "Đã gỡ liên kết" trên màn hình chi tiết nợ',
      'Tương thích ngược: nợ tự do (free-text) hiện có không bị ảnh hưởng',
    ],
  ),
  _ReleaseNote(
    version: '0.0.11',
    date: '12/04/2026',
    changes: [
      'Ngân sách theo kỳ (tuần/tháng) + xem chi tiết giao dịch trong kỳ',
      'Ví tiết kiệm & ví nợ: FAB mở rộng (thêm mục tiêu/nợ + nạp/trả)',
      'Liên kết ví nợ ↔ khoản nợ, hiển thị tổng nợ/đã trả/còn nợ từ data thực',
      'Xóa nạp mục tiêu nhầm (swipe trong goal detail)',
      'Quản lý từ khóa đã học: xem, xóa từng từ hoặc xóa tất cả',
      'Đổi tên hiển thị theo từng family (nickname per-account)',
      'Hiện account đang dùng trong Settings (personal/family)',
      'Nhắc thanh toán: đổi wording cho rõ nghĩa (không phải tự động tạo giao dịch)',
      'Quick-add: giữ casing gốc khi ghi chú, fix parse "1 trái dừa" → 1đ thay vì 1tr',
      'Fix FAB scrim che toàn màn hình + bỏ gạch vàng dưới text overlay',
      'Fix goal contribution screen rerender liên tục / mất focus keyboard',
      'Tất cả amount field dùng chung AmountInputField (format + chips)',
      'Debt & Goal hiển thị cho toàn bộ family (bỏ filter created_by)',
      'Chuyển tiền: mặc định toWallet + chỉ hiện ví cùng account',
      'Trả nợ: validate số dư ví trước khi trả',
    ],
  ),
];

class ReleaseNotesScreen extends StatelessWidget {
  const ReleaseNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Có gì mới',
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _releases.length,
        itemBuilder: (context, index) => _buildRelease(_releases[index]),
      ),
    );
  }

  Widget _buildRelease(_ReleaseNote release) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                ),
                child: Text(
                  'v${release.version}',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(release.date, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...release.changes.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.check_circle_outline, size: 14, color: AppColors.income),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(c, style: AppTextStyles.body)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
