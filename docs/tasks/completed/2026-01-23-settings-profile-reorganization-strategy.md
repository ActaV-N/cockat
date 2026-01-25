# 설정/프로필 페이지 재구성 및 기타 재료 반영 문제 해결 전략

## 개요
- **목적**: 설정 및 프로필 페이지의 중복 제거, 구조 개선, 기타 재료 반영 문제 해결
- **범위**: Settings Screen, Profile Screen, 재료 설정 페이지, 데이터 동기화 로직
- **예상 소요 기간**: 2-3일

## 현재 상태 분석

### 1. 페이지 구조 및 중복 사항

#### Settings Screen (`lib/features/settings/settings_screen.dart`)
**현재 구성**:
- Account Section (회원 정보, 로그인/로그아웃)
- General Section
  - Theme (System/Light/Dark)
  - Language (System/English/Korean)
- Ingredient Settings Section
  - Other Ingredients (기타 재료 설정)
  - Unit Settings (단위 설정)
- Data Management Section
  - Re-run Setup (초기 설정 다시하기)
  - **[제거 대상]** "데이터 동기화" 버튼 (현재 "Coming Soon" 상태)
- About Section
  - Version info
  - Data Source info

#### Profile Screen (`lib/features/profile/profile_screen.dart`)
**현재 구성**:
- Profile Header (아바타, 이메일/게스트 정보)
- Auth Section (비로그인 시 회원가입/로그인 버튼)
- Account Section (로그인 시 로그아웃 버튼)
- **[중복]** Theme Section (System/Light/Dark)
- **[중복]** Language Section (System/English/Korean)
- Settings 링크 (설정 화면으로 이동)
- About Section
  - Version info
  - Data Source info

**중복 항목**:
1. Theme 설정 (Settings ↔ Profile)
2. Language 설정 (Settings ↔ Profile)
3. About 섹션 (Settings ↔ Profile)
4. Account 섹션 (Settings ↔ Profile)

### 2. 기타 재료 반영 문제 분석

#### 데이터 흐름 추적

**1단계: 기타 재료 선택**
- 위치: `lib/features/settings/pages/other_ingredients_settings_page.dart`
- Provider: `effectiveSelectedMiscItemsProvider` (line 51)
- Service: `effectiveMiscItemsServiceProvider` (line 163)

**2단계: 저장 메커니즘**
- 파일: `lib/data/providers/misc_item_provider.dart`
- 비회원: `selectedMiscItemsLocalProvider` → SharedPreferences 저장 (line 54-93)
- 회원: `userMiscItemsDbProvider` → Supabase DB 저장 (line 98-109)
- 통합: `effectiveSelectedMiscItemsProvider` (line 114-123)

**3단계: 칵테일 매칭에 사용**
- 파일: `lib/data/providers/cocktail_provider.dart`
- Provider: `allSelectedIngredientIdsProvider` (line 88-100)
  - 상품에서 추출한 재료: `ingredientIdsFromProductsProvider`
  - 직접 선택한 재료: `selectedIngredientsProvider`
  - **문제 발견**: 기타 재료(misc_items)가 포함되지 않음!

**4단계: 매칭 로직**
- Provider: `cocktailMatchesProvider` (line 118-208)
- 사용 재료: `allSelectedIngredientIdsProvider`만 사용
- **문제**: misc_items가 재료 목록에 포함되지 않아 칵테일 매칭 시 반영 안 됨

#### 문제 근본 원인
```
기타 재료(misc_items) 선택 → effectiveSelectedMiscItemsProvider에 저장
                                    ↓
                                    X (연결 끊김)
                                    ↓
칵테일 매칭 ← allSelectedIngredientIdsProvider (상품 재료 + 직접 선택 재료만 포함)
```

**핵심 문제**: `allSelectedIngredientIdsProvider`가 기타 재료를 포함하지 않음

### 3. 데이터 동기화 버튼 위치 및 기능

#### 현재 위치 및 코드
- 파일: `lib/features/settings/settings_screen.dart` (line 310-319)
```dart
ListTile(
  leading: const Icon(Icons.sync),
  title: Text(l10n.syncData),
  subtitle: Text(l10n.comingSoon),
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.featureComingSoon)),
    );
  },
),
```

#### 관련 코드 검색 결과
- 실제 동기화 로직은 `lib/data/providers/onboarding_provider.dart`에 구현됨
  - `migrateLocalToDb()` (line 201-260): 로컬 → DB 마이그레이션
  - `syncDbToLocal()` (line 262-286): DB → 로컬 동기화
- **현재 상태**: Settings 화면의 버튼은 "Coming Soon" 메시지만 표시
- **자동 동기화**: 로그인 시 `auth_page.dart`에서 자동으로 `migrateLocalToDb()` 호출

## 구현 전략

### 접근 방식
1. **Phase 1**: 기타 재료 반영 문제 해결 (우선순위 높음)
2. **Phase 2**: 데이터 동기화 버튼 및 관련 코드 제거
3. **Phase 3**: 설정/프로필 페이지 구조 재편성
4. **Phase 4**: 재료 설정 페이지를 프로필 하위로 이동
5. **Phase 5**: "초기 설정 다시하기" 버튼 제거

### 세부 구현 단계

#### Phase 1: 기타 재료 반영 문제 해결

**Step 1.1: 통합 재료 Provider 수정**
- 파일: `lib/data/providers/cocktail_provider.dart`
- 위치: `allSelectedIngredientIdsProvider` (line 88-100)
- 작업:
  1. 기존 로직에 misc_items 추가
  2. 비회원/회원 모두 misc_items 포함하도록 수정

```dart
// Before
final allSelectedIngredientIdsProvider = Provider<Set<String>>((ref) {
  if (isAuthenticated) {
    return ref.watch(effectiveAllIngredientIdsProvider);
  } else {
    final fromProducts = ref.watch(ingredientIdsFromProductsProvider);
    final directSelection = ref.watch(selectedIngredientsProvider);
    return {...fromProducts, ...directSelection};
  }
});

// After (예시)
final allSelectedIngredientIdsProvider = Provider<Set<String>>((ref) {
  if (isAuthenticated) {
    return ref.watch(effectiveAllIngredientIdsProvider);
  } else {
    final fromProducts = ref.watch(ingredientIdsFromProductsProvider);
    final directSelection = ref.watch(selectedIngredientsProvider);
    final miscItems = ref.watch(selectedMiscItemsLocalProvider);
    return {...fromProducts, ...directSelection, ...miscItems};
  }
});
```

**Step 1.2: Unified Provider 수정**
- 파일: `lib/data/providers/unified_providers.dart`
- 위치: `effectiveAllIngredientIdsProvider` (line 168-176)
- 작업:
  1. misc_items를 재료 목록에 추가
  2. Stream provider watch 추가 (실시간 업데이트 보장)

```dart
// Before
final effectiveAllIngredientIdsProvider = Provider<Set<String>>((ref) {
  ref.watch(userIngredientsDbProvider);
  ref.watch(userProductsDbProvider);

  final fromProducts = ref.watch(effectiveIngredientIdsFromProductsProvider);
  final directSelection = ref.watch(effectiveSelectedIngredientsProvider);
  return {...fromProducts, ...directSelection};
});

// After (예시)
final effectiveAllIngredientIdsProvider = Provider<Set<String>>((ref) {
  ref.watch(userIngredientsDbProvider);
  ref.watch(userProductsDbProvider);
  ref.watch(userMiscItemsDbProvider);  // 추가

  final fromProducts = ref.watch(effectiveIngredientIdsFromProductsProvider);
  final directSelection = ref.watch(effectiveSelectedIngredientsProvider);
  final miscItems = ref.watch(effectiveSelectedMiscItemsProvider);  // 추가
  return {...fromProducts, ...directSelection, ...miscItems};
});
```

**Step 1.3: 테스트 및 검증**
- 기타 재료 선택 → 칵테일 매칭 결과 확인
- 비회원/회원 모두 테스트
- 로그인/로그아웃 시 데이터 유지 확인

#### Phase 2: 데이터 동기화 버튼 제거

**Step 2.1: Settings Screen 수정**
- 파일: `lib/features/settings/settings_screen.dart`
- 작업:
  1. Line 310-319의 "데이터 동기화" ListTile 제거
  2. Account Section에서 해당 부분만 삭제

**Step 2.2: 다국어 리소스 정리 (선택사항)**
- 파일: `lib/l10n/app_localizations_*.dart`
- 작업: `syncData`, `comingSoon`, `featureComingSoon` 메시지 제거 여부 결정
  - 주의: 다른 곳에서 사용 중인지 확인 필요

**Step 2.3: 자동 동기화 로직 유지**
- 파일: `lib/features/onboarding/pages/auth_page.dart`
- 확인: 로그인 시 자동 마이그레이션 로직 유지
- 변경사항 없음 (자동 동기화는 계속 작동)

#### Phase 3: 설정/프로필 페이지 구조 재편성

**Step 3.1: 설정 페이지를 앱 설정 전용으로 변경**
- 파일: `lib/features/settings/settings_screen.dart`
- 최종 구조:
  ```
  Settings Screen
  ├── General (앱 설정)
  │   ├── Theme
  │   └── Language
  ├── About
  │   ├── Version
  │   └── Data Source
  ```

**변경 내용**:
1. Account Section 제거 (Profile로 이동)
2. Ingredient Settings Section 제거 (Profile 하위로 이동)
3. Data Management Section 제거
4. Theme, Language, About만 유지

**Step 3.2: 프로필 페이지를 사용자 중심으로 변경**
- 파일: `lib/features/profile/profile_screen.dart`
- 최종 구조:
  ```
  Profile Screen
  ├── Profile Header (아바타, 이메일/게스트)
  ├── Account Section
  │   ├── [비로그인] 회원가입/로그인 버튼
  │   └── [로그인] 로그아웃 버튼
  ├── Ingredient Settings (새로 추가)
  │   ├── Other Ingredients (기타 재료)
  │   └── Unit Settings (단위 설정)
  └── App Settings (설정 화면 링크)
  ```

**변경 내용**:
1. Theme Section 제거 (Settings로 이동)
2. Language Section 제거 (Settings로 이동)
3. About Section 제거 (Settings로 이동)
4. Ingredient Settings Section 추가 (Settings에서 이동)

**Step 3.3: 코드 구현**

**설정 화면 수정**:
```dart
// settings_screen.dart
body: ListView(
  children: [
    // General Section (Theme & Language)
    _SectionHeader(title: l10n.general),

    // Theme
    _SubSectionHeader(title: l10n.theme),
    // ... theme tiles ...

    // Language
    _SubSectionHeader(title: l10n.language),
    // ... language tiles ...

    const Divider(),

    // About Section
    _SectionHeader(title: l10n.about),
    // ... about info ...
  ],
)
```

**프로필 화면 수정**:
```dart
// profile_screen.dart
SliverList(
  delegate: SliverChildListDelegate([
    // Auth Section (if not logged in)
    if (!isAuthenticated) ...[
      // 회원가입/로그인 버튼
    ],

    // Account Section (if logged in)
    if (isAuthenticated) ...[
      _SectionHeader(title: l10n.account),
      // 로그아웃 버튼
      const Divider(),
    ],

    // Ingredient Settings Section (새로 추가)
    _SectionHeader(title: l10n.ingredientSettings),
    ListTile(
      leading: const Icon(Icons.kitchen),
      title: Text(l10n.otherIngredients),
      subtitle: Text(l10n.otherIngredientsDescription),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(...),
    ),
    ListTile(
      leading: const Icon(Icons.straighten),
      title: Text(l10n.unitSettings),
      subtitle: Text(l10n.unitSettingsDescription),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(...),
    ),

    const Divider(),

    // App Settings
    ListTile(
      leading: const Icon(Icons.settings),
      title: Text(l10n.appSettings), // 새 다국어 키 필요
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(...),
    ),
  ]),
)
```

#### Phase 4: 재료 설정 페이지 경로 변경

**현재 경로**: Settings → Ingredient Settings → Other Ingredients/Unit Settings
**목표 경로**: Profile → Ingredient Settings → Other Ingredients/Unit Settings

**Step 4.1: Navigation 코드 수정**
- 프로필에서 재료 설정 페이지로의 라우팅 추가
- Settings에서 재료 설정 관련 코드 제거

**Step 4.2: 파일 구조 유지**
- 파일 위치는 그대로 유지: `lib/features/settings/pages/`
- 단, 접근 경로만 Profile을 통하도록 변경

#### Phase 5: "초기 설정 다시하기" 버튼 제거

**Step 5.1: Settings Screen 수정**
- 파일: `lib/features/settings/settings_screen.dart`
- 작업: Line 123-162의 "Re-run Setup" 관련 코드 제거
  - Data Management Section 전체 제거
  - ListTile, AlertDialog, navigation 로직 모두 제거

**Step 5.2: 다국어 리소스 정리 (선택사항)**
- `reRunSetup`, `reRunSetupDescription`, `resetSetupConfirm`, `setupReset` 키 제거 검토
- 다른 곳에서 사용되는지 확인

**Step 5.3: OnboardingService 메서드 유지**
- `resetOnboarding()` 메서드는 유지 (향후 필요할 수 있음)
- UI에서만 접근 불가하도록 변경

### 기술적 고려사항

#### 아키텍처
- Provider 구조 유지 (Riverpod)
- 통합 Provider 패턴 유지 (비회원/회원 자동 분기)
- Optimistic UI 패턴 유지

#### 의존성
- 신규 의존성 추가 없음
- 기존 Provider 간 의존성 수정
  - `effectiveAllIngredientIdsProvider` → misc_items 추가
  - `allSelectedIngredientIdsProvider` → misc_items 추가

#### 데이터 모델
- 변경 없음 (기존 MiscItem 모델 사용)
- DB 스키마 변경 없음

#### API 설계
- 변경 없음 (Supabase 쿼리 그대로 유지)

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 기타 재료 추가 시 칵테일 매칭 성능 저하 | 중간 | Set 연산 사용으로 O(1) 조회 유지, 대규모 테스트 필요 |
| 기존 사용자의 misc_items 데이터 손실 | 낮음 | 데이터는 그대로 유지, Provider만 수정하므로 안전 |
| 프로필/설정 분리로 인한 UX 혼란 | 중간 | 명확한 섹션 분리 및 레이블 사용, 사용자 테스트 필요 |
| 동기화 버튼 제거 후 사용자 혼란 | 낮음 | 자동 동기화가 작동 중이므로 실제 기능 상실 없음 |
| 다국어 키 제거 시 빌드 오류 | 낮음 | 제거 전 전체 검색으로 사용처 확인 |

## 테스트 전략

### 단위 테스트
- Provider 테스트
  - `allSelectedIngredientIdsProvider`에 misc_items 포함 여부
  - `effectiveAllIngredientIdsProvider`에 misc_items 포함 여부
- Service 테스트
  - `EffectiveMiscItemsService.toggle()` 정상 작동 확인

### 통합 테스트
- 칵테일 매칭 시나리오
  1. 상품만 선택 → 칵테일 매칭
  2. 재료만 선택 → 칵테일 매칭
  3. **기타 재료만 선택 → 칵테일 매칭** (새로운 테스트)
  4. 상품 + 재료 + 기타 재료 → 칵테일 매칭
- 로그인/로그아웃 시나리오
  1. 비회원 상태에서 기타 재료 선택 → 로그인 → 데이터 마이그레이션 확인
  2. 회원 상태에서 기타 재료 선택 → 로그아웃 → 로컬 데이터 확인

### UI 테스트
- 프로필 화면
  - 재료 설정 섹션 표시 확인
  - 설정 화면 링크 작동 확인
- 설정 화면
  - Theme/Language만 표시되는지 확인
  - About 섹션 표시 확인
- 재료 설정 페이지
  - 프로필에서 접근 가능한지 확인
  - 선택한 재료가 칵테일 화면에 반영되는지 확인

## 성공 기준

### Phase 1 (기타 재료 반영)
- [ ] 기타 재료 선택 시 `allSelectedIngredientIdsProvider`에 포함됨
- [ ] 기타 재료만 선택하여 칵테일 제작 가능
- [ ] 비회원/회원 모두 정상 작동
- [ ] 로그인/로그아웃 시 데이터 유지

### Phase 2 (동기화 버튼 제거)
- [ ] Settings 화면에 "데이터 동기화" 버튼 없음
- [ ] 로그인 시 자동 마이그레이션 정상 작동
- [ ] 빌드 오류 없음

### Phase 3 (페이지 구조 재편성)
- [ ] Settings 화면: Theme, Language, About만 표시
- [ ] Profile 화면: Account, Ingredient Settings, App Settings 링크 표시
- [ ] 중복 섹션 제거 완료
- [ ] UI/UX 일관성 유지

### Phase 4 (재료 설정 이동)
- [ ] Profile → Ingredient Settings 경로로 접근 가능
- [ ] Settings에서 Ingredient Settings 제거
- [ ] Navigation 정상 작동

### Phase 5 (초기 설정 버튼 제거)
- [ ] Settings 화면에 "초기 설정 다시하기" 버튼 없음
- [ ] `OnboardingService.resetOnboarding()` 메서드 유지
- [ ] 빌드 오류 없음

## 참고 자료

### 관련 파일
- `lib/features/settings/settings_screen.dart` - 설정 화면
- `lib/features/profile/profile_screen.dart` - 프로필 화면
- `lib/features/settings/pages/other_ingredients_settings_page.dart` - 기타 재료 설정
- `lib/features/settings/pages/unit_settings_page.dart` - 단위 설정
- `lib/data/providers/misc_item_provider.dart` - 기타 재료 Provider
- `lib/data/providers/cocktail_provider.dart` - 칵테일 매칭 Provider
- `lib/data/providers/unified_providers.dart` - 통합 Provider
- `lib/data/providers/onboarding_provider.dart` - 온보딩 및 동기화

### 데이터 흐름도
```
[사용자 선택]
    ├── Products → effectiveSelectedProductsProvider
    ├── Ingredients → effectiveSelectedIngredientsProvider
    └── Misc Items → effectiveSelectedMiscItemsProvider
                            ↓
            [통합 Provider - 수정 필요]
            effectiveAllIngredientIdsProvider
            ↓
        [칵테일 매칭]
        cocktailMatchesProvider
            ↓
        [UI 표시]
        Cocktail List with canMake status
```

### 페이지 구조 변경 요약
```
Before:
Settings: Account, Theme, Language, Ingredient Settings, Data Mgmt, About
Profile: Header, Account, Theme, Language, Settings Link, About

After:
Settings: Theme, Language, About
Profile: Header, Account, Ingredient Settings, App Settings Link
```
