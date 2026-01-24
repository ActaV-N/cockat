# 검색 필터링 버그 수정 구현 전략

## 개요
- **목적**: 검색 페이지에서 홈으로 돌아올 때 검색 필터가 유지되는 버그 수정
- **범위**: 검색 화면 상태 관리 및 라이프사이클 처리
- **예상 소요 기간**: 30분

## 현재 상태 분석

### 기존 구현
- **관련 파일**:
  - `lib/features/cocktails/cocktail_search_screen.dart` - 검색 화면
  - `lib/features/cocktails/cocktails_screen.dart` - 홈(칵테일) 화면
  - `lib/data/providers/cocktail_provider.dart` - 검색 쿼리 상태 관리
  - `lib/features/home/home_screen.dart` - 메인 화면 (IndexedStack 사용)

### 문제점/한계

#### 1. 상태 초기화 시점 문제
**현재 코드** (`cocktail_search_screen.dart:34-41`):
```dart
@override
void dispose() {
  _controller.dispose();
  _focusNode.dispose();
  // Clear search query when leaving the screen
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(cocktailSearchQueryProvider.notifier).state = '';
  });
  super.dispose();
}
```

**문제**:
- `dispose()` 메서드에서 `addPostFrameCallback`으로 상태를 초기화
- `HomeScreen`이 `IndexedStack`을 사용하여 모든 탭 화면을 유지
- 검색 화면은 `Navigator.push`로 별도 라우트로 열림
- 검색 화면을 닫을 때 `dispose()`가 호출되지만, `IndexedStack`이 홈 화면을 이미 빌드한 후임
- `filteredCocktailMatchesProvider`가 `cocktailSearchQueryProvider`를 watch하고 있어, 검색어가 남아있으면 필터링이 적용됨

#### 2. IndexedStack의 영향
**HomeScreen 구현** (`home_screen.dart:32-34`):
```dart
body: IndexedStack(
  index: _selectedIndex,
  children: screens,
),
```

- `IndexedStack`은 모든 자식 위젯을 메모리에 유지
- 탭 전환 시 위젯이 재생성되지 않음
- 검색 화면에서 뒤로 가기 시, `CocktailsScreen`은 이미 빌드된 상태
- 검색어가 초기화되기 전에 `filteredCocktailMatchesProvider`가 재평가됨

#### 3. Provider 의존성 체인
```
CocktailsScreen (line 39)
  → filteredCocktailMatchesProvider (cocktail_provider.dart:227)
    → cocktailSearchQueryProvider (cocktail_provider.dart:229)
```

- 검색어 상태가 전역 상태로 관리됨
- 검색 화면이 닫힐 때까지 상태가 유지됨
- `dispose()`의 `addPostFrameCallback`이 실행되는 시점이 화면 빌드 이후

## 구현 전략

### 접근 방식
**해결 방안**: 검색 화면이 팝될 때 즉시 검색 쿼리를 초기화하도록 수정

### 세부 구현 단계

#### 1. dispose 메서드 수정
**변경 파일**: `lib/features/cocktails/cocktail_search_screen.dart`

**현재 코드** (line 34-41):
```dart
@override
void dispose() {
  _controller.dispose();
  _focusNode.dispose();
  // Clear search query when leaving the screen
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(cocktailSearchQueryProvider.notifier).state = '';
  });
  super.dispose();
}
```

**수정 후**:
```dart
@override
void dispose() {
  // Clear search query immediately when leaving the screen
  // This prevents the filter from being applied when returning to home
  ref.read(cocktailSearchQueryProvider.notifier).state = '';

  _controller.dispose();
  _focusNode.dispose();
  super.dispose();
}
```

**변경 이유**:
- `addPostFrameCallback` 제거: dispose 시점에서 프레임 후 콜백이 필요 없음
- 즉시 상태 초기화: `IndexedStack`이 홈 화면을 빌드하기 전에 상태를 초기화
- 순서 변경: Provider 상태를 먼저 정리한 후 리소스 해제

#### 2. 검증 및 테스트
- 검색 화면에서 검색어 입력
- 뒤로 가기 버튼으로 홈으로 복귀
- 홈 화면에서 필터링이 적용되지 않았는지 확인
- 다시 검색 화면 진입 시 검색어가 초기화되었는지 확인

### 기술적 고려사항

#### 1. 상태 관리
- **Provider 라이프사이클**: Riverpod의 StateProvider는 전역 상태이므로 명시적 초기화 필요
- **dispose 타이밍**: dispose()는 위젯이 트리에서 완전히 제거되기 직전 호출됨
- **IndexedStack 동작**: 자식 위젯들이 메모리에 유지되므로 상태 초기화가 중요

#### 2. Navigation
- **push/pop 동작**: Navigator.pop() 시 검색 화면의 dispose() 호출됨
- **상태 전파**: Provider 상태 변경이 즉시 모든 listener에게 전파됨

#### 3. 대안 방안 (필요시)
만약 현재 수정으로 해결되지 않을 경우:

**Option 1**: RouteObserver 사용
```dart
class CocktailSearchScreen extends ConsumerStatefulWidget with RouteAware {
  @override
  void didPop() {
    ref.read(cocktailSearchQueryProvider.notifier).state = '';
    super.didPop();
  }
}
```

**Option 2**: WillPopScope 사용 (Flutter 3.12 이전)
```dart
WillPopScope(
  onWillPop: () async {
    ref.read(cocktailSearchQueryProvider.notifier).state = '';
    return true;
  },
  child: Scaffold(...),
)
```

**Option 3**: PopScope 사용 (Flutter 3.12+)
```dart
PopScope(
  onPopInvoked: (didPop) {
    if (didPop) {
      ref.read(cocktailSearchQueryProvider.notifier).state = '';
    }
  },
  child: Scaffold(...),
)
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| dispose()에서 Provider 접근 시 오류 | 낮음 | dispose() 시점에서도 ref는 유효함. 테스트로 검증 |
| 다른 화면에서 동일한 provider 사용 시 영향 | 낮음 | 검색어는 검색 화면 전용이므로 영향 없음 |
| 애니메이션 중 상태 변경으로 인한 깜빡임 | 낮음 | dispose는 화면 전환 후 발생하므로 시각적 영향 없음 |

## 테스트 전략

### 단위 테스트
필요 없음 (간단한 버그 수정)

### 통합 테스트
**시나리오 1**: 검색 후 홈 복귀
1. 홈 화면에서 검색 아이콘 클릭
2. 검색어 입력 (예: "mojito")
3. 검색 결과 확인
4. 뒤로 가기 버튼 클릭
5. 홈 화면에서 필터링이 적용되지 않았는지 확인
6. 모든 칵테일이 표시되는지 확인

**시나리오 2**: 검색 화면 재진입
1. 검색 화면 진입
2. 검색어 입력
3. 뒤로 가기
4. 다시 검색 화면 진입
5. 검색 필드가 비어있는지 확인

**시나리오 3**: 탭 전환
1. 검색 화면에서 검색어 입력
2. 뒤로 가기로 홈 복귀
3. 다른 탭(내 술장, 상품, 프로필)으로 이동
4. 다시 칵테일 탭으로 복귀
5. 필터링이 적용되지 않았는지 확인

## 성공 기준
- [x] 검색 화면에서 홈으로 복귀 시 검색 필터가 초기화됨
- [x] 홈 화면에서 모든 칵테일이 정상적으로 표시됨
- [x] 검색 화면 재진입 시 검색 필드가 비어있음
- [x] 다른 탭과의 전환에서도 정상 동작함

## 참고 자료
- [Flutter Widget Lifecycle](https://api.flutter.dev/flutter/widgets/State-class.html)
- [Riverpod StateProvider](https://riverpod.dev/docs/providers/state_provider/)
- [IndexedStack 동작 원리](https://api.flutter.dev/flutter/widgets/IndexedStack-class.html)
