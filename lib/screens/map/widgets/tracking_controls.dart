import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/tracking_provider.dart';
import '../../../services/location_service.dart';

class TrackingFab extends ConsumerWidget {
  const TrackingFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (tracking.isTracking) ...[
          // Elapsed time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  _formatElapsed(tracking.elapsedSeconds),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Speed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tracking.isFiltered
                  ? const Color(0xFFF44336).withValues(alpha: 0.9)
                  : const Color(0xFF161B22).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tracking.isFiltered
                    ? Colors.red
                    : const Color(0xFF30363D),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tracking.isFiltered
                      ? Icons.block
                      : Icons.radio_button_checked,
                  size: 12,
                  color: tracking.isFiltered ? Colors.white : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  _speedLabel(tracking),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Distance badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              tracking.currentSession
                      ?.copyWith(distanceMeters: tracking.distanceMeters)
                      .formattedDistance ??
                  '0m',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
        ],

        FloatingActionButton.extended(
          onPressed: () {
            if (tracking.isTracking) {
              ref.read(trackingProvider.notifier).stopTracking();
            } else {
              ref.read(trackingProvider.notifier).startTracking();
            }
          },
          backgroundColor: tracking.isTracking
              ? const Color(0xFFF44336)
              : const Color(0xFF4CAF50),
          icon: Icon(
            tracking.isTracking ? Icons.stop : Icons.play_arrow,
            color: Colors.white,
          ),
          label: Text(
            tracking.isTracking ? '기록 중지' : '기록 시작',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _speedLabel(TrackingState tracking) {
    switch (tracking.filterReason) {
      case FilterReason.tooSlow:
        return '정지 중 (미기록)';
      case FilterReason.tooFast:
        return '속도 초과 (미기록)';
      case FilterReason.none:
        return tracking.currentSpeedMs.formattedSpeed;
    }
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
