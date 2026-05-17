import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';

class PeriodStats {
  final double weekKm;
  final double monthKm;
  const PeriodStats({required this.weekKm, required this.monthKm});
}

final periodStatsProvider = FutureProvider<PeriodStats>((ref) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final weekR = await FirestoreService().getSessionsPage(
    from: DateTime(weekStart.year, weekStart.month, weekStart.day),
    to: today,
  );
  final monthR = await FirestoreService().getSessionsPage(
    from: DateTime(now.year, now.month, 1),
    to: today,
  );

  final weekKm = weekR.sessions
      .fold<double>(0, (s, r) => s + r.distanceMeters / 1000);
  final monthKm = monthR.sessions
      .fold<double>(0, (s, r) => s + r.distanceMeters / 1000);

  return PeriodStats(weekKm: weekKm, monthKm: monthKm);
});
