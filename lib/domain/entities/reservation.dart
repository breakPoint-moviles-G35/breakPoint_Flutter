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
    required this.totalAmount,
    required this.currency,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? '',
      userId: json['user']?['id'] ?? '',
      userName: json['user']?['name'] ?? '',
      spaceId: json['space']?['id'] ?? '',
      spaceTitle: json['space']?['title'] ?? '',
      spaceImageUrl: json['space']?['imageUrl'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      slotStart: DateTime.parse(json['slot_start']),
      slotEnd: DateTime.parse(json['slot_end']),
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
      'totalAmount': totalAmount,
      'currency': currency,
      'slotStart': slotStart.toIso8601String(),
      'slotEnd': slotEnd.toIso8601String(),
      'status': status.name,
    };
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

  /// Métodos auxiliares para mostrar en UI
  String get formattedDate {
    return '${slotStart.day}/${slotStart.month}/${slotStart.year}';
  }

  String get formattedTimeRange {
    final start = '${slotStart.hour}:${slotStart.minute.toString().padLeft(2, '0')}';
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
