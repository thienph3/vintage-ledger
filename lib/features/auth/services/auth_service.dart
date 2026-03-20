import 'dart:io';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();

      if (!supported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: _reason(),
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  String _reason() {
    if (Platform.isWindows) {
      return "Xác thực bằng Windows Hello";
    }
    return "Xác thực để mở ứng dụng";
  }
}