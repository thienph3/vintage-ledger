import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {

  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _unlock() async {

    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await _authService.authenticate();

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = "Xác thực thất bại";
      });
    }
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: Center(

          child: Padding(
            padding: const EdgeInsets.all(32),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                const Icon(
                  Icons.lock_outline,
                  size: 80,
                ),

                const SizedBox(height: 24),

                const Text(
                  "Ứng dụng đang bị khóa",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Xác thực để tiếp tục",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(

                    onPressed: _loading ? null : _unlock,

                    icon: const Icon(Icons.fingerprint),

                    label: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Mở khóa"),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _exitApp,
                  child: const Text("Thoát ứng dụng"),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}