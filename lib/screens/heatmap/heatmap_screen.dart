import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../providers/tracking_provider.dart';
import '../../services/tile_service.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  final _mapController = MapController();
  LatLng? _initialCenter;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _centroid(Map<String, int> tiles) {
    if (tiles.isEmpty) {
      return const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    }
    final svc = TileService();
    double sumLat = 0, sumLng = 0;
    int n = 0;
    for (final id in tiles.keys) {
      final coord = TileCoord.fromId(id);
      if (coord == null) continue;
      final c = svc.tileCenter(coord);
      sumLat += c.latitude;
      sumLng += c.longitude;
      n++;
    }
    return n == 0
        ? const LatLng(AppConstants.defaultLat, AppConstants.defaultLng)
        : LatLng(sumLat / n, sumLng / n);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(trackingProvider.select((s) => s.tileVersion));
    final allTiles = ref.read(trackingProvider.notifier).allVisitedTiles;

    _initialCenter ??= _centroid(allTiles);

    final maxCount =
        allTiles.values.isEmpty ? 1 : allTiles.values.reduce(math.max);

    final polygons = allTiles.entries.expand((e) {
      final coord = TileCoord.fromId(e.key);
      if (coord == null) return const <Polygon>[];
      final bounds = TileService().tileBoundary(coord);
      final ratio = math.log(e.value + 1) / math.log(maxCount + 1);
      final alpha = 0.20 + ratio * 0.70;
      return [
        Polygon(
          points: bounds,
          color: Color.fromRGBO(76, 175, 80, alpha),
          borderColor: Colors.transparent,
          borderStrokeWidth: 0,
        ),
      ];
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.footprintapp.footprint',
                tileProvider: NetworkTileProvider(),
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: const Text(
                      '누적 발자국',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                  const Spacer(),
                  if (allTiles.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${allTiles.length} 구역',
                        style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Empty state
          if (allTiles.isEmpty)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined, color: Colors.white24, size: 56),
                  SizedBox(height: 12),
                  Text('아직 기록된 경로가 없습니다',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
