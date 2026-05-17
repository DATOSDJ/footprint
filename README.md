# Footprint 발자국

걷거나 달린 경로를 지도 위에 기록하고, 대한민국 전국 행정구역 커버리지를 추적하는 Flutter 앱.

## 주요 기능

- **경로 기록** — GPS 기반 실시간 경로 추적 (백그라운드 포함)
- **히트맵** — 방문 구역을 방문 횟수에 따라 색상으로 표시
- **전국 커버리지** — 전 세계 / 대한민국 / 17개 시도 / ~250개 구·군·시 단위 퍼센트
- **속도 필터** — 정지 및 차량 이동 자동 제외 (걷기/달리기/자전거 프리셋)
- **기록 히스토리** — 세션별 거리·시간 통계

## 스크린샷

| 지도 & 히트맵 | 전국 커버리지 통계 | 기록 히스토리 |
|---|---|---|
| (준비 중) | (준비 중) | (준비 중) |

## 기술 스택

| 분류 | 라이브러리 |
|---|---|
| UI / 지도 | Flutter 3.x · flutter_map (OpenStreetMap) |
| 상태관리 | flutter_riverpod 2.x |
| 백엔드 | Firebase Auth · Cloud Firestore |
| 위치 | geolocator 13.x · flutter_foreground_task 8.x |

## 커버리지 계산 방식

OSM 표준 타일 좌표계(zoom=16, 약 600m/타일)를 사용해 방문 구역을 계산합니다.

- **소형 지역** (구·군 단위): 정확한 타일 교집합 계산
- **대형 지역** (시도 단위): O(visited) 고속 추정 — 방문 타일만 순회

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
  sessions/{id}       # 기록 세션
  cells/{tileId}      # 방문 타일 (16_x_y 형식)
  stats_cache/coverage # 커버리지 통계 캐시 (1시간)
  settings            # 속도 필터 설정
```

## 라이선스

MIT
