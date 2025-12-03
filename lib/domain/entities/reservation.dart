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
    return (DateTime.tryParse(value.toString()) ?? DateTime.now()).toLocal();
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
