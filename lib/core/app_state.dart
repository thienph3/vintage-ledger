class AppState {
  String? currentUserId;
  String currentAccountId;

  AppState({this.currentUserId, this.currentAccountId = ''});

  bool get isLoggedIn => currentUserId != null;
  bool get isAnonymous => currentAccountId.isNotEmpty && currentUserId != null;
  bool get hasAccount => currentAccountId.isNotEmpty;
}
