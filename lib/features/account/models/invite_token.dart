class InviteToken {
  final String id;
  final String accountId;
  final String accountName;
  final String createdBy;
  final int createdAt;
  final int expiresAt;

  InviteToken({
    required this.id,
    required this.accountId,
    this.accountName = '',
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  factory InviteToken.fromMap(String id, Map<String, dynamic> map) => InviteToken(
    id: id,
    accountId: map['account_id'] ?? '',
    accountName: map['account_name'] ?? '',
    createdBy: map['created_by'] ?? '',
    createdAt: map['created_at'] ?? 0,
    expiresAt: map['expires_at'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'account_id': accountId,
    'account_name': accountName,
    'created_by': createdBy,
    'created_at': createdAt,
    'expires_at': expiresAt,
  };
}
