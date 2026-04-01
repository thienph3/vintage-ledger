import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  Future<User?> signInAnonymously() async {
    final result = await _firebaseAuth.signInAnonymously();
    return result.user;
  }

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

  /// Link anonymous account to email/password (upgrade)
  Future<User?> linkWithEmail(String email, String password, String displayName) async {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    final result = await _firebaseAuth.currentUser?.linkWithCredential(credential);
    await result?.user?.updateDisplayName(displayName);
    return result?.user;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
