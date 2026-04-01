import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vintage_ledger/firebase_options.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';
import 'package:vintage_ledger/features/auth/screens/login_screen.dart';
import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
import 'package:vintage_ledger/core/theme/app_theme.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?._setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale _locale = const Locale('vi', 'VN');
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      QuickAddParser.flush();
    }
  }

  Future<void> _init() async {
    // Auto sign-in anonymously if no user
    final user = sl.authService.currentUser;
    if (user != null) {
      sl.appState.currentUserId = user.uid;
      if (!user.isAnonymous) {
        final locale = await sl.settingService.getLocale();
        // Restore last account
        final lastAccountId = await sl.settingService.getLastAccountId();
        if (lastAccountId != null) sl.appState.currentAccountId = lastAccountId;
        await QuickAddParser.init();
        setState(() { _locale = Locale(locale); _ready = true; });
        return;
      }
    }

    if (user == null) {
      final anon = await sl.authService.signInAnonymously();
      if (anon != null) {
        sl.appState.currentUserId = anon.uid;
        final accountId = await sl.accountService.getOrCreatePersonalAccountId(
          anon.uid, '', 'Anonymous',
        );
        sl.appState.currentAccountId = accountId;
        // Auto-create default wallet for first-time user
        await _ensureDefaultWallet();
      }
    } else {
      // Anonymous user already exists
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, '', 'Anonymous',
      );
      sl.appState.currentAccountId = accountId;
    }

    setState(() => _ready = true);
    await QuickAddParser.init();
  }

  Future<void> _ensureDefaultWallet() async {
    final wallets = await sl.walletService.getWallets();
    if (wallets.isEmpty) {
      await sl.walletService.createWallet('Ví chính', 0);
    }
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vintage Ledger',
      theme: AppTheme.light,
      locale: _locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = sl.authService.currentUser;
    if (user == null) return const LoginScreen();

    // Anonymous → straight to Home
    if (user.isAnonymous) return const HomeScreen();

    // Logged in with email → check account count
    sl.appState.currentUserId = user.uid;
    if (sl.appState.hasAccount) return const HomeScreen();
    return const AccountPickerScreen();
  }
}
