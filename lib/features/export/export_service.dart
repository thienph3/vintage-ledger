import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

class ExportService {
  final TransactionRepository _txnRepo = TransactionRepository();

  /// Export all transactions to CSV string, return temp file path
  Future<String> exportTransactionsCsv() async {
    // Load all transactions
    final txns = await _txnRepo.getAll(
      queryBuilder: (ref) => ref.orderBy('date', descending: true),
    );

    // Resolve names
    final categories = await sl.categoryService.getCategories();
    final catMap = {for (var c in categories) c.id!: c.name};
    final wallets = await sl.walletService.getWallets();
    final walletMap = {for (var w in wallets) w.id!: w.name};

    // Build CSV
    final buf = StringBuffer();
    // UTF-8 BOM for Excel
    buf.write('\uFEFF');
    buf.writeln('Date,Type,Amount,Category,Wallet,Note');

    for (final t in txns) {
      final txn = t.transaction;
      final date = DateFormatter.fullDate(txn.date);
      final time = DateFormatter.time(txn.date);
      final cat = catMap[txn.categoryId] ?? '';
      final wallet = walletMap[txn.walletId] ?? '';
      final note = _escapeCsv(txn.note ?? '');
      buf.writeln('$date $time,${txn.type.value},${txn.amount},$cat,$wallet,$note');
    }

    // Write to temp file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vintage_ledger_export.csv');
    await file.writeAsString(buf.toString());
    return file.path;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
