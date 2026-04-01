import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  static const _maxRetries = 2;
  static const _retryDelays = [Duration(milliseconds: 500), Duration(seconds: 1)];

  String? _serverKey;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// #1: Deduplication — track recently sent event IDs (TTL 60s)
  final Map<String, DateTime> _sentEvents = {};

  void setNavigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  Future<void> init() async {
    await _requestPermission();
    await _registerToken();
    await _fetchServerKey();
    _setupHandlers();
    _cleanupOldNotificationEvents();
  }

  Future<void> _fetchServerKey() async {
    try {
      final doc = await _firestore.collection('config').doc('fcm').get();
      _serverKey = doc.data()?['server_key'] as String?;
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  // ── #5: Token registration (prevent duplicates) ──

  Future<void> _registerToken() async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final tokensRef = _firestore.collection('users').doc(userId).collection('fcm_tokens');

    // Remove all existing tokens for this device, then set current
    final existing = await tokensRef.get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      if (doc.id != token) batch.delete(doc.reference);
    }
    batch.set(tokensRef.doc(token), {
      'token': token,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    _messaging.onTokenRefresh.listen((newToken) {
      // Old token auto-replaced
      tokensRef.doc(token).delete();
      tokensRef.doc(newToken).set({
        'token': newToken,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Handlers ──

  void _setupHandlers() {
    FirebaseMessaging.onMessage.listen((_) {});
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    _messaging.getInitialMessage().then((msg) {
      if (msg != null) _handleTap(msg);
    });
  }

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    switch (data['type']) {
      case 'invite':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      case 'transaction':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
    }
  }

  // ── #2: Collect tokens (exclude self) ──

  Future<List<String>> _getTokensForUsers(List<String> userIds) async {
    final currentUserId = sl.appState.currentUserId;
    final tokens = <String>[];

    for (final userId in userIds) {
      if (userId == currentUserId) continue;
      final snap = await _firestore.collection('users').doc(userId)
          .collection('fcm_tokens').get();
      for (final doc in snap.docs) {
        final token = doc.data()['token'] as String?;
        if (token != null) tokens.add(token);
      }
    }
    return tokens;
  }

  // ── Deduplication: in-memory fast path + Firestore cross-device lock ──

  bool _isDuplicateLocal(String eventId) {
    _cleanExpiredEvents();
    if (_sentEvents.containsKey(eventId)) return true;
    _sentEvents[eventId] = DateTime.now();
    return false;
  }

  /// Cross-device dedup via Firestore lock doc
  Future<bool> _acquireNotificationLock(String accountId, String eventId) async {
    if (_isDuplicateLocal(eventId)) return false;

    try {
      final ref = _firestore.collection('accounts').doc(accountId)
          .collection('notification_events').doc(eventId);

      return await _firestore.runTransaction<bool>((txn) async {
        final snap = await txn.get(ref);
        if (snap.exists) return false; // another device already sent
        txn.set(ref, {'created_at': FieldValue.serverTimestamp()});
        return true;
      });
    } catch (e) {
      _log('Lock failed for $eventId: $e');
      return true; // on error, proceed (best effort)
    }
  }

  void _cleanExpiredEvents() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 60));
    _sentEvents.removeWhere((_, time) => time.isBefore(cutoff));
  }

  // ── #3: Send with retry + #4: stale token cleanup + #6: debug logging ──

  Future<void> _sendPush({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (tokens.isEmpty || _serverKey == null) return;

    for (var i = 0; i < tokens.length; i += 1000) {
      final batch = tokens.skip(i).take(1000).toList();
      await _sendWithRetry(batch, title, body, data);
    }
  }

  Future<void> _sendWithRetry(
    List<String> tokens, String title, String body, Map<String, String> data,
  ) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_fcmUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$_serverKey',
          },
          body: jsonEncode({
            'registration_ids': tokens,
            'notification': {'title': title, 'body': body},
            'data': data,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _handleFcmResponse(response.body, tokens);
          return;
        }

        if (attempt < _maxRetries) {
          _log('FCM retry ${attempt + 1}: status ${response.statusCode}');
          await Future.delayed(_retryDelays[attempt]);
        }
      } catch (e) {
        if (attempt < _maxRetries) {
          _log('FCM retry ${attempt + 1}: $e');
          await Future.delayed(_retryDelays[attempt]);
        } else {
          _log('FCM failed after $_maxRetries retries: $e');
        }
      }
    }
  }

  /// #4: Parse FCM response, remove stale tokens
  void _handleFcmResponse(String responseBody, List<String> tokens) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>? ?? [];

      for (var i = 0; i < results.length && i < tokens.length; i++) {
        final result = results[i] as Map<String, dynamic>;
        final error = result['error'] as String?;
        if (error == 'InvalidRegistration' || error == 'NotRegistered') {
          _removeStaleToken(tokens[i]);
        }
      }
    } catch (_) {}
  }

  void _removeStaleToken(String token) {
    // Find and delete this token across all users (best effort)
    _log('Removing stale token: ${token.substring(0, 10)}...');
    // We only know our own tokens collection, so just try to delete
    final userId = sl.appState.currentUserId;
    if (userId != null) {
      _firestore.collection('users').doc(userId)
          .collection('fcm_tokens').doc(token).delete();
    }
  }

  /// #6: Debug logging
  void _log(String message) {
    if (kDebugMode) debugPrint('[FCM] $message');
  }

  /// TTL cleanup: delete notification_events > 3 days (1x/day)
  Future<void> _cleanupOldNotificationEvents() async {
    final accountId = sl.appState.currentAccountId;
    if (accountId.isEmpty) return;

    final key = 'notif_cleanup_$accountId';
    final last = await sl.settingService.getSetting(key);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last != null && now - (int.tryParse(last) ?? 0) < 86400000) return; // < 1 day

    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
      final old = await _firestore.collection('accounts').doc(accountId)
          .collection('notification_events')
          .where('created_at', isLessThan: Timestamp.fromMillisecondsSinceEpoch(cutoff))
          .limit(50).get();

      if (old.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in old.docs) { batch.delete(doc.reference); }
        await batch.commit();
      }

      await sl.settingService.setSetting(key, now.toString());
    } catch (_) {}
  }

  // ── Public API ──

  // ── Anti-spam debounce ──

  int _pendingTxnCount = 0;
  Timer? _txnDebounceTimer;

  Future<void> notifyInvite({
    required String accountId,
    required String targetUserId,
  }) async {
    final tokens = await _getTokensForUsers([targetUserId]);
    await _sendPush(
      tokens: tokens,
      title: 'Lời mời gia đình',
      body: 'Bạn có lời mời tham gia sổ thu chi gia đình',
      data: {'type': 'invite', 'account_id': accountId},
    );
  }

  Future<void> notifyTransaction({
    required String accountId,
    required int amount,
    required String type,
    String? transactionId,
    String? categoryName,
  }) async {
    final eventId = 'txn_${transactionId ?? DateTime.now().millisecondsSinceEpoch}';
    if (!await _acquireNotificationLock(accountId, eventId)) return;

    final account = await sl.accountService.getAccount(accountId);
    if (account == null || account.type != 'family') return;

    // Debounce: batch rapid transactions
    _pendingTxnCount++;
    _txnDebounceTimer?.cancel();
    _txnDebounceTimer = Timer(const Duration(seconds: 2), () async {
      final tokens = await _getTokensForUsers(account.memberIds);
      final body = _pendingTxnCount > 1
          ? 'Có $_pendingTxnCount giao dịch mới'
          : _buildTxnBody(type, amount, categoryName);
      await _sendPush(
        tokens: tokens,
        title: account.name,
        body: body,
        data: {'type': 'transaction', 'account_id': accountId, 'event_id': eventId},
      );
      _pendingTxnCount = 0;
    });
  }

  String _buildTxnBody(String type, int amount, String? categoryName) {
    final action = type == 'income' ? 'thu' : 'chi';
    final cat = categoryName != null ? ' $categoryName' : '';
    return 'Giao dịch mới: $action $amount$cat';
  }

  Future<void> removeToken() async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(userId)
        .collection('fcm_tokens').doc(token).delete();
  }
}
