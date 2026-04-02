import 'package:vintage_ledger/core/firestore/firestore_repository.dart';
import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';

class RecurringRuleRepository extends FirestoreRepository<RecurringRule> {
  @override
  String get collectionName => 'recurring_rules';

  @override
  RecurringRule fromFirestore(String id, Map<String, dynamic> data) =>
      RecurringRule.fromMap(id, data);

  @override
  Map<String, dynamic> toFirestore(RecurringRule item) => item.toMap();

  Future<List<RecurringRule>> getDueRules(int now) => getAll(
    queryBuilder: (ref) => ref
        .where('enabled', isEqualTo: true)
        .where('next_run_at', isLessThanOrEqualTo: now),
  );
}
