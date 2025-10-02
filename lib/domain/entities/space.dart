class Space {
  final String id;
  final String title;
  final String subtitle;
  final double rating;
  final double price; // COP por 30m
  final String imageUrl;

  Space({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.price,
    required this.imageUrl,
  });
}
