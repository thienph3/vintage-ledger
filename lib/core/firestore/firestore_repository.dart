import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';

abstract class FirestoreRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get collectionName;

  T fromFirestore(String id, Map<String, dynamic> data);
  Map<String, dynamic> toFirestore(T item);

  CollectionReference<Map<String, dynamic>> _collection(String accountId) =>
      _firestore.collection('accounts').doc(accountId).collection(collectionName);

  String get _accountId => sl.appState.currentAccountId;

  // ── Write ──

  Future<String> add(T item) async {
    final data = toFirestore(item);
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    final doc = await _collection(_accountId).add(data);
    return doc.id;
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection(_accountId).doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await _collection(_accountId).doc(id).delete();
  }

  // ── Read (one-shot) ──

  Future<T?> getById(String id) async {
    final doc = await _collection(_accountId).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return fromFirestore(doc.id, doc.data()!);
  }

  Future<List<T>> getAll({Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>>)? queryBuilder}) async {
    final ref = _collection(_accountId);
    final query = queryBuilder != null ? queryBuilder(ref) : ref;
    final snapshot = await query.get();
    return snapshot.docs.map((d) => fromFirestore(d.id, d.data())).toList();
  }

  // ── Realtime streams ──

  Stream<List<T>> watchAll({Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>>)? queryBuilder}) {
    final ref = _collection(_accountId);
    final query = queryBuilder != null ? queryBuilder(ref) : ref;
    return query.snapshots().map(
      (snap) => snap.docs.map((d) => fromFirestore(d.id, d.data())).toList(),
    );
  }

  Stream<T?> watchById(String id) {
    return _collection(_accountId).doc(id).snapshots().map(
      (doc) => doc.exists && doc.data() != null ? fromFirestore(doc.id, doc.data()!) : null,
    );
  }
}
