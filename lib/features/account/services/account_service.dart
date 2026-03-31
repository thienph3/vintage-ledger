import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

class AccountService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _accounts => _firestore.collection('accounts');
  CollectionReference get _users => _firestore.collection('users');

  // ── Create ──

  Future<String> createUserWithPersonalAccount({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final accountRef = await _accounts.add({
      'type': 'personal',
      'name': displayName,
      'owner_id': userId,
      'member_ids': [userId],
      'created_at': now,
    });

    await _users.doc(userId).set({
      'email': email,
      'display_name': displayName,
      'account_ids': [accountRef.id],
      'created_at': now,
    });

    return accountRef.id;
  }

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

    await _users.doc(userId).update({
      'account_ids': FieldValue.arrayUnion([accountRef.id]),
    });

    await _seedCategories(accountRef.id);

    return accountRef.id;
  }

  // ── Read ──

  Future<List<Account>> getAccountsForUser(String userId) async {
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

  Future<Account?> getAccount(String accountId) async {
    final doc = await _accounts.doc(accountId).get();
    if (!doc.exists) return null;
    return Account.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<String> getOrCreatePersonalAccountId(
      String userId, String email, String displayName) async {
    final userDoc = await _users.doc(userId).get();
    if (userDoc.exists) {
      final accountIds = List<String>.from(
        (userDoc.data() as Map<String, dynamic>)['account_ids'] ?? [],
      );
      if (accountIds.isNotEmpty) return accountIds.first;
    }
    return await createUserWithPersonalAccount(
      userId: userId, email: email, displayName: displayName,
    );
  }

  /// Lấy member display names cho family detail
  Future<List<Map<String, String>>> getMemberProfiles(List<String> memberIds) async {
    final results = <Map<String, String>>[];
    for (final id in memberIds) {
      final doc = await _users.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        results.add({
          'id': id,
          'name': data['display_name'] ?? '',
          'email': data['email'] ?? '',
        });
      }
    }
    return results;
  }

  // ── Invite member (#22) ──

  Future<void> inviteMember({
    required String accountId,
    required String email,
  }) async {
    // Tìm user theo email
    final query = await _users.where('email', isEqualTo: email).limit(1).get();
    if (query.docs.isEmpty) throw Exception('User not found');

    final invitedUserId = query.docs.first.id;

    // Check đã là member chưa
    final account = await getAccount(accountId);
    if (account != null && account.memberIds.contains(invitedUserId)) {
      throw Exception('Already a member');
    }

    // Thêm vào account.member_ids
    await _accounts.doc(accountId).update({
      'member_ids': FieldValue.arrayUnion([invitedUserId]),
    });

    // Thêm accountId vào user.account_ids
    await _users.doc(invitedUserId).update({
      'account_ids': FieldValue.arrayUnion([accountId]),
    });
  }

  // ── Leave family (#23) ──

  Future<void> leaveFamily({
    required String accountId,
    required String userId,
  }) async {
    final account = await getAccount(accountId);
    if (account == null) return;

    // Remove user từ member_ids
    await _accounts.doc(accountId).update({
      'member_ids': FieldValue.arrayRemove([userId]),
    });

    // Remove accountId từ user.account_ids
    await _users.doc(userId).update({
      'account_ids': FieldValue.arrayRemove([accountId]),
    });

    // Nếu owner rời → chuyển owner cho member đầu tiên, hoặc xóa nếu trống
    if (account.ownerId == userId) {
      final remaining = account.memberIds.where((id) => id != userId).toList();
      if (remaining.isEmpty) {
        await deleteFamily(accountId: accountId);
      } else {
        await _accounts.doc(accountId).update({'owner_id': remaining.first});
      }
    }
  }

  /// Remove member (owner action)
  Future<void> removeMember({
    required String accountId,
    required String memberId,
  }) async {
    await _accounts.doc(accountId).update({
      'member_ids': FieldValue.arrayRemove([memberId]),
    });
    await _users.doc(memberId).update({
      'account_ids': FieldValue.arrayRemove([accountId]),
    });
  }

  // ── Delete family (#24) ──

  Future<void> deleteFamily({required String accountId}) async {
    final account = await getAccount(accountId);
    if (account == null) return;

    // Remove accountId từ tất cả members
    for (final memberId in account.memberIds) {
      await _users.doc(memberId).update({
        'account_ids': FieldValue.arrayRemove([accountId]),
      });
    }

    // Xóa subcollections
    for (final sub in ['wallets', 'transactions', 'categories']) {
      final docs = await _accounts.doc(accountId).collection(sub).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    // Xóa account document
    await _accounts.doc(accountId).delete();
  }

  // ── Seed categories (#25) ──

  Future<void> _seedCategories(String accountId) async {
    final batch = _firestore.batch();
    final catCol = _accounts.doc(accountId).collection('categories');

    final seeds = [
      {'name': 'Ăn uống', 'type': 'expense', 'icon': kCategoryIcons[0].codePoint},
      {'name': 'Di chuyển', 'type': 'expense', 'icon': kCategoryIcons[1].codePoint},
      {'name': 'Mua sắm', 'type': 'expense', 'icon': kCategoryIcons[2].codePoint},
      {'name': 'Nhà ở', 'type': 'expense', 'icon': kCategoryIcons[3].codePoint},
      {'name': 'Hóa đơn', 'type': 'expense', 'icon': kCategoryIcons[8].codePoint},
      {'name': 'Khác', 'type': 'expense', 'icon': kCategoryIcons[9].codePoint},
      {'name': 'Lương', 'type': 'income', 'icon': kCategoryIcons[10].codePoint},
      {'name': 'Thưởng', 'type': 'income', 'icon': kCategoryIcons[11].codePoint},
      {'name': 'Khác', 'type': 'income', 'icon': kCategoryIcons[9].codePoint},
    ];

    for (final seed in seeds) {
      batch.set(catCol.doc(), seed);
    }
    await batch.commit();
  }
}
