class Review {
  final String id;
  final String spaceId;
  final String userId;
  final String text;
  final double rating;
  final String? userName;
  final String? userEmail;

  Review({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.text,
    required this.rating,
    this.userName,
    this.userEmail,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      spaceId: json['space_id'] ?? '',
      userId: json['user_id'] ?? '',
      text: json['text'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      userName: json['user']?['name'] ?? '',
      userEmail: json['user']?['email'] ?? '',
    );
  }
}
