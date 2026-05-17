import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../models/coverage_stats.dart';
import '../models/route_session.dart';

class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference get _userDoc =>
      _db.collection(AppConstants.colUsers).doc(_uid);

  CollectionReference get _sessionsCol =>
      _userDoc.collection(AppConstants.colSessions);

  CollectionReference get _cellsCol =>
      _userDoc.collection(AppConstants.colCells);

  // ── Sessions ──────────────────────────────────────────────

  Future<RouteSession> createSession() async {
    final ref = _sessionsCol.doc();
    final session = RouteSession(
      id: ref.id,
      startTime: DateTime.now(),
      distanceMeters: 0,
      pointCount: 0,
      isActive: true,
    );
    await ref.set(session.toFirestore());
    return session;
  }

  Future<void> updateSession(RouteSession session) async {
    await _sessionsCol.doc(session.id).update(session.toFirestore());
  }

  Future<void> deleteSession(String sessionId) async {
    // Delete route subcollection document first
    await _sessionsCol
        .doc(sessionId)
        .collection('route')
        .doc('points')
        .delete();
    await _sessionsCol.doc(sessionId).delete();
  }

  Future<RouteSession?> getActiveSession() async {
    final snap = await _sessionsCol
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RouteSession.fromFirestore(
        snap.docs.first.id, snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<List<RouteSession>> getSessions({int limit = 20}) async {
    final snap = await _sessionsCol
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) =>
            RouteSession.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<RouteSession>> getSessionsInRange({
    DateTime? from,
    DateTime? to,
    int limit = 300,
  }) async {
    Query query = _sessionsCol.orderBy('startTime', descending: true);
    if (from != null) {
      query = query.where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await query.limit(limit).get();
    return snap.docs
        .map((d) =>
            RouteSession.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  /// Cursor-based page fetch. Returns sessions + the last document (for next page).
  /// When [limit] is null, fetches ALL documents in the range (for date-filtered views).
  Future<({List<RouteSession> sessions, DocumentSnapshot? lastDoc})>
      getSessionsPage({
    DateTime? from,
    DateTime? to,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _sessionsCol.orderBy('startTime', descending: true);
    if (from != null) {
      query = query.where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    if (limit != null) query = query.limit(limit);

    final snap = await query.get();
    final sessions = snap.docs
        .map((d) =>
            RouteSession.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();
    final lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
    return (sessions: sessions, lastDoc: lastDoc);
  }

  // ── Route Points ──────────────────────────────────────────

  Future<void> saveSessionRoute(String sessionId, List<LatLng> points) async {
    if (points.isEmpty) return;
    await _sessionsCol.doc(sessionId).collection('route').doc('points').set({
      'points': points
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
    });
  }

  Future<List<LatLng>> loadSessionRoute(String sessionId) async {
    final doc = await _sessionsCol
        .doc(sessionId)
        .collection('route')
        .doc('points')
        .get();
    if (!doc.exists) return [];
    final pts = doc.data()?['points'] as List? ?? [];
    return pts
        .map((p) => LatLng((p as GeoPoint).latitude, p.longitude))
        .toList();
  }

  // ── H3 Cells ──────────────────────────────────────────────

  // Batch upsert visited tiles (increment by actual visit count in flush window)
  Future<void> recordCells(Map<String, int> tiles) async {
    if (tiles.isEmpty) return;

    final batch = _db.batch();
    final now = Timestamp.now();

    for (final entry in tiles.entries) {
      final ref = _cellsCol.doc(entry.key);
      batch.set(
        ref,
        {
          'count': FieldValue.increment(entry.value),
          'lastVisit': now,
          'firstVisit': now,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // Load all visited cells (returns Map<hex, count>)
  Future<Map<String, int>> loadAllCells() async {
    final snap = await _cellsCol.get();
    return Map.fromEntries(
      snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return MapEntry(d.id, (data['count'] as num?)?.toInt() ?? 1);
      }),
    );
  }

  // Load cells updated after a timestamp (for incremental sync)
  Future<Map<String, int>> loadCellsSince(DateTime since) async {
    final snap = await _cellsCol
        .where('lastVisit', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return Map.fromEntries(
      snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return MapEntry(d.id, (data['count'] as num?)?.toInt() ?? 1);
      }),
    );
  }

  // ── Coverage Stats ─────────────────────────────────────────

  Future<void> saveCoverageStats(CoverageStats stats) async {
    await _userDoc
        .collection('stats_cache')
        .doc('coverage')
        .set(stats.toFirestore());
  }

  Future<CoverageStats?> loadCoverageStats() async {
    final doc =
        await _userDoc.collection('stats_cache').doc('coverage').get();
    if (!doc.exists) return null;
    return CoverageStats.fromFirestore(doc.data()!);
  }

  // ── Profile / Settings ────────────────────────────────────

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _userDoc.set({'settings': settings}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['settings'] as Map<String, dynamic>?;
  }
}
