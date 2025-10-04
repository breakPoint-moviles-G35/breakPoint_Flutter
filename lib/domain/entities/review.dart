class Review {
  final String id;
  final int rating;
  final String? comment;
  final String? authorName;
  final String createdAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      authorName: json['authorName'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}


