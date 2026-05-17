class AppConstants {
  // Tile zoom level for tracking (zoom 16 ≈ 600m/tile at Korea latitude)
  static const int tileZoom = 16;

  // Speed filter defaults (m/s)
  static const double minSpeedMs = 0.5;   // GPS 드리프트 필터
  static const double defaultMaxSpeedMs = 8.33; // 30 km/h (걷기/달리기 최대)

  // GPS update interval
  static const int locationUpdateIntervalMs = 3000;
  static const double locationDistanceFilterM = 5.0;

  // Approximate tile counts (zoom 16) for coverage %
  // Used as denominators when bbox enumeration is too expensive.
  static const int worldLandTilesZ16 = 800000000; // rough estimate of land tiles
  static const int koreaTilesZ16 = 780000;        // bounding box estimate
  static const int seoulTilesZ16 = 2800;          // computed from bbox

  // Map
  static const double defaultLat = 37.5665;
  static const double defaultLng = 126.9780;
  static const double defaultZoom = 14.0;

  // Heatmap colors (visit count thresholds)
  static const int heatLow = 1;
  static const int heatMed = 5;
  static const int heatHigh = 20;

  // Firestore collections
  static const String colUsers = 'users';
  static const String colSessions = 'sessions';
  static const String colCells = 'cells';
  static const String docStats = 'stats';
  static const String docProfile = 'profile';
}

class SpeedPreset {
  final String label;
  final double maxSpeedMs;
  const SpeedPreset(this.label, this.maxSpeedMs);
}

const speedPresets = [
  SpeedPreset('걷기 (6 km/h)', 1.67),
  SpeedPreset('빠른 걷기 (10 km/h)', 2.78),
  SpeedPreset('달리기 (20 km/h)', 5.56),
  SpeedPreset('자전거 (30 km/h)', 8.33),
  SpeedPreset('제한 없음', 999.0),
];
