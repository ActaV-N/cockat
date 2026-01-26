# 검색바 및 Radio Button UI 개선 전략

## 개요
- **목적**: 검색 화면 검색바 텍스트 정렬 문제 해결 및 상품 탭 선택 표시 디자인 개선
- **범위**:
  1. Cocktail 검색 화면의 검색바 텍스트 정렬 문제 수정
  2. 상품(Product) 카드의 선택 표시(AnimatedSelectionIndicator) 디자인 개선
- **예상 소요 기간**: 1-2일

## 현재 상태 분석

### 1. 검색바 구현 현황

#### 공통 컴포넌트: `SearchBarField` (lib/core/widgets/search_bar_field.dart)
- **위치**: `/Users/actav/Documents/cockat/lib/core/widgets/search_bar_field.dart`
- **사용처**: `products_screen.dart` (상품 탭)
- **구현 방식**:
  - Flutter의 표준 `TextField` 위젯 사용
  - Riverpod 상태 관리와 통합
  - `contentPadding` 미지정 (기본값 사용)

#### Cocktail 검색 화면: `CocktailSearchScreen` (lib/features/cocktails/cocktail_search_screen.dart)
- **위치**: `/Users/actav/Documents/cockat/lib/features/cocktails/cocktail_search_screen.dart`
- **구현 방식**:
  - AppBar의 `title` 속성에 직접 `TextField` 배치
  - `contentPadding: EdgeInsets.symmetric(horizontal: 16)` 설정
  - `border: InputBorder.none` 사용
- **문제점**:
  - AppBar 내부에 TextField를 배치하면서 텍스트가 위쪽으로 정렬되는 문제
  - `contentPadding`이 수평만 지정되어 수직 정렬이 기본값에 의존

#### Products Catalog 검색바: `_SearchBarWithSubmit` (lib/features/products/products_catalog_screen.dart)
- **위치**: `/Users/actav/Documents/cockat/lib/features/products/products_catalog_screen.dart`
- **구현 방식**:
  - 독립적인 검색바 컴포넌트 (body 영역에 배치)
  - 최근 검색어 기능 통합
  - `SearchBarField`와 유사하지만 별도 구현

#### Ingredients 검색바 (lib/features/ingredients/ingredients_screen.dart)
- **위치**: `/Users/actav/Documents/cockat/lib/features/ingredients/ingredients_screen.dart`
- **구현 방식**:
  - `TextField` 직접 사용
  - `SearchBarField` 컴포넌트 미사용
  - 간단한 구현

### 2. 선택 표시(Selection Indicator) 구현 현황

#### AnimatedSelectionIndicator (lib/core/widgets/animated_selection_indicator.dart)
- **위치**: `/Users/actav/Documents/cockat/lib/core/widgets/animated_selection_indicator.dart`
- **사용처**: `ProductCard` (상품 카드)
- **현재 디자인**:
  - 원형 배경 (CircleShape)
  - 선택 시: Primary 색상 배경 + 흰색 테두리 + 체크 아이콘
  - 미선택 시: 흰색 배경 (alpha: 0.9) + outline 테두리
  - 그림자 효과 포함
- **문제점**:
  - "radio button" 스타일이 아닌 "checkbox" 스타일
  - 사용자가 원하는 것은 radio button 스타일의 디자인 개선

#### SelectionIndicator (lib/core/widgets/selection_indicator.dart)
- **위치**: `/Users/actav/Documents/cockat/lib/core/widgets/selection_indicator.dart`
- **현재 상태**: 사용되지 않는 것으로 보임 (AnimatedSelectionIndicator가 사용됨)

### 3. 재사용 가능성 평가

#### 검색바
- ✅ **재사용 가능한 컴포넌트 존재**: `SearchBarField`
- ⚠️ **문제**: Cocktail 검색 화면은 AppBar 내부에 배치되어 특수한 경우
- **결론**: `SearchBarField`를 기반으로 하되, AppBar용 변형이 필요

#### 선택 표시
- ✅ **기존 컴포넌트**: `AnimatedSelectionIndicator`, `SelectionIndicator`
- **결론**: 기존 컴포넌트 디자인 개선 필요 (radio button 스타일로)

## 구현 전략

### 접근 방식

#### 1. 검색바 텍스트 정렬 문제 해결
1. **원인 분석**: AppBar 내 TextField의 수직 정렬 문제
2. **해결 방안**: `contentPadding`에 수직 패딩 추가 또는 `textAlignVertical` 속성 사용
3. **재사용성 고려**: AppBar용 검색바 변형 또는 옵션 추가

#### 2. 선택 표시 디자인 개선
1. **디자인 방향**: Radio button 스타일 (동그라미 + 내부 점)
2. **구현 방법**: `AnimatedSelectionIndicator` 수정
3. **애니메이션**: 선택/해제 시 부드러운 전환 효과

### 세부 구현 단계

#### Phase 1: 검색바 텍스트 정렬 수정

**Step 1.1: CocktailSearchScreen 검색바 수정**
- 파일: `lib/features/cocktails/cocktail_search_screen.dart`
- 수정 사항:
  ```dart
  // 현재
  decoration: InputDecoration(
    hintText: l10n.searchCocktails,
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    // ...
  ),

  // 수정 후
  decoration: InputDecoration(
    hintText: l10n.searchCocktails,
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12, // 수직 패딩 추가
    ),
    // 또는 textAlignVertical: TextAlignVertical.center 추가
    // ...
  ),
  ```

**Step 1.2: 검증 및 테스트**
- 텍스트 입력 시 수직 정렬 확인
- placeholder 텍스트 정렬 확인
- 다양한 기기 크기에서 테스트

#### Phase 2: 선택 표시 디자인 개선

**Step 2.1: AnimatedSelectionIndicator 디자인 변경**
- 파일: `lib/core/widgets/animated_selection_indicator.dart`
- 현재: Checkbox 스타일 (선택 시 채워진 원 + 체크 아이콘)
- 변경: Radio button 스타일 (항상 테두리 원 + 선택 시 내부 점)

**디자인 방향성 (3가지 옵션)**

**옵션 A: Classic Radio Button**
```dart
// 미선택: 빈 원 (테두리만)
// 선택: 테두리 원 + 내부 작은 원 (점)
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
    border: Border.all(
      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
      width: 2,
    ),
  ),
  child: isSelected
      ? Center(
          child: Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        )
      : null,
)
```

**옵션 B: Modern Radio Button (추천)**
```dart
// 미선택: 흰색 배경 + 얇은 테두리
// 선택: Primary 색상 배경 + 굵은 테두리 + 작은 내부 원
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: isSelected
        ? theme.colorScheme.primary
        : Colors.white.withValues(alpha: 0.9),
    border: Border.all(
      color: isSelected
          ? Colors.white
          : theme.colorScheme.outline,
      width: isSelected ? 3 : 2,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.gray900.withValues(alpha: 0.3),
        blurRadius: isSelected ? 8 : 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: isSelected
      ? Center(
          child: Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        )
      : null,
)
```

**옵션 C: Keep Current but Polish**
```dart
// 현재 체크 아이콘 스타일을 유지하되 더 세련되게
// 선택 시: Primary 배경 + 흰색 굵은 테두리 + 체크 아이콘
// 미선택 시: 투명 배경 + outline 테두리
// 더 강조된 그림자와 애니메이션
```

**Step 2.2: 애니메이션 추가**
```dart
class AnimatedSelectionIndicator extends StatelessWidget {
  // AnimatedContainer로 변경하여 부드러운 전환
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      // ... decoration
    );
  }
}
```

**Step 2.3: 검증 및 테스트**
- 선택/해제 애니메이션 부드러움 확인
- 다크모드/라이트모드 테마 대응 확인
- 제품 카드에서 시각적 조화 확인

### 기술적 고려사항

#### 아키텍처
- **컴포넌트 재사용**: 공통 위젯 활용으로 일관성 유지
- **테마 연동**: ColorScheme 기반 색상 사용
- **반응형**: 다양한 화면 크기 대응

#### 디자인 시스템 통일성
- **색상**: 기존 AppColors, ColorScheme 활용
- **간격**: 기존 패딩/마진 패턴 유지
- **애니메이션**: Duration 200-300ms, easeInOut curve 사용

#### 접근성
- **터치 영역**: 최소 44x44 픽셀 유지
- **색상 대비**: WCAG AA 기준 충족
- **다크모드**: 라이트/다크 테마 모두 지원

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| AppBar 내 TextField 정렬 불안정 | 중간 | 다양한 기기에서 테스트, 필요시 대체 방안 검토 |
| 선택 표시 디자인 사용자 선호도 불일치 | 낮음 | 3가지 옵션 제시, 피드백 수렴 후 최종 결정 |
| 다크모드 색상 대비 문제 | 낮음 | 다크/라이트 테마 모두 테스트, 색상 조정 |
| 애니메이션 성능 이슈 | 낮음 | AnimatedContainer 사용, 복잡도 최소화 |

## 테스트 전략

### 단위 테스트
- SearchBarField 컴포넌트 렌더링 테스트
- AnimatedSelectionIndicator 상태 전환 테스트

### 통합 테스트
- CocktailSearchScreen 검색 플로우 테스트
- ProductCard 선택/해제 동작 테스트

### 시각적 테스트
- ✅ 다양한 기기 크기 (iPhone SE, iPhone Pro Max, iPad)
- ✅ 라이트/다크 테마
- ✅ 텍스트 입력 시 정렬 확인
- ✅ 선택 표시 애니메이션 부드러움

### 사용성 테스트
- 검색바 텍스트 입력 편의성
- 선택 표시의 명확성
- 터치 영역 적절성

## 성공 기준

### 검색바 개선
- [x] Cocktail 검색 화면에서 텍스트 입력 시 수직 중앙 정렬
- [x] placeholder 텍스트도 중앙 정렬
- [x] 다양한 기기 크기에서 일관된 동작

### 선택 표시 개선
- [x] Radio button 스타일의 명확한 선택 상태 표시
- [x] 선택/해제 시 부드러운 애니메이션 (200-300ms)
- [x] 라이트/다크 테마 모두 적절한 색상 대비
- [x] 제품 카드 디자인과 조화

### 전체 품질
- [x] 코드 재사용성 개선
- [x] 디자인 시스템 통일성 유지
- [x] 접근성 기준 충족 (터치 영역, 색상 대비)

## 구현 우선순위

### High Priority (필수)
1. **Cocktail 검색바 텍스트 정렬 수정** - 사용성에 직접적 영향
2. **AnimatedSelectionIndicator 디자인 개선** - 사용자 피드백 기반

### Medium Priority (권장)
3. 검색바 컴포넌트 통합 검토 (장기적 유지보수성 개선)
4. 애니메이션 세밀 조정 및 성능 최적화

### Low Priority (선택)
5. SelectionIndicator 컴포넌트 정리 (미사용 시 제거)
6. 검색바 관련 추가 기능 (자동완성, 필터 등)

## 참고 자료

### Flutter 문서
- [TextField class - Material Library](https://api.flutter.dev/flutter/material/TextField-class.html)
- [InputDecoration class](https://api.flutter.dev/flutter/material/InputDecoration-class.html)
- [AnimatedContainer class](https://api.flutter.dev/flutter/widgets/AnimatedContainer-class.html)

### 디자인 패턴
- Material Design - Text Fields
- Material Design - Selection Controls (Radio buttons)
- iOS Human Interface Guidelines - Search Bars

### 관련 코드 파일
- `/Users/actav/Documents/cockat/lib/core/widgets/search_bar_field.dart`
- `/Users/actav/Documents/cockat/lib/core/widgets/animated_selection_indicator.dart`
- `/Users/actav/Documents/cockat/lib/core/widgets/selection_indicator.dart`
- `/Users/actav/Documents/cockat/lib/features/cocktails/cocktail_search_screen.dart`
- `/Users/actav/Documents/cockat/lib/features/products/products_screen.dart`
- `/Users/actav/Documents/cockat/lib/features/products/products_catalog_screen.dart`
- `/Users/actav/Documents/cockat/lib/core/widgets/product_card.dart`
