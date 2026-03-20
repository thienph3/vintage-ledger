import 'package:flutter/material.dart';

import 'package:vintage_ledger/features/auth/screens/lock_screen.dart';

class AutoLockWrapper extends StatefulWidget {
  final Widget child;
  final Duration lockDelay;

  const AutoLockWrapper({
    super.key,
    required this.child,
    this.lockDelay = const Duration(seconds: 10),
  });

  @override
  State<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends State<AutoLockWrapper>
    with WidgetsBindingObserver {

  DateTime? _backgroundTime;
  bool _showingLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    /// Lock ngay khi mở app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {

      _backgroundTime = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {

      if (_backgroundTime == null) return;

      final diff = DateTime.now().difference(_backgroundTime!);

      if (diff > widget.lockDelay) {
        _showLock();
      }
    }
  }

  Future<void> _showLock() async {

    if (_showingLock) return;

    _showingLock = true;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LockScreen(),
      ),
    );

    _showingLock = false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}