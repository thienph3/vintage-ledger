import 'dart:io';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    print(await _auth.canCheckBiometrics);
    print(await _auth.isDeviceSupported());
    print(await _auth.getAvailableBiometrics());
    try {
      final supported = await _auth.isDeviceSupported();

      if (!supported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: _reason(),
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      print("Auth error: ${e.code}");
      return false;
    } catch (e) {
      print("Auth error: $e");
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