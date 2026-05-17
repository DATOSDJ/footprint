import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/region_data.dart';
import '../../models/coverage_stats.dart';
import '../../providers/coverage_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(coverageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 발자국'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(coverageProvider.notifier).refresh(),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('통계 로드 실패',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(coverageProvider.notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (stats) => _StatsBody(stats: stats),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final CoverageStats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary cards ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: '방문 구역',
                value: nf.format(stats.totalCells),
                unit: '타일',
                icon: Icons.grid_on,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: '총 거리',
                value: stats.totalDistanceKm.toStringAsFixed(1),
                unit: 'km',
                icon: Icons.straighten,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: '총 세션',
                value: nf.format(stats.totalSessions),
                unit: '회',
                icon: Icons.route,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Global coverage ────────────────────────────────────
        const _SectionHeader('전국 커버리지'),
        const SizedBox(height: 12),
        _CoverageCard(
          emoji: '🌍',
          label: '전 세계',
          percent: stats.worldPercent,
          sublabel: '육상 기준 추정치',
        ),
        const SizedBox(height: 8),
        _CoverageCard(
          emoji: '🇰🇷',
          label: '대한민국',
          percent: stats.koreaPercent,
        ),

        // ── Province coverage ──────────────────────────────────
        const SizedBox(height: 24),
        const _SectionHeader('시도별 커버리지'),
        const SizedBox(height: 12),

        ...koreaProvinces.map((province) {
          final pct = stats.regionPercents[province.id] ?? 0;
          final districts = getDistrictsOf(province.id);
          final hasDistricts = districts.isNotEmpty;

          if (!hasDistricts) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CoverageCard(
                emoji: _provinceEmoji(province.id),
                label: province.name,
                percent: pct,
                compact: true,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProvinceExpansionCard(
              province: province,
              percent: pct,
              districts: districts,
              regionPercents: stats.regionPercents,
            ),
          );
        }),

        const SizedBox(height: 24),
        if (stats.lastComputed != null)
          Center(
            child: Text(
              '마지막 계산: ${DateFormat('MM/dd HH:mm').format(stats.lastComputed!)}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _provinceEmoji(String id) {
    switch (id) {
      case 'KR-11': return '🏙️';
      case 'KR-26': return '🌊';
      case 'KR-27': return '🍎';
      case 'KR-28': return '✈️';
      case 'KR-29': return '🎨';
      case 'KR-30': return '🔬';
      case 'KR-31': return '🏭';
      case 'KR-36': return '🏛️';
      case 'KR-41': return '🌆';
      case 'KR-42': return '⛰️';
      case 'KR-43': return '🌲';
      case 'KR-44': return '🌾';
      case 'KR-45': return '🍚';
      case 'KR-46': return '🌺';
      case 'KR-47': return '🍑';
      case 'KR-48': return '🌅';
      case 'KR-50': return '🍊';
      default: return '📍';
    }
  }
}

class _ProvinceExpansionCard extends StatelessWidget {
  final RegionData province;
  final double percent;
  final List<RegionData> districts;
  final Map<String, double> regionPercents;

  const _ProvinceExpansionCard({
    required this.province,
    required this.percent,
    required this.districts,
    required this.regionPercents,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    final displayPct = pct < 0.001 ? '< 0.001' : pct.toStringAsFixed(4);

    // Sort districts by coverage descending
    final sorted = [...districts]
      ..sort((a, b) =>
          (regionPercents[b.id] ?? 0).compareTo(regionPercents[a.id] ?? 0));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Text(
                province.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$displayPct%',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: const Color(0xFF30363D),
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct > 50
                      ? const Color(0xFF4CAF50)
                      : pct > 10
                          ? const Color(0xFF81C784)
                          : Color.fromRGBO(76, 175, 80, 0.6),
                ),
              ),
            ),
          ),
          children: sorted.map((district) {
            final dPct = (regionPercents[district.id] ?? 0).clamp(0.0, 100.0);
            final dDisplay =
                dPct < 0.001 ? '< 0.001' : dPct.toStringAsFixed(3);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              district.name,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$dDisplay%',
                              style: const TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: dPct / 100,
                            minHeight: 3,
                            backgroundColor: const Color(0xFF30363D),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              dPct > 30
                                  ? const Color(0xFF4CAF50)
                                  : Color.fromRGBO(76, 175, 80, 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          Text(unit,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

class _CoverageCard extends StatelessWidget {
  final String emoji;
  final String label;
  final double percent;
  final String? sublabel;
  final bool compact;

  const _CoverageCard({
    required this.emoji,
    required this.label,
    required this.percent,
    this.sublabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    final displayPct = pct < 0.001 ? '< 0.001' : pct.toStringAsFixed(4);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: compact ? 14.0 : 18.0)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$displayPct%',
                style: TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontSize: compact ? 14.0 : 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: compact ? 4.0 : 6.0,
              backgroundColor: const Color(0xFF30363D),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct > 50
                    ? const Color(0xFF4CAF50)
                    : pct > 10
                        ? const Color(0xFF81C784)
                        : Color.fromRGBO(76, 175, 80, 0.6),
              ),
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 6),
            Text(sublabel!,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
