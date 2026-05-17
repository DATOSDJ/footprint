# Footprint — Claude Code 프로젝트 가이드

## 프로젝트 개요
걷거나 달린 경로를 지도 위에 기록하고, 방문 구역을 히트맵으로 표시하며  
전 세계 / 대한민국 / **17개 시도 / 각 시도의 모든 구·군·시** 단위 커버리지 퍼센트를 계산하는 Flutter 앱.

**GitHub**: https://github.com/DATOSDJ/footprint  
**Firebase 프로젝트**: footprint-d0b44 (asia-northeast3 / 서울)

## 현재 상태 (2026-05-18)
- `flutter analyze` → **No issues found** ✓
- Firebase Auth (Google 로그인) + Firestore 연결 완료 ✓
- `lib/firebase_options.dart` 생성 완료 (gitignore 처리됨) ✓
- Android 실기기 실행 확인 ✓ (Samsung SM-S928N)
- GitHub push 완료 ✓

## 기술 스택
- **Flutter 3.41.9** (iOS / Android)
- **flutter_map 7.x** — OpenStreetMap 기반 지도 (무료, API 키 불필요)
- **Firebase Auth** — Google 소셜 로그인
- **Cloud Firestore** — 경로·타일 데이터 저장
- **geolocator 13.x** — GPS 위치 추적
- **flutter_foreground_task 8.17.0** — 백그라운드 포그라운드 서비스
- **flutter_riverpod 2.x** — 상태관리
- **flutter_launcher_icons 0.14.3** (dev) — 앱 아이콘 생성

## 디렉토리 구조
```
lib/
├── main.dart                    # 앱 진입점, Firebase/ForegroundTask 초기화
├── app.dart                     # MaterialApp, 인증 분기
├── firebase_options.dart        # gitignore 처리 — flutterfire configure로 재생성
├── core/
│   ├── constants.dart           # 앱 전역 상수 (tileZoom=16, 속도 기본값 등)
│   └── theme.dart               # 다크 테마, 히트맵 색상 팔레트
├── data/
│   └── region_data.dart         # 전국 행정구역 bbox 정의
│                                #   - 대한민국 + 17개 시도
│                                #   - 각 시도별 구·군·시 (~250개 총)
│                                #   - provinceDistrictsMap, getDistrictsOf()
├── models/
│   ├── location_point.dart      # GPS 포인트 모델
│   ├── route_session.dart       # 기록 세션 모델 (formattedDistance, formattedDuration)
│   └── coverage_stats.dart      # 커버리지 통계 모델
│                                #   regionPercents: Map<String, double>  (지역ID→%)
├── services/
│   ├── tile_service.dart        # OSM 타일 좌표 변환·커버리지 계산 (핵심)
│   │                            #   tilesInBBox() — 지역 내 모든 타일 열거
│   │                            #   countVisitedInBBox() — 방문 타일만 카운트(고속)
│   │                            #   coveragePercent() — 교집합 퍼센트
│   │                            #   tileCenter(TileCoord) — 타일 중심 좌표
│   ├── location_service.dart    # GPS 스트림, 속도 필터링
│   │                            #   FilterReason enum 정의 (none/tooSlow/tooFast)
│   │                            #   LocationUpdate.filterReason 필드
│   ├── firestore_service.dart   # Firestore CRUD
│   │                            #   recordCells(Map<String,int>) — 방문 횟수 정확히 기록
│   │                            #   getSessionsPage() — 커서 기반 페이지네이션
│   └── background_task_handler.dart  # 백그라운드 위치 서비스 + startCallback
│                                #   _Mode enum: idle / auto / manual
├── providers/
│   ├── auth_provider.dart       # Firebase Auth 스트림
│   ├── tracking_provider.dart   # 기록 상태, 타일 누적, 거리 계산
│   │                            #   TrackingState: isWatching, isAutoSession, filterReason,
│   │                            #                  elapsedSeconds, tileVersion
│   │                            #   startWatching() — GPS + 포그라운드 서비스 시작
│   ├── history_provider.dart    # 기록 히스토리 — 날짜 필터 + 커서 페이지네이션
│   │                            #   HistoryFilter: all/today/week/month/custom
│   │                            #   HistoryData: sessions, hasMore, isLoadingMore
│   ├── past_routes_provider.dart # 지도 오버레이용 과거 경로 (발자국 탭 외)
│   ├── coverage_provider.dart   # 전국 모든 지역 커버리지 % 계산 및 캐시
│   └── settings_provider.dart   # 속도 필터 설정 (SharedPreferences)
└── screens/
    ├── auth/login_screen.dart   # Google 로그인
    ├── home/home_screen.dart    # BottomNav 쉘 (5탭: 지도/발자국/통계/기록/설정)
    │                            #   initState에서 startWatching() 호출
    ├── map/
    │   ├── map_screen.dart      # 메인 지도 화면 (현재 세션 경로만 표시)
    │   └── widgets/
    │       └── tracking_controls.dart # FAB + 경과시간/속도/거리 배지
    ├── heatmap/
    │   └── heatmap_screen.dart  # 누적 방문 타일 히트맵 (발자국 탭)
    ├── stats/stats_screen.dart  # 커버리지 통계 화면 (계층형 ExpansionTile UI)
    ├── history/
    │   ├── history_screen.dart  # 기록 세션 목록 (날짜 필터, 무한 스크롤)
    │   └── session_map_screen.dart # 개별 세션 경로 지도
    └── settings/settings_screen.dart # 속도 설정, 배터리 최적화, 로그아웃
```

## 핵심 설계 결정

### FilterReason (location_service.dart)
- `none` — 정상 기록
- `tooSlow` — 정지 중 (0.5 m/s 미만) → "정지 중 (미기록)"
- `tooFast` — 속도 초과 → "속도 초과 (미기록)"
- TrackingState.filterReason으로 UI에 전달

### 커버리지 계산 (tile_service.dart + coverage_provider.dart)
- h3_dart 대신 **OSM 표준 타일 좌표계** (z/x/y) 사용. 외부 라이브러리 불필요.
- `tileZoom = 16` — 한국 위도 기준 약 600m/타일, 걷기 추적에 적합
- 방문 타일 ID 형식: `"16_54321_23456"` (z_x_y)
- **두 가지 커버리지 계산 경로** (coverage_provider.dart 기준):
  - `approximateTiles ≤ 5000` (소형 지역, 구·군 단위): `tilesInBBox()` + `coveragePercent()` — 정확한 교집합
  - `approximateTiles > 5000` (대형 지역, 시도 단위): `countVisitedInBBox()` ÷ `approximateTiles` — O(visited) 고속 추정

### 구·군 중복 계산 방지 (coverage_provider.dart)
- **문제**: 울주군 bbox가 울산 북구·동구 bbox를 기하학적으로 포함 → 같은 타일이 두 지역에 동시 집계
- **해결**: `_computeDistrictCoverage()` — 각 타일을 **하나의 지역(가장 작은 bbox)에만** 귀속
  - 지역을 `approximateTiles` 오름차순 정렬 (작은 지역 우선)
  - 타일 중심점이 처음으로 포함되는 지역에 할당 후 break
  - 전국 모든 17개 시도에 적용

### 기록 히스토리 페이지네이션 (history_provider.dart)
- `HistoryNotifier` + `HistoryData(sessions, hasMore, isLoadingMore)`
- "전체" 탭: 100개씩 Firestore 커서 페이지네이션 (`startAfterDocument`)
- 날짜 필터 탭: 범위가 자연적 한계 → limit 없이 전체 로드
- ScrollController 리스너: 하단 400px 이내 진입 시 `loadMore()` 자동 호출

### 지역 데이터 구조 (region_data.dart)
- `RegionData`: id, name, parentId, minLat/maxLat/minLon/maxLon, approximateTiles
- ID 체계: `KR` → `KR-11`(서울) → `KR-11-110`(종로구)
- `koreaProvinces`: 17개 시도 리스트
- `provinceDistrictsMap`: 시도 ID → 하위 지역 리스트
- `getDistrictsOf(id)`: 특정 시도의 구·군·시 리스트 반환

### 통계 화면 계층 구조 (stats_screen.dart)
```
전국 커버리지 (세계 + 대한민국 카드)
시도별 커버리지 (17개 ExpansionTile)
  └── 각 시도 클릭 시: 하위 구·군·시 커버리지 리스트 (내림차순)
```
퍼센트 표시: 작은 값도 유효숫자 2자리 이상 (`_fmtPct()` 함수 — 0.0000001 형태 지원)

### 속도 필터 (location_service.dart)
- `minSpeedMs = 0.5 m/s` — GPS 드리프트 제거 (정지 시 미기록)
- `defaultMaxSpeedMs = 8.33 m/s` (30 km/h) — 차량 이동 제외
- 설정 화면에서 프리셋 선택 가능: 걷기 / 달리기 / 자전거 / 제한 없음

### 백그라운드 추적 (background_task_handler.dart)
- `startCallback()` 함수는 `@pragma('vm:entry-point')` 어노테이션 필수
- `_Mode` enum: `idle` / `auto` (자동 감지 세션) / `manual` (수동 세션)
- 자동 추적: 속도 임계값 초과 → `auto` 모드 진입 → 세션 생성
- `sendDataToMain({action, lat, lng, speed, distanceMeters, ...})` 로 메인 isolate 통신
- `ForegroundTaskOptions`: `autoRunOnBoot: true`, `allowWakeLock: true`, `allowWifiLock: true`
  - `allowAutoRestart`는 v8.17.0에 존재하지 않음 (컴파일 에러 주의)

### 배터리 최적화 제외
- `android/app/src/main/AndroidManifest.xml`: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 권한
- 설정 화면: `FlutterForegroundTask.requestIgnoreBatteryOptimization()` 버튼

### 앱 아이콘
- `assets/icon/app_icon.png` — 1024×1024, 다크 배경(#0D1117) + 초록 발자국(#4CAF50)
- `assets/icon/app_icon_foreground.png` — 투명 배경 (adaptive icon 전경)
- `pubspec.yaml` flutter_launcher_icons 설정: `adaptive_icon_background: "#0D1117"`

### Firestore 구조
```
users/{uid}/
  sessions/{sessionId}      # 기록 세션 (startTime, endTime, distanceMeters, isActive)
  cells/{tileId}            # 방문 타일 ("16_x_y") — count, firstVisit, lastVisit
  stats_cache/coverage      # CoverageStats 캐시 (1시간마다 갱신)
    └── regionPercents: { "KR-11": 0.5, "KR-11-110": 2.3, ... }
  settings                  # 속도 필터 등 사용자 설정
```

## 빌드 환경 (Windows)

### PATH 설정 (새 PowerShell 세션마다)
```powershell
$env:PATH = "C:\Program Files\Git\bin;C:\Program Files\nodejs;C:\Users\dongj\AppData\Roaming\npm;C:\Users\dongj\.puro\envs\stable\flutter\bin;C:\Users\dongj\.puro\shared\pub_cache\bin;C:\Users\dongj\AppData\Local\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "C:\Users\dongj\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

### Firebase 재연결 (새 클론 시)
```powershell
# FlutterFire CLI (이미 설치됨)
dart pub global activate flutterfire_cli

# Firebase CLI (이미 설치됨 — npm global)
# firebase login 먼저 실행

flutterfire configure
# footprint-d0b44 프로젝트 선택, android + ios 체크
```

### Android 디버그 SHA-1
```
F6:85:44:D9:08:F5:2C:04:68:7D:D8:5E:BE:17:33:5A:BA:BA:13:5D
```
Firebase 콘솔 → 프로젝트 설정 → Android 앱 → 디지털 지문에 등록 필요

### 빌드 및 실행
```powershell
flutter pub get
flutter run              # 연결된 기기/에뮬레이터에서 실행
flutter build apk        # Android APK
flutter build ios        # iOS (macOS 필요)
```

## 플랫폼 설정 완료 사항
- **Android**: `minSdk = 21`, 위치 권한 4종, 포그라운드 서비스 선언, 배터리 최적화 제외 권한
- **iOS**: NSLocation 권한 3종, UIBackgroundModes (location, fetch)
- **Firestore 보안 규칙**: `firestore.rules` 참고 (프로덕션 전 콘솔에 적용)

## 주의사항
- `firebase_options.dart` 는 .gitignore 처리 — 새 클론 시 `flutterfire configure` 재실행
- Android 에뮬레이터에서는 위치 권한이 자동 거부될 수 있음 — 실제 기기 권장
- 커버리지 첫 계산 시 수 초 소요 (250개 지역 bbox 연산, 이후 1시간 캐시)
- Google 로그인 안 될 경우: Firebase 콘솔에 디버그 SHA-1 지문 등록 확인
- `allowAutoRestart`는 flutter_foreground_task 8.17.0에 없음 → `allowWakeLock` 사용
