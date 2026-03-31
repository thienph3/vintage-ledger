class Account {
  final String id;
  final String type;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final int createdAt;

  Account({
    required this.id,
    required this.type,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  bool get isPersonal => type == 'personal';
  bool get isFamily => type == 'family';

  Account copyWith({
    String? id, String? type, String? name,
    String? ownerId, List<String>? memberIds, int? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'name': name,
    'owner_id': ownerId,
    'member_ids': memberIds,
    'created_at': createdAt,
  };

  factory Account.fromMap(String id, Map<String, dynamic> map) => Account(
    id: id,
    type: map['type'] ?? 'personal',
    name: map['name'] ?? '',
    ownerId: map['owner_id'] ?? '',
    memberIds: List<String>.from(map['member_ids'] ?? []),
    createdAt: map['created_at'] ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && id == other.id && type == other.type &&
          name == other.name && ownerId == other.ownerId;

  @override
  int get hashCode => Object.hash(id, type, name, ownerId);

  @override
  String toString() => 'Account(id: $id, type: $type, name: $name)';
}
