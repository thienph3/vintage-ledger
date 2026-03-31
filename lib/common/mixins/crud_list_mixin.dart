import 'package:flutter/material.dart';

import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

mixin CrudListMixin<T> on State {
  List<T> items = [];
  bool crudLoading = true;
  String? crudError;

  Future<List<T>> fetchItems();
  Future<void> removeItem(T item);
  int itemId(T item);
  Widget formScreen({T? item});
  String get deleteTitle;
  String get deleteContent;

  Future<void> loadItems() async {
    try {
      final list = await fetchItems();
      setState(() {
        items = list;
        crudLoading = false;
        crudError = null;
      });
    } catch (e) {
      setState(() {
        crudLoading = false;
        crudError = e.toString();
      });
    }
  }

  Future<void> deleteItem(T item) async {
    await removeItem(item);
    loadItems();
  }

  Future<bool?> confirmDelete() {
    return showDeleteConfirmation(
      context,
      titleKey: deleteTitle,
      contentKey: deleteContent,
    );
  }

  Future<void> openForm({T? item}) async {
    final result = await context.pushScreen(formScreen(item: item));
    if (result == true) loadItems();
  }
}
