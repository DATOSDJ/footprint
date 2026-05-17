import 'package:cloud_firestore/cloud_firestore.dart';

class CoverageStats {
  final int totalCells;
  final double worldPercent;
  final double koreaPercent;
  // regionPercents: maps region ID (e.g. 'KR-11', 'KR-11-110') to coverage %
  final Map<String, double> regionPercents;
  final double totalDistanceKm;
  final int totalSessions;
  final DateTime? lastComputed;

  const CoverageStats({
    required this.totalCells,
    required this.worldPercent,
    required this.koreaPercent,
    required this.regionPercents,
    required this.totalDistanceKm,
    required this.totalSessions,
    this.lastComputed,
  });

  static CoverageStats empty() => const CoverageStats(
        totalCells: 0,
        worldPercent: 0,
        koreaPercent: 0,
        regionPercents: {},
        totalDistanceKm: 0,
        totalSessions: 0,
      );

  Map<String, dynamic> toFirestore() => {
        'totalCells': totalCells,
        'worldPercent': worldPercent,
        'koreaPercent': koreaPercent,
        'regionPercents': regionPercents,
        'totalDistanceKm': totalDistanceKm,
        'totalSessions': totalSessions,
        'lastComputed': lastComputed != null
            ? Timestamp.fromDate(lastComputed!)
            : null,
      };

  factory CoverageStats.fromFirestore(Map<String, dynamic> d) =>
      CoverageStats(
        totalCells: (d['totalCells'] as num?)?.toInt() ?? 0,
        worldPercent: (d['worldPercent'] as num?)?.toDouble() ?? 0,
        koreaPercent: (d['koreaPercent'] as num?)?.toDouble() ?? 0,
        regionPercents: (d['regionPercents'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
        totalDistanceKm: (d['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        totalSessions: (d['totalSessions'] as num?)?.toInt() ?? 0,
        lastComputed: d['lastComputed'] != null
            ? (d['lastComputed'] as Timestamp).toDate()
            : null,
      );
}
