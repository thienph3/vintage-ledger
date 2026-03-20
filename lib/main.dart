import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'widgets/auto_lock_wrapper.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vintage Ledger',

      theme: AppTheme.light,

      locale: const Locale('vi', 'VN'),

      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: Platform.isWindows
          ? const HomeScreen()
          : AutoLockWrapper(child: const HomeScreen()),
    );
  }
}