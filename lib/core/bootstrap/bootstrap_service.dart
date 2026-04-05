import 'dart:async';
import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/bootstrap/bootstrap_models.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_history.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';

const _stepTimeout = Duration(seconds: 8);

class BootstrapService {
  final LoginIntent? loginIntent;

  BootstrapService({this.loginIntent});

  Stream<BootstrapProgress> run() async* {
    var locale = 'vi';
    var needsLogin = false;
    var needsAccountPick = false;

    // ── Step 0: Auth ──
    yield const BootstrapProgress(step: BootstrapStep.auth, current: 0, labelKey: 'bootstrapAuth');
    try {
      await _runAuth().timeout(_stepTimeout);
    } catch (e) {
      debugPrint('[Bootstrap] Auth error: $e');
      needsLogin = true;
      yield BootstrapProgress(
        step: BootstrapStep.auth, current: 0, labelKey: 'bootstrapAuth', done: true,
        result: BootstrapResult(needsLogin: true, locale: locale),
      );
      return;
    }

    // ── Step 1: Account ──
    yield const BootstrapProgress(step: BootstrapStep.account, current: 1, labelKey: 'bootstrapAccount');
    try {
      needsAccountPick = await _runAccount().timeout(_stepTimeout);
    } catch (e) {
      debugPrint('[Bootstrap] Account error: $e');
      needsLogin = true;
      yield BootstrapProgress(
        step: BootstrapStep.account, current: 1, labelKey: 'bootstrapAccount', done: true,
        result: BootstrapResult(needsLogin: true, locale: locale),
      );
      return;
    }

    // ── Step 2: Settings ──
    yield const BootstrapProgress(step: BootstrapStep.settings, current: 2, labelKey: 'bootstrapSettings');
    try {
      final result = await _runSettings().timeout(_stepTimeout);
      locale = result['locale'] ?? 'vi';
    } catch (e) {
      debugPrint('[Bootstrap] Settings error: $e');
    }

    // ── Step 3: Data ──
    yield const BootstrapProgress(step: BootstrapStep.data, current: 3, labelKey: 'bootstrapData');
    try {
      await _runData().timeout(_stepTimeout);
    } catch (e) {
      debugPrint('[Bootstrap] Data error: $e');
    }

    // ── Step 4: Background (fire-and-forget) ──
    yield const BootstrapProgress(step: BootstrapStep.background, current: 4, labelKey: 'bootstrapAlmost');
    _runBackground();

    // ── Done ──
    yield BootstrapProgress(
      step: BootstrapStep.background, current: 5, labelKey: 'bootstrapAlmost', done: true,
      result: BootstrapResult(
        needsLogin: needsLogin,
        needsAccountPick: needsAccountPick,
        locale: locale,
        returnToTab: loginIntent?.returnToTab,
      ),
    );
  }

  // ── Auth ──

  Future<void> _runAuth() async {
    if (loginIntent != null) {
      // Explicit login flow: logout first, then sign in
      await sl.authService.logout();
      switch (loginIntent!.method) {
        case LoginMethod.google:
          final user = await sl.authService.signInWithGoogle();
          if (user == null) throw Exception('Google sign-in cancelled');
          sl.appState.currentUserId = user.uid;
        case LoginMethod.email:
          final user = await sl.authService.loginWithEmail(
            loginIntent!.email!, loginIntent!.password!,
          );
          if (user == null) throw Exception('Email sign-in failed');
          sl.appState.currentUserId = user.uid;
      }
      return;
    }

    // Normal boot: check existing user
    final user = sl.authService.currentUser;
    if (user != null) {
      sl.appState.currentUserId = user.uid;
      return;
    }
    final anon = await sl.authService.signInAnonymously();
    if (anon != null) {
      sl.appState.currentUserId = anon.uid;
    } else {
      throw Exception('Auth failed');
    }
  }

  // ── Account ──

  Future<bool> _runAccount() async {
    final user = sl.authService.currentUser;
    if (user == null) throw Exception('No user');

    if (user.isAnonymous) {
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, '', 'Anonymous',
      );
      sl.appState.currentAccountId = accountId;
      await _ensureDefaultWallet();
      return false;
    }

    // Logged-in user
    sl.accountService.ensureEmailIndex(user.uid, user.email ?? '');

    // Check last used account first
    final lastAccountId = await sl.settingService.getLastAccountId();
    if (lastAccountId != null && lastAccountId.isNotEmpty) {
      final account = await sl.accountService.getAccount(lastAccountId);
      if (account != null && account.memberIds.contains(user.uid)) {
        sl.appState.currentAccountId = lastAccountId;
        await _syncProfileAndMigrate(user);
        return false;
      }
    }

    // Fallback: resolve personal account
    final accountId = await sl.accountService.getOrCreatePersonalAccountId(
      user.uid, user.email ?? '', user.displayName ?? '',
    );
    sl.appState.currentAccountId = accountId;
    sl.settingService.setLastAccountId(accountId);

    await _syncProfileAndMigrate(user);
    return false;
  }

  Future<void> _syncProfileAndMigrate(dynamic user) async {
    // Sync profile
    await sl.accountService.updateUserProfile(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
    );

    // Migrate anonymous data if needed
    final anonId = loginIntent?.anonAccountIdToMigrate;
    if (anonId != null && anonId.isNotEmpty && anonId != sl.appState.currentAccountId) {
      await sl.accountService.migrateAccount(anonId, sl.appState.currentAccountId);
      await sl.accountService.deleteAccount(anonId);
    }
  }

  Future<void> _ensureDefaultWallet() async {
    final wallets = await sl.walletService.getWallets();
    if (wallets.isEmpty) {
      await sl.walletService.createWallet('Ví chính', 0);
    }
  }

  // ── Settings ──

  Future<Map<String, String?>> _runSettings() async {
    final locale = await sl.settingService.getLocale();
    final lastWalletId = await sl.settingService.getLastWalletId();
    sl.cache.lastWalletId = lastWalletId;
    return {'locale': locale, 'lastWalletId': lastWalletId};
  }

  // ── Data ──

  Future<void> _runData() async {
    final accountId = sl.appState.currentAccountId;
    if (accountId.isEmpty) return;

    final results = await Future.wait([
      sl.categoryService.getCategories(),
      sl.accountService.getAccount(accountId),
    ]);

    final categories = results[0] as List;
    sl.cache.setCategories(categories.cast());

    final account = results[1];
    if (account != null) {
      sl.cache.currentAccount = account as dynamic;
      final memberIds = (account as dynamic).memberIds as List<String>;
      if (memberIds.length > 1) {
        final profiles = await sl.accountService.getMemberProfiles(memberIds);
        sl.cache.memberProfiles = profiles;
        await FeedHelper.preloadNames(memberIds);
      }
    }
  }

  // ── Background ──

  void _runBackground() {
    QuickAddParser.init();
    QuickAddHistory.init();
    AmountHistory.init();
    sl.notificationService.init();
    sl.recurringService.checkAndRun();
  }
}
