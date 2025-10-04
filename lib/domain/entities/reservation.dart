enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class Reservation {
  final String id;
  final String spaceId;
  final String spaceTitle;
  final String spaceAddress;
  final String userId;
  final String userName;
  final DateTime startTime;
  final int durationHours;
  final int numberOfGuests;
  final double totalPrice;
  final ReservationStatus status;
  final DateTime createdAt;
  final String? notes;

  Reservation({
    required this.id,
    required this.spaceId,
    required this.spaceTitle,
    required this.spaceAddress,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.durationHours,
    required this.numberOfGuests,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      spaceId: json['spaceId'] as String,
      spaceTitle: json['spaceTitle'] as String,
      spaceAddress: json['spaceAddress'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      durationHours: json['durationHours'] as int,
      numberOfGuests: json['numberOfGuests'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spaceId': spaceId,
      'spaceTitle': spaceTitle,
      'spaceAddress': spaceAddress,
      'userId': userId,
      'userName': userName,
      'startTime': startTime.toIso8601String(),
      'durationHours': durationHours,
      'numberOfGuests': numberOfGuests,
      'totalPrice': totalPrice,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  DateTime get endTime => startTime.add(Duration(hours: durationHours));

  String get formattedStartTime {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedDate {
    return '${startTime.day}/${startTime.month}/${startTime.year}';
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
