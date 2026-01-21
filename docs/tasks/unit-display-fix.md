# 단위 표시 버그 수정 계획 (Unit Display Bug Fix Plan)

## 개요

사용자가 설정에서 단위(oz, ml, parts)를 선택해도 칵테일 디테일 페이지에서는 항상 데이터베이스의 원본 단위(주로 ml)가 표시되는 버그를 수정합니다.

---

## 문제 분석 (Problem Analysis)

### 현재 동작 흐름

```
[사용자] → [Onboarding/Settings에서 oz 선택]
            ↓
[SharedPreferences/DB에 저장] (정상 동작 ✅)
            ↓
[Cocktail Detail 페이지 열기]
            ↓
[CocktailIngredient.formattedAmount 표시] ← 단위 설정 무시 ❌
            ↓
[항상 DB의 원본 units 표시 (ml)]
```

### 근본 원인 (Root Cause)

**파일**: `lib/data/models/ingredient.dart:193-202`

```dart
String get formattedAmount {
  if (amountMax != null) {
    return '$amount-$amountMax $units';  // ← units는 DB 원본값 (ml)
  }
  final amountStr = amount == amount.roundToDouble()
      ? amount.round().toString()
      : amount.toString();
  return '$amountStr $units';  // ← 사용자 설정 무시
}
```

**문제점**:
- `formattedAmount` getter가 사용자의 단위 설정(`effectiveUnitSystemProvider`)을 참조하지 않음
- 데이터베이스의 `units` 필드를 그대로 표시
- Consumer가 아닌 일반 getter라서 Riverpod provider 접근 불가

---

## 해결 방법 (Solution Design)

### 방법 1: Unit Converter 유틸리티 추가 (권장 ✅)

**장점**:
- 단일 책임 원칙 준수 (모델은 데이터만, 변환은 유틸리티)
- 재사용 가능
- 테스트 용이
- 모델 구조 변경 없음

**구조**:
```dart
// lib/core/utils/unit_converter.dart (신규 생성)
class UnitConverter {
  static double mlToOz(double ml) => ml / 29.5735;
  static double ozToMl(double oz) => oz * 29.5735;

  static String formatAmount(
    double amount,
    String originalUnit,
    UnitSystem targetUnit, {
    double? amountMax,
  }) {
    // 변환 로직
  }
}
```

**사용 예시**:
```dart
// lib/features/cocktails/cocktail_detail_screen.dart
class _IngredientsList extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final userUnit = ref.watch(effectiveUnitSystemProvider);

    return ListTile(
      subtitle: Text(
        UnitConverter.formatAmount(
          ingredient.amount,
          ingredient.units,
          userUnit,
          amountMax: ingredient.amountMax,
        ),
      ),
    );
  }
}
```

### 방법 2: formattedAmount를 메서드로 변경

**단점**:
- 모든 호출부 수정 필요
- 모델에 비즈니스 로직 추가 (단일 책임 위반)

---

## 구현 계획 (Implementation Plan)

### Phase 1: Core 유틸리티 작성

**파일**: `lib/core/utils/unit_converter.dart` (신규)

```dart
import '../providers/onboarding_provider.dart';

class UnitConverter {
  /// ml → oz 변환
  static double mlToOz(double ml) => ml / 29.5735;

  /// oz → ml 변환
  static double ozToMl(double oz) => oz * 29.5735;

  /// 사용자 설정에 맞춰 단위 변환 및 포맷팅
  static String formatAmount(
    double amount,
    String originalUnit,
    UnitSystem targetUnit, {
    double? amountMax,
  }) {
    // Case 1: 범위 표시 (amount-amountMax)
    if (amountMax != null) {
      final convertedAmount = _convert(amount, originalUnit, targetUnit);
      final convertedMax = _convert(amountMax, originalUnit, targetUnit);
      return '${_formatNumber(convertedAmount)}-${_formatNumber(convertedMax)} ${targetUnit.value}';
    }

    // Case 2: 단일 값 표시
    final converted = _convert(amount, originalUnit, targetUnit);
    return '${_formatNumber(converted)} ${targetUnit.value}';
  }

  /// 실제 변환 로직
  static double _convert(double value, String from, UnitSystem to) {
    // 원본이 이미 목표 단위면 변환 불필요
    if (from == to.value) return value;

    // parts는 비율이므로 변환 불가
    if (from == 'parts' || to == UnitSystem.parts) return value;

    // ml ↔ oz 변환
    if (from == 'ml' && to == UnitSystem.oz) {
      return mlToOz(value);
    } else if (from == 'oz' && to == UnitSystem.ml) {
      return ozToMl(value);
    }

    return value; // 기타 경우 원본 반환
  }

  /// 숫자 포맷팅 (소수점 정리)
  static String _formatNumber(double value) {
    // 정수면 소수점 제거
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    // 소수점 1자리로 반올림
    return value.toStringAsFixed(1);
  }
}
```

### Phase 2: Cocktail Detail 화면 수정

**파일**: `lib/features/cocktails/cocktail_detail_screen.dart:227-262`

**변경 전**:
```dart
class _IngredientsList extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      subtitle: Text(ingredient.formattedAmount), // ← 문제
    );
  }
}
```

**변경 후**:
```dart
import '../../core/utils/unit_converter.dart';

class _IngredientsList extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final userUnit = ref.watch(effectiveUnitSystemProvider);

    return ListTile(
      subtitle: Text(
        UnitConverter.formatAmount(
          ingredient.amount,
          ingredient.units,
          userUnit,
          amountMax: ingredient.amountMax,
        ),
      ),
    );
  }
}
```

### Phase 3: Settings 화면에 단위 설정 추가 (선택적)

현재 단위 설정은 Onboarding에만 존재하므로, Settings 화면에도 추가하면 사용자가 나중에 변경 가능합니다.

**파일**: `lib/features/settings/settings_screen.dart:84-127`

**추가 섹션**:
```dart
const Divider(),

// Unit System Section
_SectionHeader(title: l10n.unitSystem),
_UnitTile(
  title: l10n.unitMl,
  subtitle: '30ml, 45ml, 60ml...',
  isSelected: unitSystem == UnitSystem.ml,
  onTap: () {
    ref.read(onboardingServiceProvider).setUnitSystem(UnitSystem.ml);
  },
),
_UnitTile(
  title: l10n.unitOz,
  subtitle: '1oz, 1.5oz, 2oz...',
  isSelected: unitSystem == UnitSystem.oz,
  onTap: () {
    ref.read(onboardingServiceProvider).setUnitSystem(UnitSystem.oz);
  },
),
_UnitTile(
  title: l10n.unitParts,
  subtitle: '1 part, 2 parts...',
  isSelected: unitSystem == UnitSystem.parts,
  onTap: () {
    ref.read(onboardingServiceProvider).setUnitSystem(UnitSystem.parts);
  },
),
```

---

## 테스트 케이스 (Test Cases)

### 단위 변환 정확성

| 입력 | 사용자 설정 | 기대 출력 |
|------|------------|----------|
| `30ml` | oz | `1oz` |
| `45ml` | oz | `1.5oz` |
| `60ml` | oz | `2oz` |
| `1oz` | ml | `30ml` |
| `1.5oz` | ml | `45ml` |
| `2oz` | ml | `60ml` |
| `1 part` | oz | `1 part` (변환 안 됨) |
| `30-45ml` | oz | `1-1.5oz` (범위) |

### UI 테스트

1. **Onboarding에서 oz 선택** → 칵테일 디테일 → oz로 표시 ✅
2. **Onboarding에서 ml 선택** → 칵테일 디테일 → ml로 표시 ✅
3. **Settings에서 oz → ml 변경** → 칵테일 디테일 → 즉시 ml로 변경 ✅
4. **로그인 후 설정 동기화** → 다른 기기에서도 동일 단위 표시 ✅

---

## 추가 개선 사항 (Future Enhancements)

### 1. 다양한 단위 지원

현재는 ml, oz, parts만 지원하지만, 추후 확장 가능:
- `cl` (centiliters) - 유럽권
- `tsp` (teaspoon) - 소량 재료
- `dash` - 비터스 등

### 2. 지역별 기본 단위

```dart
static UnitSystem getDefaultUnit(String locale) {
  return switch (locale) {
    'en' => UnitSystem.oz,   // 미국
    'ko' => UnitSystem.ml,   // 한국
    _ => UnitSystem.ml,      // 기본값
  };
}
```

### 3. 혼합 단위 지원

일부 레시피는 "30ml vodka + 1 dash bitters" 처럼 혼합 단위 사용:
- 메인 재료: ml/oz
- 소량 재료: dash, tsp

---

## 파일 변경 요약 (Files to Change)

### 신규 파일
- ✅ `lib/core/utils/unit_converter.dart`

### 수정 파일
- ✅ `lib/features/cocktails/cocktail_detail_screen.dart` (227-262줄)
- ⚠️ `lib/features/settings/settings_screen.dart` (선택적, 84-127줄)

### 삭제/Deprecated
- ⚠️ `lib/data/models/ingredient.dart:193-202` (formattedAmount getter는 유지하되, 사용 중단 권장)

---

## 구현 우선순위

1. **High Priority** (필수):
   - UnitConverter 유틸리티 작성
   - Cocktail Detail 화면 수정
   - 기본 테스트 케이스 검증

2. **Medium Priority** (권장):
   - Settings 화면에 단위 설정 추가
   - 포괄적인 단위 테스트 작성

3. **Low Priority** (추후):
   - 추가 단위 지원 (cl, tsp, dash)
   - 지역별 기본 단위 설정
   - 혼합 단위 지원

---

## 참고 자료 (References)

- **단위 변환**: 1 oz = 29.5735 ml (US fluid ounce 기준)
- **Bar Assistant 데이터**: 대부분 ml 단위로 저장됨
- **Flutter Provider**: effectiveUnitSystemProvider (onboarding_provider.dart:117-127)
