import 'package:vintage_ledger/features/wallet/models/wallet.dart';

class AccountWallets {
  final String accountId;
  final String accountName;
  final List<Wallet> wallets;

  const AccountWallets({
    required this.accountId,
    required this.accountName,
    required this.wallets,
  });
}
