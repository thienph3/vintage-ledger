import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/common/widgets/auto_lock_wrapper.dart';
import 'package:vintage_ledger/features/home_screen.dart';
import 'package:vintage_ledger/features/onboarding/welcome_screen.dart';
import 'package:vintage_ledger/core/theme/app_theme.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
  bool? _setupDone;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final code = await sl.settingService.getLocale();
    final done = await sl.settingService.isSetupDone();
    setState(() {
      _locale = Locale(code);
      _setupDone = done;
    });
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
    // Still loading settings
    if (_setupDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screen = _setupDone! ? const HomeScreen() : const WelcomeScreen();

    if (Platform.isWindows) return screen;
    return AutoLockWrapper(child: screen);
  }
}
