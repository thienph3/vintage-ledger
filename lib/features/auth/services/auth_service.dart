import 'package:firebase_auth/firebase_auth.dart';
import 'package:vintage_ledger/core/error_mapper.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final _googleProvider = GoogleAuthProvider();

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  bool get isGoogleUser => currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  bool get isEmailUser => currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

  // ── Anonymous ──

  Future<User?> signInAnonymously() async {
    try {
      final result = await _firebaseAuth.signInAnonymously();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  // ── Google SSO ──

  Future<User?> signInWithGoogle() async {
    try {
      final result = await _firebaseAuth.signInWithProvider(_googleProvider);
      await result.user?.getIdToken(true);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<User?> linkWithGoogle() async {
    try {
      final result = await _firebaseAuth.currentUser?.linkWithProvider(_googleProvider);
      await result?.user?.getIdToken(true);
      return result?.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<User?> linkEmailUserWithGoogle() async {
    try {
      final result = await _firebaseAuth.currentUser?.linkWithProvider(_googleProvider);
      await result?.user?.getIdToken(true);
      return result?.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  // ── Email (deprecated) ──

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      await result.user?.getIdToken(true);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<User?> registerWithEmail(String email, String password, String displayName) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      await result.user?.updateDisplayName(displayName);
      await result.user?.getIdToken(true);
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
      await result?.user?.getIdToken(true);
      return result?.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  // ── Logout ──

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
