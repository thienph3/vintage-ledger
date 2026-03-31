class Account {
  final String id;
  final String type; // 'personal' | 'family'
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
}
