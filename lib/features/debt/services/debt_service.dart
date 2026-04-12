import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/debt_payment.dart';
import 'package:vintage_ledger/features/debt/repositories/debt_repository.dart';

class DebtService {
  final _repo = DebtRepository();
  final _firestore = FirebaseFirestore.instance;

  // ── Core Operations ──

  Future<String> choVay({
    required String partyName,
    required int amount,
    String? contact,
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final now = DateTime.now();
    final debt = Debt(
      id: '',
      accountId: sl.appState.currentAccountId,
      type: DebtType.lend,
      partyName: partyName,
      partyContact: contact,
      totalAmount: amount,
      paidAmount: 0,
      dueDate: dueDate,
      interestRate: interestRate,
      description: description,
      walletId: walletId,
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addDebt(debt);
  }

  Future<String> vayMuon({
    required String partyName,
    required int amount,
    String? contact,
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final now = DateTime.now();
    final debt = Debt(
      id: '',
      accountId: sl.appState.currentAccountId,
      type: DebtType.borrow,
      partyName: partyName,
      partyContact: contact,
      totalAmount: amount,
      paidAmount: 0,
      dueDate: dueDate,
      interestRate: interestRate,
      description: description,
      walletId: walletId,
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addDebt(debt);
  }

  // ── Linked Debt Operations ──

  Future<String> choVayLienKet({
    required String partyUserId,
    required String partyAccountId,
    required String partyName,
    required int amount,
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    return _createLinkedDebt(
      creatorType: DebtType.lend,
      partyType: DebtType.borrow,
      partyUserId: partyUserId,
      partyAccountId: partyAccountId,
      partyName: partyName,
      amount: amount,
      walletId: walletId,
      dueDate: dueDate,
      interestRate: interestRate,
      description: description,
    );
  }

  Future<String> vayMuonLienKet({
    required String partyUserId,
    required String partyAccountId,
    required String partyName,
    required int amount,
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    return _createLinkedDebt(
      creatorType: DebtType.borrow,
      partyType: DebtType.lend,
      partyUserId: partyUserId,
      partyAccountId: partyAccountId,
      partyName: partyName,
      amount: amount,
      walletId: walletId,
      dueDate: dueDate,
      interestRate: interestRate,
      description: description,
    );
  }

  Future<String> _createLinkedDebt({
    required DebtType creatorType,
    required DebtType partyType,
    required String partyUserId,
    required String partyAccountId,
    required String partyName,
    required int amount,
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final accountId = sl.appState.currentAccountId;
    final currentUserId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Pre-generate 2 doc refs in 2 account subcollections
    final creatorDebtRef = _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('debts_v2')
        .doc();
    final partyDebtRef = _firestore
        .collection('accounts')
        .doc(partyAccountId)
        .collection('debts_v2')
        .doc();

    // Get creator's display name for the party's document
    final creatorName = await sl.accountService.getAccountNameForUser(currentUserId);

    // Shared fields
    final sharedFields = <String, dynamic>{
      'total_amount': amount,
      'paid_amount': 0,
      'status': DebtStatus.active.name,
      'created_at': nowMs,
      'updated_at': nowMs,
      // ignore: use_null_aware_elements
      if (dueDate != null) 'due_date': dueDate.millisecondsSinceEpoch,
      // ignore: use_null_aware_elements
      if (interestRate != null) 'interest_rate': interestRate,
      // ignore: use_null_aware_elements
      if (description != null) 'description': description,
    };

    // Creator's debt document
    final creatorData = <String, dynamic>{
      ...sharedFields,
      'account_id': accountId,
      'type': creatorType.name,
      'party_name': partyName,
      'linked_debt_id': partyDebtRef.id,
      'linked_account_id': partyAccountId,
      'party_user_id': partyUserId,
      'created_by': currentUserId,
      // ignore: use_null_aware_elements
      if (walletId != null) 'wallet_id': walletId,
    };

    // Party's debt document
    final partyData = <String, dynamic>{
      ...sharedFields,
      'account_id': partyAccountId,
      'type': partyType.name,
      'party_name': creatorName.isNotEmpty ? creatorName : 'Người dùng',
      'linked_debt_id': creatorDebtRef.id,
      'linked_account_id': accountId,
      'party_user_id': currentUserId,
      'created_by': currentUserId,
    };

    // Firestore transaction: create both documents atomically
    await _firestore.runTransaction((txn) async {
      txn.set(creatorDebtRef, creatorData);
      txn.set(partyDebtRef, partyData);
    });

    // Send notification to party (fire-and-forget)
    sl.notificationService.notifyDebtCreated(
      targetUserId: partyUserId,
      creatorName: creatorName.isNotEmpty ? creatorName : 'Người dùng',
      amount: amount,
      debtType: creatorType.name,
    );

    return creatorDebtRef.id;
  }

  // ── Payment Operations ──

  Future<void> nhanTienTra(String debtId, int amount, {
    required String walletId,
    String? note,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();

    // Resolve system category
    final sysCat = await sl.categoryService.ensureSystemCategory('debt_payment');
    final categoryId = sysCat.id ?? '';

    // Track linked debt info for post-transaction notification
    String? linkedPartyUserId;
    int? newPaidAmountResult;
    int? totalAmountResult;
    bool isCompleted = false;

    await firestore.runTransaction((txn) async {
      // 1. Read debt document
      final debtRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(debtId);
      final debtSnap = await txn.get(debtRef);
      if (!debtSnap.exists) throw Exception('Debt not found');
      final debtData = debtSnap.data()!;
      if (debtData['type'] != 'lend') throw Exception('Not a lend debt');
      final paidAmount = debtData['paid_amount'] as int? ?? 0;
      final totalAmount = debtData['total_amount'] as int? ?? 0;
      final linkedDebtId = debtData['linked_debt_id'] as String?;
      final linkedAccountId = debtData['linked_account_id'] as String?;
      final partyUserId = debtData['party_user_id'] as String?;

      // 2. Read wallet balance
      final walletRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('wallets')
          .doc(walletId);
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception('Wallet not found');
      final walletBalance = walletSnap.data()!['balance'] as int? ?? 0;

      // 3. Create income transaction
      final txnRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('transactions')
          .doc();
      txn.set(txnRef, {
        'wallet_id': walletId,
        'category_id': categoryId,
        'type': 'income',
        'amount': amount,
        'note': note ?? 'Nhận trả nợ',
        'date': now.millisecondsSinceEpoch,
        'created_by': userId,
        'debt_id': debtId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. Add to wallet balance
      txn.update(walletRef, {'balance': walletBalance + amount});

      // 5. Create payment in debt's subcollection
      final paymentRef = debtRef.collection('payments').doc();
      txn.set(paymentRef, {
        'debt_id': debtId,
        'amount': amount,
        'date': now.millisecondsSinceEpoch,
        'note': note,
        'created_by': userId,
        'created_at': now.millisecondsSinceEpoch,
      });

      // 6. Update debt paid_amount and status if completed
      final newPaidAmount = paidAmount + amount;
      final debtUpdates = <String, dynamic>{
        'paid_amount': newPaidAmount,
        'updated_at': now.millisecondsSinceEpoch,
      };
      if (newPaidAmount >= totalAmount) {
        debtUpdates['status'] = 'completed';
      }
      txn.update(debtRef, debtUpdates);

      // 7. Sync linked debt if applicable
      if (linkedDebtId != null && linkedAccountId != null) {
        final linkedDebtRef = firestore
            .collection('accounts')
            .doc(linkedAccountId)
            .collection('debts_v2')
            .doc(linkedDebtId);
        final linkedDebtSnap = await txn.get(linkedDebtRef);

        if (linkedDebtSnap.exists) {
          // Update paidAmount and status on linked debt
          final linkedUpdates = <String, dynamic>{
            'paid_amount': newPaidAmount,
            'updated_at': now.millisecondsSinceEpoch,
          };
          if (newPaidAmount >= totalAmount) {
            linkedUpdates['status'] = 'completed';
          }
          txn.update(linkedDebtRef, linkedUpdates);

          // Store info for post-transaction notification
          linkedPartyUserId = partyUserId;
        } else {
          // Linked debt doc doesn't exist — unlink and continue normally
          txn.update(debtRef, {
            'linked_debt_id': FieldValue.delete(),
            'linked_account_id': FieldValue.delete(),
          });
        }
      }

      // Store results for post-transaction notification
      newPaidAmountResult = newPaidAmount;
      totalAmountResult = totalAmount;
      isCompleted = newPaidAmount >= totalAmount;
    });

    // 8. Send notification after transaction succeeds (fire-and-forget)
    if (linkedPartyUserId != null) {
      final currentUserName = await sl.accountService.getAccountNameForUser(userId);
      final payerName = currentUserName.isNotEmpty ? currentUserName : 'Người dùng';

      if (isCompleted) {
        sl.notificationService.notifyDebtCompleted(
          targetUserId: linkedPartyUserId!,
          partyName: payerName,
          totalAmount: totalAmountResult!,
        );
      } else {
        sl.notificationService.notifyDebtPayment(
          targetUserId: linkedPartyUserId!,
          payerName: payerName,
          amount: amount,
          remainingAmount: totalAmountResult! - newPaidAmountResult!,
        );
      }
    }
  }

  Future<void> traNop(String debtId, int amount, {
    required String walletId,
    String? note,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();

    // Resolve system category
    final sysCat = await sl.categoryService.ensureSystemCategory('debt_payment');
    final categoryId = sysCat.id ?? '';

    // Track linked debt info for post-transaction notification
    String? linkedPartyUserId;
    int? newPaidAmountResult;
    int? totalAmountResult;
    bool isCompleted = false;

    await firestore.runTransaction((txn) async {
      // 1. Read debt document
      final debtRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(debtId);
      final debtSnap = await txn.get(debtRef);
      if (!debtSnap.exists) throw Exception('Debt not found');
      final debtData = debtSnap.data()!;
      if (debtData['type'] != 'borrow') throw Exception('Not a borrow debt');
      final paidAmount = debtData['paid_amount'] as int? ?? 0;
      final totalAmount = debtData['total_amount'] as int? ?? 0;
      final linkedDebtId = debtData['linked_debt_id'] as String?;
      final linkedAccountId = debtData['linked_account_id'] as String?;
      final partyUserId = debtData['party_user_id'] as String?;

      // 2. Read wallet balance
      final walletRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('wallets')
          .doc(walletId);
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception('Wallet not found');
      final walletBalance = walletSnap.data()!['balance'] as int? ?? 0;

      // 3. Validate sufficient balance
      if (walletBalance < amount) throw Exception('Số dư ví không đủ');

      // 4. Create expense transaction
      final txnRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('transactions')
          .doc();
      txn.set(txnRef, {
        'wallet_id': walletId,
        'category_id': categoryId,
        'type': 'expense',
        'amount': amount,
        'note': note ?? 'Trả nợ',
        'date': now.millisecondsSinceEpoch,
        'created_by': userId,
        'debt_id': debtId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 5. Deduct wallet balance
      txn.update(walletRef, {'balance': walletBalance - amount});

      // 6. Create payment in debt's subcollection
      final paymentRef = debtRef.collection('payments').doc();
      txn.set(paymentRef, {
        'debt_id': debtId,
        'amount': amount,
        'date': now.millisecondsSinceEpoch,
        'note': note,
        'created_by': userId,
        'created_at': now.millisecondsSinceEpoch,
      });

      // 7. Update debt paid_amount and status if completed
      final newPaidAmount = paidAmount + amount;
      final debtUpdates = <String, dynamic>{
        'paid_amount': newPaidAmount,
        'updated_at': now.millisecondsSinceEpoch,
      };
      if (newPaidAmount >= totalAmount) {
        debtUpdates['status'] = 'completed';
      }
      txn.update(debtRef, debtUpdates);

      // 8. Sync linked debt if applicable
      if (linkedDebtId != null && linkedAccountId != null) {
        final linkedDebtRef = firestore
            .collection('accounts')
            .doc(linkedAccountId)
            .collection('debts_v2')
            .doc(linkedDebtId);
        final linkedDebtSnap = await txn.get(linkedDebtRef);

        if (linkedDebtSnap.exists) {
          // Update paidAmount and status on linked debt
          final linkedUpdates = <String, dynamic>{
            'paid_amount': newPaidAmount,
            'updated_at': now.millisecondsSinceEpoch,
          };
          if (newPaidAmount >= totalAmount) {
            linkedUpdates['status'] = 'completed';
          }
          txn.update(linkedDebtRef, linkedUpdates);

          // Store info for post-transaction notification
          linkedPartyUserId = partyUserId;
        } else {
          // Linked debt doc doesn't exist — unlink and continue normally
          txn.update(debtRef, {
            'linked_debt_id': FieldValue.delete(),
            'linked_account_id': FieldValue.delete(),
          });
        }
      }

      // Store results for post-transaction notification
      newPaidAmountResult = newPaidAmount;
      totalAmountResult = totalAmount;
      isCompleted = newPaidAmount >= totalAmount;
    });

    // 9. Send notification after transaction succeeds (fire-and-forget)
    if (linkedPartyUserId != null) {
      final currentUserName = await sl.accountService.getAccountNameForUser(userId);
      final payerName = currentUserName.isNotEmpty ? currentUserName : 'Người dùng';

      if (isCompleted) {
        sl.notificationService.notifyDebtCompleted(
          targetUserId: linkedPartyUserId!,
          partyName: payerName,
          totalAmount: totalAmountResult!,
        );
      } else {
        sl.notificationService.notifyDebtPayment(
          targetUserId: linkedPartyUserId!,
          payerName: payerName,
          amount: amount,
          remainingAmount: totalAmountResult! - newPaidAmountResult!,
        );
      }
    }
  }

  // ── Queries ──

  Future<List<Debt>> getTienChoVay() async {
    return await _repo.getDebtsByType(DebtType.lend);
  }

  Future<List<Debt>> getTienVayMuon() async {
    return await _repo.getDebtsByType(DebtType.borrow);
  }

  Future<List<Debt>> getOverdueDebts() async {
    return await _repo.getOverdueDebts();
  }

  Stream<List<Debt>> watchActiveDebts() {
    return _repo.watchActiveDebts();
  }

  Stream<List<Debt>> watchDebtsByWallet(String walletId) {
    return _repo.watchActiveDebtsByWallet(walletId);
  }

  Future<List<Debt>> getDebtsByWallet(String walletId) async {
    return await _repo.getActiveDebtsByWallet(walletId);
  }

  Future<Debt?> getDebt(String id) async {
    return await _repo.getDebt(id);
  }

  Future<List<DebtPayment>> getPayments(String debtId) async {
    return await _repo.getPayments(debtId);
  }

  Stream<List<DebtPayment>> watchPayments(String debtId) {
    return _repo.watchPayments(debtId);
  }

  // ── Management ──

  Future<void> updateDebt(String id, {
    String? partyName,
    String? partyContact,
    int? totalAmount,
    DateTime? dueDate,
    double? interestRate,
    String? description,
    String? walletId,
  }) async {
    final updates = <String, dynamic>{};
    if (partyName != null) updates['party_name'] = partyName;
    if (partyContact != null) updates['party_contact'] = partyContact;
    if (totalAmount != null) updates['total_amount'] = totalAmount;
    if (dueDate != null) updates['due_date'] = dueDate.millisecondsSinceEpoch;
    if (interestRate != null) updates['interest_rate'] = interestRate;
    if (description != null) updates['description'] = description;
    if (walletId != null) updates['wallet_id'] = walletId;

    if (updates.isNotEmpty) {
      await _repo.updateDebt(id, updates);
    }
  }

  Future<void> cancelDebt(String id) async {
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Track linked debt info for post-transaction notification
    String? linkedPartyUserId;
    int? totalAmount;

    await _firestore.runTransaction((txn) async {
      // 1. Read debt document
      final debtRef = _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(id);
      final debtSnap = await txn.get(debtRef);
      if (!debtSnap.exists) throw Exception('Debt not found');
      final debtData = debtSnap.data()!;
      final linkedDebtId = debtData['linked_debt_id'] as String?;
      final linkedAccountId = debtData['linked_account_id'] as String?;
      final partyUserId = debtData['party_user_id'] as String?;

      // 2. Cancel the current debt
      txn.update(debtRef, {
        'status': DebtStatus.cancelled.name,
        'updated_at': now,
      });

      // 3. If linked: unlink the other side
      if (linkedDebtId != null && linkedAccountId != null) {
        final linkedDebtRef = _firestore
            .collection('accounts')
            .doc(linkedAccountId)
            .collection('debts_v2')
            .doc(linkedDebtId);
        final linkedDebtSnap = await txn.get(linkedDebtRef);

        if (linkedDebtSnap.exists) {
          txn.update(linkedDebtRef, {
            'linked_debt_id': FieldValue.delete(),
            'linked_account_id': FieldValue.delete(),
            'updated_at': now,
          });
          // Store info for post-transaction notification
          linkedPartyUserId = partyUserId;
          totalAmount = debtData['total_amount'] as int?;
        }
        // If linked debt doc doesn't exist: continue cancel normally (no error)
      }
    });

    // 4. Send notification to partner after transaction succeeds (fire-and-forget)
    if (linkedPartyUserId != null) {
      final currentUserName = await sl.accountService.getAccountNameForUser(userId);
      final cancellerName = currentUserName.isNotEmpty ? currentUserName : 'Người dùng';
      sl.notificationService.notifyDebtCancelled(
        targetUserId: linkedPartyUserId!,
        cancellerName: cancellerName,
        amount: totalAmount ?? 0,
      );
    }
  }

  Future<void> deleteDebt(String id) async {
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Track linked debt info for post-transaction notification
    String? linkedPartyUserId;
    int? totalAmount;

    await _firestore.runTransaction((txn) async {
      // 1. Read debt document before deleting
      final debtRef = _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(id);
      final debtSnap = await txn.get(debtRef);
      if (!debtSnap.exists) throw Exception('Debt not found');
      final debtData = debtSnap.data()!;
      final linkedDebtId = debtData['linked_debt_id'] as String?;
      final linkedAccountId = debtData['linked_account_id'] as String?;
      final partyUserId = debtData['party_user_id'] as String?;

      // 2. If linked: unlink the other side
      if (linkedDebtId != null && linkedAccountId != null) {
        final linkedDebtRef = _firestore
            .collection('accounts')
            .doc(linkedAccountId)
            .collection('debts_v2')
            .doc(linkedDebtId);
        final linkedDebtSnap = await txn.get(linkedDebtRef);

        if (linkedDebtSnap.exists) {
          txn.update(linkedDebtRef, {
            'linked_debt_id': FieldValue.delete(),
            'linked_account_id': FieldValue.delete(),
            'updated_at': now,
          });
          // Store info for post-transaction notification
          linkedPartyUserId = partyUserId;
          totalAmount = debtData['total_amount'] as int?;
        }
        // If linked debt doc doesn't exist: continue delete normally (no error)
      }

      // 3. Delete the current debt document
      txn.delete(debtRef);
    });

    // 4. Delete payments subcollection (outside transaction, best-effort)
    try {
      final paymentsSnap = await _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(id)
          .collection('payments')
          .limit(500)
          .get();
      if (paymentsSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in paymentsSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}

    // 5. Send notification to partner after transaction succeeds (fire-and-forget)
    if (linkedPartyUserId != null) {
      final currentUserName = await sl.accountService.getAccountNameForUser(userId);
      final deleterName = currentUserName.isNotEmpty ? currentUserName : 'Người dùng';
      sl.notificationService.notifyDebtCancelled(
        targetUserId: linkedPartyUserId!,
        cancellerName: deleterName,
        amount: totalAmount ?? 0,
      );
    }
  }
}
