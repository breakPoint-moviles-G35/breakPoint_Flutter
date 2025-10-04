class Host {
  final String id;
  final String? name;
  final String? avatarUrl;
  final double? rating;
  final bool? isSuperhost;
  final int? reviewsCount;
  final int? monthsHosting;
  final String? born;
  final String? location;
  final String? work;

  Host({
    required this.id,
    this.name,
    this.avatarUrl,
    this.rating,
    this.isSuperhost,
    this.reviewsCount,
    this.monthsHosting,
    this.born,
    this.location,
    this.work,
  });

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'] ?? '',
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? "0"),
      isSuperhost: json['isSuperhost'] ?? false,
      reviewsCount: json['reviewsCount'] ?? 0,
      monthsHosting: json['monthsHosting'] ?? 0,
      born: json['born'] ?? 'Born in the 80s',
      location: json['location'] ?? 'Bogotá, Colombia',
      work: json['work'] ?? 'Host',
    );
  }

  // Métodos helper para obtener valores con fallbacks
  String get displayBorn => born ?? 'Born in the 80s';
  String get displayLocation => location ?? 'Bogotá, Colombia';
  String get displayWork => work ?? 'Host';
  String get displayName => name ?? 'Host';
  
  // Solo mostrar rating si hay reviews
  double? get displayRating => (reviewsCount != null && reviewsCount! > 0) ? rating : null;
  
  bool get displayIsSuperhost => isSuperhost ?? false;
  int get displayReviewsCount => reviewsCount ?? 0;
  int get displayMonthsHosting => monthsHosting ?? 0;
  
  // Método para verificar si tiene reviews
  bool get hasReviews => displayReviewsCount > 0;
}


