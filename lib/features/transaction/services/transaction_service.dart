import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
export 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
export 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';

class TransactionService {
  final TransactionRepository _repo = TransactionRepository();

  // ── Streams ──

  Stream<List<TransactionWithItems>> watchRecent(int limit, {String? walletId}) =>
      _repo.watchRecent(limit, walletId: walletId);

  Stream<List<TransactionWithItems>> watchByDateRange(int startDate, int endDate, {String? walletId}) =>
      _repo.watchByDateRange(startDate, endDate, walletId: walletId);

  // ── One-shot reads ──

  Future<DashboardData> getDashboard({String? walletId}) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // print('[getDashboard] Loading dashboard for ${monthStart.toString().substring(0, 10)} to ${monthEnd.toString().substring(0, 10)}');

    final recent = await _repo.getRecent(5, walletId: walletId);
    final monthly = await _repo.getByDateRange(
      monthStart.millisecondsSinceEpoch,
      monthEnd.millisecondsSinceEpoch,
      walletId: walletId,
    );
    
    // print('[getDashboard] Found ${recent.length} recent, ${monthly.length} monthly transactions');
    
    final categories = await sl.categoryService.getCategories();
    final categoryMap = {for (var c in categories) if (c.id != null) c.id!: c};

    int balance;
    if (walletId != null) {
      final wallet = await sl.walletService.getWallet(walletId);
      balance = wallet?.balance ?? 0;
    } else {
      final wallets = await sl.walletService.getWallets();
      balance = wallets.fold<int>(0, (s, w) => s + w.balance);
    }

    return DashboardData(
      recent: recent, monthly: monthly, categoryMap: categoryMap, balance: balance,
    );
  }

  // ── Atomic Create (#1) ──

  Future<String> createTransaction({
    required String walletId,
    required String categoryId,
    required TransactionType type,
    required int amount,
    String? note,
    required int date,
    List<TransactionItemModel> items = const [],
  }) async {
    if (amount <= 0) throw Exception("Amount must be greater than 0");

    final firestore = _repo.firestore;
    final walletRef = sl.walletService.repo.collection.doc(walletId);
    final txnData = _repo.toFirestore(TransactionWithItems(
      transaction: TransactionModel(
        walletId: walletId, categoryId: categoryId, type: type,
        amount: amount, note: note, date: date,
        createdBy: sl.appState.currentUserId,
      ),
      items: items,
    ));
    txnData['created_at'] = FieldValue.serverTimestamp();
    txnData['updated_at'] = FieldValue.serverTimestamp();

    final delta = type.isIncome ? amount : -amount;

    final newDocRef = _repo.collection.doc();

    await firestore.runTransaction((txn) async {
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception("Wallet not found");
      final currentBalance = walletSnap.data()?['balance'] as int? ?? 0;

      txn.set(newDocRef, txnData);
      txn.update(walletRef, {'balance': currentBalance + delta});
    });

    _logActivity(type.value, amount, note);

    // Notify family members
    sl.notificationService.notifyTransaction(
      accountId: sl.appState.currentAccountId, amount: amount, type: type.value,
      transactionId: newDocRef.id,
    );

    return newDocRef.id;
  }

  // ── Atomic Update (#2) ──

  Future<void> updateTransaction(TransactionWithItems updated) async {
    final id = updated.transaction.id;
    if (id == null) throw Exception("Transaction ID required");

    final firestore = _repo.firestore;
    final txnRef = _repo.collection.doc(id);

    final newData = _repo.toFirestore(updated);
    newData['updated_at'] = FieldValue.serverTimestamp();

    await firestore.runTransaction((txn) async {
      final oldSnap = await txn.get(txnRef);
      if (!oldSnap.exists) throw Exception("Transaction not found");
      final oldData = oldSnap.data()!;
      final oldType = TransactionType.fromString(oldData['type'] ?? 'expense');
      final oldAmount = oldData['amount'] as int? ?? 0;
      final oldWalletId = oldData['wallet_id'] as String? ?? '';
      final newWalletId = updated.transaction.walletId;
      final sameWallet = oldWalletId == newWalletId;

      // Read ALL wallets first (before any writes)
      final walletRef = sl.walletService.repo.collection.doc(newWalletId);
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception("Wallet not found");

      DocumentSnapshot<Map<String, dynamic>>? oldWalletSnap;
      DocumentReference<Map<String, dynamic>>? oldWalletRef;
      if (!sameWallet && oldWalletId.isNotEmpty) {
        oldWalletRef = sl.walletService.repo.collection.doc(oldWalletId);
        oldWalletSnap = await txn.get(oldWalletRef);
      }

      // Now do all writes
      if (sameWallet) {
        var balance = walletSnap.data()?['balance'] as int? ?? 0;
        balance += oldType.isIncome ? -oldAmount : oldAmount;
        balance += updated.transaction.type.isIncome ? updated.transaction.amount : -updated.transaction.amount;
        txn.update(walletRef, {'balance': balance});
      } else {
        // Revert old wallet
        if (oldWalletSnap?.exists == true && oldWalletRef != null) {
          final oldBalance = oldWalletSnap!.data()?['balance'] as int? ?? 0;
          final revert = oldType.isIncome ? -oldAmount : oldAmount;
          txn.update(oldWalletRef, {'balance': oldBalance + revert});
        }
        // Apply to new wallet
        final newBalance = walletSnap.data()?['balance'] as int? ?? 0;
        final apply = updated.transaction.type.isIncome ? updated.transaction.amount : -updated.transaction.amount;
        txn.update(walletRef, {'balance': newBalance + apply});
      }

      txn.update(txnRef, newData);
    });
  }

  // ── Update Transfer ──

  Future<void> updateTransfer({
    required String txnId,
    required String linkedTxnId,
    String? linkedAccountId,
    required int oldAmount,
    required String sourceWalletId,
    required String destWalletId,
    required String oldSourceWalletId,
    required String oldDestWalletId,
    required int newAmount,
    String? note,
    required int date,
    String? createdBy,
  }) async {
    final firestore = _repo.firestore;
    final now = FieldValue.serverTimestamp();
    final isCrossAccount = linkedAccountId != null && linkedAccountId.isNotEmpty && linkedAccountId != sl.appState.currentAccountId;

    await firestore.runTransaction((txn) async {
      // Read ALL first
      final txnOutRef = _repo.collection.doc(txnId);
      final txnInRef = isCrossAccount
          ? firestore.collection('accounts').doc(linkedAccountId).collection('transactions').doc(linkedTxnId)
          : _repo.collection.doc(linkedTxnId);
      final txnOutSnap = await txn.get(txnOutRef);
      final txnInSnap = await txn.get(txnInRef);
      if (!txnOutSnap.exists || !txnInSnap.exists) throw Exception('Transaction not found');

      final oldSrcRef = sl.walletService.repo.collection.doc(oldSourceWalletId);
      final oldDstRef = isCrossAccount
          ? firestore.collection('accounts').doc(linkedAccountId).collection('wallets').doc(oldDestWalletId)
          : sl.walletService.repo.collection.doc(oldDestWalletId);
      final oldSrcSnap = await txn.get(oldSrcRef);
      final oldDstSnap = await txn.get(oldDstRef);

      final walletsChanged = sourceWalletId != oldSourceWalletId || destWalletId != oldDestWalletId;
      DocumentSnapshot<Map<String, dynamic>>? newSrcSnap;
      DocumentSnapshot<Map<String, dynamic>>? newDstSnap;
      DocumentReference<Map<String, dynamic>>? newSrcRef;
      DocumentReference<Map<String, dynamic>>? newDstRef;
      if (walletsChanged) {
        newSrcRef = sourceWalletId != oldSourceWalletId ? sl.walletService.repo.collection.doc(sourceWalletId) : null;
        if (newSrcRef != null) newSrcSnap = await txn.get(newSrcRef);
        
        newDstRef = destWalletId != oldDestWalletId ? sl.walletService.repo.collection.doc(destWalletId) : null;
        if (newDstRef != null) newDstSnap = await txn.get(newDstRef);
      }

      // Write ALL
      // Revert old wallets
      if (oldSrcSnap.exists) {
        txn.update(oldSrcRef, {'balance': (oldSrcSnap.data()?['balance'] as int? ?? 0) + oldAmount});
      }
      if (oldDstSnap.exists) {
        txn.update(oldDstRef, {'balance': (oldDstSnap.data()?['balance'] as int? ?? 0) - oldAmount});
      }

      // Apply new wallets
      final srcRef = newSrcRef ?? oldSrcRef;
      final dstRef = newDstRef ?? oldDstRef;
      final srcBalance = (newSrcSnap ?? oldSrcSnap).data()?['balance'] as int? ?? 0;
      final dstBalance = (newDstSnap ?? oldDstSnap).data()?['balance'] as int? ?? 0;
      // If same ref as old, balance already reverted above
      final srcAdjust = srcRef == oldSrcRef ? srcBalance + oldAmount : srcBalance;
      final dstAdjust = dstRef == oldDstRef ? dstBalance - oldAmount : dstBalance;
      txn.update(srcRef, {'balance': srcAdjust - newAmount});
      txn.update(dstRef, {'balance': dstAdjust + newAmount});

      // Update txn docs
      // Resolve names for display
      final srcWalletName = (oldSrcSnap.data()?['name'] as String?) ?? '';
      final dstWalletName = (oldDstSnap.data()?['name'] as String?) ?? '';
      final srcAccount = await sl.accountService.getAccount(sl.appState.currentAccountId);
      final srcAccountName = isCrossAccount ? (srcAccount?.name ?? '') : null;
      final dstAccountName = isCrossAccount ? (txnOutSnap.data()?['to_account_name'] as String? ?? '') : null;

      txn.update(txnOutRef, {
        'wallet_id': sourceWalletId, 'to_wallet_id': destWalletId,
        'to_wallet_name': dstWalletName,
        ...?dstAccountName != null ? {'to_account_name': dstAccountName} : null,
        'amount': newAmount, 'note': note, 'date': date,
        ...?createdBy != null ? {'created_by': createdBy} : null,
        'updated_at': now,
      });
      txn.update(txnInRef, {
        'wallet_id': destWalletId, 'to_wallet_id': sourceWalletId,
        'to_wallet_name': srcWalletName,
        ...?srcAccountName != null ? {'to_account_name': srcAccountName} : null,
        'amount': newAmount, 'note': note, 'date': date,
        ...?createdBy != null ? {'created_by': createdBy} : null,
        'updated_at': now,
      });
    });
  }

  // ── Atomic Delete (#3) ──

  Future<void> deleteTransaction(String id) async {
    final firestore = _repo.firestore;
    final txnRef = _repo.collection.doc(id);

    await firestore.runTransaction((txn) async {
      final txnSnap = await txn.get(txnRef);
      if (!txnSnap.exists) return;
      final data = txnSnap.data()!;
      final type = TransactionType.fromString(data['type'] ?? 'expense');
      final amount = data['amount'] as int? ?? 0;
      final walletId = data['wallet_id'] as String? ?? '';
      final linkedId = data['linked_transaction_id'] as String?;
      final toWalletId = data['to_wallet_id'] as String? ?? '';

      // Read ALL documents first
      DocumentSnapshot<Map<String, dynamic>>? walletSnap;
      DocumentReference<Map<String, dynamic>>? walletRef;
      DocumentSnapshot<Map<String, dynamic>>? linkedWalletSnap;
      DocumentReference<Map<String, dynamic>>? linkedWalletRef;
      DocumentSnapshot<Map<String, dynamic>>? linkedTxnSnap;
      DocumentReference<Map<String, dynamic>>? linkedTxnRef;

      if (walletId.isNotEmpty) {
        walletRef = sl.walletService.repo.collection.doc(walletId);
        walletSnap = await txn.get(walletRef);
      }

      if (linkedId?.isNotEmpty == true) {
        // Linked txn in same account (same-account transfer) or cross-account
        final linkedAccountId = data['to_account_id'] as String?;
        if (linkedAccountId != null && linkedAccountId.isNotEmpty) {
          linkedTxnRef = firestore.collection('accounts').doc(linkedAccountId).collection('transactions').doc(linkedId);
        } else {
          linkedTxnRef = _repo.collection.doc(linkedId);
        }
        linkedTxnSnap = await txn.get(linkedTxnRef);

        if (toWalletId.isNotEmpty) {
          if (linkedAccountId != null && linkedAccountId.isNotEmpty) {
            linkedWalletRef = firestore.collection('accounts').doc(linkedAccountId).collection('wallets').doc(toWalletId);
          } else {
            linkedWalletRef = sl.walletService.repo.collection.doc(toWalletId);
          }
          linkedWalletSnap = await txn.get(linkedWalletRef);
        }
      }

      // Now write ALL
      // Revert this wallet
      if (walletSnap?.exists == true && walletRef != null) {
        final balance = walletSnap!.data()?['balance'] as int? ?? 0;
        final delta = type.isIncome || type.isTransferIn ? -amount : amount;
        txn.update(walletRef, {'balance': balance + delta});
      }

      // Revert linked wallet + delete linked txn
      if (linkedTxnSnap?.exists == true && linkedTxnRef != null) {
        if (linkedWalletSnap?.exists == true && linkedWalletRef != null) {
          final linkedBalance = linkedWalletSnap!.data()?['balance'] as int? ?? 0;
          // Linked txn is the opposite: if we're transfer_out, linked is transfer_in
          final linkedDelta = type.isTransferOut ? -amount : amount;
          txn.update(linkedWalletRef, {'balance': linkedBalance + linkedDelta});
        }
        txn.delete(linkedTxnRef);
      }

      txn.delete(txnRef);
    });
  }

  // ── Items (embedded) ──

  Future<TransactionWithItems?> getTransactionWithItems(String id) => _repo.getById(id);

  Future<void> updateTransactionField(String id, Map<String, dynamic> fields) async {
    fields['updated_at'] = FieldValue.serverTimestamp();
    await _repo.update(id, fields);
  }

  /// Direct date range query (for TransactionListScreen lazy loading)
  Future<List<TransactionWithItems>> getByDateRange(int startDate, int endDate, {String? walletId}) =>
      _repo.getByDateRange(startDate, endDate, walletId: walletId);

  // ── Transfer ──

  Future<String> createTransfer({
    required String sourceWalletId,
    required String destWalletId,
    required int amount,
    String? note,
    required int date,
    String? destAccountId,
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than 0');
    final sourceAccountId = sl.appState.currentAccountId;
    final isCrossAccount = destAccountId != null && destAccountId != sourceAccountId;
    final firestore = _repo.firestore;
    final now = FieldValue.serverTimestamp();

    // Resolve system category
    final systemKey = isCrossAccount ? 'funding' : 'transfer';
    final sysCat = await sl.categoryService.ensureSystemCategory(systemKey);
    final categoryId = sysCat.id ?? '';

    if (!isCrossAccount) {
      // Same-account transfer: 2 linked txns (out + in)
      final srcRef = sl.walletService.repo.collection.doc(sourceWalletId);
      final dstRef = sl.walletService.repo.collection.doc(destWalletId);
      final txnOutRef = _repo.collection.doc();
      final txnInRef = _repo.collection.doc();

      // Resolve wallet names from Firestore
      final srcWalletDoc = await sl.walletService.repo.collection.doc(sourceWalletId).get();
      final dstWalletDoc = await sl.walletService.repo.collection.doc(destWalletId).get();
      final srcName = (srcWalletDoc.data()?['name'] as String?) ?? '';
      final dstName = (dstWalletDoc.data()?['name'] as String?) ?? '';

      final outData = {
        'wallet_id': sourceWalletId, 'category_id': categoryId, 'type': 'transfer_out',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'to_wallet_id': destWalletId, 'to_wallet_name': dstName,
        'linked_transaction_id': txnInRef.id,
        'created_at': now, 'updated_at': now,
      };
      final inData = {
        'wallet_id': destWalletId, 'category_id': categoryId, 'type': 'transfer_in',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'to_wallet_id': sourceWalletId, 'to_wallet_name': srcName,
        'linked_transaction_id': txnOutRef.id,
        'created_at': now, 'updated_at': now,
      };

      await firestore.runTransaction((txn) async {
        final srcSnap = await txn.get(srcRef);
        final dstSnap = await txn.get(dstRef);
        if (!srcSnap.exists || !dstSnap.exists) throw Exception('Wallet not found');
        txn.set(txnOutRef, outData);
        txn.set(txnInRef, inData);
        txn.update(srcRef, {'balance': (srcSnap.data()?['balance'] as int? ?? 0) - amount});
        txn.update(dstRef, {'balance': (dstSnap.data()?['balance'] as int? ?? 0) + amount});
      });
      return txnOutRef.id;
    }

    // Cross-account transfer
    final srcWalletRef = firestore.collection('accounts').doc(sourceAccountId).collection('wallets').doc(sourceWalletId);
    final dstWalletRef = firestore.collection('accounts').doc(destAccountId).collection('wallets').doc(destWalletId);
    final txnARef = firestore.collection('accounts').doc(sourceAccountId).collection('transactions').doc();
    final txnBRef = firestore.collection('accounts').doc(destAccountId).collection('transactions').doc();

    // Resolve names for display (before the transaction)
    final srcWalletSnap = await srcWalletRef.get();
    final dstWalletSnap = await dstWalletRef.get();
    final srcWalletName = srcWalletSnap.data()?['name'] as String? ?? '';
    final dstWalletName = dstWalletSnap.data()?['name'] as String? ?? '';
    final srcAccount = await sl.accountService.getAccount(sourceAccountId);
    final dstAccount = await sl.accountService.getAccount(destAccountId);
    final srcAccountName = srcAccount?.name ?? '';
    final dstAccountName = dstAccount?.name ?? '';

    await firestore.runTransaction((txn) async {
      // Read wallet balances INSIDE the transaction
      final srcSnap = await txn.get(srcWalletRef);
      final dstSnap = await txn.get(dstWalletRef);
      if (!srcSnap.exists || !dstSnap.exists) throw Exception('Wallet not found');

      final srcBalance = srcSnap.data()?['balance'] as int? ?? 0;
      final dstBalance = dstSnap.data()?['balance'] as int? ?? 0;

      txn.set(txnARef, {
        'wallet_id': sourceWalletId, 'category_id': categoryId, 'type': 'transfer_out',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'to_wallet_id': destWalletId, 'to_account_id': destAccountId,
        'to_wallet_name': dstWalletName, 'to_account_name': dstAccountName,
        'linked_transaction_id': txnBRef.id,
        'created_at': now, 'updated_at': now,
      });
      txn.set(txnBRef, {
        'wallet_id': destWalletId, 'category_id': categoryId, 'type': 'transfer_in',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'to_wallet_id': sourceWalletId, 'to_account_id': sourceAccountId,
        'to_wallet_name': srcWalletName, 'to_account_name': srcAccountName,
        'linked_transaction_id': txnARef.id,
        'created_at': now, 'updated_at': now,
      });

      txn.update(srcWalletRef, {'balance': srcBalance - amount});
      txn.update(dstWalletRef, {'balance': dstBalance + amount});
    });
    return txnARef.id;
  }

  // ── Funded Expense (personal wallet → family expense) ──

  Future<String> createWithFunding({
    required String walletId,
    required String categoryId,
    required int amount,
    String? note,
    required int date,
    required String fundingWalletId,
    required String fundingAccountId,
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than 0');
    final familyAccountId = sl.appState.currentAccountId;
    final firestore = _repo.firestore;
    final now = FieldValue.serverTimestamp();

    // Pre-generate doc refs (before the transaction)
    final srcWalletRef = firestore.collection('accounts').doc(fundingAccountId).collection('wallets').doc(fundingWalletId);
    final transferOutRef = firestore.collection('accounts').doc(fundingAccountId).collection('transactions').doc();
    final transferInRef = firestore.collection('accounts').doc(familyAccountId).collection('transactions').doc();
    final expenseRef = firestore.collection('accounts').doc(familyAccountId).collection('transactions').doc();

    await firestore.runTransaction((txn) async {
      // Read wallet balance INSIDE the transaction
      final srcSnap = await txn.get(srcWalletRef);
      if (!srcSnap.exists) throw Exception('Wallet not found');
      final srcBalance = srcSnap.data()?['balance'] as int? ?? 0;

      // Transfer out (personal)
      txn.set(transferOutRef, {
        'wallet_id': fundingWalletId, 'category_id': '', 'type': 'transfer_out',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'to_wallet_id': walletId, 'to_account_id': familyAccountId,
        'linked_transaction_id': transferInRef.id,
        'created_at': now, 'updated_at': now,
      });

      // Transfer in (family)
      txn.set(transferInRef, {
        'wallet_id': walletId, 'category_id': '', 'type': 'transfer_in',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'to_wallet_id': fundingWalletId, 'to_account_id': fundingAccountId,
        'linked_transaction_id': transferOutRef.id,
        'created_at': now, 'updated_at': now,
      });

      // Expense (family)
      txn.set(expenseRef, {
        'wallet_id': walletId, 'category_id': categoryId, 'type': 'expense',
        'amount': amount, 'note': note, 'date': date,
        'created_by': sl.appState.currentUserId,
        'funding_wallet_id': fundingWalletId,
        'funding_account_id': fundingAccountId,
        'funding_transfer_id': transferOutRef.id,
        'created_at': now, 'updated_at': now,
      });

      // Wallet balance: deduct from personal wallet
      txn.update(srcWalletRef, {'balance': srcBalance - amount});
      // Family wallet: +amount (transfer in) -amount (expense) = net 0
      // No update needed for family wallet balance
    });
    return expenseRef.id;
  }

  void _logActivity(String action, int amount, String? note) {
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId;
    if (accountId.isEmpty || userId == null) return;

    final actionLabel = action == 'income' ? 'thu' : 'chi';
    final noteStr = note != null && note.isNotEmpty ? ' - $note' : '';
    final desc = 'đã $actionLabel $amount$noteStr';
    sl.accountService.logActivity(
      accountId: accountId, userId: userId, action: action, description: desc,
    );
  }
}
