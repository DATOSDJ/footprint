import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class TrackingSettings {
  final double maxSpeedMs;
  final bool recordAltitude;
  final bool vibrateOnFilter;

  const TrackingSettings({
    required this.maxSpeedMs,
    this.recordAltitude = true,
    this.vibrateOnFilter = false,
  });

  TrackingSettings copyWith({double? maxSpeedMs, bool? recordAltitude, bool? vibrateOnFilter}) =>
      TrackingSettings(
        maxSpeedMs: maxSpeedMs ?? this.maxSpeedMs,
        recordAltitude: recordAltitude ?? this.recordAltitude,
        vibrateOnFilter: vibrateOnFilter ?? this.vibrateOnFilter,
      );
}

class SettingsNotifier extends Notifier<TrackingSettings> {
  static const _keyMaxSpeed = 'max_speed_ms';

  @override
  TrackingSettings build() {
    _load();
    return TrackingSettings(maxSpeedMs: AppConstants.defaultMaxSpeedMs);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getDouble(_keyMaxSpeed) ?? AppConstants.defaultMaxSpeedMs;
    state = state.copyWith(maxSpeedMs: speed);
  }

  Future<void> setMaxSpeed(double speedMs) async {
    state = state.copyWith(maxSpeedMs: speedMs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxSpeed, speedMs);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, TrackingSettings>(
  SettingsNotifier.new,
);
