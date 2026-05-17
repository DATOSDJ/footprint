import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/route_session.dart';
import '../../services/firestore_service.dart';

class SessionMapScreen extends StatefulWidget {
  final RouteSession session;
  const SessionMapScreen({super.key, required this.session});

  @override
  State<SessionMapScreen> createState() => _SessionMapScreenState();
}

class _SessionMapScreenState extends State<SessionMapScreen> {
  List<LatLng>? _points;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pts =
        await FirestoreService().loadSessionRoute(widget.session.id);
    if (mounted) setState(() { _points = pts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final date = s.startTime;
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('$dateStr  $timeStr'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _chip(Icons.straighten, s.formattedDistance),
                const SizedBox(width: 12),
                _chip(Icons.timer_outlined, s.formattedDuration),
                const SizedBox(width: 12),
                _chip(Icons.place_outlined,
                    '${s.pointCount} 포인트'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _points == null || _points!.isEmpty
              ? const Center(
                  child: Text('경로 데이터 없음',
                      style: TextStyle(color: Colors.white54)),
                )
              : _MapView(points: _points!),
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

class _MapView extends StatelessWidget {
  final List<LatLng> points;
  const _MapView({required this.points});

  @override
  Widget build(BuildContext context) {
    // Compute bounding box to fit the route
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(minLat - 0.001, minLng - 0.001),
            LatLng(maxLat + 0.001, maxLng + 0.001),
          ),
          padding: const EdgeInsets.all(32),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.footprintapp.footprint',
          tileProvider: NetworkTileProvider(),
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: const Color(0xFF4CAF50),
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Start marker
            Marker(
              point: points.first,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 12),
              ),
            ),
            // End marker
            Marker(
              point: points.last,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
