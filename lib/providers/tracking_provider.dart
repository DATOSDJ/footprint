import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../models/route_session.dart';
import '../services/background_task_handler.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/tile_service.dart';
import 'history_provider.dart';
import 'past_routes_provider.dart';
import 'settings_provider.dart';

class TrackingState {
  final bool isTracking;
  final bool isWatching;
  final bool isAutoSession; // true = started by background auto-detect
  final RouteSession? currentSession;
  final List<LatLng> currentRoute;
  final double currentSpeedMs;
  final FilterReason filterReason;
  final LatLng? currentPosition;
  final double distanceMeters;
  final int elapsedSeconds;
  final int tileVersion;

  const TrackingState({
    this.isTracking = false,
    this.isWatching = false,
    this.isAutoSession = false,
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
    bool? isAutoSession,
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
        isAutoSession: isAutoSession ?? this.isAutoSession,
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
  final _allVisitedTiles = <String, int>{};
  Timer? _elapsedTimer;
  final _distanceCalc = const Distance();
  LatLng? _lastRecordedPoint;

  @override
  TrackingState build() => const TrackingState();

  Map<String, int> get allVisitedTiles => Map.unmodifiable(_allVisitedTiles);

  // ── Startup ───────────────────────────────────────────────────────────────

  Future<void> startWatching() async {
    await _loadTiles();

    final locService = LocationService();
    final hasPermission = await locService.requestPermissions();
    if (!hasPermission) return;

    locService.startListening();
    _locationSub?.cancel();
    _locationSub = locService.updates.listen(_onUpdate);

    // Start the foreground service (always-on for auto-tracking)
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Footprint',
        notificationText: '대기 중...',
        callback: startCallback,
      );
    }
    FlutterForegroundTask.addTaskDataCallback(_onBackgroundData);

    // Sync settings to background
    final settings = ref.read(settingsProvider);
    FlutterForegroundTask.sendDataToTask({
      'command': 'set_auto',
      'enabled': settings.autoTracking,
    });
    FlutterForegroundTask.sendDataToTask({
      'command': 'set_auto_stop',
      'minutes': settings.autoStopMinutes,
    });

    // Check if background already has an active session (e.g., app was killed mid-session)
    final active = await FirestoreService().getActiveSession();
    if (active != null) {
      state = state.copyWith(
        isWatching: true,
        isTracking: true,
        isAutoSession: true,
        currentSession: active,
        distanceMeters: active.distanceMeters,
      );
      _startElapsedTimer();
    } else {
      state = state.copyWith(isWatching: true);
    }
  }

  // ── Manual Recording ──────────────────────────────────────────────────────

  Future<void> startTracking() async {
    if (state.isTracking) return;

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

    // Tell background to enter manual mode (don't auto-stop)
    FlutterForegroundTask.sendDataToTask({
      'command': 'manual_start',
      'sessionId': session.id,
    });

    _elapsedTimer?.cancel();
    _startElapsedTimer();
    _lastRecordedPoint = null;

    state = state.copyWith(
      isTracking: true,
      isWatching: true,
      isAutoSession: false,
      currentSession: session,
      currentRoute: [],
      distanceMeters: 0,
      elapsedSeconds: 0,
    );
  }

  Future<void> stopTracking() async {
    _elapsedTimer?.cancel();

    if (state.isAutoSession) {
      // Background manages this session — just tell it to stop
      FlutterForegroundTask.sendDataToTask({'command': 'manual_stop'});
      state = TrackingState(
        isWatching: true,
        currentPosition: state.currentPosition,
        currentSpeedMs: state.currentSpeedMs,
        tileVersion: state.tileVersion,
      );
      ref.read(historyProvider.notifier).reload();
    ref.read(pastRoutesProvider.notifier).reload();
      return;
    }

    // Manual session: foreground handles Firestore writes
    FlutterForegroundTask.sendDataToTask({'command': 'manual_stop'});

    // Flush any remaining tiles directly (background already flushed its copy)
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

    ref.read(historyProvider.notifier).reload();
    ref.read(pastRoutesProvider.notifier).reload();

    state = TrackingState(
      isWatching: true,
      currentPosition: state.currentPosition,
      currentSpeedMs: state.currentSpeedMs,
      filterReason: state.filterReason,
      tileVersion: state.tileVersion,
    );
    _lastRecordedPoint = null;
  }

  // ── Auto-tracking toggle ──────────────────────────────────────────────────

  void setAutoTracking(bool enabled) {
    FlutterForegroundTask.sendDataToTask({
      'command': 'set_auto',
      'enabled': enabled,
    });
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  Future<void> _loadTiles() async {
    final tiles = await FirestoreService().loadAllCells();
    _allVisitedTiles.addAll(tiles);
    state = state.copyWith(tileVersion: state.tileVersion + 1);
  }

  void _onBackgroundData(Object data) {
    if (data is! Map<String, dynamic>) return;

    // Handle auto-session lifecycle events
    final action = data['action'] as String?;
    if (action == 'session_started') {
      _onAutoSessionStarted(data['sessionId'] as String? ?? '');
      return;
    }
    if (action == 'session_stopped') {
      _onAutoSessionStopped();
      return;
    }

    // Position update from background
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    final speed = (data['speed'] as num?)?.toDouble() ?? 0;
    final isRecording = data['isRecording'] as bool? ?? false;
    final sessionId = data['sessionId'] as String?;
    final distFromBg = (data['distanceMeters'] as num?)?.toDouble();

    if (lat == null || lng == null) return;

    // If background is recording a session we don't know about yet, sync
    if (isRecording && sessionId != null && !state.isTracking) {
      _onAutoSessionStarted(sessionId);
    }

    // For auto sessions, use distance reported by background
    if (state.isAutoSession && distFromBg != null) {
      state = state.copyWith(
        currentPosition: LatLng(lat, lng),
        currentSpeedMs: speed,
        distanceMeters: distFromBg,
      );
      return;
    }

    // For manual sessions or watching, use normal processing
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

  Future<void> _onAutoSessionStarted(String sessionId) async {
    if (state.isTracking) return; // Already tracking (manual session)
    _elapsedTimer?.cancel();
    HapticFeedback.mediumImpact();

    RouteSession? session;
    try {
      session = await FirestoreService().getActiveSession();
    } catch (_) {}

    _startElapsedTimer();
    state = state.copyWith(
      isTracking: true,
      isAutoSession: true,
      currentSession: session,
      currentRoute: [],
      distanceMeters: 0,
      elapsedSeconds: 0,
    );
  }

  void _onAutoSessionStopped() {
    _elapsedTimer?.cancel();
    ref.read(historyProvider.notifier).reload();
    ref.read(pastRoutesProvider.notifier).reload();
    state = TrackingState(
      isWatching: true,
      currentPosition: state.currentPosition,
      currentSpeedMs: state.currentSpeedMs,
      tileVersion: state.tileVersion,
    );
  }

  void _onUpdate(LocationUpdate update) {
    _processPoint(update.position, update.speedMs, update.filterReason);
  }

  void _processPoint(LatLng pos, double speed, FilterReason reason) {
    state = state.copyWith(
      currentPosition: pos,
      currentSpeedMs: speed,
      filterReason: state.isTracking && !state.isAutoSession
          ? reason
          : FilterReason.none,
    );

    // Auto sessions: background accumulates route, foreground just shows position
    if (state.isAutoSession) return;
    if (reason != FilterReason.none || !state.isTracking) return;

    final newRoute = [...state.currentRoute, pos];
    double newDist = state.distanceMeters;
    if (_lastRecordedPoint != null) {
      newDist += _distanceCalc.as(LengthUnit.Meter, _lastRecordedPoint!, pos);
    }
    _lastRecordedPoint = pos;

    final tileId = TileService().latLngToTileId(pos.latitude, pos.longitude);
    final isNewTile = !_allVisitedTiles.containsKey(tileId);
    _allVisitedTiles[tileId] = (_allVisitedTiles[tileId] ?? 0) + 1;

    state = state.copyWith(
      currentRoute: newRoute,
      distanceMeters: newDist,
      tileVersion: isNewTile ? state.tileVersion + 1 : state.tileVersion,
    );
  }
}

final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
