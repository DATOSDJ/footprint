# Footprint — 진행 현황

## 앱 소개
내가 걷거나 뛴 경로를 지도에 기록하고, 방문 구역을 히트맵으로 시각화하며  
전 세계 / 대한민국 / **17개 시도 / 각 시도의 모든 구·군·시** 단위로 커버리지 퍼센트를 보여주는 지도 앱.

## 구현 완료 항목

### 인프라
- [x] Flutter 3.41.9 + Puro(버전 관리) 설치
- [x] Git 설치
- [x] Android Studio 설치
- [x] FlutterFire CLI 설치 (`flutterfire 1.3.2`)
- [x] `flutter pub get` — 전체 패키지 설치 완료
- [x] `flutter analyze` — **에러 없음** 확인
- [x] Android SDK 설치 완료
  - cmdline-tools (latest)
  - platform-tools 37.0.0
  - platforms;android-35
  - platforms;android-36
  - build-tools;35.0.0
  - 라이선스 파일 작성 (`$ANDROID_HOME/licenses/`)

### 소스 코드 (`lib/`)
- [x] 앱 진입점 (`main.dart`, `app.dart`)
- [x] 다크 테마 (`core/theme.dart`)
- [x] 앱 상수 (`core/constants.dart`) — tileZoom=16, 속도 기본값 등
- [x] 타일 서비스 (`services/tile_service.dart`) — OSM 타일 기반 커버리지 계산
  - `countVisitedInBBox()` 추가 — 대형 지역 고속 커버리지 계산 (O(visited))
- [x] 위치 서비스 (`services/location_service.dart`) — GPS + 속도 필터
- [x] 백그라운드 핸들러 (`services/background_task_handler.dart`)
- [x] Firestore 서비스 (`services/firestore_service.dart`)
- [x] **한국 지역 경계 데이터** (`data/region_data.dart`) — **전국 완성**
  - 대한민국 (국가)
  - 17개 시도 (서울/부산/대구/인천/광주/대전/울산/세종/경기/강원/충북/충남/전북/전남/경북/경남/제주)
  - 서울 25구
  - 부산 16구·군
  - 대구 8구·군
  - 인천 10구·군
  - 광주 5구
  - 대전 5구
  - 울산 5구·군
  - 세종 1 (단일시)
  - 경기 31시·군
  - 강원 18시·군
  - 충청북도 11시·군
  - 충청남도 15시·군
  - 전북 14시·군
  - 전남 22시·군
  - 경북 23시·군
  - 경남 18시·군
  - 제주 2시
  - **총 ~250개 행정구역 bbox 정의 완료**
- [x] 데이터 모델 3종 (`location_point`, `route_session`, `coverage_stats`)
  - `coverage_stats.dart` — `regionPercents: Map<String, double>` (지역ID→퍼센트)
- [x] Riverpod 프로바이더 4종 (`auth`, `tracking`, `coverage`, `settings`)
  - `coverage_provider.dart` — 전국 모든 지역 커버리지 계산
    - 소형 지역(≤5000타일): 정확한 tilesInBBox 교집합
    - 대형 지역(>5000타일): countVisitedInBBox + approximateTiles 고속 추정
- [x] 로그인 화면 (Google 소셜 로그인)
- [x] 메인 지도 화면 (OSM 타일 + 히트맵 + 경로 오버레이)
- [x] 히트맵 레이어 (방문 타일 → 직사각형 폴리곤, 방문 횟수별 색상)
- [x] 기록 컨트롤 (시작/중지 FAB, 속도 배지, 거리 배지)
- [x] **통계 화면** (`stats/stats_screen.dart`) — **계층형 커버리지 UI**
  - 전국 커버리지 (세계 + 대한민국)
  - 17개 시도 카드 (확장 시 하위 구·군·시 목록 표시)
  - ExpansionTile 기반 접기/펼치기
  - 지역 내 커버리지 순으로 정렬
- [x] 설정 화면 (속도 프리셋, 프로필, 로그아웃)

### 플랫폼 설정
- [x] Android `minSdk = 21`
- [x] Android 위치 권한 4종 + 포그라운드 서비스 선언
- [x] iOS NSLocation 권한 3종 + UIBackgroundModes (location, fetch)
- [x] Firestore 보안 규칙 (`firestore.rules`)

---

## 남은 작업 (순서대로)

### 1. Android 라이선스 수동 수락 (사용자 직접)
```powershell
# 새 PowerShell 터미널에서:
$env:PATH = "C:\Program Files\Git\bin;C:\Users\dongj\.puro\envs\stable\flutter\bin;$env:PATH"
$env:ANDROID_HOME = "C:\Users\dongj\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
flutter doctor --android-licenses
# → 각 라이선스마다 y 입력 후 Enter
```
*(빌드 자체는 이 단계 없이도 동작할 수 있음)*

### 2. Firebase 프로젝트 생성 (사용자 직접)
```
https://console.firebase.google.com
- 새 프로젝트: footprint
- Authentication → Google 로그인 활성화
- Firestore Database → 테스트 모드 → 리전: asia-northeast3 (서울)
```

### 3. FlutterFire 연결
```powershell
cd C:\Users\dongj\Downloads\footprint
$env:PATH = "C:\Users\dongj\.puro\envs\stable\flutter\bin;C:\Users\dongj\.puro\shared\pub_cache\bin;$env:PATH"
flutterfire configure
# → Google 로그인 → 프로젝트 선택 → android + ios 선택
# → lib/firebase_options.dart 자동 생성됨
```

### 4. 에뮬레이터 또는 실기기 연결 후 실행
```powershell
$env:PATH = "C:\Program Files\Git\bin;C:\Users\dongj\.puro\envs\stable\flutter\bin;C:\Users\dongj\AppData\Local\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "C:\Users\dongj\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
cd C:\Users\dongj\Downloads\footprint
flutter devices
flutter run
```

### 5. Firebase 보안 규칙 배포 (프로덕션 전)
```
Firestore 콘솔 → 규칙 탭 → firestore.rules 내용 붙여넣기 → 게시
```

---

## 앱 주요 화면

| 화면 | 설명 |
|---|---|
| 지도 | OSM 기반 지도, 방문 타일 히트맵(초록→노랑→빨강), 현재 경로 |
| 통계 | 세계·한국·17개 시도·구·군·시별 커버리지 %, 총 거리, 세션 수 |
| 설정 | 최대 기록 속도 프리셋 (걷기/달리기/자전거/제한 없음), 로그아웃 |

## 커버리지 계층 구조

```
전 세계
└── 대한민국
    ├── 서울특별시
    │   ├── 종로구, 중구, 용산구 ... (25개 구)
    ├── 부산광역시
    │   ├── 중구, 서구, 동구 ... (16개 구·군)
    ├── 대구광역시 (8개)
    ├── 인천광역시 (10개)
    ├── 광주광역시 (5개)
    ├── 대전광역시 (5개)
    ├── 울산광역시 (5개)
    ├── 세종특별자치시 (1개)
    ├── 경기도 (31개 시·군)
    ├── 강원특별자치도 (18개)
    ├── 충청북도 (11개)
    ├── 충청남도 (15개)
    ├── 전북특별자치도 (14개)
    ├── 전라남도 (22개)
    ├── 경상북도 (23개)
    ├── 경상남도 (18개)
    └── 제주특별자치도 (2개)
```

## 히트맵 색상 기준

| 색상 | 조건 |
|---|---|
| 초록 | 1회 방문 |
| 노랑 | 2~5회 방문 |
| 주황 | 6~20회 방문 |
| 빨강 | 21회 이상 |

## 설치된 도구 경로

| 도구 | 경로 |
|---|---|
| Flutter | `C:\Users\dongj\.puro\envs\stable\flutter\bin` |
| Puro | `C:\Users\dongj\AppData\Local\Programs\puro` |
| FlutterFire CLI | `C:\Users\dongj\.puro\shared\pub_cache\bin\flutterfire.bat` |
| Android Studio | `C:\Program Files\Android\Android Studio` |
| Android SDK | `C:\Users\dongj\AppData\Local\Android\Sdk` |
| Android JBR | `C:\Program Files\Android\Android Studio\jbr` |
| Git | `C:\Program Files\Git\bin` |

## PATH 설정 (새 PowerShell 세션마다)
```powershell
$env:PATH = "C:\Program Files\Git\bin;C:\Users\dongj\.puro\envs\stable\flutter\bin;C:\Users\dongj\AppData\Local\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "C:\Users\dongj\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```
