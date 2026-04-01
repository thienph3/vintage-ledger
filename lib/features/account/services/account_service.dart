import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/features/account/models/invite_token.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

class AccountService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _accounts => _firestore.collection('accounts');
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _invites => _firestore.collection('invites');

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

    await _seedCategories(accountRef.id);

    return accountRef.id;
  }

  /// Task #4: Tạo family + shared wallet mặc định
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

    // Shared wallet mặc định
    await accountRef.collection('wallets').add({
      'name': 'Ví chung',
      'balance': 0,
      'currency': 'VND',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

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

  // ── Invite by link (#1, #2, #9) ──

  /// Tạo invite token, trả về token ID dùng làm link
  Future<String> createInviteToken({
    required String accountId,
    required String createdBy,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + 7 * 24 * 60 * 60 * 1000; // 7 ngày

    final doc = await _invites.add({
      'account_id': accountId,
      'created_by': createdBy,
      'created_at': now,
      'expires_at': expiresAt,
    });

    return doc.id;
  }

  /// Lấy invite token, check expiry
  Future<InviteToken?> getInviteToken(String tokenId) async {
    final doc = await _invites.doc(tokenId).get();
    if (!doc.exists) return null;
    return InviteToken.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Join family bằng invite token
  Future<void> joinByInvite({
    required String tokenId,
    required String userId,
  }) async {
    final token = await getInviteToken(tokenId);
    if (token == null) throw Exception('Invite not found');
    if (token.isExpired) throw Exception('Invite expired');

    final account = await getAccount(token.accountId);
    if (account == null) throw Exception('Family not found');
    if (account.memberIds.contains(userId)) throw Exception('Already a member');

    await _accounts.doc(token.accountId).update({
      'member_ids': FieldValue.arrayUnion([userId]),
    });

    await _users.doc(userId).update({
      'account_ids': FieldValue.arrayUnion([token.accountId]),
    });

    logActivity(accountId: token.accountId, userId: userId, action: 'join', description: 'đã tham gia');
  }

  /// Build invite link string
  String buildInviteLink(String tokenId) =>
      'https://vintage-ledger.web.app/invite/$tokenId';

  // ── Leave / Remove / Delete ──

  Future<void> leaveFamily({
    required String accountId,
    required String userId,
  }) async {
    final account = await getAccount(accountId);
    if (account == null) return;

    await _accounts.doc(accountId).update({
      'member_ids': FieldValue.arrayRemove([userId]),
    });

    await _users.doc(userId).update({
      'account_ids': FieldValue.arrayRemove([accountId]),
    });

    logActivity(accountId: accountId, userId: userId, action: 'leave', description: 'đã rời');

    if (account.ownerId == userId) {
      final remaining = account.memberIds.where((id) => id != userId).toList();
      if (remaining.isEmpty) {
        await deleteFamily(accountId: accountId);
      } else {
        await _accounts.doc(accountId).update({'owner_id': remaining.first});
      }
    }
  }

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

  Future<void> deleteFamily({required String accountId}) async {
    final account = await getAccount(accountId);
    if (account == null) return;

    for (final memberId in account.memberIds) {
      await _users.doc(memberId).update({
        'account_ids': FieldValue.arrayRemove([accountId]),
      });
    }

    for (final sub in ['wallets', 'transactions', 'categories', 'activities']) {
      final docs = await _accounts.doc(accountId).collection(sub).get();
      if (docs.docs.isEmpty) continue;
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _accounts.doc(accountId).delete();
  }

  // ── Activity feed (#6) ──

  Future<void> logActivity({
    required String accountId,
    required String userId,
    required String action,
    required String description,
  }) async {
    await _accounts.doc(accountId).collection('activities').add({
      'user_id': userId,
      'action': action,
      'description': description,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchActivities(String accountId, {int limit = 30}) {
    return _accounts.doc(accountId)
        .collection('activities')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList());
  }

  // ── Seed categories ──

  Future<void> _seedCategories(String accountId) async {
    final batch = _firestore.batch();
    final catCol = _accounts.doc(accountId).collection('categories');

    final now = DateTime.now().millisecondsSinceEpoch;
    final seeds = [
      {'name': 'Ăn uống', 'type': 'expense', 'icon': kCategoryIcons[0].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Di chuyển', 'type': 'expense', 'icon': kCategoryIcons[1].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Mua sắm', 'type': 'expense', 'icon': kCategoryIcons[2].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Nhà ở', 'type': 'expense', 'icon': kCategoryIcons[3].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Hóa đơn', 'type': 'expense', 'icon': kCategoryIcons[8].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Khác', 'type': 'expense', 'icon': kCategoryIcons[9].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Lương', 'type': 'income', 'icon': kCategoryIcons[10].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Thưởng', 'type': 'income', 'icon': kCategoryIcons[11].codePoint, 'created_at': now, 'updated_at': now},
      {'name': 'Khác', 'type': 'income', 'icon': kCategoryIcons[9].codePoint, 'created_at': now, 'updated_at': now},
    ];

    for (final seed in seeds) {
      batch.set(catCol.doc(), seed);
    }
    await batch.commit();
  }
}
