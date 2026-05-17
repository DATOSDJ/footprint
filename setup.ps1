# Footprint 프로젝트 초기 설정 스크립트 (Windows PowerShell)
# 실행 전: Flutter SDK가 PATH에 있어야 합니다.
# https://flutter.dev/docs/get-started/install/windows

$ProjectDir = "C:\Users\dongj\Downloads\footprint"
$TempDir = "$env:TEMP\footprint_src"

Write-Host "=== Footprint 프로젝트 셋업 ===" -ForegroundColor Green

# 1. 임시 디렉토리에 새 Flutter 프로젝트 생성
Write-Host "`n[1/5] Flutter 프로젝트 기본 구조 생성 중..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force $TempDir | Out-Null
Set-Location $TempDir
flutter create --org com.yourname --project-name footprint --platforms android,ios .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter create 실패. Flutter SDK가 설치되어 있는지 확인하세요." -ForegroundColor Red
    exit 1
}

# 2. 생성된 android, ios 폴더를 프로젝트로 복사
Write-Host "`n[2/5] 플랫폼 파일 복사 중..." -ForegroundColor Cyan
Copy-Item -Recurse -Force "$TempDir\android" "$ProjectDir\android"
Copy-Item -Recurse -Force "$TempDir\ios" "$ProjectDir\ios"

# 3. pubspec.yaml의 dependency 설치
Write-Host "`n[3/5] 패키지 설치 중..." -ForegroundColor Cyan
Set-Location $ProjectDir
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "패키지 설치 실패. 에러를 확인하세요." -ForegroundColor Red
    exit 1
}

# 4. Android build.gradle minSdkVersion 패치
Write-Host "`n[4/5] Android minSdkVersion 설정 중..." -ForegroundColor Cyan
$GradlePath = "$ProjectDir\android\app\build.gradle"
if (Test-Path $GradlePath) {
    (Get-Content $GradlePath) -replace 'minSdkVersion \d+', 'minSdkVersion 21' |
        Set-Content $GradlePath
    Write-Host "  android/app/build.gradle: minSdkVersion=21 설정 완료" -ForegroundColor Green
}

Write-Host "`n[5/5] 완료!" -ForegroundColor Green
Write-Host @"

다음 단계:
  1. Firebase 프로젝트 생성: https://console.firebase.google.com
     - Authentication > Google 로그인 활성화
     - Firestore Database 생성 (테스트 모드로 시작)

  2. FlutterFire 설정:
       dart pub global activate flutterfire_cli
       cd $ProjectDir
       flutterfire configure
     (자동으로 lib/firebase_options.dart 생성됨)

  3. Android 권한 추가:
     android_manifest_template.xml 내용을
     android\app\src\main\AndroidManifest.xml 에 추가

  4. iOS 권한 추가:
     ios_infoplist_additions.txt 내용을
     ios\Runner\Info.plist 에 추가

  5. 앱 실행:
       flutter run
"@

Set-Location $ProjectDir
