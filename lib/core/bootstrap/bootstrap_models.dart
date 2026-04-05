enum BootstrapStep { auth, account, settings, data, background }

enum LoginMethod { google, email }

class LoginIntent {
  final LoginMethod method;
  final String? anonAccountIdToMigrate;
  final int? returnToTab;
  final String? email;
  final String? password;

  const LoginIntent({
    required this.method,
    this.anonAccountIdToMigrate,
    this.returnToTab,
    this.email,
    this.password,
  });
}

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
  final int? returnToTab;

  const BootstrapResult({
    this.needsLogin = false,
    this.needsAccountPick = false,
    this.locale = 'vi',
    this.returnToTab,
  });
}
