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
│       │       ├── heatmap_layer.dart
│       │       └── tracking_controls.dart
│       ├── stats/
│       │   └── stats_screen.dart
│       └── settings/
│           └── settings_screen.dart
├── assets/
│   └── geojson/           # 지역 경계 데이터 (미사용 가능성 있음)
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
            ├─ FlutterForegroundTask.startService()    → 백그라운드 알림 시작
            ├─ LocationService.startListening()        → GPS 스트림 시작
            └─ Timer(10s) → _flush()                   → Firestore 배치 쓰기

GPS 위치 수신
  ├─ [포그라운드] LocationService._onPosition()
  │    └─ LocationUpdate 스트림 emit
  │         └─ TrackingNotifier._onUpdate()
  │              └─ _processPoint()
  │
  └─ [백그라운드] LocationTaskHandler._onPosition()
       └─ FlutterForegroundTask.sendDataToMain()
            └─ TrackingNotifier._onBackgroundData()
                 └─ _processPoint()

_processPoint(pos, speed, isFiltered)
  ├─ state 업데이트 (currentPosition, currentSpeedMs, isFiltered)
  ├─ [필터 통과 시]
  │    ├─ currentRoute에 좌표 추가
  │    ├─ distanceMeters 누적
  │    ├─ TileService.latLngToTileId() → tileId 생성
  │    ├─ _pendingTiles에 추가
  │    └─ _allVisitedTiles 카운트 증가
  └─ [필터 실패 시] 위치만 업데이트, 기록 안 함

매 10초 _flush()
  └─ FirestoreService.recordCells(_pendingTiles)
       └─ Firestore batch.set (count increment)
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
                 ├─ 각 지역(한국, 시도, 구)별 _computeForRegion()
                 │    ├─ [타일 수 > 5000] countVisitedInBBox() — 빠른 경로
                 │    └─ [타일 수 ≤ 5000] tilesInBBox() 후 교집합 — 정확한 경로
                 ├─ FirestoreService.getSessions()    → 총 거리 합산
                 └─ FirestoreService.saveCoverageStats() → 캐시 저장
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
| `seoulTilesZ16` | 2,800 | 서울 bbox 타일 수 추정치 |
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

| 방문 횟수 | 색상 |
|-----------|------|
| 1 ~ 4 | `#4CAF50` (초록) — 첫 방문 |
| 5 ~ 19 | `#FFEB3B` (노랑) — 자주 방문 |
| 20+ | `#F44336` (빨강) — 단골 |

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

`formattedDistance` getter: 1000m 미만이면 "500m", 이상이면 "1.5km" 형태 반환.

#### `coverage_stats.dart`
커버리지 통계 집계 결과.

| 필드 | 타입 | 설명 |
|------|------|------|
| `totalCells` | int | 방문한 총 타일 수 |
| `worldPercent` | double | 전세계 커버리지 % |
| `koreaPercent` | double | 한국 커버리지 % |
| `regionPercents` | Map\<String, double\> | 시도/구별 커버리지. 키: 지역 ID (예: `KR-11`, `KR-11-110`) |
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
isFiltered = speedMs < 0.5 || (maxSpeed < 999 && speedMs > maxSpeed)
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

**`recordCells(List<String> cellIds)`**: Firestore batch로 `count: increment(1)`, `lastVisit`, `firstVisit` 업서트. 동일 타일 중복 방지를 위해 `.toSet()` 후 처리.

**`loadCellsSince(DateTime since)`**: `lastVisit > since` 조건으로 증분 동기화 지원 (현재 미사용).

#### `background_task_handler.dart`
별도 Dart isolate에서 실행.

- `@pragma('vm:entry-point')` — 트리 쉐이킹 방지를 위한 필수 어노테이션
- `LocationTaskHandler.onStart()`: geolocator 스트림 시작
- `_onPosition()`: 위치를 `sendDataToMain({lat, lng, speed, accuracy, timestamp})`로 메인 isolate에 전송
- `onRepeatEvent()`: 3초마다 알림 텍스트를 현재 속도로 업데이트

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
| `currentSession` | RouteSession? | 진행 중인 세션 |
| `currentRoute` | List\<LatLng\> | 현재 세션 경로 좌표 목록 |
| `currentSpeedMs` | double | 최신 GPS 속도 |
| `isFiltered` | bool | 속도 필터로 제외 중인지 여부 |
| `currentPosition` | LatLng? | 최신 GPS 위치 |
| `distanceMeters` | double | 현재 세션 누적 거리 |

`TrackingNotifier` 내부 상태 (non-reactive):
- `_pendingTiles`: Firestore 배치 flush 대기 중인 타일 Set
- `_allVisitedTiles`: 전체 방문 타일 Map (tileId → count). `allVisitedTiles` getter로 노출.
- `_flushTimer`: 10초 주기 Firestore 배치 쓰기
- `_lastRecordedPoint`: 거리 계산용 직전 포인트

#### `coverage_provider.dart`

`AsyncNotifier`. 캐시 우선 전략:
1. Firestore 캐시 읽기
2. 캐시가 1시간 이상 됐으면 → 백그라운드에서 재계산 후 state 교체
3. 캐시 없으면 → 즉시 계산

타일 수에 따른 두 계산 경로:
- **빠른 경로** (타일 > 5,000): bbox 내 방문 타일 count / approximateTiles
- **정확한 경로** (타일 ≤ 5,000): 지역 타일 전체 열거 후 교집합

#### `settings_provider.dart`

`TrackingSettings` 필드: `maxSpeedMs`, `recordAltitude`, `vibrateOnFilter`

- `SharedPreferences`에 `max_speed_ms` 키로 저장
- `build()`는 기본값으로 초기화 후 즉시 `_load()` 호출해 덮어씀

---

### screens

#### `auth/login_screen.dart`
Google 로그인 버튼 하나. `AuthService.signInWithGoogle()` 호출.

#### `home/home_screen.dart`
`BottomNavigationBar` 쉘. 탭: 지도(0), 통계(1), 설정(2).
`initState`에서 `trackingProvider.notifier.loadTiles()` 호출해 Firestore에서 전체 방문 타일 로드.

#### `map/map_screen.dart`
지도 메인 화면. `flutter_map` 기반.

레이어 구성 (아래 → 위):
1. `TileLayer` — OpenStreetMap 배경 타일
2. `HeatmapLayer` — 방문 타일 히트맵 폴리곤
3. `PolylineLayer` — 현재 세션 경로 (초록색)
4. `MarkerLayer` — 현재 위치 원형 마커

UI 요소:
- 우측 상단: OpenStreetMap 저작권 표시
- 우측 상단 (사용자가 지도 이동 시): "내 위치로 돌아가기" 버튼
- 우측 중단: 줌 +/- 버튼
- 우측 하단: `TrackingFab` (기록 시작/중지)
- 좌측 하단 (zoom ≥ 11): 히트맵 범례 (첫 방문 / 자주 방문 / 단골)

`_followUser` 플래그: 사용자가 지도를 직접 드래그하면 false, "내 위치" 버튼 누르면 true.

#### `map/widgets/heatmap_layer.dart`
zoom < 11이면 렌더링 스킵 (성능 최적화). 각 타일 ID를 `TileCoord`로 파싱 후 `tileBoundary()`로 꼭짓점 계산, `PolygonLayer`로 렌더링.

#### `map/widgets/tracking_controls.dart`
`TrackingFab`: 추적 상태에 따라 기록 시작(초록) / 기록 중지(빨강) FAB 표시.
추적 중일 때:
- 속도 배지: 필터 걸리면 빨간 배경 + "속도 초과 (미기록)" 표시
- 거리 배지: 현재 세션 누적 거리 표시

#### `stats/stats_screen.dart`
`coverageProvider`를 watch. 상단 3개 요약 카드 (방문 구역 / 총 거리 / 총 세션) + 지역별 커버리지 progress bar.

`_CoverageCard`: progress bar 색상이 커버리지에 따라 변화 (50% 이상: 초록 / 10~50%: 연초록 / 10% 미만: 반투명 초록).

#### `settings/settings_screen.dart`
속도 프리셋 선택 (Radio 버튼), 로그아웃 버튼.

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
isFiltered = (speed < 0.5 m/s)                        // 정지 / GPS 드리프트
          || (maxSpeed < 999 && speed > maxSpeed)      // 차량 등 고속 이동
```

### 커버리지 % 계산
```
// bbox 내 방문 타일 수 (빠른 경로)
count = visitedSet.count(tile => isInsideBBox(tile, bbox))
percent = (count / approximateTiles) * 100

// 정확한 경로
regionTiles = enumerate all tiles in bbox
percent = |visitedSet ∩ regionTiles| / |regionTiles| * 100
```

### Firestore 배치 전략
- 추적 중 GPS 포인트마다 `_pendingTiles` Set에 누적
- 10초마다 flush: batch.set으로 한 번에 upsert
- 중복 좌표 자동 제거 (Set 특성)

---

## 알려진 이슈

### 1. 히트맵 실시간 미갱신
`map_screen.dart:31`에서 `ref.read` 사용으로 인해 추적 중 새 타일 추가 시 히트맵이 자동 업데이트되지 않음.

```dart
// 현재 (반응형 아님)
final tiles = ref.read(trackingProvider.notifier).allVisitedTiles;

// 올바른 방법: TrackingState에 allVisitedTiles를 포함시키고 ref.watch 사용
```

### 2. H3 주석 잔재
`firestore_service.dart`의 "H3 Cells" 주석은 초기 설계(Uber H3 라이브러리)의 흔적. 실제 구현은 OSM 타일 ID 사용.

### 3. 전세계 커버리지 부정확
`worldLandTilesZ16 = 800,000,000`은 실제 육상 타일 수의 rough estimate으로, 정확한 수치가 아님.

### 4. Apple 로그인 미구현
`pubspec.yaml`에 `sign_in_with_apple` 의존성이 있지만 `auth_provider.dart`에 Apple 로그인 구현이 없음.
