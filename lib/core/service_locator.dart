import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/features/settings/services/setting_service.dart';
import 'package:vintage_ledger/features/auth/services/auth_service.dart';

class ServiceLocator {
  ServiceLocator._();
  static final instance = ServiceLocator._();

  final walletService = WalletService();
  final transactionService = TransactionService();
  final categoryService = CategoryService();
  final settingService = SettingService();
  final authService = AuthService();
}

final sl = ServiceLocator.instance;
