import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

class TileCoord {
  final int z;
  final int x;
  final int y;

  const TileCoord(this.z, this.x, this.y);

  String get id => '${z}_${x}_$y';

  static TileCoord? fromId(String id) {
    final parts = id.split('_');
    if (parts.length != 3) return null;
    final z = int.tryParse(parts[0]);
    final x = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (z == null || x == null || y == null) return null;
    return TileCoord(z, x, y);
  }

  @override
  bool operator ==(Object other) =>
      other is TileCoord && z == other.z && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(z, x, y);
}

class TileService {
  static final TileService _i = TileService._();
  factory TileService() => _i;
  TileService._();

  // ── Coordinate math (standard OSM/Mercator) ──────────────

  int _lonToX(double lon, int z) =>
      ((lon + 180) / 360 * (1 << z)).floor().clamp(0, (1 << z) - 1);

  int _latToY(double lat, int z) {
    final r = lat * math.pi / 180;
    final val = math.log(math.tan(math.pi / 4 + r / 2));
    return ((1 - val / math.pi) / 2 * (1 << z))
        .floor()
        .clamp(0, (1 << z) - 1);
  }

  LatLng _tileNW(int x, int y, int z) {
    final n = math.pi - 2 * math.pi * y / (1 << z);
    final lat = 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    final lon = x / (1 << z) * 360 - 180;
    return LatLng(lat, lon);
  }

  // ── Public API ────────────────────────────────────────────

  TileCoord latLngToTile(double lat, double lng, {int? zoom}) {
    final z = zoom ?? AppConstants.tileZoom;
    return TileCoord(z, _lonToX(lng, z), _latToY(lat, z));
  }

  String latLngToTileId(double lat, double lng, {int? zoom}) =>
      latLngToTile(lat, lng, zoom: zoom).id;

  // Tile bounding box as 4-point polygon [NW, NE, SE, SW]
  List<LatLng> tileBoundary(TileCoord tile) {
    final nw = _tileNW(tile.x, tile.y, tile.z);
    final se = _tileNW(tile.x + 1, tile.y + 1, tile.z);
    return [
      nw,
      LatLng(nw.latitude, se.longitude),
      se,
      LatLng(se.latitude, nw.longitude),
    ];
  }

  LatLng tileCenter(TileCoord tile) {
    final nw = _tileNW(tile.x, tile.y, tile.z);
    final se = _tileNW(tile.x + 1, tile.y + 1, tile.z);
    return LatLng(
      (nw.latitude + se.latitude) / 2,
      (nw.longitude + se.longitude) / 2,
    );
  }

  // All tiles inside a bounding box at given zoom
  Set<String> tilesInBBox({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int? zoom,
  }) {
    final z = zoom ?? AppConstants.tileZoom;
    final xMin = _lonToX(minLon, z);
    final xMax = _lonToX(maxLon, z);
    final yMin = _latToY(maxLat, z); // max lat → min y (y increases southward)
    final yMax = _latToY(minLat, z);

    final tiles = <String>{};
    for (int x = xMin; x <= xMax; x++) {
      for (int y = yMin; y <= yMax; y++) {
        tiles.add(TileCoord(z, x, y).id);
      }
    }
    return tiles;
  }

  // Tiles visible in the current map viewport
  Set<String> tilesInViewport({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int? zoom,
  }) =>
      tilesInBBox(
        minLat: minLat,
        maxLat: maxLat,
        minLon: minLon,
        maxLon: maxLon,
        zoom: zoom,
      );

  // Coverage percentage
  double coveragePercent(Set<String> visitedIds, Set<String> regionIds) {
    if (regionIds.isEmpty) return 0;
    return visitedIds.intersection(regionIds).length / regionIds.length * 100;
  }

  // Count visited tiles inside a bbox — O(visited) instead of O(region tiles).
  // Use this for large regions where tilesInBBox would be prohibitively slow.
  int countVisitedInBBox(
    Set<String> visitedIds, {
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int? zoom,
  }) {
    final z = zoom ?? AppConstants.tileZoom;
    final xMin = _lonToX(minLon, z);
    final xMax = _lonToX(maxLon, z);
    final yMin = _latToY(maxLat, z);
    final yMax = _latToY(minLat, z);

    int count = 0;
    for (final id in visitedIds) {
      final parts = id.split('_');
      if (parts.length != 3) continue;
      final iz = int.tryParse(parts[0]);
      final ix = int.tryParse(parts[1]);
      final iy = int.tryParse(parts[2]);
      if (iz == z && ix != null && iy != null &&
          ix >= xMin && ix <= xMax && iy >= yMin && iy <= yMax) {
        count++;
      }
    }
    return count;
  }

  // World coverage estimate (land tiles approximation)
  double worldCoveragePercent(int visitedCount) =>
      visitedCount / AppConstants.worldLandTilesZ16 * 100;
}
