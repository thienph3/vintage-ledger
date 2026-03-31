class AppState {
  String? currentUserId;
  String currentAccountId;

  AppState({this.currentUserId, this.currentAccountId = 'local'});

  bool get isLoggedIn => currentUserId != null;
  bool get isLocal => currentAccountId == 'local';
}
