import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

class AppCache {
  List<Category> categories = [];
  Map<String, String> categoryNameMap = {};
  List<Wallet> wallets = [];
  Map<String, String> walletNameMap = {};
  Account? currentAccount;
  List<Map<String, dynamic>> memberProfiles = [];
  String? lastWalletId;

  void clear() {
    categories = [];
    categoryNameMap = {};
    wallets = [];
    walletNameMap = {};
    currentAccount = null;
    memberProfiles = [];
    lastWalletId = null;
  }

  void setCategories(List<Category> cats) {
    categories = cats;
    categoryNameMap = {for (var c in cats) if (c.id != null) c.id!: c.name};
  }

  void setWallets(List<Wallet> list) {
    wallets = list;
    walletNameMap = {for (var w in list) if (w.id != null) w.id!: w.name};
  }
}
