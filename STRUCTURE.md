# Footprint — 코드 구조 상세 문서

## 목차
1. [전체 디렉토리 구조](#전체-디렉토리-구조)
2. [데이터 흐름](#데이터-흐름)
3. [각 레이어 상세](#각-레이어-상세)
   - [main / app](#main--app)
   - [core](#core)
   - [models](#models)
   - [services](#services)
   - [providers](#providers)
   - [screens](#screens)
4. [Firestore 스키마](#firestore-스키마)
5. [핵심 알고리즘](#핵심-알고리즘)
6. [알려진 이슈](#알려진-이슈)

---

## 전체 디렉토리 구조

```
footprint/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── firebase_options.dart
│   ├── core/
│   │   ├── constants.dart
│   │   └── theme.dart
│   ├── data/
│   │   └── region_data.dart
│   ├── models/
│   │   ├── location_point.dart
│   │   ├── route_session.dart
│   │   └── coverage_stats.dart
│   ├── services/
│   │   ├── tile_service.dart
│   │   ├── location_service.dart
│   │   ├── firestore_service.dart
│   │   └── background_task_handler.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── tracking_provider.dart
│   │   ├── history_provider.dart
│   │   ├── past_routes_provider.dart
│   │   ├── coverage_provider.dart
│   │   └── settings_provider.dart
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart
│       ├── home/
│       │   └── home_screen.dart
│       ├── map/
│       │   ├── map_screen.dart
│       │   └── widgets/
│       │       └── tracking_controls.dart
│       ├── heatmap/
│       │   └── heatmap_screen.dart
│       ├── stats/
│       │   └── stats_screen.dart
│       ├── history/
│       │   ├── history_screen.dart
│       │   └── session_map_screen.dart
│       └── settings/
│           └── settings_screen.dart
├── assets/
│   └── icon/
│       ├── app_icon.png              # 1024×1024 — 다크 배경 + 초록 발자국
│       └── app_icon_foreground.png   # 투명 배경 (adaptive icon 전경)
├── android/
├── ios/
├── firestore.rules
└── pubspec.yaml
```

---

## 데이터 흐름

### 추적 시작 ~ 타일 저장 흐름

```
사용자 [기록 시작] 버튼
  └─ TrackingFab.onPressed
       └─ trackingProvider.notifier.startTracking()
            ├─ LocationService.requestPermissions()
            ├─ FirestoreService.createSession()         → Firestore 세션 생성
            ├─ FlutterForegroundTask.sendDataToTask(manual_start)
            ├─ LocationService.startListening()        → GPS 스트림 시작
            └─ _startElapsedTimer()                    → 1초 타이머

GPS 위치 수신
  ├─ [포그라운드] LocationService._onPosition()
  │    └─ LocationUpdate 스트림 emit
  │         └─ TrackingNotifier._onUpdate()
  │              └─ _processPoint()
  │
  └─ [백그라운드] LocationTaskHandler._onPosition()
       └─ FlutterForegroundTask.sendDataToMain({lat, lng, speed, distanceMeters, ...})
            └─ TrackingNotifier._onBackgroundData()
                 ├─ [auto session] state.copyWith(position, speed, distanceMeters)
                 └─ [manual/watching] _processPoint()

_processPoint(pos, speed, reason)
  ├─ state 업데이트 (currentPosition, currentSpeedMs, filterReason)
  ├─ [auto session] 조기 반환 (백그라운드가 경로 관리)
  ├─ [필터 통과 + 수동 추적 시]
  │    ├─ currentRoute에 좌표 추가
  │    ├─ distanceMeters 누적
  │    ├─ TileService.latLngToTileId() → tileId 생성
  │    └─ _allVisitedTiles 카운트 증가, tileVersion bump (새 타일 시)
  └─ [필터 실패 시] 위치만 업데이트
```

### 자동 세션 흐름 (background_task_handler.dart)

```
백그라운드 서비스 시작 (autoRunOnBoot 포함)
  └─ LocationTaskHandler.onStart()
       └─ geolocator 스트림 → _onPosition()
            ├─ [idle] 속도 > 임계값 → auto 모드 진입
            │    ├─ FirestoreService.createSession()
            │    └─ sendDataToMain({action: 'session_started', sessionId})
            ├─ [auto] 위치·거리 업데이트 → sendDataToMain({isRecording: true, ...})
            │    └─ 속도 < 임계값 지속 → 세션 종료
            │         ├─ FirestoreService.updateSession(ended)
            │         └─ sendDataToMain({action: 'session_stopped'})
            └─ [manual] foreground 지시에 따라 기록 / 중지
```

### 커버리지 계산 흐름

```
StatsScreen 진입
  └─ ref.watch(coverageProvider)
       └─ CoverageNotifier.build()
            ├─ FirestoreService.loadCoverageStats()   → 캐시 조회
            │    ├─ 캐시 있고 1시간 미만 → 캐시 반환
            │    ├─ 캐시 있고 1시간 이상 → 캐시 반환 + 백그라운드 재계산
            │    └─ 캐시 없음 → _compute() 즉시 실행
            │
            └─ _compute()
                 ├─ FirestoreService.loadAllCells()   → 전체 방문 타일 로드
                 ├─ TileService.worldCoveragePercent()
                 ├─ _computeForRegion(koreaRegion)    → 전국 커버리지
                 ├─ 각 시도 _computeForRegion()       → 시도 커버리지
                 ├─ 각 시도의 구·군 _computeDistrictCoverage()
                 │    └─ 타일을 작은 지역 우선으로 배타적 귀속
                 ├─ FirestoreService.getSessions()    → 총 거리 합산
                 └─ FirestoreService.saveCoverageStats() → 캐시 저장
```

### 기록 히스토리 페이지네이션 흐름

```
HistoryScreen 진입
  └─ ref.watch(historyProvider)
       └─ HistoryNotifier.build()
            ├─ [날짜 필터 있음] getSessionsPage(from, to) → 전체 로드
            └─ [전체] getSessionsPage(limit: 100) → 첫 페이지

스크롤 하단 400px 이내
  └─ HistoryNotifier.loadMore()
       ├─ [hasMore=false 또는 isLoadingMore=true] 무시
       └─ getSessionsPage(limit: 100, startAfter: _lastDoc) → 다음 페이지 추가
```

---

## 각 레이어 상세

### main / app

| 파일 | 역할 |
|------|------|
| `main.dart` | Firebase 초기화, FlutterForegroundTask 초기화, ProviderScope 루트 설정 |
| `app.dart` | MaterialApp 정의. `authStateProvider`를 watch해서 로그인 여부에 따라 `HomeScreen` 또는 `LoginScreen`으로 분기 |

**초기화 순서 (main.dart)**
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp()`
3. `FlutterForegroundTask.initCommunicationPort()` — 메인 ↔ 백그라운드 통신 포트 열기
4. `FlutterForegroundTask.init()` — 알림 채널 및 주기(3초) 설정
5. `runApp(ProviderScope(...))`

**ForegroundTaskOptions 설정:**
```dart
ForegroundTaskOptions(
  eventAction: ForegroundTaskEventAction.repeat(3000),
  autoRunOnBoot: true,
  allowWakeLock: true,
  allowWifiLock: true,
)
```

---

### core

#### `constants.dart`
앱 전역에서 사용하는 숫자 상수 모음.

| 상수 | 값 | 의미 |
|------|----|------|
| `tileZoom` | 16 | OSM 타일 줌 레벨. zoom 16 ≈ 한국 위도에서 약 600m/타일 |
| `minSpeedMs` | 0.5 m/s | GPS 드리프트 필터 하한 (정지 시 미기록) |
| `defaultMaxSpeedMs` | 8.33 m/s | 기본 최대 속도 (30 km/h, 자전거 기준) |
| `worldLandTilesZ16` | 800,000,000 | 전세계 커버리지 분모 (rough estimate) |
| `koreaTilesZ16` | 780,000 | 한국 bbox 타일 수 추정치 |
| `defaultLat/Lng` | 37.5665, 126.9780 | 초기 지도 중심 (서울 시청) |

`SpeedPreset` 목록 (설정 화면 선택지):
- 걷기 (6 km/h) → 1.67 m/s
- 빠른 걷기 (10 km/h) → 2.78 m/s
- 달리기 (20 km/h) → 5.56 m/s
- 자전거 (30 km/h) → 8.33 m/s
- 제한 없음 → 999.0 m/s

#### `theme.dart`
- 다크 테마 정의 (`AppTheme.dark`)
- 히트맵 색상 팔레트 (`AppTheme.heatmapColor(visitCount)`)

---

### models

#### `location_point.dart`
GPS 포인트 단순 모델. `LatLng` + `DateTime` + `speedMs` + `accuracy`.

#### `route_session.dart`
추적 세션 하나를 나타내는 모델.

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | String | Firestore 문서 ID |
| `startTime` | DateTime | 기록 시작 시각 |
| `endTime` | DateTime? | 기록 종료 시각 (진행 중이면 null) |
| `distanceMeters` | double | 총 이동 거리 |
| `pointCount` | int | 기록된 GPS 포인트 수 |
| `isActive` | bool | 현재 진행 중 여부 |

`formattedDistance` getter: 1000m 미만이면 "500m", 이상이면 "1.5km".  
`formattedDuration` getter: "HH:MM:SS" 또는 "MM:SS" 형태.

#### `coverage_stats.dart`
커버리지 통계 집계 결과.

| 필드 | 타입 | 설명 |
|------|------|------|
| `totalCells` | int | 방문한 총 타일 수 |
| `worldPercent` | double | 전세계 커버리지 % |
| `koreaPercent` | double | 한국 커버리지 % |
| `regionPercents` | Map\<String, double\> | 시도/구별 커버리지. 키: 지역 ID |
| `totalDistanceKm` | double | 전체 세션 누적 거리 (km) |
| `totalSessions` | int | 총 세션 수 |
| `lastComputed` | DateTime? | 마지막 계산 시각 |

---

### services

#### `tile_service.dart` (핵심)
외부 라이브러리 없이 OSM 표준 Mercator 좌표 수학으로 타일 계산.

**주요 메서드:**

| 메서드 | 입력 | 출력 | 설명 |
|--------|------|------|------|
| `latLngToTileId(lat, lng)` | 위경도 | `"16_x_y"` | 좌표 → 타일 ID |
| `latLngToTile(lat, lng)` | 위경도 | `TileCoord` | 좌표 → TileCoord 객체 |
| `tileBoundary(tile)` | TileCoord | `List<LatLng>` | 타일의 NW/NE/SE/SW 꼭짓점 4개 |
| `tileCenter(tile)` | TileCoord | `LatLng` | 타일 중심 좌표 |
| `tilesInBBox(...)` | bbox | `Set<String>` | bbox 내 모든 타일 ID 열거 |
| `countVisitedInBBox(...)` | bbox + visited | `int` | bbox 내 방문 타일 수 (빠른 경로) |
| `coveragePercent(visited, region)` | 두 Set | `double` | 교집합 비율 × 100 |
| `worldCoveragePercent(count)` | int | `double` | count / 800,000,000 × 100 |

**좌표 변환 공식 (OSM Mercator):**
```
x = floor((lon + 180) / 360 * 2^z)
y = floor((1 - ln(tan(lat_rad) + sec(lat_rad)) / π) / 2 * 2^z)
```

#### `location_service.dart`
싱글톤. GPS 스트림 관리 및 속도 필터 적용.

- `startListening()`: `distanceFilter: 5m`, `accuracy: high`로 geolocator 스트림 시작
- `_onPosition()`: speed < 0이면 0으로 보정, 속도 필터 판정 후 `LocationUpdate` emit
- `setMaxSpeed(speedMs)`: 설정에서 변경 시 동적으로 상한 업데이트

```dart
reason = speed < 0.5 ? FilterReason.tooSlow
       : (maxSpeed < 999 && speed > maxSpeed) ? FilterReason.tooFast
       : FilterReason.none;
```

#### `firestore_service.dart`
싱글톤. 모든 Firestore 읽기/쓰기 담당.

**컬렉션 경로:**
```
users/{uid}/sessions/{sessionId}
users/{uid}/cells/{tileId}
users/{uid}/stats_cache/coverage
users/{uid}.settings
```

**`recordCells(Map<String, int> tiles)`**: Firestore batch로 `count: increment(n)`, `lastVisit`, `firstVisit` 업서트.

**`getSessionsPage({from, to, limit, startAfter})`**: 커서 기반 페이지네이션.
- `limit: null` → 전체 로드 (날짜 필터 뷰)
- `startAfter: DocumentSnapshot` → 다음 페이지
- 반환: `({List<RouteSession> sessions, DocumentSnapshot? lastDoc})`

**`loadCellsSince(DateTime since)`**: `lastVisit > since` 조건으로 증분 동기화 지원.

#### `background_task_handler.dart`
별도 Dart isolate에서 실행.

- `@pragma('vm:entry-point')` — 트리 쉐이킹 방지 필수 어노테이션
- `_Mode` enum: `idle` / `auto` / `manual`
- `LocationTaskHandler.onStart()`: geolocator 스트림 시작
- `_onPosition()`: 속도·모드에 따라 자동 세션 관리 + `sendDataToMain()`
- `onRepeatEvent()`: 3초마다 알림 텍스트를 현재 속도로 업데이트
- `onReceiveData()`: foreground에서 `manual_start` / `manual_stop` / `set_auto` 명령 수신

---

### providers

#### `auth_provider.dart`

| Provider | 타입 | 역할 |
|----------|------|------|
| `authStateProvider` | `StreamProvider<User?>` | Firebase Auth 상태 스트림 |
| `currentUserProvider` | `Provider<User?>` | 현재 유저 단순 접근 |

`AuthService` (static): Google 로그인, 로그아웃 처리.

#### `tracking_provider.dart`

`TrackingState` 필드:

| 필드 | 타입 | 설명 |
|------|------|------|
| `isTracking` | bool | 현재 추적 중 여부 |
| `isWatching` | bool | GPS 수신 활성 여부 (추적 없이도 위치 표시) |
| `isAutoSession` | bool | 백그라운드 자동 감지 세션 여부 |
| `currentSession` | RouteSession? | 진행 중인 세션 |
| `currentRoute` | List\<LatLng\> | 현재 세션 경로 좌표 (수동 세션만) |
| `currentSpeedMs` | double | 최신 GPS 속도 |
| `filterReason` | FilterReason | 속도 필터 상태 |
| `currentPosition` | LatLng? | 최신 GPS 위치 |
| `distanceMeters` | double | 현재 세션 누적 거리 |
| `elapsedSeconds` | int | 현재 세션 경과 시간 (초) |
| `tileVersion` | int | 새 타일 방문 시 increment — 히트맵 갱신 트리거 |

`TrackingNotifier` 내부 상태 (non-reactive):
- `_allVisitedTiles`: 전체 방문 타일 Map (tileId → count). `allVisitedTiles` getter로 노출.
- `_elapsedTimer`: 1초 주기 경과시간 타이머
- `_lastRecordedPoint`: 거리 계산용 직전 포인트

#### `history_provider.dart`

`HistoryFilter` 팩토리 생성자:
- `HistoryFilter.all()` — 전체 (페이지네이션)
- `HistoryFilter.today()` — 오늘
- `HistoryFilter.thisWeek()` — 이번 주 (월요일 기준)
- `HistoryFilter.thisMonth()` — 이번 달
- `HistoryFilter.custom(DateTimeRange)` — 사용자 선택 범위

`HistoryData` 필드:

| 필드 | 타입 | 설명 |
|------|------|------|
| `sessions` | List\<RouteSession\> | 로드된 세션 목록 |
| `hasMore` | bool | 다음 페이지 존재 여부 |
| `isLoadingMore` | bool | 추가 로드 중 여부 |

`historyFilterProvider`: `StateProvider<HistoryFilter>` — 탭 전환 시 필터 유지.

#### `past_routes_provider.dart`
세션 id 목록 + 각 세션 경로 좌표 로드. 발자국 탭이 아닌 다른 목적(현재 미사용 or 레거시)으로 존재.

#### `coverage_provider.dart`

`AsyncNotifier`. 캐시 우선 전략:
1. Firestore 캐시 읽기
2. 캐시가 1시간 이상 됐으면 → 백그라운드에서 재계산 후 state 교체
3. 캐시 없으면 → 즉시 계산

구·군 커버리지는 `_computeDistrictCoverage()`로 배타적 타일 귀속:
- 지역을 `approximateTiles` 오름차순 정렬
- 각 타일을 중심점 기준 가장 작은 포함 지역 하나에만 귀속

#### `settings_provider.dart`

`TrackingSettings` 필드: `maxSpeedMs`, `autoTracking`

- `SharedPreferences`에 `max_speed_ms` 키로 저장
- `build()`는 기본값으로 초기화 후 즉시 `_load()` 호출해 덮어씀

---

### screens

#### `auth/login_screen.dart`
Google 로그인 버튼 하나. `AuthService.signInWithGoogle()` 호출.

#### `home/home_screen.dart`
`BottomNavigationBar` 쉘. 탭: 지도(0) / 발자국(1) / 통계(2) / 기록(3) / 설정(4).  
`initState`에서 `trackingProvider.notifier.startWatching()` 호출 → GPS + 포그라운드 서비스 시작.

#### `map/map_screen.dart`
지도 메인 화면. `flutter_map` 기반. **현재 세션 경로만 표시** (과거 누적 히트맵 제외).

레이어 구성 (아래 → 위):
1. `TileLayer` — OpenStreetMap 배경 타일
2. `PolylineLayer` — 현재 세션 경로 (초록색, 수동 세션만)
3. `MarkerLayer` — 현재 위치 원형 마커

UI 요소:
- 우측 상단: OpenStreetMap 저작권 표시
- 우측 상단 (사용자가 지도 이동 시): "내 위치로 돌아가기" 버튼
- 우측 중단: 줌 +/- 버튼
- 우측 하단: `TrackingFab` (기록 시작/중지)
- 하단 오버레이 (추적 중): 속도/거리/경과시간 배지

#### `heatmap/heatmap_screen.dart`
누적 방문 타일 히트맵. **발자국 탭** 전용.

- `ref.watch(trackingProvider.select((s) => s.tileVersion))` — 새 타일 추가 시 갱신
- `ref.read(trackingProvider.notifier).allVisitedTiles` — 전체 타일 맵
- 타일 색상: `alpha = 0.20 + log(count+1)/log(maxCount+1) * 0.70`
- 초기 카메라: 방문 타일 전체 centroid, zoom 14
- 상단 우측: 총 방문 타일 수 칩

#### `stats/stats_screen.dart`
`coverageProvider`를 watch. 상단 요약 카드 (방문 구역 / 총 거리 / 총 세션) + 지역별 커버리지.

- `_fmtPct(double pct)`: 작은 값도 유효숫자 2자리 이상 동적 표시 (0.0000001% 형태 지원)
- `_CoverageCard`: progress bar 색상이 커버리지에 따라 변화

#### `history/history_screen.dart`
`ConsumerStatefulWidget`. 기록 세션 목록.

- `ScrollController` 리스너: 하단 400px 이내 → `loadMore()` 자동 호출
- 필터 칩: 전체 / 오늘 / 이번 주 / 이번 달 / 날짜 선택(캘린더)
- `showDateRangePicker` 다크 테마 적용
- `_DaySection`: 날짜별 그룹, 하루 합계 거리 표시
- `_SessionRow`: 탭 시 `SessionMapScreen`으로 이동

#### `history/session_map_screen.dart`
개별 세션 경로를 지도에 표시. `FirestoreService.loadSessionRoute()`로 경로 GeoPoint 로드.

#### `settings/settings_screen.dart`
속도 프리셋 선택 (Radio 버튼), 배터리 최적화 제외 버튼 (`FlutterForegroundTask.requestIgnoreBatteryOptimization()`), 자동 추적 토글, 로그아웃 버튼.

---

## Firestore 스키마

```
users/
  {uid}/                              # 유저 문서 (settings 필드 포함)
    settings: { max_speed_ms: 8.33 }

    sessions/
      {sessionId}/
        startTime: Timestamp
        endTime:   Timestamp | null
        distanceMeters: number
        pointCount: number
        isActive:  boolean

    cells/
      {tileId}/                       # tileId 형식: "16_x_y"
        count:      number            # 방문 횟수 (FieldValue.increment)
        firstVisit: Timestamp
        lastVisit:  Timestamp

    stats_cache/
      coverage/
        totalCells:     number
        worldPercent:   number
        koreaPercent:   number
        regionPercents: { "KR-11": 0.5, "KR-11-110": 2.3, ... }
        totalDistanceKm: number
        totalSessions:  number
        lastComputed:   Timestamp
```

---

## 핵심 알고리즘

### 타일 ID 생성
```
zoom = 16
x = floor((lon + 180) / 360 * 65536)
y = floor((1 - log(tan(lat_rad) + 1/cos(lat_rad)) / π) / 2 * 65536)
tileId = "16_{x}_{y}"
```

### 속도 필터 판정
```
reason = speed < 0.5               → FilterReason.tooSlow
       | maxSpeed < 999
         && speed > maxSpeed       → FilterReason.tooFast
       | else                      → FilterReason.none
```

### 커버리지 % 계산
```
// bbox 내 방문 타일 수 (빠른 경로, approximateTiles > 5000)
count = visitedSet.count(tile => isInsideBBox(tile, bbox))
percent = (count / approximateTiles) * 100

// 정확한 경로 (approximateTiles ≤ 5000)
regionTiles = enumerate all tiles in bbox
percent = |visitedSet ∩ regionTiles| / |regionTiles| * 100
```

### 구·군 배타적 타일 귀속 (중복 방지)
```
sorted = districts.sortBy(approximateTiles ascending)  // 작은 지역 우선

for tile in visitedTiles:
  center = tileCenter(tile)
  for district in sorted:
    if center inside district.bbox:
      counts[district.id] += 1
      break  // 하나의 지역에만 귀속

percent[d] = counts[d] / d.approximateTiles * 100
```

### 커서 기반 히스토리 페이지네이션
```
// 첫 페이지
(sessions, lastDoc) = getSessionsPage(limit: 100)
state = HistoryData(sessions, hasMore: sessions.length >= 100)

// 다음 페이지
(more, nextDoc) = getSessionsPage(limit: 100, startAfter: lastDoc)
state = HistoryData(
  sessions: [...current, ...more],
  hasMore: more.length >= 100,
)
```

---

## 알려진 이슈

### 1. 전세계 커버리지 부정확
`worldLandTilesZ16 = 800,000,000`은 실제 육상 타일 수의 rough estimate으로, 정확한 수치가 아님. 매우 작은 비율에 영향을 줌.

### 2. H3 주석 잔재
`firestore_service.dart`의 "H3 Cells" 주석은 초기 설계(Uber H3 라이브러리)의 흔적. 실제 구현은 OSM 타일 ID 사용.

### 3. Apple 로그인 미구현
`pubspec.yaml`에 `sign_in_with_apple` 의존성이 있지만 `auth_provider.dart`에 Apple 로그인 구현이 없음.

### 4. 구·군 bbox 기반 귀속의 한계
현재 구현은 bbox(사각형) 기반. 실제 행정구역 경계는 다각형이므로, bbox가 겹치지 않더라도 실제 경계를 넘는 타일이 잘못 귀속될 수 있음. 정확한 해결책은 GeoJSON 경계 데이터 사용.
