import 'package:vintage_ledger/core/enums/transaction_type.dart';

class Category {
  final String? id;
  final String name;
  final TransactionType? type;
  final int? icon;

  Category({this.id, required this.name, this.type, this.icon});

  Category copyWith({String? id, String? name, TransactionType? type, int? icon}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
    );
  }

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
