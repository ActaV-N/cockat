# Available Ingredient Product 네비게이션 구현 전략

## 개요
- **목적**: 칵테일 상세 화면의 소유 재료 아코디언에서 상품 클릭 시 상품 상세 페이지로 이동 기능 추가
- **범위**: IngredientAvailabilityCard 위젯 수정, ProductDetailScreen 재사용
- **예상 소요 기간**: 1-2시간

## 현재 상태 분석

### 기존 구현
**파일**: `lib/features/cocktails/widgets/ingredient_availability_card.dart`

**현재 UI 구조**:
```
ExpansionTile (재료)
└── 확장된 영역
    ├── 직접 소유 제품 섹션
    │   └── _buildProductItem (각 상품) - onTap 없음
    └── 대체재 섹션
        └── _buildSubstituteItem (각 대체재)
            └── 소유한 대체재 제품들 - onTap 없음
```

**현재 코드** (`ingredient_availability_card.dart:187-206`):
```dart
Widget _buildProductItem(BuildContext context, Product product) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          Icons.liquor,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            product.displayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
```

### 문제점/한계

#### 1. 상호작용 부재
- 상품 목록이 단순 텍스트로만 표시됨
- 클릭해도 아무 반응이 없어 사용자 혼란 초래
- 상품 상세 정보 확인 불가

#### 2. 일관성 결여
- Task 2에서 구현할 내 술장의 상품 클릭 동작과 일관성 필요
- 앱 전체에서 상품 항목은 클릭 가능해야 함

#### 3. UX 개선 기회
- 시각적 피드백 (InkWell ripple 효과) 부재
- 클릭 가능함을 나타내는 UI 힌트 없음

## 구현 전략

### 접근 방식
**핵심 변경**:
1. **InkWell 추가**: 상품 항목을 클릭 가능하게 만들기
2. **네비게이션 추가**: ProductDetailScreen으로 이동
3. **시각적 개선**: trailing 아이콘 추가, hover/tap 피드백 강화
4. **대체재 상품도 동일 적용**: 일관성 있는 UX 제공

### 세부 구현 단계

#### 1. _buildProductItem 메서드 수정

**파일**: `lib/features/cocktails/widgets/ingredient_availability_card.dart`

**현재 코드** (line 187-206):
```dart
Widget _buildProductItem(BuildContext context, Product product) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          Icons.liquor,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            product.displayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
```

**수정 후**:
```dart
Widget _buildProductItem(BuildContext context, Product product) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.liquor,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

**변경 사항**:
- `Material` + `InkWell` 추가: 클릭 가능하게 만들고 ripple 효과 제공
- `onTap` 핸들러: ProductDetailScreen으로 네비게이션
- `borderRadius`: InkWell에 둥근 모서리 효과
- `Padding` 조정: 클릭 영역 확대
- `trailing Icon` 추가: 클릭 가능함을 시각적으로 표시

#### 2. _buildSubstituteItem 메서드 수정

**파일**: `lib/features/cocktails/widgets/ingredient_availability_card.dart`

**현재 코드** (line 209-260):
```dart
Widget _buildSubstituteItem(BuildContext context, SubstituteInfo substitute) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.swap_horiz,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                substitute.substituteName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        if (substitute.ownedProducts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: substitute.ownedProducts
                  .map(
                    (product) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${product.displayName}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    ),
  );
}
```

**수정 후**:
```dart
Widget _buildSubstituteItem(BuildContext context, SubstituteInfo substitute) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 대체재 이름 (클릭 불가)
        Row(
          children: [
            const Icon(
              Icons.swap_horiz,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                substitute.substituteName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),

        // 소유한 대체재 제품들 (클릭 가능)
        if (substitute.ownedProducts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: substitute.ownedProducts
                  .map(
                    (product) => _buildSubstituteProductItem(context, product),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    ),
  );
}

/// 대체재 제품 항목 (클릭 가능)
Widget _buildSubstituteProductItem(BuildContext context, Product product) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '• ${product.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.warning.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

**변경 사항**:
- `_buildSubstituteProductItem` 메서드 신규 추가
- 대체재 상품도 클릭 가능하게 변경
- 동일한 InkWell 패턴 적용
- chevron 아이콘 추가
- warning 색상 유지 (일관성)

#### 3. Import 추가

**파일**: `lib/features/cocktails/widgets/ingredient_availability_card.dart`

**추가 필요**:
```dart
import '../../products/product_detail_screen.dart';
```

**현재 import 확인** (line 1-7):
```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/onboarding_provider.dart';
import '../../../l10n/app_localizations.dart';
```

**추가 후**:
```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/onboarding_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/product_detail_screen.dart';
```

### 기술적 고려사항

#### 1. 네비게이션
- **라우팅**: `Navigator.push`를 사용하여 새 화면으로 이동
- **화면 스택**: 칵테일 상세 → 상품 상세 (2단계 깊이)
- **뒤로 가기**: 상품 상세에서 뒤로 가면 칵테일 상세로 복귀

#### 2. 상태 관리
- ProductDetailScreen에서 상품 제거 시 칵테일 상세 화면 자동 업데이트
- Riverpod의 reactive provider가 자동으로 UI 갱신
- 상품 제거 후 화면 닫힘 시 칵테일 상세도 재평가됨

#### 3. UX
- **시각적 피드백**: InkWell의 ripple 효과
- **명확한 힌트**: chevron 아이콘으로 클릭 가능 표시
- **일관성**: 앱 전체에서 동일한 패턴 사용

#### 4. 접근성
- InkWell은 기본적으로 접근성 지원
- 스크린 리더 사용자도 탭 가능 항목으로 인식
- semanticLabel 추가 고려 (선택사항)

#### 5. 성능
- Navigator.push는 경량 작업
- ProductDetailScreen은 별도 라우트로 독립적
- 메모리 영향 미미

### 디자인 일관성

**앱 전체 상품 클릭 패턴**:
1. **내 술장** (Task 2): ListTile + chevron_right
2. **상품 카탈로그**: 기존 패턴 확인 필요
3. **칵테일 상세** (현재): InkWell + chevron_right

**통일된 디자인 언어**:
- 모든 상품 항목에 chevron_right 아이콘
- InkWell을 통한 Material ripple 효과
- 클릭 시 ProductDetailScreen으로 이동

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| ProductDetailScreen 미구현 상태 | 높음 | Task 2와 병행 또는 순차 진행, 임시 화면 사용 가능 |
| 네비게이션 스택 깊이 증가 | 낮음 | 2단계는 적절한 깊이, 사용자 혼란 없음 |
| InkWell 영역이 작아서 클릭 어려움 | 낮음 | Padding으로 클릭 영역 확대, 최소 48px 높이 권장 |
| 색상 일관성 문제 (대체재 warning 색상) | 낮음 | 현재 warning 색상 유지, chevron만 투명도 조정 |
| import 경로 오류 | 낮음 | 상대 경로 정확히 확인, IDE 자동완성 활용 |

## 테스트 전략

### 단위 테스트
필요 없음 (UI 변경 위주)

### 통합 테스트

**시나리오 1**: 직접 소유 제품 클릭
1. 칵테일 선택하여 상세 화면 진입
2. 소유한 재료 아코디언 확장
3. "내 술장 제품" 섹션의 상품 클릭
4. ProductDetailScreen 진입 확인
5. 상품 정보 표시 확인
6. 뒤로 가기 시 칵테일 상세로 복귀

**시나리오 2**: 대체재 제품 클릭
1. 칵테일 선택하여 상세 화면 진입
2. 대체재가 있는 재료 아코디언 확장
3. "대체 가능 재료" 섹션의 상품 클릭
4. ProductDetailScreen 진입 확인
5. 대체재 상품 정보 표시 확인

**시나리오 3**: 상품 제거 후 복귀
1. 칵테일 상세 → 상품 상세 이동
2. 상세 화면에서 "내 술장에서 제거" 클릭
3. 확인 후 제거
4. 화면 자동 닫힘 확인
5. 칵테일 상세 화면에서 재료 상태 업데이트 확인

**시나리오 4**: 시각적 피드백
1. 상품 항목 탭 시 ripple 효과 확인
2. chevron 아이콘 표시 확인
3. hover 상태 확인 (데스크톱)

## 성공 기준
- [ ] 소유 재료 섹션의 모든 상품이 클릭 가능
- [ ] 대체재 섹션의 모든 상품이 클릭 가능
- [ ] 클릭 시 ProductDetailScreen으로 정상 이동
- [ ] chevron 아이콘이 모든 상품 항목에 표시됨
- [ ] InkWell ripple 효과가 작동함
- [ ] 뒤로 가기 시 칵테일 상세로 복귀
- [ ] 상품 제거 후 칵테일 상세 화면 자동 갱신

## 참고 자료
- [Material InkWell](https://api.flutter.dev/flutter/material/InkWell-class.html)
- [Navigator Push/Pop](https://api.flutter.dev/flutter/widgets/Navigator-class.html)
- [Material Design: Clickable Items](https://m3.material.io/components/lists/guidelines)

## 구현 순서

**권장 순서** (Task 2와의 의존성 고려):
1. Task 2 먼저 구현 (ProductDetailScreen 생성)
2. Task 3 구현 (네비게이션 추가)

**대안** (병행 진행):
- Task 3 먼저 구현하되, ProductDetailScreen placeholder 사용
- Task 2 완료 후 실제 화면으로 교체

**최소 구현** (MVP):
- InkWell + onTap만 추가
- 임시 Scaffold 화면으로 이동
- 나중에 ProductDetailScreen으로 교체
