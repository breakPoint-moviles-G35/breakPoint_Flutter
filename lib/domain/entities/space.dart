class Space {
  final String id;
  final String title;
  final String? subtitle;
  final String? geo;
  final int capacity;
  final List<String> amenities;
  final List<String>? accessibility;
  final String rules;
  final double price;
  double rating;
  final String imageUrl;

  Space({
    required this.id,
    required this.title,
    this.subtitle,
    this.geo,
    required this.capacity,
    required this.amenities,
    this.accessibility,
    required this.rules,
    required this.price,
    required this.rating,
    required this.imageUrl, 
  });

  
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      geo: json['geo'],
      capacity: json['capacity'] ?? 0,
      amenities: (json['amenities'] as List?)?.map((a) => a.toString()).toList() ?? [],
      accessibility: (json['accessibility'] as List?)?.map((a) => a.toString()).toList(),
      rules: json['rules'] ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? "0") ?? 0.0,
      rating: (json['rating_avg'] is num)
          ? (json['rating_avg'] as num).toDouble()
          : double.tryParse(json['rating_avg']?.toString() ?? "0") ?? 0.0,
      imageUrl: json['imageUrl'] ?? '', 
    );
  }
}
