import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/insights/screens/insights_tab.dart';
import 'package:vintage_ledger/features/settings/screens/setting_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
  }

  static const _tabs = [
    HomeScreen(),
    TransactionListScreen(isTab: true),
    InsightsTab(),
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        
        final currentNavigator = _navigatorKeys[_index].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: List.generate(4, (i) => Navigator(
            key: _navigatorKeys[i],
            onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _tabs[i]),
          )),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
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
      ),
    );
  }
}
