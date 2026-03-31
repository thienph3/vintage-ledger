class Category {
  final int? id;
  final String name;
  final String? type;
  final int? icon;

  Category({this.id, required this.name, this.type, this.icon});

  Category copyWith({int? id, String? name, String? type, int? icon}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      icon: map['icon'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          icon == other.icon;

  @override
  int get hashCode => Object.hash(id, name, type, icon);

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
