class AccountInfo {
  final String username;
  final String email;
  final String favoriteGenre;

  AccountInfo({
    required this.username,
    required this.email,
    required this.favoriteGenre,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'favorite_genre': favoriteGenre,
    };
  }

  factory AccountInfo.fromMap(Map<String, dynamic> map) {
    return AccountInfo(
      username: map['username'],
      email: map['email'],
      favoriteGenre: map['favorite_genre'],
    );
  }
}
