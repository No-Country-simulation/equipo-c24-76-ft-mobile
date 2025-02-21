class User {
  final String id;
  final String email;
  final String username;
  final String? profilePicture;
  final List<String> followers;
  final List<String> following;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePicture,
    this.followers = const [],
    this.following = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      profilePicture: json['profilePicture'],
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
} 