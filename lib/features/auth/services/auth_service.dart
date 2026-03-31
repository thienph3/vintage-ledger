import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
