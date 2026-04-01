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
}
