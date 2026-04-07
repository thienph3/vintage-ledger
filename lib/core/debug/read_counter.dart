/// Debug counter for Firestore reads in current session.
class ReadCounter {
  static int _count = 0;
  static final Map<String, int> _perScreen = {};
  static final Map<String, int> _perOperation = {};
  static final Map<String, int> _perCollection = {};
  static String _currentScreen = '';

  static int get count => _count;
  static Map<String, int> get perScreen => Map.unmodifiable(_perScreen);
  static Map<String, int> get perOperation => Map.unmodifiable(_perOperation);
  static Map<String, int> get perCollection => Map.unmodifiable(_perCollection);

  static void setScreen(String name) => _currentScreen = name;

  static void increment([int n = 1]) {
    _count += n;
    if (_currentScreen.isNotEmpty) {
      _perScreen[_currentScreen] = (_perScreen[_currentScreen] ?? 0) + n;
    }
  }

  /// Track specific operations for detailed analysis
  static void trackQuery(String operation, String collection, int count) {
    _count += count;
    _perOperation[operation] = (_perOperation[operation] ?? 0) + count;
    _perCollection[collection] = (_perCollection[collection] ?? 0) + count;
    
    if (_currentScreen.isNotEmpty) {
      final screenKey = '$_currentScreen:$operation';
      _perScreen[screenKey] = (_perScreen[screenKey] ?? 0) + count;
    }
  }

  /// Track batch operations
  static void trackBatchRead(String operation, List<String> collections, int totalCount) {
    _count += totalCount;
    final batchOp = 'batch_$operation';
    _perOperation[batchOp] = (_perOperation[batchOp] ?? 0) + totalCount;
    
    for (final collection in collections) {
      _perCollection[collection] = (_perCollection[collection] ?? 0) + 1;
    }
  }

  static void reset() {
    _count = 0;
    _perScreen.clear();
    _perOperation.clear();
    _perCollection.clear();
  }

  static String get breakdown {
    if (_perScreen.isEmpty && _perOperation.isEmpty) return 'No data';
    
    final buffer = StringBuffer();
    buffer.writeln('=== Read Counter Breakdown ===');
    buffer.writeln('Total reads: $_count');
    
    if (_perScreen.isNotEmpty) {
      buffer.writeln('\nBy Screen:');
      for (final e in _perScreen.entries) {
        buffer.writeln('  ${e.key}: ${e.value}');
      }
    }
    
    if (_perOperation.isNotEmpty) {
      buffer.writeln('\nBy Operation:');
      for (final e in _perOperation.entries) {
        buffer.writeln('  ${e.key}: ${e.value}');
      }
    }
    
    if (_perCollection.isNotEmpty) {
      buffer.writeln('\nBy Collection:');
      for (final e in _perCollection.entries) {
        buffer.writeln('  ${e.key}: ${e.value}');
      }
    }
    
    return buffer.toString();
  }

  /// Export metrics for analysis
  static Map<String, dynamic> exportMetrics() {
    return {
      'total_reads': _count,
      'per_screen': Map.from(_perScreen),
      'per_operation': Map.from(_perOperation),
      'per_collection': Map.from(_perCollection),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get efficiency score (lower is better)
  static double get efficiencyScore {
    if (_perOperation.isEmpty) return 0.0;
    
    final batchOps = _perOperation.keys.where((k) => k.startsWith('batch_')).length;
    final singleOps = _perOperation.keys.where((k) => !k.startsWith('batch_')).length;
    
    if (batchOps + singleOps == 0) return 0.0;
    return singleOps / (batchOps + singleOps);
  }
}
