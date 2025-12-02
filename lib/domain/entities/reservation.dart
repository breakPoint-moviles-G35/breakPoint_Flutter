enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String spaceId;
  final String spaceTitle;
  final String? spaceImageUrl;
  final double? spacePrice; // Precio del espacio (del JSON space.price)
  final double baseSubtotal;
  final bool discountApplied;
  final double discountPercent;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final DateTime slotStart;
  final DateTime slotEnd;
  final ReservationStatus status;

  Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.spaceId,
    required this.spaceTitle,
    this.spaceImageUrl,
    this.spacePrice,
    required this.baseSubtotal,
    required this.discountApplied,
    required this.discountPercent,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // 🔹 Adapta nombres snake_case / camelCase
    final slotStartValue = json['slot_start'] ?? json['slotStart'];
    final slotEndValue = json['slot_end'] ?? json['slotEnd'];
    final totalAmountValue =
        json['total'] ?? json['total_amount'] ?? json['totalAmount'];
    final baseSubtotalValue =
        json['base_subtotal'] ?? json['baseSubtotal'] ?? json['subtotal'];
    final discountAppliedValue =
        json['discount_applied'] ?? json['discountApplied'];
    final discountPercentValue =
        json['discount_percent'] ?? json['discountPercent'];
    final discountAmountValue =
        json['discount_amount'] ?? json['discountAmount'];

    double _toDouble(dynamic value, [double defaultValue = 0]) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? defaultValue;
    }

    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }
      return false;
    }

    return Reservation(
      id: json['id']?.toString() ?? '',
      userId: json['user']?['id']?.toString() ?? '',
      userName: json['user']?['name'] ?? '',
      spaceId: json['space']?['id']?.toString() ?? '',
      spaceTitle: json['space']?['title'] ?? '',
      spaceImageUrl: json['space']?['imageUrl'] ?? json['space']?['image_url'],
      spacePrice: json['space']?['price'] != null ? _toDouble(json['space']?['price'], 0) : null,
      baseSubtotal: _toDouble(baseSubtotalValue, 0),
      discountApplied: _toBool(discountAppliedValue),
      discountPercent: _toDouble(discountPercentValue, 0),
      discountAmount: _toDouble(discountAmountValue, 0),
      totalAmount: _toDouble(totalAmountValue, 0),
      currency: json['currency'] ?? 'USD',
      slotStart: _parseDateTime(slotStartValue),
      slotEnd: _parseDateTime(slotEndValue),
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'spaceId': spaceId,
      'spaceTitle': spaceTitle,
      'spaceImageUrl': spaceImageUrl,
      'spacePrice': spacePrice,
      'baseSubtotal': baseSubtotal,
      'discountApplied': discountApplied,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'slotStart': slotStart.toIso8601String(),
      'slotEnd': slotEnd.toIso8601String(),
      'status': status.name,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    final dateTimeStr = value.toString().trim();
    if (dateTimeStr.isEmpty) return DateTime.now();
    
    // Si el string tiene 'Z' al final, es UTC explícito
    if (dateTimeStr.endsWith('Z')) {
      final parsed = DateTime.tryParse(dateTimeStr);
      return parsed?.toLocal() ?? DateTime.now();
    }
    
    // Si tiene offset de zona horaria (+/-HH:MM), parsear directamente
    if (dateTimeStr.contains('+') || (dateTimeStr.contains('-') && dateTimeStr.length > 19)) {
      final parsed = DateTime.tryParse(dateTimeStr);
      return parsed?.toLocal() ?? DateTime.now();
    }
    
    // Si no tiene indicador de zona horaria, asumir que viene en UTC del backend
    // Parsear como si fuera UTC y luego convertir a local
    final parsed = DateTime.tryParse(dateTimeStr);
    if (parsed == null) return DateTime.now();
    
    // Si ya está marcado como UTC, solo convertir a local
    if (parsed.isUtc) {
      return parsed.toLocal();
    }
    
    // Si no está marcado como UTC pero no tiene zona horaria en el string,
    // asumir que el backend lo envió en UTC y crear un DateTime UTC explícito
    final utcDateTime = DateTime.utc(
      parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second, parsed.millisecond, parsed.microsecond
    );
    return utcDateTime.toLocal();
  }

  static ReservationStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'completed':
        return ReservationStatus.completed;
      default:
        return ReservationStatus.pending;
    }
  }

  String get formattedDate =>
      '${slotStart.day}/${slotStart.month}/${slotStart.year}';

  String get formattedTimeRange {
    final start =
        '${slotStart.hour}:${slotStart.minute.toString().padLeft(2, '0')}';
    final end = '${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get statusText {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.cancelled:
        return 'Cancelada';
      case ReservationStatus.completed:
        return 'Completada';
    }
  }
}
