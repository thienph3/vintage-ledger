import 'dart:async';
import 'package:flutter/foundation.dart';

class ListenerManager {
  static final ListenerManager _instance = ListenerManager._internal();
  factory ListenerManager() => _instance;
  ListenerManager._internal();

  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, int> _listenerCounts = {};

  /// Add a listener with automatic deduplication
  void addListener(String key, StreamSubscription subscription) {
    // Cancel existing listener if any
    removeListener(key);
    
    _subscriptions[key] = subscription;
    _listenerCounts[key] = (_listenerCounts[key] ?? 0) + 1;
    
    if (kDebugMode) {
      debugPrint('[ListenerManager] Added listener: $key (total: ${_subscriptions.length})');
    }
  }

  /// Remove a specific listener
  void removeListener(String key) {
    final subscription = _subscriptions.remove(key);
    if (subscription != null) {
      subscription.cancel();
      if (kDebugMode) {
        debugPrint('[ListenerManager] Removed listener: $key (remaining: ${_subscriptions.length})');
      }
    }
  }

  /// Remove all listeners for a specific screen/context
  void removeListenersForScreen(String screenName) {
    final keysToRemove = _subscriptions.keys
        .where((key) => key.startsWith('$screenName:'))
        .toList();
    
    for (final key in keysToRemove) {
      removeListener(key);
    }
  }

  /// Clear all listeners (use on logout/app termination)
  void clearAll() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _listenerCounts.clear();
    
    if (kDebugMode) {
      debugPrint('[ListenerManager] Cleared all listeners');
    }
  }

  /// Get current listener count for debugging
  int get activeListenerCount => _subscriptions.length;

  /// Get listener statistics
  Map<String, int> get listenerStats => Map.unmodifiable(_listenerCounts);

  /// Check if a listener exists
  bool hasListener(String key) => _subscriptions.containsKey(key);

  /// Generate listener key for screens
  static String screenKey(String screenName, String dataType, [String? id]) {
    return id != null ? '$screenName:$dataType:$id' : '$screenName:$dataType';
  }

  /// Generate listener key for global data
  static String globalKey(String dataType, [String? id]) {
    return id != null ? 'global:$dataType:$id' : 'global:$dataType';
  }
}

/// Mixin for screens that use listeners
mixin ListenerMixin {
  final ListenerManager _listenerManager = ListenerManager();
  
  String get screenName;

  void addScreenListener(String dataType, StreamSubscription subscription, [String? id]) {
    final key = ListenerManager.screenKey(screenName, dataType, id);
    _listenerManager.addListener(key, subscription);
  }

  void removeScreenListener(String dataType, [String? id]) {
    final key = ListenerManager.screenKey(screenName, dataType, id);
    _listenerManager.removeListener(key);
  }

  void clearScreenListeners() {
    _listenerManager.removeListenersForScreen(screenName);
  }
}