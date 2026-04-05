import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/account/models/account.dart';

class AppCache {
  List<Category> categories = [];
  Map<String, String> categoryNameMap = {};
  Account? currentAccount;
  List<Map<String, String>> memberProfiles = [];
  String? lastWalletId;

  void clear() {
    categories = [];
    categoryNameMap = {};
    currentAccount = null;
    memberProfiles = [];
    lastWalletId = null;
  }

  void setCategories(List<Category> cats) {
    categories = cats;
    categoryNameMap = {for (var c in cats) if (c.id != null) c.id!: c.name};
  }
}
