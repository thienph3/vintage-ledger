/// Debug counter for Firestore reads in current session.
/// Only for development — remove or disable in production.
class ReadCounter {
  static int _count = 0;

  static int get count => _count;

  static void increment([int n = 1]) => _count += n;

  static void reset() => _count = 0;
}
