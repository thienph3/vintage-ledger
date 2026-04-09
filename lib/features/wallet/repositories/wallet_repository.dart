import 'package:vintage_ledger/core/firestore/firestore_repository.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

class WalletRepository extends FirestoreRepository<Wallet> {
  @override
  String get collectionName => 'wallets';

  @override
  Wallet fromFirestore(String id, Map<String, dynamic> data) => Wallet(
    id: id,
    name: data['name'] ?? '',
    balance: data['balance'] ?? 0,
    initialBalance: data['initial_balance'] ?? 0,
    currency: data['currency'] ?? 'VND',
    type: WalletType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => WalletType.normal,
    ),
  );

  @override
  Map<String, dynamic> toFirestore(Wallet item) => {
    'name': item.name,
    'balance': item.balance,
    'initial_balance': item.initialBalance,
    'currency': item.currency,
    'type': item.type.name,
  };

  Stream<List<Wallet>> watchWallets() => watchAll();
}
