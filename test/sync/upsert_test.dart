import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vintage_ledger/features/sync/repositories/sync_repository.dart';
import 'package:vintage_ledger/core/database.dart';

void main() {
  late SyncRepository syncRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    syncRepo = SyncRepository();
    // Reset DB singleton for each test
    AppDatabase.resetForTest();
  });

  group('upsertByRemoteId', () {
    test('inserts new record when remote_id not found', () async {
      final localId = await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'Test Wallet', 'created_at': 1000, 'updated_at': 100},
      );

      expect(localId, greaterThan(0));

      final db = await AppDatabase.instance.database;
      final rows = await db.query('wallets', where: 'id = ?', whereArgs: [localId]);
      expect(rows.length, 1);
      expect(rows.first['name'], 'Test Wallet');
      expect(rows.first['remote_id'], 'remote_1');
      expect(rows.first['is_synced'], 1);
    });

    test('updates existing record when remote_id found', () async {
      // Insert first
      await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'Old Name', 'created_at': 1000, 'updated_at': 100},
      );

      // Upsert with same remote_id
      final localId = await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'New Name', 'created_at': 1000, 'updated_at': 200},
      );

      final db = await AppDatabase.instance.database;
      final rows = await db.query('wallets', where: 'id = ?', whereArgs: [localId]);
      expect(rows.first['name'], 'New Name');
    });

    test('skips overwrite when local is newer and dirty', () async {
      // Insert synced record
      final localId = await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'Original', 'created_at': 1000, 'updated_at': 100},
      );

      // Mark as dirty with newer updated_at
      final db = await AppDatabase.instance.database;
      await db.update('wallets',
          {'name': 'Local Edit', 'updated_at': 300, 'is_synced': 0},
          where: 'id = ?', whereArgs: [localId]);

      // Try to overwrite with older remote data
      final result = await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'Remote Old', 'created_at': 1000, 'updated_at': 200},
      );

      expect(result, -1); // skipped

      final rows = await db.query('wallets', where: 'id = ?', whereArgs: [localId]);
      expect(rows.first['name'], 'Local Edit'); // kept local
      expect(rows.first['is_synced'], 0); // still dirty
    });

    test('overwrites when remote is newer even if local is dirty', () async {
      final localId = await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'Original', 'created_at': 1000, 'updated_at': 100},
      );

      final db = await AppDatabase.instance.database;
      await db.update('wallets',
          {'name': 'Local Edit', 'updated_at': 200, 'is_synced': 0},
          where: 'id = ?', whereArgs: [localId]);

      // Remote is newer
      final result = await syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: 'remote_1',
        accountId: 'acc_1',
        data: {'name': 'Remote New', 'created_at': 1000, 'updated_at': 300},
      );

      expect(result, localId); // updated

      final rows = await db.query('wallets', where: 'id = ?', whereArgs: [localId]);
      expect(rows.first['name'], 'Remote New');
      expect(rows.first['is_synced'], 1); // marked synced
    });
  });
}
