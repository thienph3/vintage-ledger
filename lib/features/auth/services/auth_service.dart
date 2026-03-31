import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // ── Firebase Auth ──

  Future<User?> loginWithEmail(String email, String password) async {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> registerWithEmail(String email, String password, String displayName) async {
    final result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await result.user?.updateDisplayName(displayName);
    return result.user;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // ── Biometric (giữ nguyên) ──

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
