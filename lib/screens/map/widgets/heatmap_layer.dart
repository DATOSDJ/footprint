import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/theme.dart';
import '../../../services/tile_service.dart';

class HeatmapLayer extends StatelessWidget {
  final Map<String, int> tiles; // tileId -> visit count
  final double mapZoom;

  const HeatmapLayer({
    super.key,
    required this.tiles,
    required this.mapZoom,
  });

  @override
  Widget build(BuildContext context) {
    // Only render tiles at zoom 11+ to avoid performance issues at wide view
    if (mapZoom < 11 || tiles.isEmpty) return const SizedBox.shrink();

    final ts = TileService();
    final polygons = <Polygon>[];

    for (final entry in tiles.entries) {
      final coord = TileCoord.fromId(entry.key);
      if (coord == null) continue;

      try {
        final boundary = ts.tileBoundary(coord);
        polygons.add(Polygon(
          points: boundary,
          color: AppTheme.heatmapColor(entry.value),
          borderColor: Colors.transparent,
          borderStrokeWidth: 0,
        ));
      } catch (_) {
        continue;
      }
    }

    return PolygonLayer(polygons: polygons);
  }
}
