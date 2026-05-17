import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../providers/past_routes_provider.dart';
import '../../providers/tracking_provider.dart';
import 'widgets/tracking_controls.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  double _currentZoom = AppConstants.defaultZoom;
  bool _followUser = true;
  bool _showPastRoutes = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final pastRoutesAsync = ref.watch(pastRoutesProvider);

    if (_followUser && tracking.currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(tracking.currentPosition!, _currentZoom);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: tracking.currentPosition ??
                  const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
              initialZoom: _currentZoom,
              onMapEvent: (event) {
                if (event is MapEventMove) {
                  setState(() {
                    _currentZoom = event.camera.zoom;
                    if (event.source != MapEventSource.mapController) {
                      _followUser = false;
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.footprintapp.footprint',
                tileProvider: NetworkTileProvider(),
              ),
              // Past session routes (faint)
              if (_showPastRoutes)
                pastRoutesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (routes) => PolylineLayer(
                    polylines: routes
                        .map((r) => Polyline(
                              points: r.points,
                              color: const Color(0xFF4FC3F7).withValues(alpha: 0.45),
                              strokeWidth: 2.5,
                            ))
                        .toList(),
                  ),
                ),

              // Current session route (bright)
              if (tracking.currentRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: tracking.currentRoute,
                      color: const Color(0xFF4CAF50),
                      strokeWidth: 3.5,
                    ),
                  ],
                ),

              if (tracking.currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: tracking.currentPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Past routes toggle
                  GestureDetector(
                    onTap: () => setState(() => _showPastRoutes = !_showPastRoutes),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showPastRoutes
                            ? const Color(0xFF4FC3F7).withValues(alpha: 0.2)
                            : const Color(0xFF161B22).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showPastRoutes
                              ? const Color(0xFF4FC3F7)
                              : const Color(0xFF30363D),
                        ),
                      ),
                      child: Icon(
                        Icons.route,
                        color: _showPastRoutes
                            ? const Color(0xFF4FC3F7)
                            : Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_followUser)
                    GestureDetector(
                      onTap: () => setState(() => _followUser = true),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: const Icon(Icons.my_location,
                            color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _mapButton(Icons.add, () => _mapController.move(
                    _mapController.camera.center, _currentZoom + 1)),
                const SizedBox(height: 8),
                _mapButton(Icons.remove, () => _mapController.move(
                    _mapController.camera.center, _currentZoom - 1)),
              ],
            ),
          ),

          // Tracking FAB
          const Positioned(
            right: 16,
            bottom: 24,
            child: TrackingFab(),
          ),

          // Legend (zoom 11+)
          if (_currentZoom >= 11)
            Positioned(
              left: 12,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem(const Color(0xFF4CAF50), '현재 기록'),
                    const SizedBox(height: 4),
                    _legendItem(const Color(0xFF4FC3F7), '과거 경로'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _legendItem(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      );
}
