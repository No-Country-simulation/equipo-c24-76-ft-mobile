class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> likes;
  final List<Comment> comments;
  final String? location;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
    this.location,
  });
}

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });
} 