import 'space.dart';
import 'host.dart';
import 'review.dart';

class SpaceDetail {
  final Space space;
  final Host? host;
  final List<Review> reviews;

  SpaceDetail({
    required this.space,
    this.host,
    required this.reviews,
  });

  factory SpaceDetail.fromJson(Map<String, dynamic> json) {
    return SpaceDetail(
      space: Space.fromJson(json['space'] ?? {}),
      host: json['host'] != null ? Host.fromJson(json['host']) : null,
      reviews: (json['reviews'] as List?)
          ?.map((r) => Review.fromJson(r))
          .toList() ?? [],
    );
  }
}
