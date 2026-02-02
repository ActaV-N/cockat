# Custom Cocktails 기능 개선 전략

## 개요

- **목적**: Custom Cocktails 기능의 UI 일관성, 사용성, 버그 수정
- **범위**: 이미지 처리, UI/UX 개선, 재료 선택 시스템 개선
- **예상 소요 기간**: 2-3일 (개발 2일, 테스트 1일)

## 현재 상태 분석

### 기존 구현
- ✅ 커스텀 칵테일 생성/수정/삭제 기능 작동
- ✅ Supabase Storage 연동 완료
- ✅ 이미지 업로드 성공 (URL 생성 확인됨)
- ✅ 기본 CRUD 로직 구현

### 문제점/한계

#### 1. **UI 일관성 부족** (Priority: High)
**현황**:
- `user_cocktail_detail_screen.dart`가 표준 칵테일 상세화면과 다른 구조 사용
- 표준 화면은 프리미엄 디자인 시스템 적용 (gradient overlays, blur effects, stat cards)
- 사용자 칵테일 화면은 단순한 구조로 구현됨

**영향**:
- 사용자 경험 일관성 저하
- 브랜드 아이덴티티 약화
- 프로페셔널하지 못한 인상

**근본 원인**:
- `cocktail_detail_screen.dart` 참조 없이 독립적으로 개발됨
- 디자인 시스템 가이드라인 미준수

#### 2. **이미지 종횡비 문제** (Priority: Medium)
**현황**:
- `ImagePicker` 설정: `maxWidth: 1080, maxHeight: 1080` (정사각형)
- 실제 UI는 `expandedHeight: 300` (가로 방향 우선)
- 칵테일 사진은 세로 방향이 더 적합 (글라스 전체 표시)

**영향**:
- 이미지 왜곡 및 크롭
- 칵테일의 시각적 매력 감소

**근본 원인**:
- UI 요구사항과 이미지 획득 설정 불일치
- `image_upload_service.dart` 범용 설정 사용

#### 3. **재료 선택 UX 문제** (Priority: High)
**현황**:
- 기존 재료와 커스텀 재료가 단일 텍스트 필드로 혼재
- 사용자가 DB 재료 존재 여부를 알 수 없음
- 재료 검색/자동완성 없음

**영향**:
- 데이터 일관성 저하 (중복 입력)
- 재료 연동 기능 활용 불가
- 사용자 혼란

**근본 원인**:
- `_IngredientRow` 위젯이 단순 텍스트 입력만 지원
- `ingredientsProvider` 활용하지 않음

#### 4. **단위 선택 문제** (Priority: Medium)
**현황**:
- 자유 텍스트 입력으로 단위 입력
- 표준화되지 않은 단위 (oz, ounce, oz., OZ 등)
- 단위 변환 시스템과 연동 불가

**영향**:
- 데이터 정규화 실패
- 단위 변환 기능 오작동 가능성
- 데이터 분석 어려움

**근본 원인**:
- 드롭다운 대신 텍스트 필드 사용
- 유효성 검사 부재

#### 5. **이미지 표시 버그** (Priority: Critical)
**현황**:
- 이미지 업로드 성공 (Storage URL 생성 확인)
- 리스트 뷰와 상세 뷰에서 이미지 미표시
- `CachedNetworkImage` 로딩 실패로 placeholder 표시

**증상**:
```dart
// user_cocktails_list_screen.dart:172
cocktail.imageUrl != null
  ? CachedNetworkImage(
      imageUrl: cocktail.imageUrl!,  // URL은 존재
      fit: BoxFit.cover,
      // 하지만 errorWidget로 fallback됨
    )
```

**가능한 원인**:
1. **Storage 권한 문제**: Public bucket 설정 미흡
2. **URL 형식 문제**: CORS 또는 signed URL 이슈
3. **캐시 문제**: `CachedNetworkImage` 설정 오류
4. **RLS 정책 문제**: Row Level Security 제한

**근본 원인 (가장 유력)**:
- Supabase Storage bucket이 private로 설정되어 있을 가능성
- RLS 정책으로 인한 접근 제한

#### 6. **리스트 새로고침 버그** (Priority: High)
**현황**:
- 칵테일 생성 후 `Navigator.pop(true)` 반환
- 리스트 화면 복귀 시 새 칵테일 미표시
- 앱 재시작 후 표시됨

**영향**:
- 사용자 혼란 (생성 실패로 오인)
- 재시도로 인한 중복 생성 가능성

**근본 원인**:
```dart
// user_cocktails_list_screen.dart:54-57
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const CreateUserCocktailScreen(),
    ),
  ),
  // 결과값을 받지 않고 invalidate하지 않음
),
```

- `StreamProvider`는 자동 업데이트하지만 네비게이션 후 즉시 반영 안 됨
- 명시적 `ref.invalidate` 호출 필요

### 관련 코드/모듈

**UI 레이어**:
- `/lib/features/user_cocktails/user_cocktail_detail_screen.dart` - 상세 화면
- `/lib/features/user_cocktails/create_user_cocktail_screen.dart` - 생성/수정 화면
- `/lib/features/user_cocktails/user_cocktails_list_screen.dart` - 리스트 화면

**참조 디자인**:
- `/lib/features/cocktails/cocktail_detail_screen.dart` - UI 일관성 참조

**서비스 레이어**:
- `/lib/core/services/image_upload_service.dart` - 이미지 처리
- `/lib/data/providers/user_cocktail_provider.dart` - 상태 관리
- `/lib/data/providers/ingredient_provider.dart` - 재료 데이터

**데이터 모델**:
- `/lib/data/models/user_cocktail.dart` - 데이터 구조

## 구현 전략

### 접근 방식

**우선순위 기반 단계별 개선**:
1. **Critical Bugs** (Phase 1): 이미지 표시, 리스트 새로고침
2. **UI/UX Improvements** (Phase 2): UI 일관성, 재료 선택 UX
3. **Enhancement** (Phase 3): 이미지 종횡비, 단위 선택

**원칙**:
- ✅ 기존 데이터 호환성 유지 (마이그레이션 불필요)
- ✅ 표준 칵테일 화면과 일관된 UX
- ✅ 점진적 개선 (단계별 배포 가능)
- ✅ 테스트 가능한 작은 변경 단위

### 세부 구현 단계

---

## Phase 1: Critical Bug Fixes (우선순위: Critical)

### 1.1 이미지 표시 버그 수정

#### 근본 원인 진단

**진단 절차**:
```dart
// 1. Storage bucket 공개 설정 확인
// Supabase Dashboard → Storage → user-cocktail-images → Settings
// ✅ Public bucket: true
// ✅ File size limit: 5MB
// ✅ Allowed MIME types: image/*

// 2. RLS 정책 확인
SELECT * FROM storage.objects
WHERE bucket_id = 'user-cocktail-images'
LIMIT 5;

// 3. URL 접근 테스트
// 브라우저에서 직접 URL 접근 시도
// 예: https://[project-ref].supabase.co/storage/v1/object/public/user-cocktail-images/...
```

#### ~~해결 방안 1: Storage Bucket 설정~~ ✅ 완료

> Storage bucket을 public으로 변경 완료 (Supabase Dashboard에서 수동 처리)

#### 해결 방안 2: URL 형식 수정

**현재 구현**:
```dart
// image_upload_service.dart:74-75
final publicUrl = _supabase.storage
  .from(_bucketName)
  .getPublicUrl(filePath);
```

**개선 구현**:
```dart
// 더 명확한 URL 생성
Future<String?> uploadCocktailImage(File imageFile) async {
  try {
    // ... 기존 업로드 로직 ...

    // Public bucket을 위한 URL 생성
    final publicUrl = _supabase.storage
        .from(_bucketName)
        .getPublicUrl(filePath);

    // URL 유효성 검증
    if (!publicUrl.contains(_bucketName)) {
      debugPrint('Invalid public URL: $publicUrl');
      return null;
    }

    return publicUrl;
  } catch (e) {
    debugPrint('Image upload error: $e');
    return null;
  }
}
```

#### 해결 방안 3: CachedNetworkImage 설정 개선

**현재 문제**:
- 에러 핸들링 부족
- 디버그 정보 없음

**개선 구현**:
```dart
// user_cocktails_list_screen.dart
CachedNetworkImage(
  imageUrl: cocktail.imageUrl!,
  fit: BoxFit.cover,
  placeholder: (_, __) => Container(
    color: colors.card,
    child: Center(
      child: Icon(Icons.local_bar, color: colors.textSecondary),
    ),
  ),
  errorWidget: (context, url, error) {
    // 디버그 정보 출력
    debugPrint('Failed to load image: $url');
    debugPrint('Error: $error');

    return Container(
      color: colors.card,
      child: Center(
        child: Icon(Icons.local_bar, color: colors.textSecondary),
      ),
    );
  },
  // 추가: HTTP 헤더 설정
  httpHeaders: const {
    'Cache-Control': 'max-age=86400',
  },
)
```

### 1.2 리스트 새로고침 수정

**현재 문제**:
```dart
// user_cocktails_list_screen.dart:54
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const CreateUserCocktailScreen(),
    ),
  ),
  // 결과값 미사용
),
```

**해결 방안**:
```dart
// ConsumerWidget으로 변경하여 ref 접근
class UserCocktailsListScreen extends ConsumerWidget {
  const UserCocktailsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... 기존 코드 ...

    return Scaffold(
      // ... 기존 코드 ...
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateUserCocktailScreen(),
            ),
          );

          // 칵테일 생성/수정 성공 시 provider 새로고침
          if (result == true) {
            ref.invalidate(userCocktailsProvider);
          }
        },
        backgroundColor: AppColors.coralPeach,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.createCocktail),
      ),
    );
  }
}
```

**추가 개선**: 리스트 아이템 클릭 후 복귀 시에도 새로고침
```dart
// _CocktailCard 위젯 내부
InkWell(
  onTap: () async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserCocktailDetailScreen(cocktailId: cocktail.id),
      ),
    );

    // 상세 화면에서 수정/삭제 발생 시 새로고침
    if (result == true) {
      ref.invalidate(userCocktailsProvider);
    }
  },
  // ... 기존 코드 ...
)
```

---

## Phase 2: UI/UX Improvements (우선순위: High)

### 2.0 리스트 뷰 카드 형식 변경 (신규)

#### 목표
- 기존 칵테일 리스트와 동일한 카드 형식 적용
- `cocktails_screen.dart`의 `_CocktailCard` 위젯 참조
- 그리드 레이아웃으로 변경 (2열)

#### 현재 구현
```dart
// user_cocktails_list_screen.dart (현재)
ListView.builder(
  itemBuilder: (context, index) {
    return _CocktailCard(...);  // 가로형 리스트 아이템
  },
)
```

#### 개선 구현
```dart
// user_cocktails_list_screen.dart (개선)
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,  // 세로형 카드
    crossAxisSpacing: AppTheme.spacingSm,
    mainAxisSpacing: AppTheme.spacingSm,
  ),
  itemBuilder: (context, index) {
    return _UserCocktailCard(...);  // 표준 칵테일 카드 형식
  },
)
```

#### 카드 위젯 참조
- `/lib/features/cocktails/cocktails_screen.dart`의 `_CocktailCard` 위젯 구조 참조
- 이미지 상단, 이름/설명 하단 배치
- Gradient overlay 적용
- 둥근 모서리 및 그림자 효과

---

### 2.1 UI 일관성 확보

#### 목표
- 표준 칵테일 상세화면과 동일한 프리미엄 디자인 적용
- 시각적 계층 구조 통일
- 브랜드 일관성 유지

#### 상세화면 리팩토링

**현재 구조**:
```dart
// user_cocktail_detail_screen.dart (현재)
SliverAppBar(
  expandedHeight: 300,
  // 단순한 구조
  flexibleSpace: FlexibleSpaceBar(
    background: Stack([
      CachedNetworkImage(...),
      Container(gradient: ...),  // 단순 gradient
      Text(cocktail.name),
    ]),
  ),
)
```

**개선 구조** (cocktail_detail_screen.dart 참조):
```dart
// user_cocktail_detail_screen.dart (개선)
SliverAppBar(
  expandedHeight: 420,  // 표준과 동일
  pinned: true,
  stretch: true,
  backgroundColor: colors.surface,
  surfaceTintColor: Colors.transparent,
  systemOverlayStyle: SystemUiOverlayStyle.light,

  leading: _FloatingBackButton(),  // Blur effect 적용
  actions: [
    _FloatingEditButton(onTap: ...),
    const SizedBox(width: 4),
    _FloatingDeleteButton(onTap: ...),
    const SizedBox(width: 8),
  ],

  flexibleSpace: FlexibleSpaceBar(
    collapseMode: CollapseMode.parallax,
    stretchModes: const [
      StretchMode.zoomBackground,
      StretchMode.blurBackground,
    ],
    background: Stack(
      fit: StackFit.expand,
      children: [
        // 1. Hero Image
        _buildHeroImage(cocktail, colors),

        // 2. Premium gradient overlay (5-stop gradient)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.transparent,
                colors.background.withValues(alpha: 0.8),
                colors.background,
              ],
              stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
            ),
          ),
        ),

        // 3. Title and tags at bottom
        Positioned(
          left: AppTheme.spacingMd,
          right: AppTheme.spacingMd,
          bottom: AppTheme.spacingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                cocktail.getLocalizedName(locale),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
              ),

              // Tags (optional, if implemented)
              if (cocktail.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSm),
                _buildTags(cocktail.tags, colors),
              ],
            ],
          ),
        ),
      ],
    ),
  ),
)
```

#### Floating Button 위젯 구현

**BackdropFilter 적용**:
```dart
class _FloatingBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingEditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: onTap,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingDeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingDeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
              onPressed: onTap,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Stats Row 구현

**표준 화면과 동일한 stat cards**:
```dart
Widget _buildStatsRow(
  BuildContext context,
  UserCocktail cocktail,
  AppLocalizations l10n,
  AppColorsExtension colors,
) {
  return Container(
    padding: const EdgeInsets.all(AppTheme.spacingMd),
    decoration: BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (cocktail.abv != null)
          _StatItem(
            icon: Icons.local_bar,
            value: '${cocktail.abv!.toStringAsFixed(0)}%',
            label: 'ABV',
            color: AppColors.coralPeach,
          ),
        if (cocktail.glass != null)
          _StatItem(
            icon: Icons.wine_bar,
            value: cocktail.glass!,
            label: l10n.glass,
            color: AppColors.purple,
          ),
        if (cocktail.method != null)
          _StatItem(
            icon: Icons.blender,
            value: cocktail.method!,
            label: l10n.method,
            color: AppColors.success,
          ),
      ],
    ),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}
```

#### Section Title 위젯

**일관된 섹션 헤더**:
```dart
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ],
    );
  }
}
```

#### Instructions Card 개선

**번호가 있는 단계별 레이아웃**:
```dart
class _InstructionsCard extends StatelessWidget {
  final String instructions;

  const _InstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final steps = instructions
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value.trim();
            final cleanStep = step.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < steps.length - 1 ? AppTheme.spacingMd : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 번호 badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.coralPeach,
                          AppColors.coralDeep,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        cleanStep,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
```

### 2.2 재료 선택 UX 개선

#### 목표
- 기존 재료(DB)와 커스텀 재료 명확히 분리
- 재료 검색/자동완성 제공
- 데이터 일관성 향상

#### 구현 설계

**2-섹션 레이아웃**:
```
┌─────────────────────────────────┐
│ Ingredients                      │
├─────────────────────────────────┤
│ ► Existing Ingredients           │
│   ┌───────────────────────────┐ │
│   │ 🔍 Search ingredients...  │ │
│   └───────────────────────────┘ │
│   ┌───────────────────────────┐ │
│   │ ☑ Gin           1.5  oz   │ │
│   │ ☐ Vermouth      0.5  oz   │ │
│   │ ☐ Lemon Juice   ...       │ │
│   └───────────────────────────┘ │
│                                  │
│ ► Custom Ingredients             │
│   ┌───────────────────────────┐ │
│   │ Name     Amount   Unit    │ │
│   │ [Sugar]  [1tsp]  [tsp] ❌ │ │
│   └───────────────────────────┘ │
│   [+ Add Custom]                 │
└─────────────────────────────────┘
```

#### Widget 구조

**새로운 위젯 계층**:
```dart
_buildIngredientsSection()
├── _ExistingIngredientsSection()
│   ├── SearchBar()
│   └── _ExistingIngredientCheckbox() (여러 개)
└── _CustomIngredientsSection()
    └── _CustomIngredientRow() (여러 개)
```

#### 구현 상세

**1. State 모델 재설계**:
```dart
class _CreateUserCocktailScreenState extends ConsumerState<CreateUserCocktailScreen> {
  // 기존 재료 선택 (ingredient_id 사용)
  final Map<String, _ExistingIngredientEntry> _existingIngredients = {};

  // 커스텀 재료 (custom_ingredient_name 사용)
  final List<_CustomIngredientEntry> _customIngredients = [];

  // ... 기존 코드 ...
}

class _ExistingIngredientEntry {
  final String ingredientId;
  final String ingredientName;
  String amount;
  String units;
  bool isOptional;

  _ExistingIngredientEntry({
    required this.ingredientId,
    required this.ingredientName,
    this.amount = '',
    this.units = 'oz',
    this.isOptional = false,
  });
}

class _CustomIngredientEntry {
  String customName;
  String amount;
  String units;
  bool isOptional;

  _CustomIngredientEntry({
    this.customName = '',
    this.amount = '',
    this.units = 'oz',
    this.isOptional = false,
  });
}
```

**2. 기존 재료 섹션**:
```dart
Widget _buildExistingIngredientsSection(
  AppLocalizations l10n,
  AppColorsExtension colors,
) {
  final ingredientsAsync = ref.watch(ingredientsProvider);
  final searchQuery = useState('');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 헤더
      Row(
        children: [
          Icon(Icons.database, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            l10n.existingIngredients,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.spacingSm),

      // 검색바
      TextField(
        decoration: InputDecoration(
          hintText: l10n.searchIngredients,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) => searchQuery.value = value,
      ),
      const SizedBox(height: AppTheme.spacingSm),

      // 재료 목록
      ingredientsAsync.when(
        data: (ingredients) {
          final filtered = searchQuery.value.isEmpty
              ? ingredients
              : ingredients.where((ing) =>
                  ing.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                  (ing.nameKo?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false)
                ).toList();

          return Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ingredient = filtered[index];
                final isSelected = _existingIngredients.containsKey(ingredient.id);

                return _ExistingIngredientTile(
                  ingredient: ingredient,
                  isSelected: isSelected,
                  entry: _existingIngredients[ingredient.id],
                  onToggle: () {
                    setState(() {
                      if (isSelected) {
                        _existingIngredients.remove(ingredient.id);
                      } else {
                        _existingIngredients[ingredient.id] = _ExistingIngredientEntry(
                          ingredientId: ingredient.id,
                          ingredientName: ingredient.name,
                        );
                      }
                    });
                  },
                  onUpdate: (entry) {
                    setState(() {
                      _existingIngredients[ingredient.id] = entry;
                    });
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(l10n.errorLoadingIngredients),
      ),
    ],
  );
}
```

**3. 기존 재료 타일**:
```dart
class _ExistingIngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool isSelected;
  final _ExistingIngredientEntry? entry;
  final VoidCallback onToggle;
  final ValueChanged<_ExistingIngredientEntry> onUpdate;

  const _ExistingIngredientTile({
    required this.ingredient,
    required this.isSelected,
    this.entry,
    required this.onToggle,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // 재료 선택 체크박스
        CheckboxListTile(
          value: isSelected,
          onChanged: (_) => onToggle(),
          title: Text(ingredient.name),
          subtitle: ingredient.nameKo != null ? Text(ingredient.nameKo!) : null,
          dense: true,
        ),

        // 선택된 경우 양/단위 입력
        if (isSelected && entry != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 56, // 체크박스 인덴트
              right: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                // 양
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: entry!.amount,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientAmount,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      onUpdate(_ExistingIngredientEntry(
                        ingredientId: entry!.ingredientId,
                        ingredientName: entry!.ingredientName,
                        amount: value,
                        units: entry!.units,
                        isOptional: entry!.isOptional,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 단위 드롭다운
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: entry!.units,
                    decoration: InputDecoration(
                      labelText: l10n.unit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _unitOptions.map((unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit))
                    ).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdate(_ExistingIngredientEntry(
                          ingredientId: entry!.ingredientId,
                          ingredientName: entry!.ingredientName,
                          amount: entry!.amount,
                          units: value,
                          isOptional: entry!.isOptional,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Optional 체크박스
                SizedBox(
                  width: 80,
                  child: CheckboxListTile(
                    value: entry!.isOptional,
                    onChanged: (value) {
                      if (value != null) {
                        onUpdate(_ExistingIngredientEntry(
                          ingredientId: entry!.ingredientId,
                          ingredientName: entry!.ingredientName,
                          amount: entry!.amount,
                          units: entry!.units,
                          isOptional: value,
                        ));
                      }
                    },
                    title: Text(
                      l10n.optional,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const List<String> _unitOptions = ['oz', 'ml', 'part', 'dash', 'tsp', 'tbsp'];
}
```

**4. 커스텀 재료 섹션**:
```dart
Widget _buildCustomIngredientsSection(
  AppLocalizations l10n,
  AppColorsExtension colors,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 헤더
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 20, color: AppColors.coralPeach),
              const SizedBox(width: 8),
              Text(
                l10n.customIngredients,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _customIngredients.add(_CustomIngredientEntry());
              });
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addCustom),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.spacingSm),

      // 커스텀 재료 목록
      ..._customIngredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;

        return _CustomIngredientRow(
          key: ValueKey(index),
          ingredient: ingredient,
          onRemove: () {
            setState(() {
              _customIngredients.removeAt(index);
            });
          },
          onUpdate: (updated) {
            setState(() {
              _customIngredients[index] = updated;
            });
          },
        );
      }),

      if (_customIngredients.isEmpty)
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: colors.divider, style: BorderStyle.dashed),
          ),
          child: Center(
            child: Text(
              l10n.noCustomIngredients,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
    ],
  );
}
```

**5. 커스텀 재료 행**:
```dart
class _CustomIngredientRow extends StatelessWidget {
  final _CustomIngredientEntry ingredient;
  final VoidCallback onRemove;
  final ValueChanged<_CustomIngredientEntry> onUpdate;

  const _CustomIngredientRow({
    super.key,
    required this.ingredient,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        child: Column(
          children: [
            Row(
              children: [
                // 이름
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: ingredient.customName,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.label_outline, size: 20),
                    ),
                    onChanged: (value) {
                      onUpdate(_CustomIngredientEntry(
                        customName: value,
                        amount: ingredient.amount,
                        units: ingredient.units,
                        isOptional: ingredient.isOptional,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 양
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: ingredient.amount,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientAmount,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      onUpdate(_CustomIngredientEntry(
                        customName: ingredient.customName,
                        amount: value,
                        units: ingredient.units,
                        isOptional: ingredient.isOptional,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 단위
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: ingredient.units,
                    decoration: InputDecoration(
                      labelText: l10n.unit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _unitOptions.map((unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit))
                    ).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdate(_CustomIngredientEntry(
                          customName: ingredient.customName,
                          amount: ingredient.amount,
                          units: value,
                          isOptional: ingredient.isOptional,
                        ));
                      }
                    },
                  ),
                ),

                // 삭제 버튼
                IconButton(
                  icon: Icon(Icons.remove_circle, color: colors.textSecondary),
                  onPressed: onRemove,
                ),
              ],
            ),

            // Optional 체크박스
            Row(
              children: [
                Checkbox(
                  value: ingredient.isOptional,
                  onChanged: (value) {
                    if (value != null) {
                      onUpdate(_CustomIngredientEntry(
                        customName: ingredient.customName,
                        amount: ingredient.amount,
                        units: ingredient.units,
                        isOptional: value,
                      ));
                    }
                  },
                ),
                Text(l10n.optional),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _unitOptions = ['oz', 'ml', 'part', 'dash', 'tsp', 'tbsp'];
}
```

**6. 저장 로직 수정**:
```dart
Future<void> _saveCocktail() async {
  // ... 기존 validation ...

  // 재료 데이터 통합
  final ingredients = <UserCocktailIngredient>[];
  int sortOrder = 0;

  // 1. 기존 재료 추가
  for (final entry in _existingIngredients.values) {
    ingredients.add(UserCocktailIngredient(
      userCocktailId: '', // 서비스에서 설정
      ingredientId: entry.ingredientId,
      customIngredientName: null,
      amount: double.tryParse(entry.amount),
      units: entry.units.isNotEmpty ? entry.units : null,
      sortOrder: sortOrder++,
      isOptional: entry.isOptional,
    ));
  }

  // 2. 커스텀 재료 추가
  for (final entry in _customIngredients) {
    if (entry.customName.isNotEmpty) {
      ingredients.add(UserCocktailIngredient(
        userCocktailId: '',
        ingredientId: null,
        customIngredientName: entry.customName,
        amount: double.tryParse(entry.amount),
        units: entry.units.isNotEmpty ? entry.units : null,
        sortOrder: sortOrder++,
        isOptional: entry.isOptional,
      ));
    }
  }

  // ... 기존 저장 로직 ...
}
```

**7. 기존 칵테일 편집 시 로드 로직**:
```dart
Future<void> _loadExistingIngredients() async {
  if (widget.cocktailToEdit == null) return;

  final ingredients = await ref
      .read(userCocktailIngredientsProvider(widget.cocktailToEdit!.id).future);

  setState(() {
    _existingIngredients.clear();
    _customIngredients.clear();

    for (final ing in ingredients) {
      if (ing.ingredientId != null) {
        // 기존 재료
        _existingIngredients[ing.ingredientId!] = _ExistingIngredientEntry(
          ingredientId: ing.ingredientId!,
          ingredientName: ing.ingredientId!, // 실제로는 name 필요
          amount: ing.amount?.toString() ?? '',
          units: ing.units ?? 'oz',
          isOptional: ing.isOptional,
        );
      } else if (ing.customIngredientName != null) {
        // 커스텀 재료
        _customIngredients.add(_CustomIngredientEntry(
          customName: ing.customIngredientName!,
          amount: ing.amount?.toString() ?? '',
          units: ing.units ?? 'oz',
          isOptional: ing.isOptional,
        ));
      }
    }
  });
}
```

---

## Phase 3: Enhancements (우선순위: Medium)

### 3.1 이미지 종횡비 최적화

#### 목표
- 칵테일 사진에 적합한 세로 종횡비 적용
- UI 레이아웃과 조화로운 이미지 비율

#### 구현 방안

**이미지 피커 설정 수정**:
```dart
// image_upload_service.dart

/// 갤러리에서 이미지 선택 (세로 방향 최적화)
Future<File?> pickImageFromGallery() async {
  final XFile? image = await _imagePicker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1080,
    maxHeight: 1440,  // 3:4 비율 (세로)
    imageQuality: 85,
  );
  return image != null ? File(image.path) : null;
}

/// 카메라로 이미지 촬영 (세로 방향 최적화)
Future<File?> pickImageFromCamera() async {
  final XFile? image = await _imagePicker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1080,
    maxHeight: 1440,  // 3:4 비율 (세로)
    imageQuality: 85,
    // 카메라 힌트 (iOS에서 세로 방향 선호)
    preferredCameraDevice: CameraDevice.rear,
  );
  return image != null ? File(image.path) : null;
}
```

**대안: Image Cropper 통합** (선택사항):
```yaml
# pubspec.yaml
dependencies:
  image_cropper: ^5.0.0
```

```dart
// image_upload_service.dart
import 'package:image_cropper/image_cropper.dart';

Future<File?> pickAndCropImage(ImageSource source) async {
  // 1. 이미지 선택
  final XFile? image = await _imagePicker.pickImage(source: source);
  if (image == null) return null;

  // 2. 크롭
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: image.path,
    aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Cocktail Image',
        toolbarColor: AppColors.coralPeach,
        toolbarWidgetColor: Colors.white,
        aspectRatioPresets: [
          CropAspectRatioPreset.ratio3x4,
        ],
        lockAspectRatio: true,
      ),
      IOSUiSettings(
        title: 'Crop Cocktail Image',
        aspectRatioPresets: [
          CropAspectRatioPreset.ratio3x4,
        ],
        aspectRatioLockEnabled: true,
      ),
    ],
  );

  return croppedFile != null ? File(croppedFile.path) : null;
}
```

**생성 화면 업데이트**:
```dart
// create_user_cocktail_screen.dart
Widget _buildImageSection(AppLocalizations l10n, AppColorsExtension colors) {
  return GestureDetector(
    onTap: _showImagePicker,
    child: Container(
      height: 280,  // 3:4 비율에 맞춰 높이 증가
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.divider, width: 1),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
          : _existingImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    _existingImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      l10n.addPhoto,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3:4 Portrait recommended',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ],
                ),
    ),
  );
}
```

### 3.2 단위 선택 드롭다운

**이미 Phase 2.2에서 구현됨** - 재료 섹션 개선 시 함께 적용

#### 추가 개선사항

**단위 현지화**:
```dart
// l10n/app_en.arb
{
  "unitOz": "oz",
  "unitMl": "ml",
  "unitPart": "part",
  "unitDash": "dash",
  "unitTsp": "tsp",
  "unitTbsp": "tbsp"
}

// l10n/app_ko.arb
{
  "unitOz": "온스",
  "unitMl": "밀리리터",
  "unitPart": "파트",
  "unitDash": "대시",
  "unitTsp": "티스푼",
  "unitTbsp": "테이블스푼"
}
```

**드롭다운 항목 현지화**:
```dart
class _IngredientUnitDropdown extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _IngredientUnitDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final units = {
      'oz': l10n.unitOz,
      'ml': l10n.unitMl,
      'part': l10n.unitPart,
      'dash': l10n.unitDash,
      'tsp': l10n.unitTsp,
      'tbsp': l10n.unitTbsp,
    };

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: l10n.unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: units.entries.map((entry) =>
        DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        )
      ).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
}
```

---

## 기술적 고려사항

### 아키텍처

**레이어 분리 유지**:
```
Presentation Layer (UI)
  ├── user_cocktail_detail_screen.dart
  ├── create_user_cocktail_screen.dart
  └── user_cocktails_list_screen.dart
      ↓ uses
Business Logic Layer (Providers)
  ├── user_cocktail_provider.dart
  └── ingredient_provider.dart
      ↓ uses
Service Layer
  ├── image_upload_service.dart
  └── user_cocktail_service.dart
      ↓ uses
Data Layer
  ├── models/user_cocktail.dart
  └── Supabase Storage & Database
```

### 의존성

**기존 패키지 활용**:
- ✅ `cached_network_image`: 이미지 캐싱
- ✅ `image_picker`: 이미지 선택
- ✅ `flutter_riverpod`: 상태 관리
- ✅ `supabase_flutter`: Backend

**신규 패키지 (선택사항)**:
- `image_cropper: ^5.0.0` - 이미지 크롭 기능
- `flutter_hooks: ^0.20.0` - useState 등 (재료 검색에 활용)

### API 설계

**변경 없음** - 기존 Supabase API 구조 유지:
- `user_cocktails` 테이블
- `user_cocktail_ingredients` 테이블
- `user-cocktail-images` Storage bucket

### 데이터 모델

**UserCocktail**: 변경 없음
**UserCocktailIngredient**: 변경 없음

**데이터 호환성**:
- 기존 데이터 마이그레이션 불필요
- `ingredient_id` NULL / `custom_ingredient_name` NULL 구조 유지
- `units` 필드는 자유 텍스트로 유지 (기존 데이터 호환)
- 신규 입력만 드롭다운으로 제한

---

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| **Storage 권한 문제로 이미지 미표시** | 높음 | 1. Supabase Dashboard에서 bucket public 설정 확인<br/>2. RLS 정책 검증<br/>3. 개발 환경에서 먼저 테스트 |
| **재료 검색 성능 저하 (전체 재료 로드)** | 중간 | 1. Pagination 고려 (Phase 4)<br/>2. 클라이언트 측 필터링으로 시작<br/>3. 필요 시 Supabase Full-text search 적용 |
| **UI 리팩토링 중 기존 기능 파손** | 중간 | 1. 단계별 커밋 및 테스트<br/>2. 각 단계를 독립적으로 배포 가능하게 설계<br/>3. Phase별 회귀 테스트 |
| **이미지 크롭 추가로 앱 용량 증가** | 낮음 | 1. 크롭 기능을 선택사항으로 유지<br/>2. 필요 시 lazy loading 적용 |
| **기존 데이터와 신규 UI 불일치** | 낮음 | 1. 기존 데이터 호환성 유지<br/>2. Null-safe 처리로 fallback 제공 |
| **CachedNetworkImage 캐시 문제** | 낮음 | 1. Error callback으로 디버깅<br/>2. 필요 시 캐시 클리어 기능 추가 |

---

## 테스트 전략

### 단위 테스트

**모델 테스트**:
```dart
// test/data/models/user_cocktail_test.dart
test('UserCocktailIngredient should handle both DB and custom ingredients', () {
  final dbIngredient = UserCocktailIngredient(
    userCocktailId: 'test-id',
    ingredientId: 'gin',
    customIngredientName: null,
    amount: 1.5,
    units: 'oz',
  );

  expect(dbIngredient.displayName, equals('gin'));
  expect(dbIngredient.amountWithUnits, equals('1.5 oz'));

  final customIngredient = UserCocktailIngredient(
    userCocktailId: 'test-id',
    ingredientId: null,
    customIngredientName: 'Homemade Syrup',
    amount: 0.5,
    units: 'oz',
  );

  expect(customIngredient.displayName, equals('Homemade Syrup'));
});
```

**Provider 테스트**:
```dart
// test/data/providers/user_cocktail_provider_test.dart
testWidgets('userCocktailsProvider should auto-refresh on stream update', (tester) async {
  final container = ProviderContainer();

  final cocktails = await container.read(userCocktailsProvider.future);
  expect(cocktails, isNotEmpty);

  // Stream 업데이트 테스트
  // ... Supabase mock 필요
});
```

### 통합 테스트

**이미지 업로드 플로우**:
```dart
// integration_test/user_cocktail_creation_test.dart
testWidgets('Complete cocktail creation flow with image', (tester) async {
  // 1. 생성 화면 열기
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  // 2. 이미지 선택 (mock)
  // ... image_picker mock

  // 3. 정보 입력
  await tester.enterText(find.byKey(Key('name_field')), 'Test Cocktail');
  await tester.enterText(find.byKey(Key('instructions_field')), 'Test instructions');

  // 4. 재료 추가
  // ...

  // 5. 저장
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // 6. 리스트에서 확인
  expect(find.text('Test Cocktail'), findsOneWidget);

  // 7. 상세 화면에서 이미지 확인
  await tester.tap(find.text('Test Cocktail'));
  await tester.pumpAndSettle();
  expect(find.byType(CachedNetworkImage), findsOneWidget);
});
```

**재료 검색 테스트**:
```dart
testWidgets('Ingredient search and selection', (tester) async {
  // 생성 화면 열기
  // ...

  // 검색
  await tester.enterText(find.byKey(Key('ingredient_search')), 'gin');
  await tester.pumpAndSettle();

  // 결과 확인
  expect(find.text('Gin'), findsWidgets);
  expect(find.text('Vodka'), findsNothing);

  // 선택
  await tester.tap(find.text('Gin').first);
  await tester.pumpAndSettle();

  // 양/단위 입력 필드 표시 확인
  expect(find.byKey(Key('amount_field_gin')), findsOneWidget);
});
```

### 성능 테스트

**이미지 로딩 성능**:
- 리스트 스크롤 시 프레임 드롭 측정
- `CachedNetworkImage` 캐시 히트율 확인
- 메모리 사용량 모니터링

**재료 검색 성능**:
- 500+ 재료 로드 시간 측정
- 검색 응답 시간 (<100ms 목표)
- 메모리 효율성 확인

### UI/UX 테스트

**시각적 회귀 테스트**:
- Golden test로 UI 일관성 확인
- 다크/라이트 모드 양쪽 테스트
- 다양한 화면 크기 대응

**접근성 테스트**:
- Screen reader 호환성
- 충분한 터치 타겟 크기 (최소 48x48)
- 색상 대비 비율 (WCAG AA 기준)

---

## 성공 기준

### 기능적 기준

- [ ] **Phase 1 완료**:
  - [ ] 이미지가 리스트 뷰에 정상 표시됨
  - [ ] 이미지가 상세 뷰에 정상 표시됨
  - [ ] 칵테일 생성 후 리스트 즉시 업데이트됨
  - [ ] 칵테일 수정/삭제 후 리스트 즉시 업데이트됨

- [ ] **Phase 2 완료**:
  - [ ] 리스트 뷰가 2열 그리드 카드 형식으로 변경됨
  - [ ] 카드 스타일이 표준 칵테일 리스트와 일관됨
  - [ ] 상세 화면이 표준 칵테일과 시각적으로 일관됨
  - [ ] Stats row가 정상 표시됨 (ABV, Glass, Method)
  - [ ] Section title이 일관된 스타일 적용됨
  - [ ] Instructions가 번호 있는 단계로 표시됨
  - [ ] 재료 섹션이 DB/커스텀으로 분리됨
  - [ ] 재료 검색이 정상 작동함
  - [ ] 재료 선택 및 양/단위 입력이 직관적임

- [ ] **Phase 3 완료**:
  - [ ] 이미지가 세로 방향으로 최적화됨 (3:4 비율)
  - [ ] 단위 선택이 드롭다운으로 제공됨
  - [ ] 단위가 현지화됨 (EN/KO)

### 품질 기준

- [ ] **성능**:
  - [ ] 리스트 스크롤 60fps 유지
  - [ ] 이미지 로드 시간 <2초 (3G 환경)
  - [ ] 재료 검색 응답 <100ms

- [ ] **안정성**:
  - [ ] 이미지 업로드 성공률 >95%
  - [ ] 에러 발생 시 사용자 친화적 메시지 표시
  - [ ] 네트워크 오류 시 graceful degradation

- [ ] **접근성**:
  - [ ] Screen reader 호환
  - [ ] 충분한 터치 타겟 크기
  - [ ] 색상 대비 비율 WCAG AA 충족

- [ ] **데이터 무결성**:
  - [ ] 기존 데이터 100% 호환
  - [ ] 데이터 손실 0건
  - [ ] 중복 생성 방지

### 사용자 경험 기준

- [ ] 칵테일 생성 플로우가 직관적임 (사용자 테스트)
- [ ] 재료 선택이 혼란스럽지 않음
- [ ] 이미지 품질이 만족스러움
- [ ] 전체 앱과 일관된 디자인 느낌

---

## 참고 자료

### 코드 참조

**UI 디자인 참조**:
- `/lib/features/cocktails/cocktail_detail_screen.dart` - 프리미엄 디자인 시스템
- `/lib/core/theme/app_theme.dart` - 디자인 토큰
- `/lib/core/theme/app_colors.dart` - 컬러 팔레트

**유사 기능 참조**:
- `/lib/features/ingredients/ingredient_selection_screen.dart` - 재료 검색 UI
- `/lib/features/products/product_selection_screen.dart` - 선택 UX

### 문서 참조

**Supabase 문서**:
- [Storage Documentation](https://supabase.com/docs/guides/storage)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Subscriptions](https://supabase.com/docs/guides/realtime)

**Flutter 패키지**:
- [cached_network_image](https://pub.dev/packages/cached_network_image)
- [image_picker](https://pub.dev/packages/image_picker)
- [image_cropper](https://pub.dev/packages/image_cropper)

**디자인 시스템**:
- Material Design 3 Guidelines
- 프로젝트 내부 디자인 가이드 (`docs/design-system.md` 있으면)

---

## 구현 순서 요약

```
Phase 1: Critical Bugs (1일)
├── 1.1 이미지 표시 수정
│   ├── ~~Storage bucket 설정~~ ✅ 완료
│   ├── URL 형식 개선
│   └── CachedNetworkImage 에러 핸들링
└── 1.2 리스트 새로고침 수정
    ├── Navigation result 처리
    └── Provider invalidation

Phase 2: UI/UX Improvements (1일)
├── 2.0 리스트 뷰 카드 형식 변경 (신규)
│   ├── GridView 2열 레이아웃
│   ├── 표준 칵테일 카드 스타일 적용
│   └── cocktails_screen.dart 참조
├── 2.1 UI 일관성 확보
│   ├── SliverAppBar 리팩토링
│   ├── Floating buttons (blur effect)
│   ├── Stats row 구현
│   ├── Section titles 통일
│   └── Instructions card 개선
└── 2.2 재료 선택 UX 개선
    ├── State 모델 재설계
    ├── 기존 재료 섹션 (검색 포함)
    ├── 커스텀 재료 섹션
    ├── 저장 로직 수정
    └── 편집 모드 로드 로직

Phase 3: Enhancements (0.5일)
├── 3.1 이미지 종횡비 최적화
│   └── ImagePicker 설정 변경
└── 3.2 단위 현지화
    └── l10n 파일 업데이트

Testing & Polish (0.5일)
├── 통합 테스트
├── 성능 측정
└── 버그 수정
```

**총 예상 소요 기간**: 3일 (개발 2.5일, 테스트 0.5일)

---

## 배포 전략

### 단계별 배포

**Option 1: Big Bang Deployment**
- 모든 Phase를 완료 후 한 번에 배포
- 장점: 일관된 경험, 단순한 릴리스 노트
- 단점: 위험도 높음, 롤백 시 큰 영향

**Option 2: Phased Rollout (권장)**
- Phase 1 → 배포 → 모니터링
- Phase 2 → 배포 → 모니터링
- Phase 3 → 배포 → 모니터링
- 장점: 위험 분산, 점진적 개선
- 단점: 여러 릴리스 필요

### 롤백 계획

**Phase 1 롤백**:
- Storage 설정 원복
- 이전 버전 재배포

**Phase 2/3 롤백**:
- UI 변경이므로 데이터 손실 없음
- 이전 버전 재배포만으로 가능

### 모니터링

**핵심 메트릭**:
- 이미지 로드 성공률
- 칵테일 생성 완료율
- 앱 크래시율
- 사용자 피드백 (앱 스토어 리뷰)

**알림 설정**:
- 이미지 로드 실패율 >5% → 즉시 알림
- 칵테일 생성 실패율 >10% → 즉시 알림
- 앱 크래시 증가 >20% → 긴급 알림

---

## 다음 단계 (Future Enhancements)

### Phase 4: 고급 기능 (v2.0)

- [ ] **공개 칵테일 갤러리**: `is_public=true` 칵테일 공유
- [ ] **칵테일 포크**: 다른 사용자 칵테일 복제 및 수정
- [ ] **평가 및 댓글**: 커뮤니티 피드백
- [ ] **재료 추천**: AI 기반 재료 조합 제안
- [ ] **영양 정보**: 칼로리, 당분 등 표시
- [ ] **칵테일 컬렉션**: 테마별 그룹화

### 기술 부채 해결

- [ ] **이미지 최적화**: WebP 포맷 변환, Progressive loading
- [ ] **오프라인 지원**: 로컬 캐싱 및 동기화
- [ ] **성능 개선**: List virtualization, Lazy loading
- [ ] **접근성 강화**: VoiceOver 최적화, 고대비 모드

---

## 결론

본 전략은 Custom Cocktails 기능의 핵심 문제를 단계별로 해결하며, 사용자 경험과 코드 품질을 모두 개선하는 것을 목표로 합니다.

**핵심 원칙**:
1. ✅ 데이터 무결성 최우선 (기존 데이터 호환)
2. ✅ 단계적 개선 (위험 최소화)
3. ✅ 표준 준수 (일관된 UX)
4. ✅ 테스트 가능성 (품질 보증)

**예상 효과**:
- 이미지 표시 문제 해결로 사용자 만족도 ↑
- 일관된 UI로 브랜드 가치 ↑
- 직관적인 재료 선택으로 생성 완료율 ↑
- 데이터 품질 향상으로 향후 기능 확장성 ↑

이 문서를 기반으로 구현을 진행하시면, 안정적이고 확장 가능한 Custom Cocktails 기능을 완성할 수 있습니다.
