import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/firestore/firestore_repository.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';

class TransactionRepository extends FirestoreRepository<TransactionWithItems> {
  @override
  String get collectionName => 'transactions';

  @override
  TransactionWithItems fromFirestore(String id, Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((i) => TransactionItemModel.fromMap(i as Map<String, dynamic>))
        .toList();

    return TransactionWithItems(
      transaction: TransactionModel(
        id: id,
        walletId: data['wallet_id'] ?? '',
        categoryId: data['category_id'] ?? '',
        type: TransactionType.fromString(data['type'] ?? 'expense'),
        amount: data['amount'] ?? 0,
        note: data['note'],
        date: data['date'] ?? 0,
        createdBy: data['created_by'],
      ),
      items: items,
    );
  }

  @override
  Map<String, dynamic> toFirestore(TransactionWithItems item) {
    final t = item.transaction;
    return {
      'wallet_id': t.walletId,
      'category_id': t.categoryId,
      'type': t.type.value,
      'amount': t.amount,
      'note': t.note,
      'date': t.date,
      'created_by': t.createdBy,
      'items': item.items.map((i) => i.toMap()).toList(),
    };
  }

  // ── Streams ──

  Stream<List<TransactionWithItems>> watchRecent(int limit, {String? walletId}) {
    return watchAll(queryBuilder: (ref) {
      Query<Map<String, dynamic>> q = ref.orderBy('date', descending: true).limit(limit);
      if (walletId != null) q = ref.where('wallet_id', isEqualTo: walletId).orderBy('date', descending: true).limit(limit);
      return q;
    });
  }

  Stream<List<TransactionWithItems>> watchByDateRange(int startDate, int endDate, {String? walletId}) {
    return watchAll(queryBuilder: (ref) {
      Query<Map<String, dynamic>> q = ref
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true);
      if (walletId != null) {
        q = ref
            .where('wallet_id', isEqualTo: walletId)
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .orderBy('date', descending: true);
      }
      return q;
    });
  }

  // ── One-shot reads ──

  Future<List<TransactionWithItems>> getRecent(int limit, {String? walletId}) {
    return getAll(queryBuilder: (ref) {
      Query<Map<String, dynamic>> q = ref.orderBy('date', descending: true).limit(limit);
      if (walletId != null) q = ref.where('wallet_id', isEqualTo: walletId).orderBy('date', descending: true).limit(limit);
      return q;
    });
  }

  Future<List<TransactionWithItems>> getByDateRange(int startDate, int endDate, {String? walletId}) {
    return getAll(queryBuilder: (ref) {
      Query<Map<String, dynamic>> q = ref
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true);
      if (walletId != null) {
        q = ref
            .where('wallet_id', isEqualTo: walletId)
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .orderBy('date', descending: true);
      }
      return q;
    });
  }

  // ── Write with balance update ──

  Future<String> addTransaction(TransactionWithItems item) async {
    return await add(item);
  }

  Future<void> updateTransaction(String id, TransactionWithItems item) async {
    final data = toFirestore(item);
    data['updated_at'] = FieldValue.serverTimestamp();
    await update(id, data);
  }
}
