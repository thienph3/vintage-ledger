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
  );

  @override
  Map<String, dynamic> toFirestore(Wallet item) => {
    'name': item.name,
    'balance': item.balance,
  };

  Stream<List<Wallet>> watchWallets() => watchAll();
}
