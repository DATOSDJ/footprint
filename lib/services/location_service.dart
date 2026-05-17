import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

enum FilterReason { none, tooSlow, tooFast }

class LocationUpdate {
  final LatLng position;
  final double speedMs;
  final double accuracy;
  final DateTime timestamp;
  final FilterReason filterReason;

  const LocationUpdate({
    required this.position,
    required this.speedMs,
    required this.accuracy,
    required this.timestamp,
    required this.filterReason,
  });

  bool get isFiltered => filterReason != FilterReason.none;
}

class LocationService {
  static final LocationService _i = LocationService._();
  factory LocationService() => _i;
  LocationService._();

  StreamSubscription<Position>? _positionSub;
  final _controller = StreamController<LocationUpdate>.broadcast();
  double _maxSpeedMs = AppConstants.defaultMaxSpeedMs;

  Stream<LocationUpdate> get updates => _controller.stream;

  void setMaxSpeed(double speedMs) {
    _maxSpeedMs = speedMs;
  }

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return false;
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<LatLng?> getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  void startListening() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        timeLimit: null,
      ),
    ).listen(_onPosition);
  }

  void stopListening() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _onPosition(Position pos) {
    final speedMs = pos.speed < 0 ? 0.0 : pos.speed;
    final FilterReason reason;
    if (speedMs < AppConstants.minSpeedMs) {
      reason = FilterReason.tooSlow;
    } else if (_maxSpeedMs < 999 && speedMs > _maxSpeedMs) {
      reason = FilterReason.tooFast;
    } else {
      reason = FilterReason.none;
    }

    _controller.add(LocationUpdate(
      position: LatLng(pos.latitude, pos.longitude),
      speedMs: speedMs,
      accuracy: pos.accuracy,
      timestamp: pos.timestamp,
      filterReason: reason,
    ));
  }

  void dispose() {
    _positionSub?.cancel();
    _controller.close();
  }
}

extension SpeedExtension on double {
  double get kmh => this * 3.6;
  String get formattedSpeed => '${(this * 3.6).toStringAsFixed(1)} km/h';
}
