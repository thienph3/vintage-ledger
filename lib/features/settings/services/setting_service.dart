import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class SettingService {
  final _firestore = FirebaseFirestore.instance;

  DocumentReference get _userSettings {
    final userId = sl.appState.currentUserId;
    if (userId == null) throw Exception('Not logged in');
    return _firestore.collection('users').doc(userId).collection('settings').doc('prefs');
  }

  Future<String> getLocale() async {
    try {
      final doc = await _userSettings.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['locale'] ?? 'vi';
      }
    } catch (_) {}
    return 'vi';
  }

  Future<void> setLocale(String locale) async {
    await _userSettings.set({'locale': locale}, SetOptions(merge: true));
  }

  Future<String> getDefaultCurrency() async {
    try {
      final doc = await _userSettings.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['default_currency'] ?? 'VND';
      }
    } catch (_) {}
    return 'VND';
  }

  Future<void> setDefaultCurrency(String currency) async {
    await _userSettings.set({'default_currency': currency}, SetOptions(merge: true));
  }

  Future<String?> getLastAccountId() => getSetting('last_account_id');

  Future<void> setLastAccountId(String accountId) => setSetting('last_account_id', accountId);

  Future<String?> getLastWalletId() => getSetting('last_wallet_id');

  Future<void> setLastWalletId(String walletId) => setSetting('last_wallet_id', walletId);

  Future<String?> getSetting(String key) async {
    try {
      final doc = await _userSettings.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?[key]?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    await _userSettings.set({key: value}, SetOptions(merge: true));
  }

  // ── Streak ──

  /// Record today's usage. Returns current streak count.
  Future<int> recordDailyUsage() async {
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    final lastDate = await getSetting('streak_last_date');
    final streakStr = await getSetting('streak_count');
    var streak = int.tryParse(streakStr ?? '') ?? 0;

    if (lastDate == today) return streak; // already recorded today

    if (lastDate == yesterday) {
      streak++;
    } else {
      streak = 1; // reset
    }

    await _userSettings.set({
      'streak_last_date': today,
      'streak_count': streak.toString(),
    }, SetOptions(merge: true));

    return streak;
  }

  Future<int> getStreak() async {
    final s = await getSetting('streak_count');
    return int.tryParse(s ?? '') ?? 0;
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
