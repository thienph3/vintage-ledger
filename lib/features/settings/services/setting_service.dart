import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class SettingService {
  final _firestore = FirebaseFirestore.instance;

  DocumentReference get _userSettings {
    final userId = sl.appState.currentUserId;
    if (userId == null) throw Exception('Not logged in');
    return _firestore.collection('users').doc(userId).collection('settings').doc('prefs');
  }

  /// Load settings from Firestore each time
  Future<Map<String, dynamic>> _loadSettings() async {
    try {
      final doc = await _userSettings.get();
      return (doc.exists ? doc.data() as Map<String, dynamic>? : null) ?? {};
    } catch (_) {
      return {};
    }
  }

  // ── Read ──

  Future<String> getLocale() async {
    final data = await _loadSettings();
    return data['locale']?.toString() ?? 'vi';
  }

  Future<String> getDefaultCurrency() async {
    final data = await _loadSettings();
    return data['default_currency']?.toString() ?? 'VND';
  }

  Future<String?> getLastAccountId() => getSetting('last_account_id');

  Future<String?> getLastWalletId() => getSetting('last_wallet_id');

  Future<String?> getSetting(String key) async {
    final data = await _loadSettings();
    return data[key]?.toString();
  }

  // ── Write ──

  Future<void> setLocale(String locale) => _write({'locale': locale});

  Future<void> setDefaultCurrency(String currency) => _write({'default_currency': currency});

  Future<void> setLastAccountId(String accountId) => setSetting('last_account_id', accountId);

  Future<void> setLastWalletId(String walletId) => setSetting('last_wallet_id', walletId);

  Future<void> setSetting(String key, String value) => _write({key: value});

  Future<void> _write(Map<String, dynamic> data) async {
    await _userSettings.set(data, SetOptions(merge: true));
  }

  // ── Streak ──

  Future<int> recordDailyUsage() async {
    final data = await _loadSettings();
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    final lastDate = data['streak_last_date']?.toString();
    var streak = int.tryParse(data['streak_count']?.toString() ?? '') ?? 0;

    if (lastDate == today) return streak;

    if (lastDate == yesterday) {
      streak++;
    } else {
      streak = 1;
    }

    await _write({
      'streak_last_date': today,
      'streak_count': streak.toString(),
    });

    return streak;
  }

  Future<int> getStreak() async {
    final data = await _loadSettings();
    return int.tryParse(data['streak_count']?.toString() ?? '') ?? 0;
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
