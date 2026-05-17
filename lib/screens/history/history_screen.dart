import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/route_session.dart';
import '../../providers/past_routes_provider.dart';
import 'session_map_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(pastRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(pastRoutesProvider.notifier).reload(),
          ),
        ],
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('아직 기록이 없습니다',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('지도 화면에서 기록을 시작해보세요',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          final grouped = _groupByDate(routes.map((r) => r.session).toList());
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: dates.length,
            itemBuilder: (context, i) {
              final date = dates[i];
              final sessions = grouped[date]!;
              return _DaySection(date: date, sessions: sessions);
            },
          );
        },
      ),
    );
  }

  Map<String, List<RouteSession>> _groupByDate(List<RouteSession> sessions) {
    final map = <String, List<RouteSession>>{};
    for (final s in sessions) {
      final key =
          '${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}-${s.startTime.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }
}

class _DaySection extends StatelessWidget {
  final String date; // "2026-05-17"
  final List<RouteSession> sessions;

  const _DaySection({required this.date, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final parts = date.split('-');
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[dt.weekday - 1];
    final dateLabel =
        '${dt.year}년 ${dt.month}월 ${dt.day}일 ($dayName)';

    final totalDist =
        sessions.fold<double>(0, (s, r) => s + r.distanceMeters);
    final totalDistStr = totalDist < 1000
        ? '${totalDist.toStringAsFixed(0)}m'
        : '${(totalDist / 1000).toStringAsFixed(2)}km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                '합계 $totalDistStr',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Sessions for this day
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            children: sessions.asMap().entries.map((e) {
              final isLast = e.key == sessions.length - 1;
              return _SessionRow(
                session: e.value,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final RouteSession session;
  final bool isLast;

  const _SessionRow({required this.session, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionMapScreen(session: session),
        ),
      ),
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(12))
          : BorderRadius.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Timeline dot
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: session.isActive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF30363D),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: session.isActive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF58A6FF),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Time
                SizedBox(
                  width: 44,
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stats
                Expanded(
                  child: Row(
                    children: [
                      _statItem(Icons.straighten,
                          session.formattedDistance),
                      const SizedBox(width: 12),
                      _statItem(Icons.timer_outlined,
                          session.formattedDuration),
                      if (session.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('진행 중',
                              style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
                // Map arrow
                const Icon(Icons.chevron_right,
                    color: Colors.white24, size: 18),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
                height: 1, indent: 40, color: Color(0xFF21262D)),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      );
}
