import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_session.dart';
import '../services/firestore_service.dart';

// ── Filter model ──────────────────────────────────────────────────────────────

enum FilterPreset { all, today, week, month, custom }

class HistoryFilter {
  final FilterPreset preset;
  final DateTime? from;
  final DateTime? to;

  const HistoryFilter({
    this.preset = FilterPreset.all,
    this.from,
    this.to,
  });

  factory HistoryFilter.all() => const HistoryFilter(preset: FilterPreset.all);

  factory HistoryFilter.today() {
    final n = DateTime.now();
    return HistoryFilter(
      preset: FilterPreset.today,
      from: DateTime(n.year, n.month, n.day),
      to: DateTime(n.year, n.month, n.day, 23, 59, 59),
    );
  }

  factory HistoryFilter.thisWeek() {
    final n = DateTime.now();
    final start = n.subtract(Duration(days: n.weekday - 1));
    return HistoryFilter(
      preset: FilterPreset.week,
      from: DateTime(start.year, start.month, start.day),
      to: DateTime(n.year, n.month, n.day, 23, 59, 59),
    );
  }

  factory HistoryFilter.thisMonth() {
    final n = DateTime.now();
    return HistoryFilter(
      preset: FilterPreset.month,
      from: DateTime(n.year, n.month, 1),
      to: DateTime(n.year, n.month, n.day, 23, 59, 59),
    );
  }

  factory HistoryFilter.custom(DateTimeRange range) => HistoryFilter(
        preset: FilterPreset.custom,
        from: range.start,
        to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
      );

  bool get hasDateRange => from != null || to != null;

  String get customLabel {
    if (preset != FilterPreset.custom || from == null) return '날짜 선택';
    final t = to ?? from!;
    return '${from!.month}/${from!.day} ~ ${t.month}/${t.day}';
  }
}

final historyFilterProvider = StateProvider<HistoryFilter>(
  (ref) => const HistoryFilter(),
);

// ── Data model ────────────────────────────────────────────────────────────────

class HistoryData {
  final List<RouteSession> sessions;
  final bool hasMore;       // more pages available (only for "전체")
  final bool isLoadingMore;

  const HistoryData({
    required this.sessions,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  HistoryData copyWith({
    List<RouteSession>? sessions,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      HistoryData(
        sessions: sessions ?? this.sessions,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

const _pageSize = 100;

class HistoryNotifier extends AsyncNotifier<HistoryData> {
  DocumentSnapshot? _lastDoc;

  @override
  Future<HistoryData> build() async {
    _lastDoc = null;
    final filter = ref.watch(historyFilterProvider);

    // Date-filtered views: load everything in the range (no pagination).
    // The date range itself bounds the result set.
    if (filter.hasDateRange) {
      final r = await FirestoreService().getSessionsPage(
        from: filter.from,
        to: filter.to,
      );
      _lastDoc = r.lastDoc;
      return HistoryData(sessions: r.sessions, hasMore: false);
    }

    // "전체": paginated, 100 at a time
    final r = await FirestoreService().getSessionsPage(limit: _pageSize);
    _lastDoc = r.lastDoc;
    return HistoryData(
      sessions: r.sessions,
      hasMore: r.sessions.length >= _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final r = await FirestoreService().getSessionsPage(
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      _lastDoc = r.lastDoc;
      state = AsyncData(HistoryData(
        sessions: [...current.sessions, ...r.sessions],
        hasMore: r.sessions.length >= _pageSize,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await FirestoreService().deleteSession(sessionId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      sessions: current.sessions.where((s) => s.id != sessionId).toList(),
    ));
  }

  Future<void> reload() async {
    _lastDoc = null;
    state = const AsyncLoading();
    final filter = ref.read(historyFilterProvider);
    state = await AsyncValue.guard(() async {
      if (filter.hasDateRange) {
        final r = await FirestoreService().getSessionsPage(
          from: filter.from,
          to: filter.to,
        );
        _lastDoc = r.lastDoc;
        return HistoryData(sessions: r.sessions, hasMore: false);
      }
      final r = await FirestoreService().getSessionsPage(limit: _pageSize);
      _lastDoc = r.lastDoc;
      return HistoryData(
        sessions: r.sessions,
        hasMore: r.sessions.length >= _pageSize,
      );
    });
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, HistoryData>(HistoryNotifier.new);
