# Footer 컴포넌트 구현 전략

## 개요
- **목적**: 프로필 화면에 연락처 정보(문의 이메일) 및 앱 정보를 표시하는 Footer 추가
- **범위**:
  - AppFooter 위젯 생성
  - ProfileScreen 하단에만 Footer 배치 (모바일 UX 권장 패턴)
  - 다국어 지원 (한국어/영어)
  - url_launcher 패키지로 이메일 링크 기능 구현
- **문의 이메일**: dltmdwns0721@kakao.com
- **예상 소요 기간**: 2-3시간

## 현재 상태 분석

### 기존 구현
- **ProfileScreen**: `/lib/features/profile/profile_screen.dart`
  - `CustomScrollView` + `SliverAppBar` + `SliverList` 구조
  - 설정, 로그아웃 등 사용자 관련 기능 집중
  - Footer 배치에 가장 적합한 화면

### 문제점/한계
1. 현재 연락처 정보 제공 방법 부재
2. 외부 링크 기능을 위한 `url_launcher` 패키지 미설치

### 관련 코드/모듈
- `/lib/features/profile/profile_screen.dart`: Footer 배치 대상
- `/lib/core/widgets/`: 공통 위젯 저장소
- `/lib/l10n/`: 다국어 지원 파일
- `/pubspec.yaml`: 패키지 의존성 관리

## 구현 전략

### 접근 방식
프로필 화면은 사용자 설정과 앱 정보를 제공하는 자연스러운 위치입니다. 모바일 UX 베스트 프랙티스에 따라 리스트 화면(칵테일, 제품 등)에는 Footer를 두지 않고, 프로필 화면에만 배치합니다.

**핵심 원칙**:
1. ProfileScreen 하단에만 배치 (간결한 UX)
2. CustomScrollView의 `SliverToBoxAdapter`로 래핑
3. 터치 가능한 영역은 명확한 시각적 피드백 제공

### 세부 구현 단계

#### 1단계: 패키지 의존성 추가 (15분)
- `url_launcher` 패키지 추가
- `pubspec.yaml`에 의존성 추가
- iOS: Info.plist에 mailto 스키마 추가

#### 2단계: 다국어 지원 텍스트 추가 (15분)
- `/lib/l10n/app_en.arb` 및 `/lib/l10n/app_ko.arb`에 Footer 관련 문자열 추가
- 필요한 문자열:
  - `footer_contact_email`: "Contact: dltmdwns0721@kakao.com" / "문의: dltmdwns0721@kakao.com"
  - `footer_copyright`: "© 2026 Cockat" / "© 2026 Cockat"

#### 3단계: Footer 위젯 생성 (1시간)
위치: `/lib/core/widgets/app_footer.dart`

**컴포넌트 구조**:
```dart
AppFooter
├── Container (padding)
│   ├── Column
│   │   ├── Divider (구분선)
│   │   ├── Email Link (InkWell + Icon + Text)
│   │   └── Copyright Text
```

**주요 기능**:
- 이메일 클릭 시 메일 앱 실행 (`url_launcher`)
- 다크모드 지원
- 간결한 디자인

#### 4단계: ProfileScreen에 Footer 통합 (30분)
- `SliverList` 마지막에 `SliverToBoxAdapter`로 `AppFooter()` 추가
- Logout 섹션 아래에 배치
- 패딩 조정 및 시각적 검증

#### 5단계: widgets.dart에 export 추가 (5분)
- `/lib/core/widgets/widgets.dart`에 `export 'app_footer.dart';` 추가

#### 6단계: 테스트 및 검증 (30분)
- ProfileScreen에서 Footer 렌더링 확인
- 이메일 링크 동작 테스트 (iOS, Android)
- 다국어 전환 테스트
- 다크모드/라이트모드 테스트

### 기술적 고려사항

#### 의존성
```yaml
dependencies:
  url_launcher: ^6.3.1  # 이메일 링크 실행
```

#### API 설계
```dart
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dltmdwns0721@kakao.com',
      query: 'subject=Cockat 문의',
    );
    await launchUrl(emailUri);
  }
}
```

#### 스타일링
```dart
// 색상: Theme.of(context) 사용
// 텍스트: bodySmall, onSurfaceVariant
// 링크: primary color
// 패딩: EdgeInsets.symmetric(vertical: 24, horizontal: 16)
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| url_launcher iOS 권한 설정 누락 | 높음 | Info.plist에 mailto 스키마 추가 |
| 다국어 문자열 누락 | 중간 | arb 파일 먼저 작성 후 코드 구현 |
| 다크모드 가독성 문제 | 낮음 | Theme.of(context) 색상 사용 |

## 테스트 전략

### 수동 테스트 체크리스트
- [ ] ProfileScreen에서 Footer 정상 표시
- [ ] iOS에서 이메일 링크 동작 확인
- [ ] Android에서 이메일 링크 동작 확인
- [ ] 한국어/영어 환경에서 텍스트 정상 표시
- [ ] 다크모드/라이트모드 가독성 확인

## 성공 기준
- [ ] `url_launcher` 패키지 설치 완료
- [ ] `AppFooter` 위젯 생성
- [ ] ProfileScreen 하단에 Footer 배치
- [ ] 이메일 링크 클릭 시 메일 앱 실행
- [ ] 다국어 지원 정상 동작

## 참고 자료
- [url_launcher 패키지](https://pub.dev/packages/url_launcher)
- [SliverToBoxAdapter](https://api.flutter.dev/flutter/widgets/SliverToBoxAdapter-class.html)

## 추후 개선 사항 (선택사항)
1. 개인정보처리방침/이용약관 페이지 추가
2. 앱 버전 정보 자동 표시 (`package_info_plus`)
3. 소셜 미디어 링크 추가

## 구현 순서 요약
1. url_launcher 패키지 추가 및 설정 (15분)
2. 다국어 문자열 추가 (15분)
3. AppFooter 위젯 생성 (1시간)
4. ProfileScreen 통합 (30분)
5. widgets.dart export 추가 (5분)
6. 테스트 및 검증 (30분)

**총 예상 시간**: 2-3시간
