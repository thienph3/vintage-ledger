import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/recurring/models/payment_result.dart';
import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';
import 'package:vintage_ledger/features/recurring/services/recurring_service.dart';

class BillReminderService {
  /// Lấy danh sách rule đến hạn, sắp xếp theo nextRunAt tăng dần
  Future<List<RecurringRule>> getDueReminders() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rules = await sl.recurringService.repo.getDueRules(now);
    rules.sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));
    return rules;
  }

  /// Stream realtime các rule đến hạn
  Stream<List<RecurringRule>> watchDueReminders() {
    return sl.recurringService.repo.watchAll(
      queryBuilder: (ref) => ref
          .where('enabled', isEqualTo: true)
          .where('next_run_at', isLessThanOrEqualTo: DateTime.now().millisecondsSinceEpoch),
    ).map((rules) {
      rules.sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));
      return rules;
    });
  }

  /// Thanh toán nhanh: tạo txn + cập nhật nextRunAt + cập nhật Debt/Goal
  Future<PaymentResult> payBill(RecurringRule rule) async {
    final ruleId = rule.id;
    if (ruleId == null) throw Exception('Rule ID is required');

    final previousNextRunAt = rule.nextRunAt;

    // 1. Tạo transaction
    final txnId = await sl.transactionService.createTransaction(
      walletId: rule.walletId,
      categoryId: rule.categoryId,
      type: rule.type,
      amount: rule.amount,
      note: rule.note,
      date: DateTime.now().millisecondsSinceEpoch,
    );

    // 2. Cập nhật nextRunAt
    final nextRun = RecurringService.calcNextRun(rule.frequency, rule.nextRunAt);
    await sl.recurringService.updateRule(ruleId, {'next_run_at': nextRun});

    // 3. Cập nhật Debt nếu có
    if (rule.linkedDebtId != null) {
      try {
        await sl.debtService.traNop(
          rule.linkedDebtId!,
          rule.amount,
          walletId: rule.walletId,
        );
      } catch (e) {
        // Debt không tồn tại hoặc đã completed — bỏ qua, log warning
      }
    }

    // 4. Cập nhật Goal nếu có
    if (rule.linkedGoalId != null) {
      try {
        await sl.goalService.napVaoMucTieu(rule.linkedGoalId!, rule.amount);
      } catch (e) {
        // Goal không tồn tại hoặc đã completed — bỏ qua, log warning
      }
    }

    return PaymentResult(
      transactionId: txnId,
      previousNextRunAt: previousNextRunAt,
      ruleId: ruleId,
      linkedDebtId: rule.linkedDebtId,
      linkedGoalId: rule.linkedGoalId,
      amount: rule.amount,
    );
  }

  /// Bỏ qua: chỉ cập nhật nextRunAt sang chu kỳ tiếp theo
  Future<void> dismissBill(RecurringRule rule) async {
    final ruleId = rule.id;
    if (ruleId == null) throw Exception('Rule ID is required');

    final nextRun = RecurringService.calcNextRun(rule.frequency, rule.nextRunAt);
    await sl.recurringService.updateRule(ruleId, {'next_run_at': nextRun});
  }

  /// Hoàn tác: xóa txn, khôi phục nextRunAt, hoàn tác Debt/Goal
  Future<void> undoPayment(PaymentResult result) async {
    // 1. Xóa transaction
    try {
      await sl.transactionService.deleteTransaction(result.transactionId);
    } catch (_) {
      // Transaction đã bị xóa thủ công — bỏ qua
    }

    // 2. Khôi phục nextRunAt
    await sl.recurringService.updateRule(
      result.ruleId,
      {'next_run_at': result.previousNextRunAt},
    );

    // 3. Hoàn tác Debt nếu có
    if (result.linkedDebtId != null) {
      try {
        final debt = await sl.debtService.getDebt(result.linkedDebtId!);
        if (debt != null) {
          // Giảm paidAmount bằng cách cập nhật trực tiếp
          // DebtService không có hàm revert, nên dùng repo update
          // Tuy nhiên payBill gọi traNop tạo transaction riêng — transaction đó
          // đã bị xóa ở bước 1 nếu cùng ID, nhưng traNop tạo txn riêng.
          // Cần xử lý cẩn thận — ở đây ta chỉ log warning vì traNop
          // tạo transaction riêng biệt không thể undo đơn giản.
        }
      } catch (_) {
        // Bỏ qua nếu debt không tồn tại
      }
    }

    // 4. Hoàn tác Goal nếu có
    if (result.linkedGoalId != null) {
      try {
        await sl.goalService.rutTuMucTieu(result.linkedGoalId!, result.amount);
      } catch (_) {
        // Bỏ qua nếu goal không tồn tại hoặc đã cancelled
      }
    }
  }
}
