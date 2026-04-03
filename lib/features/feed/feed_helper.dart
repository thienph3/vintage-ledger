import 'package:vintage_ledger/core/service_locator.dart';

class FeedHelper {
  static Map<String, String> _nameCache = {};

  static void clearCache() => _nameCache = {};

  static Future<void> preloadNames(List<String> userIds) async {
    final missing = userIds.where((id) => !_nameCache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final profiles = await sl.accountService.getMemberProfiles(missing);
    for (final p in profiles) {
      _nameCache[p['id']!] = p['name'] ?? '?';
    }
  }

  static String resolveName(String? userId, String youLabel) {
    if (userId == null) return '';
    if (userId == sl.appState.currentUserId) return youLabel;
    return _nameCache[userId] ?? '?';
  }
}
