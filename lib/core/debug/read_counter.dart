/// Debug counter for Firestore reads in current session.
class ReadCounter {
  static int _count = 0;
  static final Map<String, int> _perScreen = {};
  static String _currentScreen = '';

  static int get count => _count;
  static Map<String, int> get perScreen => Map.unmodifiable(_perScreen);

  static void setScreen(String name) => _currentScreen = name;

  static void increment([int n = 1]) {
    _count += n;
    if (_currentScreen.isNotEmpty) {
      _perScreen[_currentScreen] = (_perScreen[_currentScreen] ?? 0) + n;
    }
  }

  static void reset() {
    _count = 0;
    _perScreen.clear();
  }

  static String get breakdown {
    if (_perScreen.isEmpty) return 'No data';
    return _perScreen.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}
