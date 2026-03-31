class Wallet {
  final int? id;
  final String name;
  final int balance;
  final int createdAt;
  final String accountId;
  final int isSynced;
  final String? remoteId;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0,
    required this.createdAt,
    this.accountId = 'local',
    this.isSynced = 1,
    this.remoteId,
  });

  Wallet copyWith({
    int? id, String? name, int? balance, int? createdAt,
    String? accountId, int? isSynced, String? remoteId,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      accountId: accountId ?? this.accountId,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'balance': balance,
    'created_at': createdAt,
    'account_id': accountId,
    'is_synced': isSynced,
    'remote_id': remoteId,
  };

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
    id: map['id'],
    name: map['name'],
    balance: map['balance'],
    createdAt: map['created_at'] is int
        ? map['created_at']
        : int.tryParse(map['created_at'].toString()) ?? 0,
    accountId: map['account_id'] ?? 'local',
    isSynced: map['is_synced'] ?? 1,
    remoteId: map['remote_id'],
  );

  bool get isDirty => isSynced == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && id == other.id && name == other.name &&
          balance == other.balance && createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, balance, createdAt);

  @override
  String toString() => 'Wallet(id: $id, name: $name, balance: $balance)';
}
