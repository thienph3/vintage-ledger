class Category {
  final int? id;
  final String name;
  final String? type;
  final int? icon;

  Category({this.id, required this.name, this.type, this.icon});

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
}
