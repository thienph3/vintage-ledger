import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/features/account/models/account.dart';

class AccountService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _accounts => _firestore.collection('accounts');
  CollectionReference get _users => _firestore.collection('users');

  /// Tạo user profile + personal account khi register
  Future<String> createUserWithPersonalAccount({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Tạo personal account
    final accountRef = await _accounts.add({
      'type': 'personal',
      'name': displayName,
      'owner_id': userId,
      'member_ids': [userId],
      'created_at': now,
    });

    // Tạo user profile
    await _users.doc(userId).set({
      'email': email,
      'display_name': displayName,
      'account_ids': [accountRef.id],
      'created_at': now,
    });

    return accountRef.id;
  }

  /// Lấy danh sách accounts của user
  Future<List<Account>> getAccountsForUser(String userId) async {
    // Lấy account_ids từ user profile
    final userDoc = await _users.doc(userId).get();
    if (!userDoc.exists) return [];

    final accountIds = List<String>.from(
      (userDoc.data() as Map<String, dynamic>)['account_ids'] ?? [],
    );
    if (accountIds.isEmpty) return [];

    final results = <Account>[];
    for (final id in accountIds) {
      final doc = await _accounts.doc(id).get();
      if (doc.exists) {
        results.add(Account.fromMap(doc.id, doc.data() as Map<String, dynamic>));
      }
    }
    return results;
  }

  /// Tạo family account
  Future<String> createFamilyAccount({
    required String userId,
    required String name,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final accountRef = await _accounts.add({
      'type': 'family',
      'name': name,
      'owner_id': userId,
      'member_ids': [userId],
      'created_at': now,
    });

    // Thêm accountId vào user profile
    await _users.doc(userId).update({
      'account_ids': FieldValue.arrayUnion([accountRef.id]),
    });

    return accountRef.id;
  }

  /// Lấy personal accountId cho user (tạo nếu chưa có)
  Future<String> getOrCreatePersonalAccountId(String userId, String email, String displayName) async {
    final userDoc = await _users.doc(userId).get();
    if (userDoc.exists) {
      final accountIds = List<String>.from(
        (userDoc.data() as Map<String, dynamic>)['account_ids'] ?? [],
      );
      if (accountIds.isNotEmpty) return accountIds.first;
    }
    return await createUserWithPersonalAccount(
      userId: userId,
      email: email,
      displayName: displayName,
    );
  }
}
