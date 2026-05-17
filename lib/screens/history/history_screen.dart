import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/route_session.dart';
import '../../providers/history_provider.dart';
import 'day_map_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 400) {
          ref.read(historyProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4CAF50),
            onPrimary: Colors.white,
            surface: Color(0xFF161B22),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(historyFilterProvider.notifier).state =
          HistoryFilter.custom(picked);
    }
  }

  void _setFilter(HistoryFilter filter) {
    ref.read(historyFilterProvider.notifier).state = filter;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(historyFilterProvider);
    final sessionsAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Chip(
                  label: '전체',
                  selected: filter.preset == FilterPreset.all,
                  onTap: () => _setFilter(HistoryFilter.all()),
                ),
                _Chip(
                  label: '오늘',
                  selected: filter.preset == FilterPreset.today,
                  onTap: () => _setFilter(HistoryFilter.today()),
                ),
                _Chip(
                  label: '이번 주',
                  selected: filter.preset == FilterPreset.week,
                  onTap: () => _setFilter(HistoryFilter.thisWeek()),
                ),
                _Chip(
                  label: '이번 달',
                  selected: filter.preset == FilterPreset.month,
                  onTap: () => _setFilter(HistoryFilter.thisMonth()),
                ),
                _Chip(
                  label: filter.customLabel,
                  icon: Icons.calendar_month_outlined,
                  selected: filter.preset == FilterPreset.custom,
                  onTap: _pickCustomRange,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF21262D)),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: sessionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text('오류: $e',
                        style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          ref.read(historyProvider.notifier).reload(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (data.sessions.isEmpty) return _EmptyState(filter: filter);

                final grouped = _groupByDate(data.sessions);
                final dates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  color: const Color(0xFF4CAF50),
                  onRefresh: () =>
                      ref.read(historyProvider.notifier).reload(),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: dates.length + (data.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == dates.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        );
                      }
                      final date = dates[i];
                      return _DayCard(
                          date: date, sessions: grouped[date]!);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

// ── Filter chip widget ────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4CAF50)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF4CAF50)
                : const Color(0xFF30363D),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : Colors.white54),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final HistoryFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = filter.preset == FilterPreset.all
        ? '아직 기록이 없습니다'
        : '해당 기간에 기록이 없습니다';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route, size: 56, color: Colors.white24),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: Colors.white54, fontSize: 16)),
          if (filter.preset == FilterPreset.all) ...[
            const SizedBox(height: 8),
            const Text('지도 화면에서 기록을 시작해보세요',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final String date;
  final List<RouteSession> sessions;

  const _DayCard({required this.date, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final parts = date.split('-');
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[dt.weekday - 1];
    final dateLabel = '${dt.year}년 ${dt.month}월 ${dt.day}일 ($dayName)';

    final totalDist =
        sessions.fold<double>(0, (s, r) => s + r.distanceMeters);
    final distStr = totalDist < 1000
        ? '${totalDist.toStringAsFixed(0)}m'
        : '${(totalDist / 1000).toStringAsFixed(2)}km';

    final totalSecs = sessions.fold<int>(0, (sum, s) {
      final end = s.endTime ?? DateTime.now();
      return sum + end.difference(s.startTime).inSeconds;
    });
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final durStr = h > 0 ? '${h}시간 ${m}분' : '${m}분';

    final hasActive = sessions.any((s) => s.isActive);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DayMapScreen(date: date, sessions: sessions)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasActive) ...[
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _stat(Icons.straighten, distStr),
                        const SizedBox(width: 16),
                        _stat(Icons.timer_outlined, durStr),
                        const SizedBox(width: 16),
                        _stat(Icons.route, '${sessions.length}회'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}
