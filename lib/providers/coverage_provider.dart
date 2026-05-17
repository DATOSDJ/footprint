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

    // Compute all 시도 and their districts
    for (final province in koreaProvinces) {
      regionPercents[province.id] =
          _computeForRegion(ts, visitedSet, province);

      final districts = getDistrictsOf(province.id);
      for (final district in districts) {
        regionPercents[district.id] =
            _computeForRegion(ts, visitedSet, district);
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
