# 로컬 데이터 → DB 동기화 프로세스 재설계 전략

## 개요
- **목적**: 회원/비회원 데이터 관리 프로세스를 명확히 분리하여 사용자 경험 개선
- **범위**: 온보딩, 로그인, 회원가입, 프로필 화면의 데이터 동기화 로직 재설계
- **예상 소요 기간**: 2-3시간

## 현재 상태 분석

### 기존 구현

#### 1. 온보딩 Auth 페이지 (`auth_page.dart`)
**현재 동작**:
- 회원가입/로그인 모두 성공 시 `migrateLocalToDb()` 호출 (라인 145, 158)
- 데이터 마이그레이션 후 온보딩 완료

**문제점**:
- 로그인과 회원가입의 동기화 전략이 동일함
- 로그인 시에도 로컬 데이터를 DB로 이동시킴 (요구사항과 불일치)

#### 2. 로그인 화면 (`login_screen.dart`)
**현재 동작**:
- 로그인 성공 시 `MigrationDialog.showIfNeeded()` 호출 (라인 52)
- `syncDbToLocal()` 호출로 DB → 로컬 동기화 (라인 55)

**문제점**:
- MigrationDialog가 로컬 데이터 존재 시 마이그레이션 여부를 묻는 형태
- 요구사항: 로그인 시 로컬 데이터를 즉시 삭제하고 DB 데이터만 사용

#### 3. 회원가입 화면 (`signup_screen.dart`)
**현재 동작**:
- 회원가입 성공 시 단순히 화면만 닫음 (라인 54)
- 실제 마이그레이션은 auth_page에서 처리됨

**문제점**:
- 회원가입 직후 로컬 데이터 마이그레이션 로직이 auth_page에 의존
- 독립적인 회원가입 흐름이 없음

#### 4. MigrationDialog (`migration_dialog.dart`)
**현재 동작**:
- 로컬 데이터 요약을 보여주고 마이그레이션 여부를 사용자에게 물음
- "동기화" 또는 "건너뛰기" 선택 가능
- 건너뛰기 시에도 로컬 데이터 삭제 (라인 76)

**사용 위치**:
- 로그인 화면에서만 사용 (라인 52)

#### 5. OnboardingService (`onboarding_provider.dart`)
**현재 메서드**:
- `migrateLocalToDb()` (라인 202-260): 로컬 → DB 마이그레이션
  - user_preferences 마이그레이션
  - 상품, 기타 아이템, 재료, 즐겨찾기 마이그레이션
  - 모든 provider invalidation

- `syncDbToLocal()` (라인 262-286): DB → 로컬 동기화
  - 오프라인 지원용
  - user_preferences만 동기화

### 관련 코드 모듈

#### 로컬 데이터 Provider
- `selectedProductsProvider` (product_provider.dart)
- `selectedMiscItemsLocalProvider` (misc_item_provider.dart)
- `selectedIngredientsProvider` (ingredient_provider.dart)
- `favoriteCocktailsProvider` (favorites_provider.dart)
- `onboardingCompletedLocalProvider` (onboarding_provider.dart)
- `unitSystemLocalProvider` (onboarding_provider.dart)

#### DB Provider
- `userProductsDbProvider` (product_provider.dart)
- `userMiscItemsDbProvider` (misc_item_provider.dart)
- `userIngredientsDbProvider` (ingredient_provider.dart)
- `userFavoritesDbProvider` (favorites_provider.dart)
- `userPreferencesDbProvider` (onboarding_provider.dart)

#### 통합 Provider (unified_providers.dart)
- `effectiveSelectedProductsProvider`: 비회원/회원 자동 분기
- `effectiveSelectedIngredientsProvider`: 비회원/회원 자동 분기
- `effectiveFavoritesProvider`: 비회원/회원 자동 분기
- Optimistic UI 지원: `_optimisticProductsProvider`, `_optimisticFavoritesProvider`, `_optimisticIngredientsProvider`

#### 프로필 화면 (`profile_screen.dart`)
**현재 동기화 관련 UI**:
- 라인 122-131: "데이터 동기화" 메뉴 (현재 "곧 출시" 상태)
- 이 버튼은 제거 예정

## 구현 전략

### 핵심 원칙
1. **로그인 시**: 로컬 데이터 즉시 삭제 → DB 데이터만 사용
2. **회원가입 시**: 로컬 데이터 → DB 마이그레이션 (단 한 번)
3. **비회원 → 회원 전환**: 회원가입 시에만 데이터 이관
4. **명확한 사용자 안내**: 온보딩 화면에서 로컬 데이터 유무에 따른 메시지 표시

### 접근 방식

#### Phase 1: OnboardingService 메서드 수정
기존 `migrateLocalToDb()` 외에 로그인 전용 메서드 추가

```dart
class OnboardingService {
  /// 회원가입 시: 로컬 데이터 → DB 마이그레이션
  Future<void> migrateLocalToDbOnSignup() async {
    // 기존 migrateLocalToDb() 로직 그대로 사용
  }

  /// 로그인 시: 로컬 데이터 삭제 + DB 데이터 로드
  Future<void> clearLocalDataOnLogin() async {
    final prefs = _ref.read(sharedPreferencesProvider);

    // 모든 로컬 데이터 삭제
    await prefs.remove('selected_products');
    await prefs.remove('selected_misc_items');
    await prefs.remove('selected_ingredients');
    await prefs.remove('favorite_cocktails');
    await prefs.remove('onboarding_completed');
    await prefs.remove('unit_system');

    // 모든 로컬 provider 초기화
    _ref.invalidate(selectedProductsProvider);
    _ref.invalidate(selectedMiscItemsLocalProvider);
    _ref.invalidate(selectedIngredientsProvider);
    _ref.invalidate(favoriteCocktailsProvider);
    _ref.invalidate(onboardingCompletedLocalProvider);
    _ref.invalidate(unitSystemLocalProvider);

    // DB provider refresh (이미 로그인 상태이므로 자동으로 DB에서 로드됨)
    _ref.invalidate(userProductsDbProvider);
    _ref.invalidate(userMiscItemsDbProvider);
    _ref.invalidate(userIngredientsDbProvider);
    _ref.invalidate(userFavoritesDbProvider);
    _ref.invalidate(userPreferencesDbProvider);
  }
}
```

#### Phase 2: 온보딩 Auth 페이지 수정

**변경 사항**:
1. 회원가입 성공 시에만 마이그레이션 실행
2. 로그인 성공 시에는 로컬 데이터 삭제만 수행
3. 로컬 데이터 유무에 따른 안내 메시지 추가

**주요 코드 변경**:
```dart
// auth_page.dart

// 회원가입 버튼 영역에 조건부 메시지 추가
Widget _buildSignUpButton(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
  final hasLocalData = ref.watch(hasLocalDataProvider); // 새로운 provider

  return Column(
    children: [
      if (hasLocalData)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.signUpToSyncData, // "회원가입하고 데이터를 연동해 보세요"
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      FilledButton(
        onPressed: () => _navigateToSignUp(context, ref),
        child: Text(l10n.signUp),
      ),
    ],
  );
}

Future<void> _navigateToSignUp(BuildContext context, WidgetRef ref) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (context) => const SignUpScreen()),
  );

  if (result == true && context.mounted) {
    // 회원가입 성공: 로컬 데이터 → DB 마이그레이션
    await ref.read(onboardingServiceProvider).migrateLocalToDbOnSignup();
    onComplete();
  }
}

Future<void> _navigateToLogin(BuildContext context, WidgetRef ref) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );

  if (result == true && context.mounted) {
    // 로그인 성공: 로컬 데이터 삭제 (DB 데이터만 사용)
    await ref.read(onboardingServiceProvider).clearLocalDataOnLogin();
    onComplete();
  }
}
```

**새로운 Provider 추가**:
```dart
// onboarding_provider.dart에 추가

/// 로컬 데이터 존재 여부 확인
final hasLocalDataProvider = Provider<bool>((ref) {
  final products = ref.watch(selectedProductsProvider);
  final miscItems = ref.watch(selectedMiscItemsLocalProvider);
  final ingredients = ref.watch(selectedIngredientsProvider);
  final favorites = ref.watch(favoriteCocktailsProvider);

  return products.isNotEmpty ||
         miscItems.isNotEmpty ||
         ingredients.isNotEmpty ||
         favorites.isNotEmpty;
});
```

#### Phase 3: 로그인 화면 수정

**변경 사항**:
- MigrationDialog 호출 제거
- 로컬 데이터 삭제 로직 통합

```dart
// login_screen.dart

Future<void> _signInWithEmail() async {
  // ... 기존 로그인 로직 ...

  if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loginSuccess)),
    );

    // 로컬 데이터 삭제 (MigrationDialog 제거)
    await ref.read(onboardingServiceProvider).clearLocalDataOnLogin();

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
```

**OAuth 로그인도 동일하게 처리** (`_signInWithGoogle`, `_signInWithApple`):
- AuthStateListener에서 자동 처리 또는
- 각 메서드에서 명시적으로 `clearLocalDataOnLogin()` 호출

#### Phase 4: 회원가입 화면 수정

**변경 사항**:
- 회원가입 성공 시 true 반환 (기존 동작 유지)
- 실제 마이그레이션은 auth_page에서 처리

```dart
// signup_screen.dart

Future<void> _signUpWithEmail() async {
  // ... 기존 회원가입 로직 ...

  if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.signUpSuccess)),
    );

    // true 반환하여 auth_page에서 마이그레이션 트리거
    Navigator.of(context).pop(true);
  }
}
```

#### Phase 5: 프로필 화면 수정

**변경 사항**:
- "데이터 동기화" 버튼 제거 (라인 122-131)

```dart
// profile_screen.dart

// Account Section (if logged in)
if (isAuthenticated) ...[
  _SectionHeader(title: l10n.account),
  // 동기화 버튼 제거됨
  ListTile(
    leading: Icon(Icons.logout, color: colorScheme.error),
    title: Text(
      l10n.logout,
      style: TextStyle(color: colorScheme.error),
    ),
    onTap: () async {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logoutSuccess)),
        );
      }
    },
  ),
  const Divider(),
],
```

#### Phase 6: MigrationDialog 제거 또는 보관

**옵션 A: 완전 제거**
- 더 이상 사용하지 않으므로 파일 삭제
- 관련 import 정리

**옵션 B: 보관 (추후 재사용 가능성 대비)**
- 파일은 유지하되 사용하지 않음
- 주석으로 deprecated 표시

**권장**: 옵션 A (완전 제거)
- 코드베이스 정리
- 혼란 방지

### 세부 구현 단계

#### Step 1: OnboardingService 메서드 추가
**파일**: `lib/data/providers/onboarding_provider.dart`

1. `clearLocalDataOnLogin()` 메서드 추가
2. `migrateLocalToDbOnSignup()` 메서드 추가 (기존 `migrateLocalToDb()` 이름 변경 또는 래퍼)
3. `hasLocalDataProvider` 추가

**예상 시간**: 30분

#### Step 2: 온보딩 Auth 페이지 수정
**파일**: `lib/features/onboarding/pages/auth_page.dart`

1. `hasLocalDataProvider` import 및 watch
2. 회원가입 버튼 영역에 조건부 메시지 추가
3. `_navigateToSignUp()` 메서드 수정 (마이그레이션 로직)
4. `_navigateToLogin()` 메서드 수정 (로컬 데이터 삭제 로직)

**예상 시간**: 30분

#### Step 3: 로그인 화면 수정
**파일**: `lib/features/auth/login_screen.dart`

1. MigrationDialog import 제거
2. `_signInWithEmail()` 메서드 수정
3. OAuth 로그인 메서드 수정 (`_signInWithGoogle`, `_signInWithApple`)

**예상 시간**: 20분

#### Step 4: 회원가입 화면 확인
**파일**: `lib/features/auth/signup_screen.dart`

1. 현재 구현 검토 (이미 true 반환 중)
2. 필요 시 주석 추가

**예상 시간**: 10분

#### Step 5: 프로필 화면 수정
**파일**: `lib/features/profile/profile_screen.dart`

1. "데이터 동기화" ListTile 제거 (라인 122-131)
2. UI 테스트

**예상 시간**: 10분

#### Step 6: MigrationDialog 제거
**파일**: `lib/features/auth/migration_dialog.dart`

1. 파일 삭제
2. 관련 import 정리 (login_screen.dart에서 제거됨)

**예상 시간**: 10분

#### Step 7: 다국어 문자열 추가
**파일**: `lib/l10n/app_*.arb`

1. `signUpToSyncData` 추가
   - EN: "Sign up to sync your data"
   - KO: "회원가입하고 데이터를 연동해 보세요"

**예상 시간**: 10분

#### Step 8: 테스트 및 검증
1. **비회원 → 회원가입 시나리오**
   - 로컬 데이터 있는 상태에서 회원가입
   - DB에 마이그레이션 확인
   - 로컬 데이터 삭제 확인

2. **비회원 → 로그인 시나리오**
   - 로컬 데이터 있는 상태에서 로그인
   - 로컬 데이터 즉시 삭제 확인
   - DB 데이터만 표시 확인

3. **회원 → 로그아웃 → 재로그인**
   - DB 데이터 정상 로드 확인

4. **온보딩 메시지 확인**
   - 로컬 데이터 있을 때 메시지 표시 확인
   - 로컬 데이터 없을 때 메시지 미표시 확인

**예상 시간**: 40분

### 기술적 고려사항

#### 아키텍처
- **기존 아키텍처 유지**: Riverpod Provider 패턴 그대로 사용
- **명확한 책임 분리**: OnboardingService가 모든 동기화 로직 관리
- **단방향 데이터 흐름**: 로그인/회원가입 → Service 메서드 호출 → Provider invalidation → UI 업데이트

#### 의존성
- 새로운 패키지 추가 없음
- 기존 코드 리팩토링만 수행

#### 데이터 모델
- 변경 없음
- 기존 SharedPreferences 키와 Supabase 테이블 스키마 그대로 사용

#### API 설계
OnboardingService 메서드:
```dart
// 회원가입 전용
Future<void> migrateLocalToDbOnSignup() async

// 로그인 전용
Future<void> clearLocalDataOnLogin() async

// 로컬 데이터 존재 여부 (Provider)
final hasLocalDataProvider = Provider<bool>((ref) => ...)
```

#### Provider Invalidation 전략
```dart
// 로그인 시
clearLocalDataOnLogin() {
  // 1. SharedPreferences 키 삭제
  // 2. 로컬 provider invalidate
  // 3. DB provider invalidate (자동으로 DB에서 재로드)
}

// 회원가입 시
migrateLocalToDbOnSignup() {
  // 1. DB upsert
  // 2. SharedPreferences 키 삭제
  // 3. 모든 provider invalidate
}
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 로그인 시 로컬 데이터 삭제 후 DB 로드 실패 | 높음 | - try-catch로 에러 처리<br>- 실패 시 사용자에게 재시도 안내<br>- 로컬 데이터 삭제 전 DB 연결 확인 |
| OAuth 로그인 흐름 처리 누락 | 중간 | - Google/Apple 로그인도 동일하게 처리<br>- AuthStateListener에서 통합 처리 고려 |
| 기존 사용자 데이터 손실 | 높음 | - 로그 추가로 모니터링<br>- 단계별 커밋으로 롤백 가능하도록 |
| Optimistic UI 충돌 | 중간 | - Optimistic state 초기화 타이밍 확인<br>- invalidate 순서 최적화 |
| 온보딩 플로우 중단 시나리오 | 낮음 | - 각 단계별 상태 저장<br>- 재진입 시 복원 가능하도록 |

## 테스트 전략

### 단위 테스트
1. **OnboardingService 메서드**
   - `clearLocalDataOnLogin()` 호출 시 모든 로컬 데이터 삭제 확인
   - `migrateLocalToDbOnSignup()` 호출 시 DB upsert 확인
   - `hasLocalDataProvider` 로컬 데이터 유무 정확성

### 통합 테스트
1. **회원가입 플로우**
   - 비회원 데이터 → DB 마이그레이션 → 로컬 삭제
   - effective providers가 DB 데이터 반환 확인

2. **로그인 플로우**
   - 로컬 데이터 즉시 삭제
   - DB 데이터만 로드
   - MigrationDialog 미표시 확인

3. **온보딩 완료 플로우**
   - auth_page에서 회원가입/로그인 후 올바른 메서드 호출
   - 온보딩 완료 상태 업데이트

### E2E 테스트 시나리오
1. **비회원 사용자가 로컬 데이터를 설정한 후 회원가입**
   - 제품 3개, 즐겨찾기 2개 선택
   - 회원가입
   - DB 조회로 마이그레이션 확인
   - 로컬 데이터 삭제 확인

2. **비회원 사용자가 로컬 데이터를 설정한 후 로그인**
   - 제품 3개 선택
   - 기존 계정으로 로그인
   - 로컬 데이터 즉시 삭제 확인
   - DB 데이터만 표시 확인

3. **기존 사용자가 로그아웃 후 재로그인**
   - 로그아웃
   - 로컬 모드에서 제품 추가 (새 데이터)
   - 재로그인
   - 새 로컬 데이터 삭제, 기존 DB 데이터만 표시

## 성공 기준
- [ ] 로그인 시 로컬 데이터 자동 삭제 및 DB 데이터만 표시
- [ ] 회원가입 시 로컬 데이터 → DB 마이그레이션 정상 작동
- [ ] 온보딩 Auth 페이지에서 로컬 데이터 유무에 따른 안내 메시지 표시
- [ ] 프로필 화면에서 동기화 버튼 제거
- [ ] MigrationDialog 완전 제거
- [ ] 모든 E2E 시나리오 통과
- [ ] 기존 사용자 데이터 손실 없음
- [ ] Provider invalidation 정상 작동 (UI 자동 업데이트)

## 영향 받는 파일 목록

### 수정 필요 파일
1. **lib/data/providers/onboarding_provider.dart**
   - `clearLocalDataOnLogin()` 추가
   - `migrateLocalToDbOnSignup()` 추가
   - `hasLocalDataProvider` 추가

2. **lib/features/onboarding/pages/auth_page.dart**
   - `_navigateToSignUp()` 수정
   - `_navigateToLogin()` 수정
   - 회원가입 버튼 영역 UI 수정

3. **lib/features/auth/login_screen.dart**
   - `_signInWithEmail()` 수정
   - MigrationDialog import 제거
   - OAuth 로그인 메서드 수정

4. **lib/features/auth/signup_screen.dart**
   - 검토 및 주석 추가 (큰 변경 없음)

5. **lib/features/profile/profile_screen.dart**
   - "데이터 동기화" ListTile 제거 (라인 122-131)

6. **lib/l10n/app_en.arb**
   - `signUpToSyncData` 추가

7. **lib/l10n/app_ko.arb**
   - `signUpToSyncData` 추가

### 삭제 파일
1. **lib/features/auth/migration_dialog.dart**
   - 전체 파일 삭제

2. **lib/core/services/migration_service.dart**
   - 검토 후 삭제 여부 결정 (MigrationDialog만 사용하는 경우 삭제)

### 영향 받지만 수정 불필요
1. **lib/data/providers/unified_providers.dart**
   - effective providers는 자동으로 분기하므로 변경 불필요
   - Optimistic UI 로직 유지

2. **lib/data/providers/product_provider.dart**
   - 변경 불필요

3. **lib/data/providers/favorites_provider.dart**
   - 변경 불필요

## UI/UX 변경 사항

### 온보딩 Auth 페이지
**Before**:
```
[Cloud Sync Icon]
클라우드 동기화
계정을 연동하여 데이터를 안전하게 보관하세요

[Benefits List]
• 동기화
• 즐겨찾기
• 백업

[Sign Up Button]
[Login Button]
[Maybe Later]
```

**After**:
```
[Cloud Sync Icon]
클라우드 동기화
계정을 연동하여 데이터를 안전하게 보관하세요

[Benefits List]
• 동기화
• 즐겨찾기
• 백업

[If hasLocalData]
  "회원가입하고 데이터를 연동해 보세요" (primary color, small)

[Sign Up Button]
[Login Button]
[Maybe Later]
```

### 로그인 화면
**Before**:
```
로그인 → 성공 → MigrationDialog 표시 → "동기화" or "건너뛰기" → 완료
```

**After**:
```
로그인 → 성공 → 로컬 데이터 자동 삭제 → 완료 (다이얼로그 없음)
```

### 프로필 화면
**Before**:
```
Account Section
├─ 데이터 동기화 (곧 출시)
└─ 로그아웃
```

**After**:
```
Account Section
└─ 로그아웃
```

## 참고 자료

### 관련 문서
- [User Experience Design](../user-experience-design.md)
- [Settings Redesign Strategy](./2026-01-21-settings-redesign-strategy.md)

### 관련 Provider 구조
- **로컬 전용**: `selectedProductsProvider`, `favoriteCocktailsProvider` 등
- **DB 전용**: `userProductsDbProvider`, `userFavoritesDbProvider` 등
- **통합 (자동 분기)**: `effectiveSelectedProductsProvider`, `effectiveFavoritesProvider` 등
- **Optimistic UI**: `_optimisticProductsProvider`, `_optimisticFavoritesProvider` 등

### Supabase 테이블 구조
```sql
-- user_preferences
user_id UUID PRIMARY KEY
onboarding_completed BOOLEAN
unit_system TEXT
updated_at TIMESTAMP

-- user_products
user_id UUID
product_id TEXT
PRIMARY KEY (user_id, product_id)

-- user_misc_items
user_id UUID
misc_item_id TEXT
PRIMARY KEY (user_id, misc_item_id)

-- user_ingredients
user_id UUID
ingredient_id TEXT
PRIMARY KEY (user_id, ingredient_id)

-- user_favorites
user_id UUID
cocktail_id TEXT
PRIMARY KEY (user_id, cocktail_id)
```

## 구현 순서 요약
1. OnboardingService 메서드 추가 (30분)
2. 온보딩 Auth 페이지 수정 (30분)
3. 로그인 화면 수정 (20분)
4. 회원가입 화면 확인 (10분)
5. 프로필 화면 수정 (10분)
6. MigrationDialog 제거 (10분)
7. 다국어 문자열 추가 (10분)
8. 테스트 및 검증 (40분)

**총 예상 시간**: 2시간 40분
