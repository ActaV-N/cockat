# Shorebird OTA 업데이트 통합 전략

## 개요
- **목적**: Dart 코드 변경사항을 앱스토어 심사 없이 OTA(Over-The-Air) 방식으로 배포
- **범위**: iOS App Store 배포 앱에 Shorebird 통합
- **예상 소요 기간**: 1-2주 (초기 설정 3-4일, 테스트 1주)
- **배포 방식**: 수동 배포 (로컬 CLI)
- **주요 이점**:
  - 긴급 버그 수정 시 앱스토어 심사 기간(평균 24-48시간) 우회
  - UI/UX 개선사항 즉시 배포
  - A/B 테스트 및 점진적 롤아웃 가능

## 현재 상태 분석

### 기존 구현
- **버전**: 1.0.1+2 (App Store 배포 완료)
- **Bundle ID**: com.cockat.cockat
- **개발 팀**: RMN8TU2V2T
- **플랫폼**: iOS 13.0+
- **배포 구성**: Release 빌드 (프로덕션 서명 완료 - App Store 배포됨)
- **Shorebird App ID**: `c9a99d3f-bd6f-4670-ab50-80dbf0247c1c` ✅ 초기화 완료

### 프로젝트 구조
```
코드 구성:
- Dart 코드: 99.1% (Shorebird 패치 가능)
- 네이티브 코드: 0.9% (패치 불가, 앱스토어 업데이트 필요)

주요 의존성:
- supabase_flutter: 백엔드 연동
- firebase_core/analytics: 분석
- google_sign_in, sign_in_with_apple: 소셜 로그인
- image_picker: 이미지 선택
- webview_flutter: Canny 피드백
- go_router: 네비게이션
- riverpod: 상태 관리
```

### 진행 상황 체크리스트

#### 1단계: 사전 준비 ✅ 완료
- [x] Shorebird CLI 설치
- [x] Shorebird 로그인
- [x] 프로젝트 초기화 (`shorebird init`)
- [x] `shorebird.yaml` 생성됨
- [x] `pubspec.yaml`에 shorebird.yaml 에셋 추가

#### 2단계: iOS 빌드 및 배포 🔄 진행중
- [ ] iOS 릴리스 빌드 (`shorebird release ios`)
- [ ] App Store Connect 업로드
- [ ] TestFlight 베타 테스트
- [ ] App Store 제출 및 심사

#### 3단계: 패치 테스트 ⏳ 대기
- [ ] 테스트용 Dart 코드 변경
- [ ] 첫 패치 생성 (`shorebird patch ios`)
- [ ] 패치 적용 확인

### 문제점/한계
1. **현재**: 버그 수정 시 앱스토어 심사 대기 필요
2. **배포 프로세스**: 수동 배포 (Shorebird CLI 사용)
3. **롤백**: 앱스토어 제출 이전 버전으로만 복구 가능

### 관련 코드/모듈
- `/ios/Runner.xcodeproj/project.pbxproj`: iOS 빌드 설정
- `/android/app/build.gradle.kts`: Android 빌드 설정 (향후 확장용)
- `/pubspec.yaml`: Flutter 의존성 관리
- `/lib/main.dart`: 앱 진입점

## 구현 전략

### 접근 방식
**단계적 통합 (Phased Integration)**:
1. **Phase 1**: 로컬 환경에서 Shorebird 설정 및 테스트
2. **Phase 2**: TestFlight 베타 테스트로 검증
3. **Phase 3**: App Store 프로덕션 배포 및 전체 롤아웃

### 세부 구현 단계

#### 1단계: 사전 준비 (1-2일)

**1.1 Shorebird 계정 및 CLI 설치**
```bash
# Shorebird CLI 설치
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# PATH 설정 확인
shorebird --version

# Shorebird 계정 생성 및 로그인
shorebird login
```

**1.2 프로젝트 초기화**
```bash
# 프로젝트 루트에서 실행
cd /Users/actav/Documents/cockat

# Shorebird 프로젝트 초기화
shorebird init

# 출력 예시:
# ✓ Shorebird initialized successfully
# App ID: your-app-id
```

**1.3 필수 파일 백업**
```bash
# 중요 설정 파일 백업
cp pubspec.yaml pubspec.yaml.backup
cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup
cp -r ios/Runner ios/Runner.backup
```

#### 2단계: iOS 빌드 설정 (1-2일)

**2.1 프로덕션 릴리스 서명 확인**
```yaml
# 이미 App Store에 배포되어 있으므로 서명 설정 완료됨
# Team ID: RMN8TU2V2T

확인 사항:
1. Xcode에서 현재 서명 설정 유지
2. Automatically manage signing 상태 확인
```

**2.2 Info.plist 권한 검토**
```xml
<!-- 현재 설정된 권한 유지 -->
- NSCameraUsageDescription: 카메라 접근
- NSPhotoLibraryUsageDescription: 사진 라이브러리 접근
- CFBundleURLTypes: Supabase, Google Sign-In deep link

<!-- Shorebird 관련 추가 설정 불필요 -->
```

**2.3 첫 Shorebird 릴리스 빌드**
```bash
# iOS 릴리스 빌드 생성
shorebird release ios --flutter-version=3.8.1

# 빌드 성공 시 출력:
# ✓ Building release 1.0.1+2
# ✓ Release published successfully
# Release Version: 1.0.1+2
# Release ID: xxxxx
```

**2.4 로컬 테스트**
```bash
# 시뮬레이터에서 테스트
shorebird preview --release-version=1.0.1+2

# 실제 기기에서 테스트 (TestFlight 필요)
# .ipa 파일 업로드: build/ios/ipa/*.ipa
```

#### 3단계: 첫 패치 생성 및 테스트 (3-4일)

**3.1 간단한 Dart 코드 변경**
```dart
// lib/main.dart 또는 간단한 UI 컴포넌트 수정
// 예시: 버전 표시 텍스트 추가, 색상 변경 등

// 변경 전
Text('Cockat')

// 변경 후
Text('Cockat v1.0.1 (Shorebird Test)')
```

**3.2 패치 생성**
```bash
# iOS 패치 생성
shorebird patch ios

# 패치 설명 입력
# Patch notes: "테스트 패치: 버전 표시 텍스트 추가"

# 출력:
# ✓ Patch created successfully
# Patch Number: 1
# Release Version: 1.0.1+2
```

**3.3 패치 검증**
```bash
# 패치 상태 확인
shorebird patch list

# 특정 패치 상세 정보
shorebird patch info --patch-number=1

# 기대 출력:
# Patch #1
# Release Version: 1.0.1+2
# Created: 2026-02-02
# Status: active
# Rollout: 100%
```

**3.4 로컬 환경에서 패치 테스트**
```bash
# 1. 기존 릴리스 버전 앱 실행
# 2. 앱 종료
# 3. 앱 재시작 → 패치 자동 다운로드 및 적용
# 4. 변경사항 확인 (예: 버전 텍스트 확인)
```

#### 4단계: TestFlight 베타 테스트 (5-7일)

**4.1 TestFlight 빌드 업로드**
```bash
# Xcode Archive를 통한 업로드
# 또는 Shorebird 릴리스 .ipa 직접 업로드

# App Store Connect에서:
# 1. 빌드 업로드 확인
# 2. 베타 테스터 그룹 선택 (5-10명 권장)
# 3. 베타 배포 시작
```

**4.2 베타 테스터 가이드라인**
```markdown
테스터 체크리스트:
□ 앱 설치 및 초기 실행
□ 주요 기능 테스트 (칵테일 검색, 저장, 공유 등)
□ 앱 종료 후 재시작 → 패치 다운로드 확인
□ 패치 적용 후 기능 정상 동작 확인
□ 네트워크 상태별 테스트 (WiFi, LTE, 오프라인)
□ 소셜 로그인 기능 테스트
□ 이미지 업로드 기능 테스트

보고 항목:
- 패치 다운로드 시간
- 패치 적용 후 앱 시작 시간
- 발견된 버그 또는 이상 동작
- 디바이스 모델 및 iOS 버전
```

**4.3 모니터링 대시보드 설정**
```bash
# Shorebird Console에서 확인할 지표:
- 패치 다운로드 성공률
- 패치 적용 성공률
- 디바이스별 분포
- iOS 버전별 분포
- 오류 리포트
```

#### 5단계: 프로덕션 배포 (App Store) (3-5일)

**5.1 App Store 제출**
```bash
# 최종 릴리스 빌드 생성
shorebird release ios --flutter-version=3.8.1

# App Store Connect에서:
# 1. 스크린샷 및 앱 설명 확인
# 2. 심사용 메모에 Shorebird 사용 명시
# 3. 심사 제출

심사용 메모 예시:
"본 앱은 Shorebird를 사용하여 Dart 코드 hot fix를 지원합니다.
네이티브 코드는 변경되지 않으며, UI/로직 버그 수정만 OTA로 배포됩니다."
```

**5.2 단계적 롤아웃 계획**
```yaml
롤아웃 전략:
Week 1:
  - 1% 사용자에게 배포
  - 모니터링 집중 (크래시율, 패치 성공률)

Week 2:
  - 문제 없으면 10%로 확대
  - A/B 테스트 가능

Week 3:
  - 50%로 확대

Week 4:
  - 100% 전체 배포
```

#### 수동 배포 가이드

**릴리스 빌드 (App Store 제출)**
```bash
# 1. 프로젝트 루트에서 실행
cd /Users/actav/Documents/cockat

# 2. Shorebird 릴리스 빌드
shorebird release ios

# 3. .ipa 파일 위치 확인
# build/ios/ipa/cockat.ipa

# 4. Xcode 또는 Transporter로 App Store Connect 업로드
```

**패치 배포 (OTA 업데이트)**
```bash
# 1. Dart 코드 수정 후
git add .
git commit -m "fix: 버그 수정"

# 2. 패치 생성 및 배포
shorebird patch ios

# 3. 패치 상태 확인
shorebird patch list

# 4. 롤아웃 비율 조정 (선택)
shorebird patch rollout set --patch-number=1 --percentage=10
```

**배포 체크리스트**
```markdown
릴리스 배포 시:
□ shorebird release ios 실행
□ Transporter로 App Store Connect 업로드
□ TestFlight 테스트
□ App Store 제출

패치 배포 시:
□ 코드 변경 및 커밋
□ shorebird patch ios 실행
□ 패치 상태 확인 (shorebird patch list)
□ 필요시 롤아웃 비율 조정
```

### 기술적 고려사항

#### 아키텍처
```
[사용자 디바이스]
     ↓ (앱 시작)
[Shorebird SDK]
     ↓ (패치 확인)
[Shorebird Server] ← [개발자 패치 배포]
     ↓ (패치 다운로드)
[로컬 캐시]
     ↓ (패치 적용)
[Flutter Engine] → [앱 실행]

주요 흐름:
1. 앱 시작 시 Shorebird SDK가 자동으로 최신 패치 확인
2. 새 패치 발견 시 백그라운드 다운로드 (비동기)
3. 다음 앱 재시작 시 패치 자동 적용
4. 패치 적용 실패 시 이전 버전으로 자동 롤백
```

#### 의존성
```yaml
# pubspec.yaml 변경사항 (Shorebird가 자동 추가)

dependencies:
  shorebird_code_push: ^1.0.0  # Shorebird SDK

# 기존 의존성과 충돌 없음 확인됨:
# - supabase_flutter: ✓
# - firebase_core/analytics: ✓
# - google_sign_in, sign_in_with_apple: ✓
# - image_picker: ✓
# - webview_flutter: ✓
```

#### 패치 가능/불가능 변경사항

**패치 가능 (OTA 배포)**:
- ✅ Dart 코드 변경 (UI, 비즈니스 로직)
- ✅ pubspec.yaml 의존성 버전 업데이트 (Dart 패키지만)
- ✅ 에셋 파일 변경 (이미지, 폰트 등)
- ✅ 상태 관리 로직 수정
- ✅ API 엔드포인트 변경
- ✅ 텍스트 및 번역 수정

**패치 불가능 (앱스토어 업데이트 필요)**:
- ❌ 네이티브 코드 변경 (Swift, Kotlin, Objective-C, Java)
- ❌ 네이티브 플러그인 추가/삭제
- ❌ Flutter 엔진 업그레이드
- ❌ Info.plist 권한 변경 (iOS)
- ❌ AndroidManifest.xml 변경
- ❌ 빌드 설정 변경 (compileSdkVersion 등)

#### 데이터 모델
```dart
// Shorebird 패치 메타데이터 (내부 관리)
class ShorebirdPatch {
  String patchNumber;
  String releaseVersion;
  DateTime createdAt;
  String description;
  int downloadSize;  // bytes
  double rolloutPercentage;
  PatchStatus status;  // active, paused, cancelled
}

// 앱 내부에서 패치 상태 확인 (선택 사항)
import 'package:shorebird_code_push/shorebird_code_push.dart';

final shorebirdCodePush = ShorebirdCodePush();

// 현재 패치 버전 확인
final currentPatchNumber = await shorebirdCodePush.currentPatchNumber();

// 패치 다운로드 상태 모니터링
shorebirdCodePush.patchUpdateAvailable().listen((available) {
  if (available) {
    // 사용자에게 앱 재시작 권장 (선택 사항)
  }
});
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 확률 | 대응 방안 |
|-----------|--------|------|----------|
| **앱스토어 심사 거부** | 높음 | 낮음 | - Apple 가이드라인 준수 (코드 서명 유지)<br>- 심사용 메모에 Shorebird 명시<br>- 네이티브 코드 불변 보장 |
| **패치 배포 실패** | 중간 | 중간 | - 자동 롤백 메커니즘 (Shorebird 내장)<br>- 단계적 롤아웃 (1% → 10% → 100%)<br>- 모니터링 대시보드로 실시간 추적 |
| **사용자 디바이스 호환성 문제** | 높음 | 낮음 | - iOS 13.0+ 타겟으로 제한<br>- TestFlight 베타 테스트 필수<br>- 디바이스별 롤아웃 제어 |
| **과도한 패치 크기** | 낮음 | 중간 | - Dart 코드만 패치 (일반적으로 < 1MB)<br>- 압축 최적화<br>- WiFi 전용 다운로드 옵션 제공 |
| **네트워크 연결 없는 환경** | 낮음 | 높음 | - 패치 다운로드 실패 시 기존 버전 유지<br>- 오프라인 모드에서도 앱 정상 동작<br>- 다음 네트워크 연결 시 재시도 |
| **프로덕션 서명 문제** | 높음 | 낮음 | - 이미 App Store 배포됨 (서명 완료)<br>- 인증서 만료 모니터링<br>- Xcode 자동 서명 유지 |
| **버전 관리 충돌** | 낮음 | 중간 | - 명확한 브랜치 전략 (main, hotfix/*)<br>- 패치 번호 자동 증가 |

## 테스트 전략

### 단위 테스트
```dart
// test/shorebird_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  group('Shorebird Integration Tests', () {
    late ShorebirdCodePush shorebirdCodePush;

    setUp(() {
      shorebirdCodePush = ShorebirdCodePush();
    });

    test('패치 번호 조회 성공', () async {
      final patchNumber = await shorebirdCodePush.currentPatchNumber();
      expect(patchNumber, isNotNull);
    });

    test('패치 업데이트 가능 여부 확인', () async {
      final available = await shorebirdCodePush.isNewPatchAvailableForDownload();
      expect(available, isA<bool>());
    });
  });
}
```

### 통합 테스트
```dart
// integration_test/shorebird_e2e_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cockat/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('앱 시작 후 패치 확인', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 앱이 정상적으로 시작되는지 확인
    expect(find.text('Cockat'), findsOneWidget);

    // 패치 다운로드 시뮬레이션 후 UI 변경사항 확인
    // (실제 패치 배포 후 테스트)
    await tester.pumpAndSettle(Duration(seconds: 3));
  });
}
```

### TestFlight 베타 테스트 계획
```yaml
베타 그룹 구성:
  - 내부 테스터: 5명 (개발팀)
  - 외부 베타 테스터: 10-20명 (파워 유저)

테스트 시나리오:
  1. 신규 설치 테스트:
     - TestFlight에서 앱 설치
     - 초기 실행 및 주요 기능 확인
     - Shorebird SDK 정상 초기화 확인

  2. 패치 수신 테스트:
     - 앱 실행 중 패치 배포
     - 앱 종료 후 재시작
     - 패치 적용 확인 (UI 변경사항, 로그 등)

  3. 네트워크 시나리오:
     - WiFi 환경에서 패치 다운로드
     - LTE 환경에서 패치 다운로드
     - 오프라인 → 온라인 전환 시 패치 다운로드

  4. 디바이스 호환성:
     - iPhone 12 이상 (iOS 13.0+)
     - iPad (선택 사항)

테스트 기간:
  - Week 1-2: 내부 테스터 집중 테스트
  - Week 3-4: 외부 베타 테스터 확대
  - Week 5: 프로덕션 배포 전 최종 검증
```

### 성능 테스트
```bash
성능 측정 지표:
1. 패치 다운로드 시간:
   - 목표: < 5초 (WiFi), < 15초 (LTE)
   - 측정 도구: Shorebird Console, Firebase Analytics

2. 패치 적용 시간:
   - 목표: < 1초 (앱 재시작 시)
   - 측정 도구: Flutter Performance Overlay

3. 앱 크기 증가:
   - 목표: < 10% (Shorebird SDK 추가)
   - 기준: 1.0.1+2 빌드 크기 대비

4. 메모리 사용량:
   - 목표: 패치 적용 전후 < 5% 증가
   - 측정 도구: Xcode Instruments

5. 배터리 소모:
   - 목표: 백그라운드 패치 다운로드 시 < 2% 추가 소모
   - 측정 도구: iOS Battery Usage Analytics
```

### 브랜치 전략 (수동 배포)
```
main (프로덕션)
  ├── hotfix/fix-xxx (핫픽스 패치)
  └── develop (개발 브랜치)
      └── feature/xxx

배포 전략:
- main: App Store 릴리스 (shorebird release ios)
- hotfix/*: 긴급 패치 (shorebird patch ios)
- develop: 개발 및 테스트
- feature/*: 기능 개발
```

## 롤백 및 긴급 대응 절차

### 자동 롤백 (Shorebird 내장)
```bash
# Shorebird는 패치 적용 실패 시 자동 롤백 수행
# 다음 상황에서 자동 롤백:
# 1. 패치 다운로드 실패 (네트워크 오류)
# 2. 패치 파일 손상
# 3. 호환성 문제 감지

# 로그 확인:
shorebird patch logs --patch-number=<N>
```

### 수동 롤백 절차

#### 1. 패치 비활성화
```bash
# 특정 패치 즉시 비활성화
shorebird patch deactivate --patch-number=<N>

# 또는 롤아웃 비율을 0%로 설정
shorebird patch rollout set --patch-number=<N> --percentage=0

# 확인
shorebird patch list
```

#### 2. 이전 패치로 복구
```bash
# 이전 패치 활성화
shorebird patch activate --patch-number=<N-1>

# 점진적 롤아웃으로 복구 시작
shorebird patch rollout set --patch-number=<N-1> --percentage=10
# 문제 없으면 점진적으로 증가
shorebird patch rollout set --patch-number=<N-1> --percentage=50
shorebird patch rollout set --patch-number=<N-1> --percentage=100
```

#### 3. 긴급 핫픽스 배포
```bash
# hotfix 브랜치 생성
git checkout -b hotfix/emergency-fix

# 코드 수정 후 커밋
git add .
git commit -m "fix: 긴급 버그 수정"

# 로컬에서 즉시 패치 배포
shorebird patch ios

# 소규모 롤아웃으로 시작
shorebird patch rollout set --patch-number=<NEW> --percentage=1

# 모니터링 후 점진적 확대
# 10분 간격으로 1% → 5% → 10% → 50% → 100%
```

### 긴급 대응 체크리스트
```markdown
□ 1. 문제 확인 및 영향 범위 파악
   - 영향 받는 사용자 수
   - 크래시율 증가 여부
   - 특정 디바이스/OS 버전 문제인지 확인

□ 2. 즉시 조치 (5분 이내)
   - 문제 패치 비활성화
   - 팀원에게 긴급 알림 (Slack)
   - Shorebird Console에서 실시간 모니터링 시작

□ 3. 원인 분석 (15분 이내)
   - 로그 분석 (Shorebird, Firebase Crashlytics)
   - 재현 시도 (TestFlight 또는 로컬)
   - 코드 변경사항 리뷰

□ 4. 복구 결정 (30분 이내)
   - 옵션 A: 이전 패치로 롤백
   - 옵션 B: 긴급 핫픽스 패치 배포
   - 옵션 C: App Store 새 버전 제출 (네이티브 문제인 경우)

□ 5. 사후 조치
   - 사후 분석 보고서 작성
   - 재발 방지 대책 수립
   - 테스트 케이스 추가
```

### 모니터링 알림 설정
```yaml
# 모니터링 임계값 설정
alerts:
  patch_failure_rate:
    threshold: 5%
    action: Slack 알림 + 자동 롤백 검토

  download_failure_rate:
    threshold: 10%
    action: Slack 알림

  crash_rate_increase:
    threshold: 2% (패치 배포 전 대비)
    action: 긴급 롤백 고려

  rollout_monitoring:
    1%: 1시간 모니터링
    10%: 2시간 모니터링
    50%: 4시간 모니터링
    100%: 24시간 집중 모니터링
```

## 패치 관리 모범 사례

### 1. 패치 배포 전 체크리스트
```markdown
□ 코드 리뷰 완료 (최소 1명)
□ 단위 테스트 통과 (flutter test)
□ 로컬 빌드 및 테스트 성공
□ 패치 노트 작성 완료
□ 관련 이슈/티켓 번호 기록
□ 예상 영향 범위 분석
□ 롤백 계획 수립
□ 배포 시간 선정 (사용자 활동 낮은 시간대)
```

### 2. 패치 노트 작성 가이드
```markdown
# 패치 노트 템플릿

## Patch #X for Release 1.0.1+2
**Date:** 2026-02-XX
**Type:** Bugfix | Feature | Performance | UI/UX

### 변경 사항
- 명확하고 간결한 변경사항 설명
- 사용자에게 미치는 영향 설명

### 기술적 상세
- 수정된 파일 목록
- 관련 이슈 번호: #123

### 테스트
- 테스트 시나리오 요약
- 영향 받는 기능 목록

### 롤아웃 계획
- 1% → 10% → 50% → 100%
- 각 단계별 모니터링 기간

### 롤백 계획
- 롤백 조건: crash rate > 2% 증가
- 롤백 담당자: @developer
```

### 3. 버전 관리 규칙
```yaml
버전 체계: MAJOR.MINOR.PATCH+BUILD

예시:
- 1.0.1+2: App Store 릴리스 버전
- 1.0.1+2 Patch #1: 첫 번째 OTA 패치
- 1.0.1+2 Patch #2: 두 번째 OTA 패치
- 1.0.2+3: 다음 App Store 릴리스 (패치 리셋)

규칙:
1. App Store 릴리스 시 BUILD 번호 증가
2. 네이티브 변경 시 MINOR 또는 MAJOR 증가
3. 패치 번호는 Shorebird가 자동 관리
4. Git 태그는 App Store 릴리스에만 사용
```

### 4. 배포 타이밍 전략
```yaml
권장 배포 시간:
  - 평일: 화-목 오전 10시-12시 (KST)
  - 주말/공휴일: 배포 지양
  - 금요일 오후: 긴급 상황 외 배포 금지

롤아웃 타이밍:
  1% → 10%: 1-2시간 간격
  10% → 50%: 2-4시간 간격
  50% → 100%: 4-8시간 간격

긴급 패치:
  - 치명적 버그: 즉시 배포
  - 보안 패치: 24시간 이내
  - UI 버그: 48시간 이내
```

### 5. 커뮤니케이션 계획
```markdown
배포 전:
□ 팀원에게 배포 계획 공유 (Slack)
□ 예상 영향 범위 공지
□ 대기 담당자 지정

배포 중:
□ 롤아웃 진행 상황 업데이트
□ 모니터링 지표 공유
□ 이상 징후 즉시 보고

배포 후:
□ 최종 결과 리포트
□ 사용자 피드백 수집
□ 다음 개선사항 논의
```

## 성공 기준

### 기술적 성공 지표
- [ ] Shorebird 프로젝트 초기화 완료
- [ ] 첫 릴리스 빌드 성공 (App Store Connect 업로드)
- [ ] 첫 패치 생성 및 배포 성공
- [ ] 패치 다운로드 성공률 ≥ 95%
- [ ] 패치 적용 성공률 ≥ 98%
- [ ] 크래시율 증가 < 0.5% (패치 배포 후)

### 운영 성공 지표
- [ ] TestFlight 베타 테스트 통과 (버그 0건)
- [ ] App Store 심사 통과 (Shorebird 사용 관련 이슈 없음)
- [ ] 첫 프로덕션 패치 배포 및 롤백 테스트 성공
- [ ] 평균 패치 배포 시간 < 30분 (코드 변경 → 사용자 수신)
- [ ] 긴급 핫픽스 대응 시간 < 2시간 (문제 발견 → 패치 배포)

### 비즈니스 성공 지표
- [ ] 앱스토어 심사 의존도 50% 감소
- [ ] 버그 수정 배포 속도 10배 향상 (48시간 → 4시간)
- [ ] 사용자 만족도 유지 또는 개선 (App Store 평점 ≥ 4.5)
- [ ] 배포 관련 개발 시간 20% 절감

## 참고 자료

### 공식 문서
- [Shorebird 공식 문서](https://docs.shorebird.dev/)
- [Shorebird Flutter 통합 가이드](https://docs.shorebird.dev/guides/flutter/)
- [Shorebird iOS 배포 가이드](https://docs.shorebird.dev/guides/deploy-ios/)
- [Shorebird CI/CD 가이드](https://docs.shorebird.dev/guides/ci-cd/)

### Apple 가이드라인
- [App Store Review Guidelines - 3.3.2](https://developer.apple.com/app-store/review/guidelines/#3.3.2)
  - "Apps may not download code" 예외 조건 확인
  - Interpreted code (Dart) vs Compiled code (네이티브) 구분
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

### 베스트 프랙티스
- [Flutter 배포 모범 사례](https://docs.flutter.dev/deployment/ios)
- [CodePush 유사 사례 연구](https://github.com/microsoft/react-native-code-push)
- [OTA 업데이트 보안 가이드](https://docs.shorebird.dev/concepts/security/)

### 모니터링 도구
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics) - 크래시 리포트
- [Firebase Analytics](https://firebase.google.com/docs/analytics) - 사용자 행동 분석
- [Shorebird Console](https://console.shorebird.dev/) - 패치 배포 모니터링

### 커뮤니티 리소스
- [Shorebird Discord](https://discord.gg/shorebird)
- [Shorebird GitHub Issues](https://github.com/shorebirdtech/shorebird/issues)
- [Flutter Community](https://flutter.dev/community)

## 추가 고려사항

### Android 지원 (향후 확장)
```yaml
현재 상태: iOS만 지원
향후 계획:
  - Android Shorebird 통합 (Phase 2)
  - build.gradle.kts 설정 업데이트
  - Google Play Console 배포 자동화
  - Android 전용 패치 관리

예상 추가 작업:
  - ProGuard/R8 설정 최적화
  - Android 서명 키 관리
  - Google Play 정책 준수 확인
```

### 비용 분석
```yaml
Shorebird 요금제 (2026년 2월 기준):
  - Free Tier: 월 1,000 active devices
  - Pro Tier: $20/월 (무제한 devices)
  - Enterprise: 커스텀 가격

예상 비용:
  - 초기 베타 테스트: Free Tier
  - 프로덕션 배포 후: Pro Tier ($20/월)
  - ROI: 앱스토어 심사 시간 절감 가치 > 비용
```

### 규정 준수
```yaml
확인 필요 사항:
  - GDPR: 패치 다운로드 시 개인정보 처리 확인
  - CCPA: 캘리포니아 사용자 데이터 처리
  - 한국 개인정보보호법: 사용자 동의 필요 여부

대응 방안:
  - 개인정보 처리방침 업데이트
  - 패치 다운로드 전 사용자 동의 (선택 사항)
  - 데이터 저장 위치 확인 (Shorebird 서버 위치)
```

---

**문서 버전**: 1.0
**작성일**: 2026-02-02
**작성자**: Claude Code (Strategic Implementation Architect)
**검토 필요**: Shorebird 계정 생성, TestFlight 베타 테스트
