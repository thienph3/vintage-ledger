enum BootstrapStep { auth, account, settings, data, background }

class BootstrapProgress {
  final BootstrapStep step;
  final int current;
  final int total;
  final String labelKey;
  final bool done;
  final String? error;
  final BootstrapResult? result;

  const BootstrapProgress({
    required this.step,
    required this.current,
    this.total = 5,
    required this.labelKey,
    this.done = false,
    this.error,
    this.result,
  });
}

class BootstrapResult {
  final bool needsLogin;
  final bool needsAccountPick;
  final String locale;

  const BootstrapResult({
    this.needsLogin = false,
    this.needsAccountPick = false,
    this.locale = 'vi',
  });
}
