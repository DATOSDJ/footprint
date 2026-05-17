# Footprint 발자국

걷거나 달린 경로를 지도 위에 기록하고, 대한민국 전국 행정구역 커버리지를 추적하는 Flutter 앱.

## 주요 기능

- **경로 기록** — GPS 기반 실시간 경로 추적. 백그라운드에서도 항상 작동 (포그라운드 서비스, 부팅 후 자동 시작)
- **자동 추적** — 걷기 시작 감지 시 자동 세션 시작, 정지 시 자동 종료
- **발자국 히트맵** — 누적 방문 구역을 별도 탭에서 방문 횟수 기반 밝기로 시각화
- **전국 커버리지** — 전 세계 / 대한민국 / 17개 시도 / ~250개 구·군·시 단위 퍼센트
- **속도 필터** — 정지 및 차량 이동 자동 제외 (걷기/달리기/자전거 프리셋)
- **기록 히스토리** — 세션별 거리·시간 통계, 날짜 필터, 무제한 페이지네이션

## 화면 구성 (5탭)

| 탭 | 아이콘 | 설명 |
|---|---|---|
| 지도 | 지도 | 현재 세션 경로만 표시. 기록 시작/중지 FAB |
| 발자국 | 레이어 | 누적 방문 타일 히트맵 (방문 횟수 기반 밝기) |
| 통계 | 차트 | 세계·한국·시도·구군시 커버리지 %, 총 거리·세션 수 |
| 기록 | 달력 | 세션 목록 (날짜 필터, 날짜별 그룹, 무한 스크롤) |
| 설정 | 설정 | 속도 프리셋, 배터리 최적화 제외, 로그아웃 |

## 기술 스택

| 분류 | 라이브러리 |
|---|---|
| UI / 지도 | Flutter 3.x · flutter_map (OpenStreetMap) |
| 상태관리 | flutter_riverpod 2.x |
| 백엔드 | Firebase Auth · Cloud Firestore |
| 위치 | geolocator 13.x · flutter_foreground_task 8.x |
| 아이콘 생성 | flutter_launcher_icons 0.14.3 |

## 커버리지 계산 방식

OSM 표준 타일 좌표계(zoom=16, 약 600m/타일)를 사용해 방문 구역을 계산합니다.

- **소형 지역** (구·군 단위): 정확한 타일 교집합 계산
- **대형 지역** (시도 단위): O(visited) 고속 추정 — 방문 타일만 순회
- **중복 방지**: 겹치는 bbox를 가진 구·군은 타일을 가장 작은 지역에만 귀속 (울주군이 북구를 둘러싸는 문제 해결)

## 시작하기

### 사전 준비

- Flutter 3.x
- Firebase 프로젝트 (Auth · Firestore 활성화)

### 설치

```bash
git clone https://github.com/DATOSDJ/footprint.git
cd footprint
flutter pub get
```

### Firebase 연결

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/firebase_options.dart` 가 자동 생성됩니다.

### 실행

```bash
flutter run
```

## Firestore 구조

```
users/{uid}/
  sessions/{id}         # 기록 세션 (startTime, endTime, distanceMeters, isActive)
  cells/{tileId}        # 방문 타일 ("16_x_y" 형식, count/firstVisit/lastVisit)
  stats_cache/coverage  # 커버리지 통계 캐시 (1시간)
  settings              # 속도 필터 설정
```

## 라이선스

MIT
