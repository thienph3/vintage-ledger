import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/account/screens/join_family_screen.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';

/// Notification service using client-side FCM push (legacy HTTP API).
///
/// ⚠️ TEMPORARY: FCM server key stored in Firestore, fetched on init.
/// TODO: Migrate to Cloud Functions when switching to Blaze plan.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  String? _serverKey;

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  Future<void> init() async {
    await _requestPermission();
    await _registerToken();
    await _fetchServerKey();
    _setupHandlers();
  }

  // ── Fetch server key from Firestore ──

  Future<void> _fetchServerKey() async {
    try {
      final doc = await _firestore.collection('config').doc('fcm').get();
      _serverKey = doc.data()?['server_key'] as String?;
    } catch (_) {}
  }

  // ── Permission ──

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  // ── Token registration ──

  Future<void> _registerToken() async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(userId)
        .collection('fcm_tokens').doc(token)
        .set({'token': token, 'updated_at': FieldValue.serverTimestamp()});

    _messaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(userId)
          .collection('fcm_tokens').doc(newToken)
          .set({'token': newToken, 'updated_at': FieldValue.serverTimestamp()});
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
        final tokenId = data['token_id'];
        if (tokenId != null) {
          nav.push(MaterialPageRoute(builder: (_) => JoinFamilyScreen(tokenId: tokenId)));
        }
      case 'transaction':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
    }
  }

  // ── Client-side FCM push ──

  /// Collect FCM tokens for target users (excluding current user)
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

  /// Send FCM notification via legacy HTTP API
  Future<void> _sendPush({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (tokens.isEmpty || _serverKey == null) return;

    // FCM legacy API supports max 1000 tokens per request
    for (var i = 0; i < tokens.length; i += 1000) {
      final batch = tokens.skip(i).take(1000).toList();
      try {
        await http.post(
          Uri.parse(_fcmUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$_serverKey',
          },
          body: jsonEncode({
            'registration_ids': batch,
            'notification': {'title': title, 'body': body},
            'data': data,
          }),
        );
      } catch (_) {
        // Silent fail — notification is best-effort
      }
    }
  }

  // ── Public API ──

  /// Notify family members about a new invite
  Future<void> notifyInvite({
    required String accountId,
    required String tokenId,
  }) async {
    final account = await sl.accountService.getAccount(accountId);
    if (account == null) return;

    final tokens = await _getTokensForUsers(account.memberIds);
    await _sendPush(
      tokens: tokens,
      title: account.name,
      body: 'Có link mời mới',
      data: {'type': 'invite', 'token_id': tokenId},
    );
  }

  /// Notify family members about a new transaction
  Future<void> notifyTransaction({
    required String accountId,
    required int amount,
    required String type,
  }) async {
    final account = await sl.accountService.getAccount(accountId);
    if (account == null || account.type != 'family') return;

    final action = type == 'income' ? 'thu' : 'chi';
    final tokens = await _getTokensForUsers(account.memberIds);
    await _sendPush(
      tokens: tokens,
      title: account.name,
      body: 'Giao dịch mới: $action $amount',
      data: {'type': 'transaction', 'account_id': accountId},
    );
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
