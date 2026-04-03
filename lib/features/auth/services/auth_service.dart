import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vintage_ledger/core/error_mapper.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Check if current user signed in with Google
  bool get isGoogleUser => currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  /// Check if current user signed in with email/password
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
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
      await result.user?.getIdToken(true);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Link current anonymous user with Google account
  Future<User?> linkWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _firebaseAuth.currentUser?.linkWithCredential(credential);
      await result?.user?.getIdToken(true);
      return result?.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Migrate email user to Google: link Google credential to existing account
  Future<User?> linkEmailUserWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _firebaseAuth.currentUser?.linkWithCredential(credential);
      await result?.user?.getIdToken(true);
      return result?.user;
    } on FirebaseAuthException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  // ── Email (deprecated — remove after migration period) ──

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      await result.user?.getIdToken(true);
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
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
