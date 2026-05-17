import 'package:cloud_firestore/cloud_firestore.dart';

class RouteSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final int pointCount;
  final bool isActive;

  const RouteSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.distanceMeters,
    required this.pointCount,
    required this.isActive,
  });

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.toStringAsFixed(0)}m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
  }

  String get formattedDuration {
    final d = duration;
    if (d == null) return '-';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}시간 ${m}분';
    if (m > 0) return '${m}분 ${s}초';
    return '${s}초';
  }

  Map<String, dynamic> toFirestore() => {
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'distanceMeters': distanceMeters,
        'pointCount': pointCount,
        'isActive': isActive,
      };

  factory RouteSession.fromFirestore(String id, Map<String, dynamic> d) =>
      RouteSession(
        id: id,
        startTime: (d['startTime'] as Timestamp).toDate(),
        endTime: d['endTime'] != null
            ? (d['endTime'] as Timestamp).toDate()
            : null,
        distanceMeters: (d['distanceMeters'] as num).toDouble(),
        pointCount: d['pointCount'] as int,
        isActive: d['isActive'] as bool? ?? false,
      );

  RouteSession copyWith({
    DateTime? endTime,
    double? distanceMeters,
    int? pointCount,
    bool? isActive,
  }) =>
      RouteSession(
        id: id,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        pointCount: pointCount ?? this.pointCount,
        isActive: isActive ?? this.isActive,
      );
}
