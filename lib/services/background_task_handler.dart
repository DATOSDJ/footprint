import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

// Recording mode
enum _Mode { idle, auto, manual }

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;

  // Firebase
  bool _ready = false;
  String? _uid;

  // State
  _Mode _mode = _Mode.idle;
  bool _autoEnabled = true;
  String? _sessionId;
  final _recentSpeeds = <double>[];
  DateTime? _lastMovingTime;
  Position? _lastPos;
  double _totalDistM = 0;
  final _routePoints = <GeoPoint>[];
  final _pendingTiles = <String, int>{};
  Timer? _flushTimer;

  // Thresholds
  static const _minSpeedMs = 0.5;
  static const _autoStartSamples = 6;   // 6 samples > min → auto-start (~18s at 3s interval)
  static const _autoStopSecs = 300;     // 5 min stationary → auto-stop

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize Firebase in this background isolate
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      _uid = FirebaseAuth.instance.currentUser?.uid;
      _ready = _uid != null;
    } catch (_) {}

    // Resume any active session from Firestore (e.g., after crash/reboot)
    if (_ready) {
      final activeId = await _fetchActiveId();
      if (activeId != null) {
        _sessionId = activeId;
        _mode = _Mode.auto;
        _lastMovingTime = DateTime.now();
      }
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    _flushTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _flush());
  }

  void _onPosition(Position pos) {
    final speed = pos.speed < 0 ? 0.0 : pos.speed;

    // Always send position to main isolate (UI update when app is open)
    FlutterForegroundTask.sendDataToMain({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': speed,
      'accuracy': pos.accuracy,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
      'isRecording': _mode != _Mode.idle,
      'sessionId': _sessionId,
      'distanceMeters': _totalDistM,
    });

    // Update notification text
    final kmh = (speed * 3.6).toStringAsFixed(1);
    final notif = switch (_mode) {
      _Mode.auto => '자동 기록 중 · $kmh km/h',
      _Mode.manual => '기록 중 · $kmh km/h',
      _Mode.idle => speed > _minSpeedMs ? '이동 감지 · $kmh km/h' : '대기 중...',
    };
    FlutterForegroundTask.updateService(notificationText: notif);

    if (!_ready) return;

    _recentSpeeds.add(speed);
    if (_recentSpeeds.length > 10) _recentSpeeds.removeAt(0);

    switch (_mode) {
      case _Mode.idle:
        if (_autoEnabled) _checkAutoStart(pos);
      case _Mode.auto:
        _recordPoint(pos, speed);
        _checkAutoStop();
      case _Mode.manual:
        _recordPoint(pos, speed);
    }
  }

  void _checkAutoStart(Position pos) {
    final moving = _recentSpeeds.where((s) => s > _minSpeedMs).length;
    if (moving >= _autoStartSamples && _recentSpeeds.length >= _autoStartSamples) {
      _startAutoSession(pos);
    }
  }

  void _checkAutoStop() {
    if (_lastMovingTime == null) return;
    final stationarySecs =
        DateTime.now().difference(_lastMovingTime!).inSeconds;
    if (stationarySecs >= _autoStopSecs) _stopAutoSession();
  }

  void _recordPoint(Position pos, double speed) {
    if (speed < _minSpeedMs) return;
    _lastMovingTime = DateTime.now();
    if (_lastPos != null) {
      _totalDistM += Geolocator.distanceBetween(
        _lastPos!.latitude, _lastPos!.longitude,
        pos.latitude, pos.longitude,
      );
    }
    _lastPos = pos;
    _routePoints.add(GeoPoint(pos.latitude, pos.longitude));
    final id = _tileId(pos.latitude, pos.longitude);
    _pendingTiles[id] = (_pendingTiles[id] ?? 0) + 1;
  }

  Future<void> _startAutoSession(Position pos) async {
    _mode = _Mode.auto;
    _lastMovingTime = DateTime.now();
    _routePoints.clear();
    _pendingTiles.clear();
    _totalDistM = 0;
    _lastPos = pos;

    final ref = FirebaseFirestore.instance
        .collection('users').doc(_uid)
        .collection('sessions').doc();
    _sessionId = ref.id;
    await ref.set({
      'startTime': Timestamp.now(),
      'distanceMeters': 0.0,
      'pointCount': 0,
      'isActive': true,
    });

    FlutterForegroundTask.sendDataToMain({
      'action': 'session_started',
      'sessionId': _sessionId,
    });
  }

  Future<void> _stopAutoSession() async {
    if (_sessionId == null || _uid == null) {
      _mode = _Mode.idle;
      return;
    }
    await _flush();

    if (_routePoints.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('sessions').doc(_sessionId)
          .collection('route').doc('points')
          .set({'points': _routePoints});
    }

    await FirebaseFirestore.instance
        .collection('users').doc(_uid)
        .collection('sessions').doc(_sessionId)
        .update({
      'endTime': Timestamp.now(),
      'distanceMeters': _totalDistM,
      'pointCount': _routePoints.length,
      'isActive': false,
    });

    FlutterForegroundTask.sendDataToMain({
      'action': 'session_stopped',
      'sessionId': _sessionId,
    });

    _mode = _Mode.idle;
    _sessionId = null;
    _routePoints.clear();
    _pendingTiles.clear();
    _totalDistM = 0;
    _lastPos = null;
  }

  Future<void> _flush() async {
    if (_pendingTiles.isEmpty || _uid == null) return;
    final toFlush = Map<String, int>.from(_pendingTiles);
    _pendingTiles.clear();
    final batch = FirebaseFirestore.instance.batch();
    final now = Timestamp.now();
    for (final e in toFlush.entries) {
      final ref = FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('cells').doc(e.key);
      batch.set(ref, {
        'count': FieldValue.increment(e.value),
        'lastVisit': now,
        'firstVisit': now,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<String?> _fetchActiveId() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('sessions')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      return snap.docs.isEmpty ? null : snap.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  String _tileId(double lat, double lng, {int zoom = 16}) {
    final n = 1 << zoom;
    final x = ((lng + 180) / 360 * n).floor();
    final latRad = lat * math.pi / 180;
    final y = ((1 -
                math.log(math.tan(latRad) + 1 / math.cos(latRad)) /
                    math.pi) /
            2 *
            n)
        .floor();
    return '${zoom}_${x}_$y';
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _flushTimer?.cancel();
    await _positionSub?.cancel();
  }

  // Receive commands from main isolate
  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final cmd = data['command'] as String?;
    switch (cmd) {
      case 'manual_start':
        // Main isolate started a session — enter manual mode
        _mode = _Mode.manual;
        _sessionId = data['sessionId'] as String?;
        _lastMovingTime = DateTime.now();
        _routePoints.clear();
        _pendingTiles.clear();
        _totalDistM = 0;
        _lastPos = null;
      case 'manual_stop':
        // Main isolate finished — return to idle
        _mode = _Mode.idle;
        _sessionId = null;
        _routePoints.clear();
        _pendingTiles.clear();
        _totalDistM = 0;
        _lastPos = null;
      case 'set_auto':
        _autoEnabled = data['enabled'] as bool? ?? true;
        if (!_autoEnabled && _mode == _Mode.auto) _stopAutoSession();
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}
}
