import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../l10n/s.dart';
import '../../models/category.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/category_service.dart';

import '../../models/wallet.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

import '../../widgets/amount_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/chart_section.dart';
import '../../widgets/ledger_card.dart';
import '../../widgets/ledger_header.dart';
import '../../widgets/transaction_section.dart';
import '../../widgets/wallet_section.dart';

import '../wallet/wallet_form_screen.dart';
import '../wallet/wallet_detail_screen.dart';
import '../transaction/transaction_form_screen.dart';
import '../settings/setting_screen.dart';

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
  List<TransactionWithItems> transactions = [];
  Map<int, Category> categoryMap = {};

  int totalBalance = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.9,
    );

    loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final w = await walletService.getWallets();
    final t = await transactionService.getTransactionsWithItems();
    final c = await categoryService.getCategories();

    final balance = w.fold<int>(0, (sum, wallet) => sum + wallet.balance);

    setState(() {
      wallets = w;
      transactions = t..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
      categoryMap = {for (var c in c) c.id!: c};
      totalBalance = balance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "",
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LedgerHeader(
                        title: S.of(context, 'homeTitle'),
                        showBackButton: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingScreen()),
                        );
                        loadData();
                      },
                    ),
                  ],
                ),
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
                        child: ChartSection(
                          transactions: transactions,
                        ),
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
                              MaterialPageRoute(builder: (_) => const WalletFormScreen()),
                            );
                            if (result == true) loadData();
                          },
                          onTapWallet: (wallet) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WalletDetailScreen(wallet: wallet)),
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
                          transactions: transactions,
                          categoryMap: categoryMap,
                          onAddTransaction: () async {
                            if (wallets.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(S.of(context, 'createWalletFirst')), backgroundColor: AppColors.divider),
                              );
                              return;
                            }
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
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
                            await transactionService.deleteTransaction(transaction.transaction.id!);
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
