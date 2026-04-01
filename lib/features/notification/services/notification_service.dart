import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/account/screens/join_family_screen.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  /// Initialize: request permission + register token + setup handlers
  Future<void> init() async {
    await _requestPermission();
    await _registerToken();
    _setupHandlers();
  }

  // ── #7: Permission ──

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── #2: Token registration ──

  Future<void> _registerToken() async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _firestore
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(newToken)
          .set({
        'token': newToken,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── #5: Handlers ──

  void _setupHandlers() {
    // Foreground
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background tap (app was in background, user tapped notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App opened from terminated state via notification
    _messaging.getInitialMessage().then((msg) {
      if (msg != null) _handleTap(msg);
    });
  }

  void _handleForeground(RemoteMessage message) {
    // Foreground: show in-app snackbar or local notification
    // For now, just log — Firestore realtime streams already update UI
  }

  // ── #6: Navigate on tap ──

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    switch (type) {
      case 'invite':
        final tokenId = data['token_id'];
        if (tokenId != null) {
          nav.push(MaterialPageRoute(
            builder: (_) => JoinFamilyScreen(tokenId: tokenId),
          ));
        }
      case 'transaction':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      default:
        break;
    }
  }

  /// Remove token on logout
  Future<void> removeToken() async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .delete();
  }
}
