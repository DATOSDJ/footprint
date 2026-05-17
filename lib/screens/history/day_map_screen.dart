import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/route_session.dart';
import '../../services/firestore_service.dart';

class DayMapScreen extends StatefulWidget {
  final String date;
  final List<RouteSession> sessions;

  const DayMapScreen({
    super.key,
    required this.date,
    required this.sessions,
  });

  @override
  State<DayMapScreen> createState() => _DayMapScreenState();
}

class _DayMapScreenState extends State<DayMapScreen> {
  List<List<LatLng>>? _routes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routes = await Future.wait(
      widget.sessions.map((s) => FirestoreService().loadSessionRoute(s.id)),
    );
    if (mounted) setState(() { _routes = routes; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.date.split('-');
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[dt.weekday - 1];
    final dateLabel = '${dt.year}년 ${dt.month}월 ${dt.day}일 ($dayName)';

    final totalDist = widget.sessions
        .fold<double>(0, (s, r) => s + r.distanceMeters);
    final distStr = totalDist < 1000
        ? '${totalDist.toStringAsFixed(0)}m'
        : '${(totalDist / 1000).toStringAsFixed(2)}km';

    final totalSecs = widget.sessions.fold<int>(0, (sum, s) {
      final end = s.endTime ?? DateTime.now();
      return sum + end.difference(s.startTime).inSeconds;
    });
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final durStr = h > 0 ? '${h}시간 ${m}분' : '${m}분';

    return Scaffold(
      appBar: AppBar(
        title: Text(dateLabel),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _chip(Icons.straighten, distStr),
                const SizedBox(width: 16),
                _chip(Icons.timer_outlined, durStr),
                const SizedBox(width: 16),
                _chip(Icons.route, '${widget.sessions.length}회'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _DayMapView(routes: _routes!),
    );
  }

  Widget _chip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}

class _DayMapView extends StatelessWidget {
  final List<List<LatLng>> routes;
  const _DayMapView({required this.routes});

  @override
  Widget build(BuildContext context) {
    final nonempty = routes.where((r) => r.isNotEmpty).toList();

    if (nonempty.isEmpty) {
      return const Center(
        child: Text('경로 데이터 없음',
            style: TextStyle(color: Colors.white54)),
      );
    }

    final allPoints = nonempty.expand((r) => r).toList();
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;
    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final polylines = nonempty
        .map((r) => Polyline(
              points: r,
              color: const Color(0xFF4CAF50),
              strokeWidth: 4,
            ))
        .toList();

    // Start dot for each segment, end dot for each segment
    final markers = nonempty
        .expand((r) => [
              Marker(
                point: r.first,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              Marker(
                point: r.last,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ])
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
            (minLat + maxLat) / 2, (minLng + maxLng) / 2),
        initialZoom: 15,
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(minLat - 0.001, minLng - 0.001),
            LatLng(maxLat + 0.001, maxLng + 0.001),
          ),
          padding: const EdgeInsets.all(40),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.footprintapp.footprint',
          tileProvider: NetworkTileProvider(),
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
