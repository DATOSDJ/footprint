# Footprint — 진행 현황

## 앱 소개
내가 걷거나 뛴 경로를 지도에 기록하고, 방문 구역을 히트맵으로 시각화하며  
전 세계 / 대한민국 / **17개 시도 / 각 시도의 모든 구·군·시** 단위로 커버리지 퍼센트를 보여주는 지도 앱.

---

## 구현 완료 항목

### 인프라
- [x] Flutter 3.41.9 + Firebase 연결
- [x] `flutter analyze` — **에러 없음** 확인
- [x] Android 실기기 확인 (Samsung SM-S928N)
- [x] GitHub 원격 저장소 연결 및 push 완료
- [x] 앱 아이콘 — 초록 발자국 디자인 (1024×1024, adaptive icon)

### 핵심 기능
- [x] **경로 추적** — GPS 기반 실시간 경로 기록
- [x] **백그라운드 추적** — 항상 켜진 포그라운드 서비스 (앱 종료 후에도 동작)
- [x] **자동 추적** — 걷기 감지 시 자동 세션 시작·종료
- [x] **배터리 최적화 제외** — 공격적 배터리 관리 우회 (설정 화면에서 요청)
- [x] **부팅 자동 시작** — `autoRunOnBoot: true`
- [x] **속도 필터** — 정지·차량 이동 자동 제외
- [x] **타일 기반 커버리지** — OSM z16 타일로 방문 구역 정확히 측정

### 화면 (5탭)
- [x] **지도 탭** — 현재 세션 경로만 표시, 기록 시작/중지 FAB
- [x] **발자국 탭** — 누적 방문 타일 히트맵 (방문 횟수 기반 밝기)
- [x] **통계 탭** — 세계·한국·17개 시도·구군시 커버리지 %, 동적 소수점 표시
- [x] **기록 탭** — 날짜 필터(전체/오늘/이번 주/이번 달/커스텀), 무한 스크롤 페이지네이션
- [x] **설정 탭** — 속도 프리셋, 자동 추적 토글, 배터리 최적화 제외, 로그아웃

### 데이터
- [x] **전국 행정구역 bbox** — 17개 시도 + ~250개 구·군·시
- [x] **커버리지 이중집계 방지** — 겹치는 bbox를 가장 작은 지역에만 귀속 (울주군/북구 문제 해결, 전국 적용)
- [x] **커버리지 통계 캐시** — Firestore에 1시간 캐시, 백그라운드 갱신
- [x] **기록 커서 페이지네이션** — `startAfterDocument` 기반, 100개씩 로드
- [x] **세션 경로 지연 로드** — 목록에서는 메타데이터만, 상세 보기 시 경로 로드

### 플랫폼
- [x] Android `minSdk = 21`, 위치 권한 4종, 포그라운드 서비스 선언
- [x] Android 배터리 최적화 제외 권한
- [x] iOS NSLocation 권한 3종, UIBackgroundModes
- [x] Firestore 보안 규칙 (`firestore.rules`)

---

## 앱 주요 화면

| 화면 | 설명 |
|---|---|
| 지도 | OSM 기반 지도. 현재 기록 세션 경로(초록). 기록 시작/중지 FAB |
| 발자국 | 방문한 전체 타일을 히트맵으로 표시. 방문 횟수에 따라 밝기 변화 |
| 통계 | 세계·한국·17개 시도·구·군·시별 커버리지 %. 총 거리, 세션 수 |
| 기록 | 세션 목록 (날짜별 그룹). 날짜 필터. 탭 시 경로 지도 표시 |
| 설정 | 최대 기록 속도 프리셋, 자동 추적 on/off, 배터리 최적화 제외, 로그아웃 |

---

## 커버리지 계층 구조

```
전 세계
└── 대한민국
    ├── 서울특별시 (25개 구)
    ├── 부산광역시 (16개 구·군)
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

---

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
$env:PATH = "C:\Program Files\Git\bin;C:\Program Files\nodejs;C:\Users\dongj\AppData\Roaming\npm;C:\Users\dongj\.puro\envs\stable\flutter\bin;C:\Users\dongj\.puro\shared\pub_cache\bin;C:\Users\dongj\AppData\Local\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "C:\Users\dongj\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```
