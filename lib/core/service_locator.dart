import 'package:vintage_ledger/core/app_state.dart';
import 'package:vintage_ledger/core/app_cache.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/features/settings/services/setting_service.dart';
import 'package:vintage_ledger/features/auth/services/auth_service.dart';
import 'package:vintage_ledger/features/account/services/account_service.dart';
import 'package:vintage_ledger/features/budget/services/budget_service.dart';
import 'package:vintage_ledger/features/notification/services/notification_service.dart';
import 'package:vintage_ledger/features/recurring/services/recurring_service.dart';
import 'package:vintage_ledger/features/reminder/reminder_service.dart';
import 'package:vintage_ledger/features/transaction/services/reaction_service.dart';
import 'package:vintage_ledger/features/wallet/services/goal_service.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';

class ServiceLocator {
  ServiceLocator._();
  static final instance = ServiceLocator._();

  final appState = AppState();
  final cache = AppCache();
  final walletService = WalletService();
  final transactionService = TransactionService();
  final categoryService = CategoryService();
  final settingService = SettingService();
  final authService = AuthService();
  final accountService = AccountService();
  final budgetService = BudgetService();
  final notificationService = NotificationService();
  final recurringService = RecurringService();
  final reminderService = ReminderService();
  final reactionService = ReactionService();
  final goalService = GoalService();
  final debtService = DebtService();
}

final sl = ServiceLocator.instance;
