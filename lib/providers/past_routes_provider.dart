import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_session.dart';
import '../services/firestore_service.dart';

class SessionRoute {
  final RouteSession session;
  final List<LatLng> points;
  const SessionRoute({required this.session, required this.points});
}

class PastRoutesNotifier extends AsyncNotifier<List<SessionRoute>> {
  @override
  Future<List<SessionRoute>> build() => _load();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  static Future<List<SessionRoute>> _load() async {
    final sessions = await FirestoreService().getSessions(limit: 30);
    final completed = sessions.where((s) => !s.isActive && s.pointCount > 0);
    final result = <SessionRoute>[];
    for (final s in completed) {
      final pts = await FirestoreService().loadSessionRoute(s.id);
      if (pts.isNotEmpty) result.add(SessionRoute(session: s, points: pts));
    }
    return result;
  }
}

final pastRoutesProvider =
    AsyncNotifierProvider<PastRoutesNotifier, List<SessionRoute>>(
        PastRoutesNotifier.new);
