# Product Card 선택 UI 재디자인 전략

## 개요
- **목적**: 제품 선택 상태를 항상 명확하게 표시하여 사용자 경험 개선
- **범위**: Product Card의 선택 표시 UI 개선 (항상 표시되는 선택 인디케이터)
- **예상 소요 기간**: 1-2시간

## 현재 상태 분석

### 기존 구현의 문제점
1. **선택 상태 불명확**: 선택되지 않은 제품은 아무런 표시가 없어 선택 가능 여부를 직관적으로 알 수 없음
2. **일관성 부족**: 선택된 항목만 체크마크가 나타나 UI 일관성 저하
3. **사용성 저하**: 사용자가 카드를 탭해야만 선택 가능 여부를 알 수 있음

### 현재 코드 (products_screen.dart, lines 234-250)
```dart
Stack(
  fit: StackFit.expand,
  children: [
    ProductImage(
      product: product,
      mode: ImageDisplayMode.thumbnail,
    ),
    // 선택된 경우에만 체크마크 표시
    if (isSelected)
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            size: 16,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
  ],
)
```

### 문제점 상세 분석
- **조건부 렌더링**: `if (isSelected)` 조건으로 인해 미선택 상태에서는 아무것도 표시되지 않음
- **사용자 혼란**: 처음 사용하는 사용자는 카드를 탭할 수 있다는 것을 직관적으로 알기 어려움
- **접근성 문제**: 시각적 힌트 부족으로 인한 접근성 저하

## 구현 전략

### 접근 방식
**Always-Visible Selection Indicator**: 모든 제품 카드에 항상 선택 인디케이터를 표시하되, 선택 상태에 따라 스타일 변경

### 디자인 옵션

#### 옵션 1: Checkbox 스타일 (권장)
```
┌─────────────────┐
│  ┌───┐         │
│  │ ✓ │  [선택됨] │
│  └───┘         │
│   [이미지]      │
│                │
│  Brand Name    │
│  Product Name  │
└─────────────────┘

┌─────────────────┐
│  ┌───┐         │
│  │   │  [미선택] │
│  └───┘         │
│   [이미지]      │
│                │
│  Brand Name    │
│  Product Name  │
└─────────────────┘
```

**장점**:
- 명확한 선택 상태 표시
- 웹/앱에서 익숙한 패턴
- Material Design 가이드라인 준수

**단점**:
- 약간의 시각적 무게감

#### 옵션 2: Circle Icon 스타일 (추천)
```
┌─────────────────┐
│          ●      │  ← Filled circle (선택됨)
│   [이미지]      │
│                │
│  Brand Name    │
│  Product Name  │
└─────────────────┘

┌─────────────────┐
│          ○      │  ← Outlined circle (미선택)
│   [이미지]      │
│                │
│  Brand Name    │
│  Product Name  │
└─────────────────┘
```

**장점**:
- 미니멀하고 깔끔한 디자인
- 시각적 부담 최소화
- 상태 구분 명확

**단점**:
- 작은 화면에서 탭 영역이 좁을 수 있음

#### 옵션 3: Badge 스타일
```
┌─────────────────┐
│     ┌─────┐    │
│     │  ✓  │    │  ← Badge (선택됨)
│     └─────┘    │
│   [이미지]      │
│                │
│  Brand Name    │
│  Product Name  │
└─────────────────┘

┌─────────────────┐
│     ┌─────┐    │
│     │  +  │    │  ← Badge (미선택)
│     └─────┘    │
│   [이미지]      │
│                │
│  Brand Name    │
│  Product Name  │
└─────────────────┘
```

**장점**:
- 인터랙션 명확성 최대
- 액션 가능 영역 명시

**단점**:
- UI 요소가 많아 복잡해 보일 수 있음

### 최종 권장안: 옵션 2 (Circle Icon 스타일)

**이유**:
1. **미니멀 디자인**: 기존 UI 스타일과 잘 어울림
2. **명확한 상태**: Filled/Outlined로 선택 여부 직관적 표시
3. **접근성**: 항상 보이는 인디케이터로 탭 가능 영역 명확화
4. **Material Design 3 호환**: Material You 디자인 시스템과 일치

### 세부 구현 단계

#### 1단계: SelectionIndicator 위젯 생성

```dart
// lib/core/widgets/selection_indicator.dart
class SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final double size;
  final Color? selectedColor;
  final Color? unselectedColor;

  const SelectionIndicator({
    super.key,
    required this.isSelected,
    this.size = 24,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSelectedColor = selectedColor ?? theme.colorScheme.primary;
    final effectiveUnselectedColor = unselectedColor ??
        theme.colorScheme.onSurface.withOpacity(0.3);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 선택 시: primary 색상으로 채움
        color: isSelected
            ? effectiveSelectedColor
            : theme.colorScheme.surface,
        // 미선택 시: outline 표시
        border: isSelected
            ? null
            : Border.all(
                color: effectiveUnselectedColor,
                width: 2,
              ),
        // 그림자 효과로 가독성 향상
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              size: size * 0.6,
              color: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }
}
```

#### 2단계: AnimatedSelectionIndicator 추가 (선택사항 - 향상된 UX)

```dart
// lib/core/widgets/animated_selection_indicator.dart
class AnimatedSelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final double size;

  const AnimatedSelectionIndicator({
    super.key,
    required this.isSelected,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        border: isSelected
            ? null
            : Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                width: 2,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? Icon(
                Icons.check,
                key: const ValueKey('check'),
                size: size * 0.6,
                color: theme.colorScheme.onPrimary,
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}
```

#### 3단계: _ProductCard 위젯 수정

```dart
// lib/features/products/products_screen.dart
class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(effectiveIsProductSelectedProvider(product.id));
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          ref.read(effectiveProductsServiceProvider).toggle(product.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with selection indicator
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    product: product,
                    mode: ImageDisplayMode.thumbnail,
                  ),
                  // CHANGE: 항상 표시되는 선택 인디케이터
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedSelectionIndicator(
                      isSelected: isSelected,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Info section remains unchanged
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (product.formattedVolume != null ||
                        product.abv != null)
                      Text(
                        [
                          if (product.formattedVolume != null)
                            product.formattedVolume,
                          if (product.abv != null) '${product.abv}%',
                        ].join(' | '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 4단계: widgets.dart 내보내기 추가

```dart
// lib/core/widgets/widgets.dart에 추가
export 'selection_indicator.dart';
export 'animated_selection_indicator.dart';
```

### 기술적 고려사항

#### UI/UX 디자인
- **시각적 위계**: 인디케이터가 제품 정보보다 우선순위가 높지 않도록 크기와 위치 조정
- **대비**: 배경 이미지와 관계없이 인디케이터가 명확히 보이도록 그림자 효과 적용
- **접근성**: 색맹 사용자도 구분할 수 있도록 filled/outlined 구조 사용

#### 성능
- **AnimatedContainer**: 하드웨어 가속 지원으로 부드러운 애니메이션
- **Widget 재사용**: SelectionIndicator 위젯 재사용으로 코드 중복 제거
- **최적화된 rebuild**: isSelected 상태만 변경 시 인디케이터만 rebuild

#### 일관성
- **디자인 시스템**: Material Design 3 가이드라인 준수
- **재사용성**: 다른 선택 가능 UI (재료 선택 등)에도 동일한 인디케이터 사용 가능

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 인디케이터가 제품 이미지를 가림 | 낮음 | 우측 상단 8px 여백으로 이미지 핵심 부분 보존 |
| 작은 화면에서 인디케이터가 작아 탭하기 어려움 | 낮음 | 카드 전체가 탭 영역이므로 문제없음 |
| 디자인 일관성 저하 우려 | 낮음 | Material Design 3 기준 준수로 일관성 유지 |
| 애니메이션으로 인한 성능 저하 | 낮음 | AnimatedContainer는 하드웨어 가속 지원 |

## 테스트 전략

### 단위 테스트
- [ ] `SelectionIndicator` 선택/미선택 상태 렌더링 확인
- [ ] `AnimatedSelectionIndicator` 애니메이션 동작 확인
- [ ] 테마 색상 적용 확인

### UI 테스트
- [ ] 모든 제품 카드에 인디케이터 표시 확인
- [ ] 선택 시 filled circle + 체크 아이콘 표시
- [ ] 미선택 시 outlined circle 표시
- [ ] 선택 상태 전환 시 애니메이션 동작 확인
- [ ] 다양한 제품 이미지 배경에서 가독성 확인

### 접근성 테스트
- [ ] 색맹 모드에서 선택 상태 구분 가능 확인
- [ ] TalkBack/VoiceOver에서 선택 상태 읽기 확인
- [ ] 고대비 모드에서 인디케이터 가시성 확인

### 성능 테스트
- [ ] 100개 제품 카드 스크롤 시 프레임 드롭 없음 확인
- [ ] 빠른 연속 선택/해제 시 애니메이션 끊김 없음 확인

## 성공 기준
- [x] 모든 제품 카드에 선택 인디케이터가 항상 표시됨
- [x] 선택 상태와 미선택 상태가 명확히 구분됨
- [x] 애니메이션이 부드럽고 자연스러움 (60fps 유지)
- [x] 다양한 배경 이미지에서 인디케이터 가독성 확보
- [x] 접근성 기준 충족 (색맹 모드, 스크린 리더)
- [x] 기존 제품 카드 레이아웃과 조화로움

## 수정할 파일 목록
1. **lib/core/widgets/selection_indicator.dart** (NEW): 기본 선택 인디케이터 위젯
2. **lib/core/widgets/animated_selection_indicator.dart** (NEW): 애니메이션 선택 인디케이터 위젯
3. **lib/core/widgets/widgets.dart**: 새 위젯 내보내기 추가
4. **lib/features/products/products_screen.dart**: `_ProductCard` Stack 구조 수정

## 추가 개선 제안 (선택사항)

### Phase 2 개선사항
1. **햅틱 피드백**: 선택/해제 시 진동 피드백 추가
```dart
onTap: () {
  HapticFeedback.selectionClick();
  ref.read(effectiveProductsServiceProvider).toggle(product.id);
}
```

2. **일괄 선택 모드**: 길게 누르면 여러 제품 선택 가능한 모드 진입
3. **선택 개수 표시**: 앱바에 "3개 선택됨" 등의 정보 표시

## 참고 자료
- [Material Design 3 - Selection Controls](https://m3.material.io/components/selection-controls/overview)
- [Flutter Cookbook - Gestures](https://docs.flutter.dev/cookbook/gestures)
- [Animation Best Practices](https://docs.flutter.dev/development/ui/animations/tutorial)
- [Accessibility Guidelines](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
