import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

// Runs in a separate isolate (background service)
class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    _lastPosition = pos;
    // Send position data to main isolate
    FlutterForegroundTask.sendDataToMain({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': pos.speed < 0 ? 0.0 : pos.speed,
      'accuracy': pos.accuracy,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Update notification with current speed
    if (_lastPosition != null) {
      final speed = _lastPosition!.speed;
      final speedKmh = speed > 0 ? (speed * 3.6).toStringAsFixed(1) : '0.0';
      await FlutterForegroundTask.updateService(
        notificationText: '속도: $speedKmh km/h · 기록 중...',
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _positionSub?.cancel();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}
}
