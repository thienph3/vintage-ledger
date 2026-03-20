class Category {
  final int? id;
  final String name;
  final int? icon; // mã icon MaterialIcons, nullable nếu muốn dùng mặc định

  Category({
    this.id,
    required this.name,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon, // lưu icon vào map
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'], // đọc icon từ map
    );
  }
}