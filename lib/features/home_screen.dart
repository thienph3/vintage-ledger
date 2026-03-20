import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';

import 'package:vintage_ledger/features/wallet/models/wallet.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_section.dart';

import 'package:vintage_ledger/features/wallet/widgets/wallet_section.dart';

import 'package:vintage_ledger/features/wallet/screens/wallet_form_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_detail_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/settings/screens/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService walletService = WalletService();
  final TransactionService transactionService = TransactionService();
  final CategoryService categoryService = CategoryService();
  late final PageController _pageController;

  List<Wallet> wallets = [];
  List<TransactionWithItems> recentTransactions = [];
  List<TransactionWithItems> monthTransactions = [];
  Map<int, Category> categoryMap = {};

  int totalBalance = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.9);

    loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final w = await walletService.getWallets();
    final recent = await transactionService.getRecentWithItems(5);
    final month = await transactionService.getByDateRangeWithItems(
      monthStart.millisecondsSinceEpoch,
      monthEnd.millisecondsSinceEpoch,
    );
    final c = await categoryService.getCategories();

    setState(() {
      wallets = w;
      recentTransactions = recent;
      monthTransactions = month;
      categoryMap = {for (var c in c) c.id!: c};
      totalBalance = w.fold<int>(0, (sum, wallet) => sum + wallet.balance);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'homeTitle'),
      showBackButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingScreen(),
              ),
            );
            loadData();
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  S.of(context, 'totalBalance'),
                  style: AppTextStyles.body,
                ),
                const SizedBox(width: AppSpacing.md),
                AmountText(
                  amount: totalBalance.abs(),
                  type: totalBalance >= 0 ? "income" : "expense",
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 350,
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: PageView(
                  controller: _pageController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: LedgerCard(
                        child: ChartSection(transactions: monthTransactions),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: LedgerCard(
                        child: WalletSection(
                          wallets: wallets,
                          onAddWallet: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WalletFormScreen(),
                              ),
                            );
                            if (result == true) loadData();
                          },
                          onTapWallet: (wallet) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WalletDetailScreen(wallet: wallet),
                              ),
                            );
                            loadData();
                          },
                          onDeleteWallet: (wallet) async {
                            await walletService.deleteWallet(wallet.id!);
                            loadData();
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: LedgerCard(
                        child: TransactionSection(
                          transactions: recentTransactions,
                          categoryMap: categoryMap,
                          onAddTransaction: () async {
                            if (wallets.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    S.of(context, 'createWalletFirst'),
                                  ),
                                  backgroundColor: AppColors.divider,
                                ),
                              );
                              return;
                            }
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionFormScreen(),
                              ),
                            );
                            if (result == true) loadData();
                          },
                          onTapTransaction: (transaction) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionFormScreen(
                                  walletId: transaction.transaction.walletId,
                                  transaction: transaction.transaction,
                                ),
                              ),
                            );
                            loadData();
                          },
                          onDeleteTransaction: (transaction) async {
                            await transactionService.deleteTransaction(
                              transaction.transaction.id!,
                            );
                            loadData();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: AppColors.inkBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
