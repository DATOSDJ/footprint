import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/region_data.dart';
import '../models/coverage_stats.dart';
import '../services/firestore_service.dart';
import '../services/tile_service.dart';

// Tile count threshold: regions with more tiles than this use the fast
// countVisitedInBBox path instead of building the full tile set.
const _largeTileThreshold = 5000;

class CoverageNotifier extends AsyncNotifier<CoverageStats> {
  @override
  Future<CoverageStats> build() async {
    final cached = await FirestoreService().loadCoverageStats();
    if (cached != null) {
      final age = DateTime.now().difference(cached.lastComputed ?? DateTime(2000));
      if (age.inHours >= 1) _refreshInBackground();
      return cached;
    }
    return _compute();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _compute());
  }

  void _refreshInBackground() {
    Future.microtask(() async {
      final stats = await _compute();
      state = AsyncData(stats);
    });
  }

  Future<CoverageStats> _compute() async {
    final cells = await FirestoreService().loadAllCells();
    final visitedSet = cells.keys.toSet();
    final ts = TileService();

    final worldPercent = ts.worldCoveragePercent(visitedSet.length);

    double koreaPercent = _computeForRegion(ts, visitedSet, regionKorea);

    final regionPercents = <String, double>{};

    // Compute all 시도 and their districts.
    // Districts use exclusive tile assignment (smallest bbox wins) to prevent
    // large counties (e.g. 울주군) from double-counting tiles inside city
    // district bboxes that they geometrically surround.
    for (final province in koreaProvinces) {
      regionPercents[province.id] =
          _computeForRegion(ts, visitedSet, province);

      final districts = getDistrictsOf(province.id);
      if (districts.isNotEmpty) {
        _computeDistrictCoverage(ts, visitedSet, districts, regionPercents);
      }
    }

    final sessions = await FirestoreService().getSessions(limit: 1000);
    final totalDist =
        sessions.fold<double>(0, (sum, s) => sum + s.distanceMeters / 1000);

    final stats = CoverageStats(
      totalCells: visitedSet.length,
      worldPercent: worldPercent,
      koreaPercent: koreaPercent,
      regionPercents: regionPercents,
      totalDistanceKm: totalDist,
      totalSessions: sessions.length,
      lastComputed: DateTime.now(),
    );

    await FirestoreService().saveCoverageStats(stats);
    return stats;
  }

  /// Assigns each visited tile to exactly one district — the smallest-bbox
  /// district whose bbox contains the tile's center. This eliminates the
  /// double-counting that occurs when a large county bbox (e.g. 울주군)
  /// geometrically contains smaller city district bboxes (e.g. 북구).
  void _computeDistrictCoverage(
    TileService ts,
    Set<String> visitedSet,
    List<RegionData> districts,
    Map<String, double> out,
  ) {
    // Sort ascending by approximateTiles so the most specific (smallest) region
    // is checked first and wins the tile assignment.
    final sorted = [...districts]
      ..sort((a, b) => a.approximateTiles.compareTo(b.approximateTiles));

    // Compute a loose province-level bbox to skip tiles clearly outside.
    final pMinLat = districts.map((d) => d.minLat).reduce(math.min);
    final pMaxLat = districts.map((d) => d.maxLat).reduce(math.max);
    final pMinLon = districts.map((d) => d.minLon).reduce(math.min);
    final pMaxLon = districts.map((d) => d.maxLon).reduce(math.max);

    final counts = <String, int>{};

    for (final tileId in visitedSet) {
      final coord = TileCoord.fromId(tileId);
      if (coord == null) continue;
      final c = ts.tileCenter(coord);

      // Quick province-level early-out
      if (c.latitude < pMinLat || c.latitude > pMaxLat ||
          c.longitude < pMinLon || c.longitude > pMaxLon) continue;

      // Assign to the smallest enclosing district only
      for (final d in sorted) {
        if (c.latitude >= d.minLat && c.latitude <= d.maxLat &&
            c.longitude >= d.minLon && c.longitude <= d.maxLon) {
          counts[d.id] = (counts[d.id] ?? 0) + 1;
          break;
        }
      }
    }

    for (final d in districts) {
      final count = counts[d.id] ?? 0;
      out[d.id] = (count / d.approximateTiles * 100).clamp(0.0, 100.0);
    }
  }

  double _computeForRegion(
      TileService ts, Set<String> visitedSet, RegionData region) {
    try {
      if (region.approximateTiles > _largeTileThreshold) {
        // Fast path: count visited tiles inside bbox, divide by approximateTiles
        final count = ts.countVisitedInBBox(
          visitedSet,
          minLat: region.minLat,
          maxLat: region.maxLat,
          minLon: region.minLon,
          maxLon: region.maxLon,
        );
        return (count / region.approximateTiles * 100).clamp(0.0, 100.0);
      } else {
        // Exact path: enumerate all region tiles, intersect with visited
        final regionTiles = ts.tilesInBBox(
          minLat: region.minLat,
          maxLat: region.maxLat,
          minLon: region.minLon,
          maxLon: region.maxLon,
        );
        return ts.coveragePercent(visitedSet, regionTiles);
      }
    } catch (_) {
      return 0;
    }
  }
}

final coverageProvider =
    AsyncNotifierProvider<CoverageNotifier, CoverageStats>(CoverageNotifier.new);
