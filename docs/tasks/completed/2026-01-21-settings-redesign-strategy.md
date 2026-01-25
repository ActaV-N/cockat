# 설정 페이지 재설계 및 구현 전략

## 개요

- **목적**: 사용자 설정 경험 개선 및 신규 설정 기능 추가
- **범위**: 프로필 페이지 개선, 기타 재료 설정 페이지, 단위 설정 페이지 구현 및 전체 설정 구조 재설계
- **예상 소요 기간**: 3-4일

## 현재 상태 분석

### 기존 구현

#### 1. 프로필 페이지 (`lib/features/profile/profile_screen.dart`)
- **위치**: 홈 화면 네비게이션 바 4번째 탭
- **현재 기능**:
  - 사용자 정보 표시 (게스트/로그인 사용자)
  - 회원가입/로그인 버튼 (비로그인 시)
  - 계정 관리 (로그아웃, 동기화)
  - 테마 설정 (시스템/라이트/다크 모드)
  - 언어 설정 (시스템/영어/한국어)
  - **"다시 설정하기" 버튼** (온보딩 재시작)
  - 앱 정보 (버전, 데이터 출처)

#### 2. 설정 페이지 (`lib/features/settings/settings_screen.dart`)
- **상태**: 현재 사용되지 않음 (홈 화면에서 직접 접근 불가)
- **기능**: 프로필 페이지와 거의 동일한 내용 중복
- **문제점**: 프로필과 설정이 분리되어 있으나 역할이 불명확

#### 3. 온보딩 페이지 구조
- **제품 선택** (`pages/products_page.dart`): 보유 술 선택
- **기타 재료 선택** (`pages/misc_items_page.dart`): 얼음, 신선 재료, 데어리, 가니시, 믹서, 시럽, 비터 선택
- **단위 설정** (`pages/preferences_page.dart`): ml/oz/parts 선택
- **회원 가입/로그인** (`pages/auth_page.dart`): 선택적 인증

### 문제점/한계

1. **프로필 페이지 문제**:
   - "다시 설정하기" 버튼이 프로필 페이지에 위치해 있어 사용자 혼란 야기
   - 온보딩 재시작은 설정 페이지에 더 적합한 기능
   - 설정과 프로필 정보가 혼재

2. **설정 구조 문제**:
   - 설정 페이지가 존재하지만 사용되지 않음
   - 기타 재료 관리 UI가 온보딩에만 존재 (설정에서 수정 불가)
   - 단위 설정도 온보딩에만 존재 (변경 시 온보딩 재시작 필요)

3. **UX 문제**:
   - 초기 설정 후 기타 재료 변경 방법 없음
   - 단위 설정 변경을 위해 전체 온보딩 재시작 필요
   - 설정 관련 기능이 여러 곳에 분산

### 관련 코드/모듈

#### 데이터 모델
- `lib/data/models/misc_item.dart`: 기타 재료 모델
- `lib/data/providers/onboarding_provider.dart`: 온보딩 및 단위 설정 provider
- `lib/data/providers/misc_item_provider.dart`: 기타 재료 provider
- `lib/data/providers/settings_provider.dart`: 테마/언어 설정 provider

#### 데이터베이스
- `user_preferences` 테이블: 온보딩 완료 여부, 단위 설정 저장
- `user_misc_items` 테이블: 필요 (현재 미구현 추정)
- `misc_items` 테이블: 기본 기타 재료 데이터

## 구현 전략

### 접근 방식

**단계적 개선 전략**을 채택하여 기존 코드를 최대한 재활용하면서 새로운 설정 페이지 구조를 구축합니다.

1. **설정 페이지 활성화**: 프로필에서 설정으로 이동 가능한 버튼 추가
2. **기능 분리**: 프로필(사용자 정보) vs 설정(앱 설정) 명확히 구분
3. **재사용**: 온보딩 페이지 컴포넌트를 설정 페이지에서 재사용
4. **데이터베이스 확장**: 기타 재료 저장 테이블 추가 (필요시)

### 세부 구현 단계

#### Phase 1: 프로필 페이지 개선

**1.1 "다시 설정하기" 버튼 제거**
- `lib/features/profile/profile_screen.dart` 수정
- 209-247 라인의 "Setup Section" 제거
- 설정 페이지로 이동하는 버튼 추가

**1.2 설정 페이지 접근 버튼 추가**
```dart
ListTile(
  leading: const Icon(Icons.settings),
  title: Text(l10n.settings),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  },
)
```

#### Phase 2: 설정 페이지 재설계

**2.1 설정 페이지 구조 재설계**

새로운 설정 페이지 구조:
```
Settings Screen
├── General (일반)
│   ├── Theme (테마)
│   └── Language (언어)
├── Ingredients (재료 설정)
│   ├── Other Ingredients (기타 재료) → 새 페이지
│   └── Unit System (단위 설정) → 새 페이지
├── Data (데이터)
│   ├── Reset Setup (다시 설정하기)
│   └── Sync Data (동기화)
└── About (정보)
    ├── Version
    └── Data Source
```

**2.2 설정 페이지 코드 수정**
- `lib/features/settings/settings_screen.dart` 전체 재작성
- 섹션별로 구조화된 ListTile 그룹 생성
- 각 설정 항목에서 세부 페이지로 네비게이션

#### Phase 3: 기타 재료 설정 페이지 구현

**3.1 설정용 기타 재료 페이지 생성**
- 파일: `lib/features/settings/pages/other_ingredients_settings_page.dart`
- 온보딩의 `misc_items_page.dart` 로직 재사용
- 차이점:
  - AppBar 추가 (온보딩은 PageView 안에서 사용)
  - "다음" 버튼 대신 변경사항 자동 저장
  - 뒤로가기 지원

**3.2 컴포넌트 분리 전략**

공통 위젯 추출:
```
lib/features/settings/widgets/
├── misc_item_category_filter.dart  // 카테고리 필터 칩
├── misc_item_grid.dart             // 아이템 선택 그리드
└── misc_item_counter.dart          // 선택 개수 표시
```

온보딩과 설정에서 동일한 위젯 재사용:
```dart
// 온보딩
OnboardingMiscItemsPage extends StatelessWidget {
  Widget build(context) => MiscItemsContent(
    showBottomBar: true,
    onComplete: onNext,
  );
}

// 설정
OtherIngredientsSettingsPage extends StatelessWidget {
  Widget build(context) => Scaffold(
    appBar: AppBar(title: Text('Other Ingredients')),
    body: MiscItemsContent(
      showBottomBar: false,
    ),
  );
}
```

#### Phase 4: 단위 설정 페이지 구현

**4.1 설정용 단위 페이지 생성**
- 파일: `lib/features/settings/pages/unit_settings_page.dart`
- 온보딩의 `preferences_page.dart` UI 재사용
- 단순화된 버전 (단위 선택만)

**4.2 단위 변경 즉시 반영**
- UnitSystem 변경 시 `onboardingServiceProvider` 통해 저장
- 모든 칵테일 레시피 표시에 즉시 반영
- 변경 완료 스낵바 표시

#### Phase 5: 데이터베이스 및 Provider 확장

**5.1 기타 재료 저장 구조 확인 및 보완**

현재 `onboarding_provider.dart`의 `migrateLocalToDb()` 함수에서:
```dart
// Migrate selected misc items
final localMiscItems = _ref.read(selectedMiscItemsLocalProvider);
if (localMiscItems.isNotEmpty) {
  final miscItemRows = localMiscItems
      .map((id) => {'user_id': userId, 'misc_item_id': id})
      .toList();
  await supabase.from('user_misc_items').upsert(miscItemRows);
}
```

→ `user_misc_items` 테이블이 필요하나 `002_user_tables.sql`에 없음
→ 마이그레이션 추가 필요

**5.2 마이그레이션 생성**
```sql
-- supabase/migrations/003_user_misc_items.sql
CREATE TABLE IF NOT EXISTS user_misc_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  misc_item_id TEXT NOT NULL REFERENCES misc_items(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, misc_item_id)
);

ALTER TABLE user_misc_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own misc items" ON user_misc_items
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_misc_items_user ON user_misc_items(user_id);
```

**5.3 Provider 동기화 확인**
- `misc_item_provider.dart`에서 DB/로컬 전환 로직 검증
- 설정 페이지에서 변경 시 즉시 DB 업데이트 확인

#### Phase 6: 다국어 지원

**6.1 필요한 번역 키 추가**

`lib/l10n/app_en.arb`:
```json
{
  "otherIngredients": "Other Ingredients",
  "otherIngredientsDescription": "Manage ice, garnishes, mixers, and more",
  "unitSettings": "Unit System",
  "unitSettingsDescription": "Choose measurement units for recipes",
  "resetSetup": "Reset Setup",
  "resetSetupDescription": "Re-run initial setup wizard",
  "resetSetupConfirm": "This will restart the setup process. Continue?",
  "dataManagement": "Data Management",
  "general": "General",
  "ingredientSettings": "Ingredient Settings",
  "unitChanged": "Unit system changed to {unit}",
  "ice": "Ice",
  "fresh": "Fresh Ingredients",
  "dairy": "Dairy & Eggs",
  "mixer": "Mixers",
  "syrup": "Syrups",
  "itemsSelected": "{count} items selected"
}
```

`lib/l10n/app_ko.arb`:
```json
{
  "otherIngredients": "기타 재료",
  "otherIngredientsDescription": "얼음, 가니시, 믹서 등 관리",
  "unitSettings": "단위 설정",
  "unitSettingsDescription": "레시피 측정 단위 선택",
  "resetSetup": "다시 설정하기",
  "resetSetupDescription": "초기 설정 마법사 재실행",
  "resetSetupConfirm": "초기 설정을 다시 시작합니다. 계속하시겠습니까?",
  "dataManagement": "데이터 관리",
  "general": "일반",
  "ingredientSettings": "재료 설정",
  "unitChanged": "단위가 {unit}로 변경되었습니다",
  "ice": "얼음",
  "fresh": "신선 재료",
  "dairy": "유제품 및 달걀",
  "mixer": "믹서",
  "syrup": "시럽",
  "itemsSelected": "{count}개 선택됨"
}
```

### 기술적 고려사항

#### 아키텍처

**계층 구조**:
```
UI Layer (Screens)
  ├── ProfileScreen (사용자 정보)
  ├── SettingsScreen (앱 설정 허브)
  └── Settings Pages
      ├── OtherIngredientsSettingsPage
      └── UnitSettingsPage

Widget Layer (재사용 가능 컴포넌트)
  └── settings/widgets/
      ├── misc_item_category_filter.dart
      ├── misc_item_grid.dart
      └── setting_section_header.dart

Provider Layer (상태 관리)
  ├── onboarding_provider (UnitSystem, 온보딩 완료)
  ├── misc_item_provider (기타 재료 선택)
  └── settings_provider (테마, 언어)

Data Layer (Supabase)
  ├── user_preferences (단위, 온보딩 완료)
  └── user_misc_items (선택된 기타 재료)
```

#### 의존성

기존 패키지 사용:
- `flutter_riverpod`: 상태 관리
- `shared_preferences`: 로컬 설정 저장
- `supabase_flutter`: DB 연동

추가 필요 없음.

#### API 설계

**설정 변경 흐름**:
```
1. User taps setting option
2. Navigate to detail page
3. User changes value
4. Provider updates:
   - If authenticated: Update DB via onboardingService
   - If not authenticated: Update SharedPreferences
5. Show confirmation snackbar
6. Auto-refresh UI via Riverpod watch
```

**데이터 동기화 흐름**:
```
Login/Signup
  → migrateLocalToDb() (로컬 → DB)
  → syncDbToLocal() (DB → 로컬, 오프라인 대비)

Setting Change
  → If authenticated: updateDbPreferences()
  → If not: update local notifier
  → invalidate providers → UI refresh
```

#### 데이터 모델

기존 모델 유지:
- `UnitSystem` enum: ml, oz, parts
- `MiscItem` model: id, name, nameKo, category
- `MiscItemCategories`: 카테고리 정의

추가 확장 불필요.

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| `user_misc_items` 테이블 미존재 | 높음 | 마이그레이션 우선 실행 및 테스트 |
| 온보딩 페이지 변경 시 설정 페이지 영향 | 중간 | 공통 위젯 추출로 독립성 확보 |
| 단위 변경 시 전체 UI 리렌더링 성능 | 중간 | Provider invalidation 최소화, 필요한 위젯만 rebuild |
| 로그인/비로그인 상태 전환 시 데이터 동기화 | 높음 | 철저한 migration/sync 테스트, 에러 핸들링 |
| 번역 누락 | 낮음 | 모든 문자열 하드코딩 금지, l10n 의무화 |

## 테스트 전략

### 단위 테스트
- `OnboardingService.setUnitSystem()` 테스트
- DB/로컬 전환 로직 테스트
- Migration/Sync 로직 테스트

### 통합 테스트
1. **기타 재료 설정 플로우**:
   - 비로그인 상태: 로컬 저장 → SharedPreferences 확인
   - 로그인 상태: DB 저장 → Supabase 쿼리 확인
   - 로그인 후: 로컬 → DB 마이그레이션 확인

2. **단위 설정 플로우**:
   - 단위 변경 → 칵테일 상세 페이지에서 레시피 단위 확인
   - ml → oz → parts 순차 변경 및 UI 반영 확인

3. **온보딩 재시작 플로우**:
   - 설정 → 다시 설정하기 → 확인 다이얼로그 → 온보딩 화면 이동
   - 온보딩 완료 → 홈 화면 복귀 확인

### 사용자 시나리오 테스트

**시나리오 1: 비로그인 사용자 설정 변경**
1. 앱 시작 (비로그인)
2. 온보딩에서 ml 선택, 기타 재료 몇 개 선택
3. 프로필 → 설정 이동
4. 단위 설정 → oz 변경
5. 기타 재료 설정 → 추가 항목 선택
6. 칵테일 레시피에서 oz 단위 확인
7. My Bar에서 기타 재료 반영 확인

**시나리오 2: 로그인 후 설정 동기화**
1. 비로그인 상태에서 ml, 기타 재료 10개 선택
2. 회원가입
3. DB에 데이터 저장 확인 (Supabase 대시보드)
4. 다른 기기에서 로그인
5. 설정 동기화 확인

**시나리오 3: 온보딩 재시작**
1. 로그인 사용자
2. 설정 → 다시 설정하기
3. 확인 다이얼로그
4. 온보딩 첫 페이지 표시
5. 새로운 설정 선택
6. 완료 후 홈 화면 복귀
7. 새 설정 반영 확인

## 성공 기준

- [x] 프로필 페이지에서 "다시 설정하기" 버튼 제거됨
- [ ] 프로필 페이지에서 설정 페이지로 이동 가능
- [ ] 설정 페이지가 명확한 섹션 구조를 가짐
- [ ] 기타 재료 설정 페이지가 정상 작동 (추가/제거)
- [ ] 단위 설정 페이지가 정상 작동 (ml/oz/parts 변경)
- [ ] 단위 변경 시 모든 레시피 표시가 즉시 업데이트됨
- [ ] 비로그인 상태에서 설정이 로컬에 저장됨
- [ ] 로그인 상태에서 설정이 DB에 저장됨
- [ ] 로그인 시 로컬 설정이 DB로 마이그레이션됨
- [ ] 모든 UI 텍스트가 영어/한국어 번역됨
- [ ] 온보딩과 설정 페이지 간 코드 중복 최소화
- [ ] "다시 설정하기"가 설정 페이지에서만 접근 가능
- [ ] 모든 테스트 시나리오 통과

## 참고 자료

### Flutter 패턴
- [Flutter Navigation 2.0](https://docs.flutter.dev/development/ui/navigation)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/reading)
- [Material 3 Settings Pattern](https://m3.material.io/components/lists/guidelines)

### 프로젝트 관련
- 기존 온보딩 구현: `lib/features/onboarding/`
- Provider 패턴: `lib/data/providers/`
- 다국어 지원: `lib/l10n/`

### Supabase 관련
- [Supabase Flutter Client](https://supabase.com/docs/reference/dart/introduction)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Real-time Subscriptions](https://supabase.com/docs/guides/realtime)

### 디자인 참고
- Material Design 3 Settings: https://m3.material.io/
- iOS Settings Pattern: https://developer.apple.com/design/human-interface-guidelines/settings
- Best Settings UX: https://www.nngroup.com/articles/settings-design/

## 구현 순서 요약

1. **Phase 1**: 프로필 페이지 수정 (0.5일)
   - "다시 설정하기" 제거
   - 설정 페이지 이동 버튼 추가

2. **Phase 2**: 설정 페이지 재설계 (1일)
   - 새로운 섹션 구조 생성
   - 네비게이션 설정

3. **Phase 3**: 기타 재료 설정 페이지 (1일)
   - 공통 위젯 추출
   - 설정 전용 페이지 생성

4. **Phase 4**: 단위 설정 페이지 (0.5일)
   - 설정 전용 페이지 생성
   - 즉시 반영 로직

5. **Phase 5**: DB 마이그레이션 및 Provider (0.5일)
   - `user_misc_items` 테이블 생성
   - 동기화 로직 검증

6. **Phase 6**: 다국어 및 테스트 (0.5일)
   - 번역 추가
   - 통합 테스트 실행

**총 예상 기간**: 4일
