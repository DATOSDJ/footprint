import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPoint {
  final double lat;
  final double lng;
  final double altitude;
  final double speedMs;
  final double accuracy;
  final DateTime timestamp;
  final String sessionId;

  const LocationPoint({
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.speedMs,
    required this.accuracy,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toFirestore() => {
        'lat': lat,
        'lng': lng,
        'altitude': altitude,
        'speedMs': speedMs,
        'accuracy': accuracy,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
      };

  factory LocationPoint.fromFirestore(Map<String, dynamic> d) => LocationPoint(
        lat: (d['lat'] as num).toDouble(),
        lng: (d['lng'] as num).toDouble(),
        altitude: (d['altitude'] as num?)?.toDouble() ?? 0,
        speedMs: (d['speedMs'] as num?)?.toDouble() ?? 0,
        accuracy: (d['accuracy'] as num?)?.toDouble() ?? 0,
        timestamp: (d['timestamp'] as Timestamp).toDate(),
        sessionId: d['sessionId'] as String,
      );
}
