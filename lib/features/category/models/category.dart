import 'package:vintage_ledger/core/enums/transaction_type.dart';

class Category {
  final int? id;
  final String name;
  final TransactionType? type;
  final int? icon;
  final String accountId;
  final int isSynced;
  final String? remoteId;

  Category({
    this.id,
    required this.name,
    this.type,
    this.icon,
    this.accountId = 'local',
    this.isSynced = 1,
    this.remoteId,
  });

  Category copyWith({
    int? id, String? name, TransactionType? type, int? icon,
    String? accountId, int? isSynced, String? remoteId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      accountId: accountId ?? this.accountId,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type?.value,
    'icon': icon,
    'account_id': accountId,
    'is_synced': isSynced,
    'remote_id': remoteId,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'],
    type: map['type'] != null ? TransactionType.fromString(map['type'] as String) : null,
    icon: map['icon'],
    accountId: map['account_id'] ?? 'local',
    isSynced: map['is_synced'] ?? 1,
    remoteId: map['remote_id'],
  );

  bool get isDirty => isSynced == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && id == other.id && name == other.name &&
          type == other.type && icon == other.icon;

  @override
  int get hashCode => Object.hash(id, name, type, icon);

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
