import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../models/route_session.dart';
import '../services/background_task_handler.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/tile_service.dart';
import 'past_routes_provider.dart';
import 'settings_provider.dart';

class TrackingState {
  final bool isTracking;
  final bool isWatching; // GPS stream active (position dot shown even before recording)
  final RouteSession? currentSession;
  final List<LatLng> currentRoute;
  final double currentSpeedMs;
  final FilterReason filterReason;
  final LatLng? currentPosition;
  final double distanceMeters;
  final int elapsedSeconds;
  final int tileVersion; // bumped when _allVisitedTiles changes → triggers heatmap rebuild

  const TrackingState({
    this.isTracking = false,
    this.isWatching = false,
    this.currentSession,
    this.currentRoute = const [],
    this.currentSpeedMs = 0,
    this.filterReason = FilterReason.none,
    this.currentPosition,
    this.distanceMeters = 0,
    this.elapsedSeconds = 0,
    this.tileVersion = 0,
  });

  bool get isFiltered => filterReason != FilterReason.none;

  TrackingState copyWith({
    bool? isTracking,
    bool? isWatching,
    RouteSession? currentSession,
    List<LatLng>? currentRoute,
    double? currentSpeedMs,
    FilterReason? filterReason,
    LatLng? currentPosition,
    double? distanceMeters,
    int? elapsedSeconds,
    int? tileVersion,
  }) =>
      TrackingState(
        isTracking: isTracking ?? this.isTracking,
        isWatching: isWatching ?? this.isWatching,
        currentSession: currentSession ?? this.currentSession,
        currentRoute: currentRoute ?? this.currentRoute,
        currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
        filterReason: filterReason ?? this.filterReason,
        currentPosition: currentPosition ?? this.currentPosition,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        tileVersion: tileVersion ?? this.tileVersion,
      );
}

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<LocationUpdate>? _locationSub;
  final _pendingTiles = <String, int>{}; // tileId -> visit count in this flush window
  final _allVisitedTiles = <String, int>{}; // tileId -> total visit count (in-memory)
  Timer? _flushTimer;
  Timer? _elapsedTimer;
  final _distanceCalc = const Distance();
  LatLng? _lastRecordedPoint;

  @override
  TrackingState build() => const TrackingState();

  Map<String, int> get allVisitedTiles => Map.unmodifiable(_allVisitedTiles);

  // ── Watching (position display without recording) ─────────────────────────

  Future<void> startWatching() async {
    await _loadTiles();

    final locService = LocationService();
    final hasPermission = await locService.requestPermissions();
    if (!hasPermission) return;

    locService.startListening();
    _locationSub?.cancel();
    _locationSub = locService.updates.listen(_onUpdate);
    state = state.copyWith(isWatching: true);
  }

  void stopWatching() {
    _locationSub?.cancel();
    LocationService().stopListening();
    state = state.copyWith(isWatching: false);
  }

  // ── Recording session ─────────────────────────────────────────────────────

  Future<void> startTracking() async {
    final locService = LocationService();

    if (!state.isWatching) {
      final hasPermission = await locService.requestPermissions();
      if (!hasPermission) return;
      locService.startListening();
      _locationSub?.cancel();
      _locationSub = locService.updates.listen(_onUpdate);
    }

    final settings = ref.read(settingsProvider);
    locService.setMaxSpeed(settings.maxSpeedMs);

    final session = await FirestoreService().createSession();

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Footprint 기록 중',
      notificationText: '경로를 기록하고 있습니다...',
      callback: startCallback,
    );

    FlutterForegroundTask.addTaskDataCallback(_onBackgroundData);

    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 10), (_) => _flush());

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    _lastRecordedPoint = null;

    state = state.copyWith(
      isTracking: true,
      isWatching: true,
      currentSession: session,
      currentRoute: [],
      distanceMeters: 0,
      elapsedSeconds: 0,
    );
  }

  Future<void> stopTracking() async {
    _flushTimer?.cancel();
    _elapsedTimer?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onBackgroundData);
    await FlutterForegroundTask.stopService();

    await _flush();

    if (state.currentSession != null) {
      final ended = state.currentSession!.copyWith(
        endTime: DateTime.now(),
        distanceMeters: state.distanceMeters,
        pointCount: state.currentRoute.length,
        isActive: false,
      );
      await Future.wait([
        FirestoreService().updateSession(ended),
        FirestoreService().saveSessionRoute(
            state.currentSession!.id, state.currentRoute),
      ]);
    }

    // Refresh past routes on map
    ref.read(pastRoutesProvider.notifier).reload();

    // Keep watching: GPS stream stays active so position dot stays visible
    state = TrackingState(
      isWatching: true,
      currentPosition: state.currentPosition,
      currentSpeedMs: state.currentSpeedMs,
      filterReason: state.filterReason,
      tileVersion: state.tileVersion,
    );
    _lastRecordedPoint = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _loadTiles() async {
    final tiles = await FirestoreService().loadAllCells();
    _allVisitedTiles.addAll(tiles);
    state = state.copyWith(tileVersion: state.tileVersion + 1);
  }

  void _onBackgroundData(Object data) {
    if (data is! Map<String, dynamic>) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    final speed = (data['speed'] as num?)?.toDouble() ?? 0;
    if (lat == null || lng == null) return;

    final settings = ref.read(settingsProvider);
    final FilterReason reason;
    if (speed < AppConstants.minSpeedMs) {
      reason = FilterReason.tooSlow;
    } else if (settings.maxSpeedMs < 999 && speed > settings.maxSpeedMs) {
      reason = FilterReason.tooFast;
    } else {
      reason = FilterReason.none;
    }

    _processPoint(LatLng(lat, lng), speed, reason);
  }

  void _onUpdate(LocationUpdate update) {
    _processPoint(update.position, update.speedMs, update.filterReason);
  }

  void _processPoint(LatLng pos, double speed, FilterReason reason) {
    state = state.copyWith(
      currentPosition: pos,
      currentSpeedMs: speed,
      filterReason: state.isTracking ? reason : FilterReason.none,
    );

    if (reason != FilterReason.none || !state.isTracking) return;

    final newRoute = [...state.currentRoute, pos];

    double newDist = state.distanceMeters;
    if (_lastRecordedPoint != null) {
      newDist += _distanceCalc.as(LengthUnit.Meter, _lastRecordedPoint!, pos);
    }
    _lastRecordedPoint = pos;

    final tileId = TileService().latLngToTileId(pos.latitude, pos.longitude);
    final isNewTile = !_allVisitedTiles.containsKey(tileId);
    _pendingTiles[tileId] = (_pendingTiles[tileId] ?? 0) + 1;
    _allVisitedTiles[tileId] = (_allVisitedTiles[tileId] ?? 0) + 1;

    state = state.copyWith(
      currentRoute: newRoute,
      distanceMeters: newDist,
      tileVersion: isNewTile ? state.tileVersion + 1 : state.tileVersion,
    );
  }

  Future<void> _flush() async {
    if (_pendingTiles.isEmpty) return;
    final toFlush = Map<String, int>.from(_pendingTiles);
    _pendingTiles.clear();
    await FirestoreService().recordCells(toFlush);
  }
}

final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
