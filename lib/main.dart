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

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('vi', 'VN');
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Auto sign-in anonymously if no user
    final user = sl.authService.currentUser;
    if (user != null) {
      sl.appState.currentUserId = user.uid;
      if (!user.isAnonymous) {
        // Logged-in user → load locale, go to account picker
        final locale = await sl.settingService.getLocale();
        setState(() { _locale = Locale(locale); _ready = true; });
        return;
      }
    }

    if (user == null) {
      final anon = await sl.authService.signInAnonymously();
      if (anon != null) {
        sl.appState.currentUserId = anon.uid;
        // Create personal account for anonymous user
        final accountId = await sl.accountService.getOrCreatePersonalAccountId(
          anon.uid, '', 'Anonymous',
        );
        sl.appState.currentAccountId = accountId;
      }
    } else {
      // Anonymous user already exists
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, '', 'Anonymous',
      );
      sl.appState.currentAccountId = accountId;
    }

    setState(() => _ready = true);
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

    // Logged in with email → Account picker
    sl.appState.currentUserId = user.uid;
    return const AccountPickerScreen();
  }
}
