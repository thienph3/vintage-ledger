import 'package:firebase_auth/firebase_auth.dart';
import 'package:vintage_ledger/core/error_mapper.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  Future<User?> signInAnonymously() async {
    try {
      final result = await _firebaseAuth.signInAnonymously();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<User?> registerWithEmail(String email, String password, String displayName) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await result.user?.updateDisplayName(displayName);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<User?> linkWithEmail(String email, String password, String displayName) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      final result = await _firebaseAuth.currentUser?.linkWithCredential(credential);
      await result?.user?.updateDisplayName(displayName);
      return result?.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
