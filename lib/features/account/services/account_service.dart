import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/core/constants/seed_categories.dart';

class AccountService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _accounts => _firestore.collection('accounts');
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _pendingInvites => _firestore.collection('pending_invites');
  CollectionReference get _userEmails => _firestore.collection('user_emails');

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

    final batch = _firestore.batch();
    batch.set(_users.doc(userId), {
      'email': email,
      'display_name': displayName,
      'account_ids': [accountRef.id],
      'created_at': now,
    });
    if (email.isNotEmpty) {
      batch.set(_userEmails.doc(email.toLowerCase()), {'user_id': userId});
    }
    await batch.commit();

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
      'initial_balance': 0,
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

  final Map<String, Account> _accountCache = {};

  Future<Account?> getAccount(String accountId) async {
    if (_accountCache.containsKey(accountId)) return _accountCache[accountId];
    final doc = await _accounts.doc(accountId).get();
    if (!doc.exists) return null;
    final account = Account.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    _accountCache[accountId] = account;
    return account;
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

  /// Update user profile + account name after anonymous upgrade
  Future<void> updateUserProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final batch = _firestore.batch();
    batch.set(_users.doc(userId), {
      'email': email,
      'display_name': displayName,
    }, SetOptions(merge: true));
    if (email.isNotEmpty) {
      batch.set(_userEmails.doc(email.toLowerCase()), {'user_id': userId});
    }
    await batch.commit();

    // Update personal account name
    final userDoc = await _users.doc(userId).get();
    if (!userDoc.exists) return;
    final accountIds = List<String>.from(
      (userDoc.data() as Map<String, dynamic>)['account_ids'] ?? [],
    );
    if (accountIds.isEmpty) return;

    final accountDoc = await _accounts.doc(accountIds.first).get();
    if (accountDoc.exists) {
      final data = accountDoc.data() as Map<String, dynamic>;
      if (data['type'] == 'personal') {
        await _accounts.doc(accountIds.first).update({'name': displayName});
      }
    }
  }

  /// Migrate all data from source account to target account (anonymous → email)
  Future<void> migrateAccount(String sourceAccountId, String targetAccountId) async {
    for (final sub in ['wallets', 'transactions', 'categories', 'budgets']) {
      final docs = await _accounts.doc(sourceAccountId).collection(sub).get();
      if (docs.docs.isEmpty) continue;
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.set(
          _accounts.doc(targetAccountId).collection(sub).doc(),
          doc.data(),
        );
      }
      await batch.commit();
    }
  }

  /// Delete an account and all its subcollections
  Future<void> deleteAccount(String accountId) async {
    for (final sub in ['wallets', 'transactions', 'categories', 'budgets', 'activities', 'notification_events']) {
      final docs = await _accounts.doc(accountId).collection(sub).get();
      if (docs.docs.isEmpty) continue;
      final batch = _firestore.batch();
      for (final doc in docs.docs) { batch.delete(doc.reference); }
      await batch.commit();
    }
    await _accounts.doc(accountId).delete();
  }

  /// Cleanup anonymous user's Firestore data (user doc + account)
  Future<void> cleanupAnonymousUser(String userId, String accountId) async {
    // Delete user subcollections
    for (final sub in ['settings', 'fcm_tokens']) {
      final docs = await _users.doc(userId).collection(sub).get();
      if (docs.docs.isEmpty) continue;
      final batch = _firestore.batch();
      for (final doc in docs.docs) { batch.delete(doc.reference); }
      await batch.commit();
    }
    await _users.doc(userId).delete();
    await deleteAccount(accountId);
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

  // ── Invite by email ──

  Future<String?> _findUserIdByEmail(String email) async {
    final doc = await _userEmails.doc(email.toLowerCase()).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>)['user_id'] as String?;
  }

  /// Backfill user_emails index for current user (for accounts created before this feature)
  Future<void> ensureEmailIndex(String userId, String email) async {
    if (email.isEmpty) return;
    final doc = await _userEmails.doc(email.toLowerCase()).get();
    if (!doc.exists) {
      await _userEmails.doc(email.toLowerCase()).set({'user_id': userId});
    }
  }

  Future<void> sendInviteByEmail({
    required String accountId,
    required String email,
  }) async {
    final targetUserId = await _findUserIdByEmail(email);
    if (targetUserId == null) {
      throw Exception('userNotFoundByEmail');
    }
    if (targetUserId == sl.appState.currentUserId) throw Exception('cannotInviteSelf');

    final account = await getAccount(accountId);
    if (account == null) throw Exception('notFound');
    if (account.memberIds.contains(targetUserId)) throw Exception('alreadyMember');

    // Check duplicate pending invite
    final existing = await _pendingInvites
        .where('from_user_id', isEqualTo: sl.appState.currentUserId)
        .where('account_id', isEqualTo: accountId)
        .where('to_user_id', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1).get();
    if (existing.docs.isNotEmpty) throw Exception('inviteAlreadySent');

    await _pendingInvites.add({
      'account_id': accountId,
      'account_name': account.name,
      'from_user_id': sl.appState.currentUserId,
      'to_user_id': targetUserId,
      'to_email': email.toLowerCase(),
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    sl.notificationService.notifyInvite(accountId: accountId, targetUserId: targetUserId);
  }

  Stream<List<Map<String, dynamic>>> watchPendingInvites(String userId) {
    return _pendingInvites
        .where('to_user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList());
  }

  Future<void> acceptInvite(String inviteId) async {
    final doc = await _pendingInvites.doc(inviteId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final accountId = data['account_id'] as String;
    final userId = data['to_user_id'] as String;

    await _accounts.doc(accountId).update({
      'member_ids': FieldValue.arrayUnion([userId]),
    });
    await _users.doc(userId).update({
      'account_ids': FieldValue.arrayUnion([accountId]),
    });
    await _pendingInvites.doc(inviteId).update({'status': 'accepted'});

    logActivity(accountId: accountId, userId: userId, action: 'join', description: 'đã tham gia');
  }

  Future<void> rejectInvite(String inviteId) async {
    await _pendingInvites.doc(inviteId).update({'status': 'rejected'});
  }

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

    for (final seed in kSeedCategories) {
      batch.set(catCol.doc(), {
        'name': seed.name,
        'type': seed.type.value,
        'icon': seed.iconCodePoint,
        'created_at': now,
        'updated_at': now,
      });
    }
    await batch.commit();
  }
}
