import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/insights/screens/insights_tab.dart';
import 'package:vintage_ledger/features/settings/screens/setting_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          TransactionListScreen(isTab: true),
          InsightsTab(),
          SettingScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.inkBlue,
        unselectedItemColor: AppColors.divider,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: S.of(context, 'tabHome'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: S.of(context, 'tabTransactions'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined),
            activeIcon: const Icon(Icons.insights),
            label: S.of(context, 'tabInsights'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: S.of(context, 'tabSettings'),
          ),
        ],
      ),
    );
  }
}
