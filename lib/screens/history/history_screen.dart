import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../models/route_session.dart';

final _sessionsProvider = FutureProvider<List<RouteSession>>((ref) async {
  return FirestoreService().getSessions(limit: 50);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_sessionsProvider),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('아직 기록이 없습니다',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sessions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFF30363D)),
            itemBuilder: (context, i) => _SessionTile(session: sessions[i]),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final RouteSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final date = session.startTime;
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: session.isActive
              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
              : const Color(0xFF30363D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          session.isActive ? Icons.radio_button_checked : Icons.route,
          color:
              session.isActive ? const Color(0xFF4CAF50) : Colors.white54,
          size: 22,
        ),
      ),
      title: Text(
        '$dateStr  $timeStr',
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            const Icon(Icons.straighten, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Text(session.formattedDistance,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.timer_outlined, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Text(session.formattedDuration,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
            if (session.isActive) ...[
              const SizedBox(width: 12),
              const Text('진행 중',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
