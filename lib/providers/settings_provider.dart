import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class TrackingSettings {
  final double maxSpeedMs;
  final bool autoTracking;
  final bool recordAltitude;

  const TrackingSettings({
    required this.maxSpeedMs,
    this.autoTracking = true,
    this.recordAltitude = true,
  });

  TrackingSettings copyWith({
    double? maxSpeedMs,
    bool? autoTracking,
    bool? recordAltitude,
  }) =>
      TrackingSettings(
        maxSpeedMs: maxSpeedMs ?? this.maxSpeedMs,
        autoTracking: autoTracking ?? this.autoTracking,
        recordAltitude: recordAltitude ?? this.recordAltitude,
      );
}

class SettingsNotifier extends Notifier<TrackingSettings> {
  static const _keyMaxSpeed = 'max_speed_ms';
  static const _keyAutoTracking = 'auto_tracking';

  @override
  TrackingSettings build() {
    _load();
    return const TrackingSettings(maxSpeedMs: AppConstants.defaultMaxSpeedMs);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      maxSpeedMs: prefs.getDouble(_keyMaxSpeed) ?? AppConstants.defaultMaxSpeedMs,
      autoTracking: prefs.getBool(_keyAutoTracking) ?? true,
    );
  }

  Future<void> setMaxSpeed(double speedMs) async {
    state = state.copyWith(maxSpeedMs: speedMs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxSpeed, speedMs);
  }

  Future<void> setAutoTracking(bool enabled) async {
    state = state.copyWith(autoTracking: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoTracking, enabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, TrackingSettings>(SettingsNotifier.new);

