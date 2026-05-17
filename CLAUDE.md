# Footprint — Claude Code 프로젝트 가이드

## 프로젝트 개요
걷거나 달린 경로를 지도 위에 기록하고, 방문 구역을 히트맵으로 표시하며  
전 세계 / 대한민국 / **17개 시도 / 각 시도의 모든 구·군·시** 단위 커버리지 퍼센트를 계산하는 Flutter 앱.

## 기술 스택
- **Flutter 3.41.9** (iOS / Android)
- **flutter_map 7.x** — OpenStreetMap 기반 지도 (무료, API 키 불필요)
- **Firebase Auth** — Google 소셜 로그인
- **Cloud Firestore** — 경로·타일 데이터 저장
- **geolocator 13.x** — GPS 위치 추적
- **flutter_foreground_task 8.x** — 백그라운드 포그라운드 서비스
- **flutter_riverpod 2.x** — 상태관리

## 디렉토리 구조
```
lib/
├── main.dart                    # 앱 진입점, Firebase/ForegroundTask 초기화
├── app.dart                     # MaterialApp, 인증 분기
├── firebase_options.dart        # ⚠️ flutterfire configure 후 교체 필요 (현재 placeholder)
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
│   ├── route_session.dart       # 기록 세션 모델
│   └── coverage_stats.dart      # 커버리지 통계 모델
│                                #   regionPercents: Map<String, double>  (지역ID→%)
├── services/
│   ├── tile_service.dart        # OSM 타일 좌표 변환·커버리지 계산 (핵심)
│   │                            #   tilesInBBox() — 지역 내 모든 타일 열거
│   │                            #   countVisitedInBBox() — 방문 타일만 카운트(고속)
│   │                            #   coveragePercent() — 교집합 퍼센트
│   ├── location_service.dart    # GPS 스트림, 속도 필터링
│   ├── firestore_service.dart   # Firestore CRUD
│   └── background_task_handler.dart  # 백그라운드 위치 서비스 + startCallback
├── providers/
│   ├── auth_provider.dart       # Firebase Auth 스트림
│   ├── tracking_provider.dart   # 기록 상태, 타일 누적, 거리 계산
│   ├── coverage_provider.dart   # 전국 모든 지역 커버리지 % 계산 및 캐시
│   └── settings_provider.dart   # 속도 필터 설정 (SharedPreferences)
└── screens/
    ├── auth/login_screen.dart   # Google 로그인
    ├── home/home_screen.dart    # BottomNav 쉘
    ├── map/
    │   ├── map_screen.dart      # 메인 지도 화면
    │   └── widgets/
    │       ├── heatmap_layer.dart    # 타일 히트맵 PolygonLayer
    │       └── tracking_controls.dart # 기록 시작/중지 FAB + 속도 배지
    ├── stats/stats_screen.dart  # 커버리지 통계 화면 (계층형 UI)
    └── settings/settings_screen.dart # 속도 설정, 로그아웃
```

## 핵심 설계 결정

### 커버리지 계산 (tile_service.dart)
- h3_dart 대신 **OSM 표준 타일 좌표계** (z/x/y) 사용. 외부 라이브러리 불필요.
- `tileZoom = 16` — 한국 위도 기준 약 600m/타일, 걷기 추적에 적합
- 방문 타일 ID 형식: `"16_54321_23456"` (z_x_y)
- **두 가지 커버리지 계산 경로** (coverage_provider.dart 기준):
  - `approximateTiles ≤ 5000` (소형 지역, 구·군 단위): `tilesInBBox()` + `coveragePercent()` — 정확한 교집합
  - `approximateTiles > 5000` (대형 지역, 시도 단위): `countVisitedInBBox()` ÷ `approximateTiles` — O(visited) 고속 추정

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

### 속도 필터 (location_service.dart)
- `minSpeedMs = 0.5 m/s` — GPS 드리프트 제거 (정지 시 미기록)
- `defaultMaxSpeedMs = 8.33 m/s` (30 km/h) — 차량 이동 제외
- 설정 화면에서 프리셋 선택 가능: 걷기 / 달리기 / 자전거 / 제한 없음

### 백그라운드 추적
- `startCallback()` 함수는 **background_task_handler.dart** 에 정의 (`@pragma('vm:entry-point')`)
- FlutterForegroundTask → LocationTaskHandler → geolocator 스트림
- 포그라운드 서비스 알림에 실시간 속도 표시

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
$env:PATH = "C:\Program Files\Git\bin;C:\Users\dongj\.puro\envs\stable\flutter\bin;C:\Users\dongj\AppData\Local\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "C:\Users\dongj\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

### Firebase 설정 (1회, 사용자 직접)
```powershell
# 1. console.firebase.google.com 에서 프로젝트 생성
#    Authentication → Google 활성화
#    Firestore → 테스트 모드 → asia-northeast3(서울)

# 2. FlutterFire CLI로 연결
$env:PATH = "C:\Users\dongj\.puro\shared\pub_cache\bin;$env:PATH"
flutterfire configure
# → lib/firebase_options.dart 자동 생성
```

### 빌드 및 실행
```powershell
flutter pub get
flutter run              # 연결된 기기/에뮬레이터에서 실행
flutter build apk        # Android APK
flutter build ios        # iOS (macOS 필요)
```

### Android 라이선스 수락 (1회, 사용자 직접)
```powershell
flutter doctor --android-licenses
# 각 라이선스마다 y 입력
```

## 플랫폼 설정 완료 사항
- **Android**: `minSdk = 21`, 위치 권한 4종, 포그라운드 서비스 선언
- **iOS**: NSLocation 권한 3종, UIBackgroundModes (location, fetch)
- **Firestore 보안 규칙**: `firestore.rules` 참고

## 주의사항
- `firebase_options.dart` 는 placeholder — `flutterfire configure` 실행 전까지 앱 시작 불가
- Firestore 보안 규칙은 `firestore.rules` 참고 (프로덕션 전 반드시 Firestore 콘솔에 적용)
- Android 에뮬레이터에서는 위치 권한이 자동 거부될 수 있음 — 실제 기기 권장
- 커버리지 첫 계산 시 수 초 소요 (250개 지역 bbox 연산, 이후 1시간 캐시)
- `flutter analyze` → **No issues found** 상태 유지 (2026-05-17 기준)
