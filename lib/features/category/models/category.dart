import 'package:vintage_ledger/core/enums/transaction_type.dart';

class Category {
  final String? id;
  final String name;
  final TransactionType? type;
  final int? icon;
  final bool isSystem;

  Category({this.id, required this.name, this.type, this.icon, this.isSystem = false});

  Category copyWith({String? id, String? name, TransactionType? type, int? icon, bool? isSystem}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && id == other.id && name == other.name &&
          type == other.type && icon == other.icon && isSystem == other.isSystem;

  @override
  int get hashCode => Object.hash(id, name, type, icon, isSystem);

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
