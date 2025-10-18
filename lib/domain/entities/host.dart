class Host {
  final String id;
  final String verificationStatus;
  final String payoutMethod;
  final String userId;
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>>? spaces;

  Host({
    required this.id,
    required this.verificationStatus,
    required this.payoutMethod,
    required this.userId,
    this.user,
    this.spaces,
  });

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'] ?? '',
      verificationStatus: json['verification_status'] ?? '',
      payoutMethod: json['payout_method'] ?? '',
      userId: json['user_id'] ?? '',
      user: json['user'] as Map<String, dynamic>?,
      spaces: (json['spaces'] as List?)?.cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verification_status': verificationStatus,
      'payout_method': payoutMethod,
      'user_id': userId,
      'user': user,
      'spaces': spaces,
    };
  }

  // Métodos auxiliares para mostrar en UI
  String get userName {
    if (user != null) {
      final firstName = user!['name']?.toString().split(' ').first ?? '';
      final lastName = user!['name']?.toString().split(' ').length > 1 
          ? user!['name']?.toString().split(' ').last ?? ''
          : '';
      return '$firstName $lastName'.trim();
    }
    return 'Host';
  }

  String get firstName {
    if (user != null) {
      return user!['name']?.toString().split(' ').first ?? 'Host';
    }
    return 'Host';
  }

  String get lastName {
    if (user != null) {
      final nameParts = user!['name']?.toString().split(' ') ?? [];
      return nameParts.length > 1 ? nameParts.last : '';
    }
    return '';
  }

  int get totalReviews {
    if (spaces != null) {
      int total = 0;
      for (var space in spaces!) {
        if (space['reviews'] != null) {
          total += (space['reviews'] as List).length;
        }
      }
      return total;
    }
    return 0;
  }

  double get averageRating {
    if (spaces != null && spaces!.isNotEmpty) {
      double totalRating = 0;
      int spacesWithRating = 0;
      
      for (var space in spaces!) {
        if (space['rating_avg'] != null) {
          totalRating += (space['rating_avg'] as num).toDouble();
          spacesWithRating++;
        }
      }
      
      return spacesWithRating > 0 ? totalRating / spacesWithRating : 0.0;
    }
    return 0.0;
  }

  int get monthsHosting {
    // Calcular meses desde la fecha de creación del primer espacio
    if (spaces != null && spaces!.isNotEmpty) {
      // Asumiendo que hay una fecha de creación en los espacios
      // Por ahora retornamos un valor por defecto
      return 10; // Valor por defecto como en el diseño
    }
    return 0;
  }

  String get location {
    if (user != null && user!['location'] != null) {
      return user!['location'].toString();
    }
    return 'Ubicación no disponible';
  }

  String get workInfo {
    if (user != null && user!['work'] != null) {
      return user!['work'].toString();
    }
    return 'Información no disponible';
  }

  String get birthInfo {
    if (user != null && user!['birth_year'] != null) {
      return 'Nacido en ${user!['birth_year']}';
    }
    return 'Información no disponible';
  }

  List<String> get confirmedInfo {
    List<String> confirmed = [];
    
    if (verificationStatus == 'verified') {
      confirmed.add('Identidad');
    }
    
    if (user != null && user!['email_verified'] == true) {
      confirmed.add('Dirección de correo');
    }
    
    if (user != null && user!['phone_verified'] == true) {
      confirmed.add('Número de teléfono');
    }
    
    return confirmed;
  }
}
