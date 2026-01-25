# Cocktail Instructions 파싱 문제 해결 전략

## 개요
- **목적**: 칵테일 instructions의 `\\n` 리터럴 문자열을 실제 개행 문자로 변환하여 모든 step이 정상 표시되도록 수정
- **범위**: DB 데이터 수정 + 프론트엔드 파싱 로직 개선 + import 스크립트 수정
- **예상 소요 기간**: 1-2시간
- **영향 범위**: 전체 칵테일 613개 중 609개 (99.3%)

## 현재 상태 분석

### 문제 증상
```
DB 저장 데이터: "1. Fill glass.\\n2. Add gin.\\n3. Stir."
현재 화면 표시: Step 1만 보임 (\\n이 개행으로 인식 안됨)
예상 표시: Step 1, 2, 3 모두 별도 라인으로 표시
```

### 영향받는 데이터
- **전체 칵테일**: 613개
- **영향받는 칵테일**: 609개 (99.3%)
- **정상 칵테일**: 4개만 문제 없음
- **예시**: Aperol Spritz, Gin & Tonic, Whiskey Sour, Daiquiri, Martini 등 거의 모든 칵테일

### 현재 구현 분석

#### 1. 프론트엔드 파싱 로직 (`lib/features/cocktails/cocktail_detail_screen.dart`)
```dart
// Line 311: _InstructionsCard
final steps = instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();
```
- `\n` (실제 개행 문자)로 split 시도
- 하지만 DB에는 `\\n` (리터럴 문자열)로 저장되어 있어 split 실패
- 결과: 전체 instructions가 하나의 step으로 인식됨

#### 2. DB 저장 형식
```sql
SELECT instructions FROM cocktails WHERE name = 'Aperol Spritz'
→ "1. Fill a wine glass with ice.\\n2. Add Aperol and prosecco.\\n3. Top with club soda.\\n4. Stir gently and garnish."
```
- `\\n`이 리터럴 문자열로 저장됨 (JSON escape sequence)
- PostgreSQL에서도 escape된 상태로 저장

#### 3. Import 스크립트 (`scripts/import_cocktails.py`)
```python
# Line 96: map_cocktail 함수
"instructions": recipe.get("instructions"),
```
- Bar Assistant JSON 파일의 instructions를 그대로 전달
- JSON에 이미 `\n`이 escape된 상태로 저장되어 있음
- Python이 JSON 읽을 때 자동으로 `\\n`으로 변환됨

### 근본 원인
1. **Bar Assistant 데이터 형식**: JSON에 instructions가 escaped newline (`\n`)으로 저장
2. **Python JSON 파싱**: JSON 읽을 때 `\n` → `\\n` (literal) 변환
3. **Supabase 저장**: literal `\\n` 그대로 DB 저장
4. **Flutter 파싱**: `\n`으로 split 시도하지만 실제로는 `\\n` 문자열이라 실패

## 구현 전략

### 접근 방식
3단계 수정 전략으로 즉시 해결 + 향후 재발 방지

### 세부 구현 단계

#### Phase 1: DB 데이터 일괄 수정 (즉시 해결)
**우선순위: HIGH | 소요시간: 5분**

1. SQL migration으로 모든 칵테일의 instructions 수정
2. PostgreSQL의 `REPLACE` 함수로 `\\n` → 실제 개행 문자 변환
3. 기존 데이터에 영향 없도록 안전한 변환

```sql
-- Migration: fix_cocktail_instructions_newlines
UPDATE cocktails
SET instructions = REPLACE(instructions, E'\\n', E'\n')
WHERE instructions LIKE '%\\n%';
```

**검증 방법**:
```sql
-- 변환 전후 비교
SELECT
  id,
  name,
  LENGTH(instructions) as length,
  instructions LIKE '%\\n%' as has_escaped_newline,
  instructions LIKE '%' || chr(10) || '%' as has_real_newline
FROM cocktails
WHERE name = 'Aperol Spritz';
```

#### Phase 2: 프론트엔드 방어 로직 추가 (Fallback)
**우선순위: MEDIUM | 소요시간: 10분**

현재 파싱 로직에 fallback 추가하여 향후 동일 문제 발생 시 대응

```dart
// lib/features/cocktails/cocktail_detail_screen.dart
class _InstructionsCard extends StatelessWidget {
  final String instructions;

  const _InstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    // Defensive parsing: handle both real newlines and escaped newlines
    String normalizedInstructions = instructions;

    // If no real newlines but has escaped newlines, replace them
    if (!instructions.contains('\n') && instructions.contains('\\n')) {
      normalizedInstructions = instructions.replaceAll('\\n', '\n');
    }

    final steps = normalizedInstructions
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Card(
      // ... rest of implementation
    );
  }
}
```

**장점**:
- DB 수정 실패 시 fallback 제공
- 향후 잘못된 데이터 import 시에도 정상 표시
- 기존 로직에 최소 영향

#### Phase 3: Import 스크립트 수정 (향후 예방)
**우선순위: LOW | 소요시간: 10분**

향후 데이터 import 시 문제 재발 방지

```python
# scripts/import_cocktails.py

def map_cocktail(recipe: dict, image_url: str = None) -> dict:
    """Bar Assistant → Supabase 칵테일 매핑"""
    instructions = recipe.get("instructions")

    # Ensure instructions have real newlines, not escaped ones
    if instructions and '\\n' in instructions:
        instructions = instructions.replace('\\n', '\n')

    return {
        "id": recipe["_id"],
        "name": recipe["name"],
        "name_ko": None,
        "description": recipe.get("description"),
        "instructions": instructions,
        # ... rest of mapping
    }
```

**검증 방법**:
```bash
# 테스트 import 실행
python scripts/import_cocktails.py \
  --local /path/to/bar-assistant/cocktails \
  --dry-run \
  --limit 5

# instructions 필드가 실제 개행 문자 포함하는지 확인
```

### 기술적 고려사항

#### 데이터 무결성
- **Idempotent Migration**: 여러 번 실행해도 안전
- **원본 보존**: 변환 실패 시 rollback 가능
- **검증**: 변환 전후 데이터 검증 쿼리 실행

#### 성능
- **Bulk Update**: 609개 레코드 일괄 업데이트 (<1초)
- **Index Impact**: instructions는 인덱스 없어 영향 없음
- **App Impact**: 프론트엔드 로직 변경은 런타임 영향 미미

#### 호환성
- **기존 데이터**: 정상 데이터 (4개)에는 영향 없음
- **향후 데이터**: import 스크립트 수정으로 예방
- **Flutter 버전**: 현재 Flutter 버전과 호환 이슈 없음

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 확률 | 대응 방안 |
|-----------|--------|------|----------|
| Migration 실패로 데이터 손상 | 높음 | 낮음 | 1. 사전 backup 쿼리 실행<br>2. Dry-run으로 영향 범위 확인<br>3. Rollback SQL 준비 |
| 일부 칵테일에서 의도하지 않은 개행 발생 | 중간 | 낮음 | 1. 변환 후 샘플 데이터 검증<br>2. UI에서 trim() 처리 유지 |
| 향후 데이터 import 시 문제 재발 | 낮음 | 중간 | 1. Import 스크립트 수정<br>2. 프론트엔드 fallback 로직 유지 |
| 프론트엔드 로직 수정으로 성능 저하 | 낮음 | 낮음 | 1. 간단한 문자열 처리로 영향 미미<br>2. 빌드 시 최적화 확인 |

## 테스트 전략

### 1. DB Migration 테스트
```sql
-- 1. 현재 상태 확인
SELECT COUNT(*) FROM cocktails WHERE instructions LIKE '%\\n%';
-- 예상: 609

-- 2. 샘플 데이터 확인
SELECT id, name, instructions FROM cocktails
WHERE name IN ('Aperol Spritz', 'Gin & Tonic', 'Daiquiri')
LIMIT 3;

-- 3. Migration 실행
UPDATE cocktails
SET instructions = REPLACE(instructions, E'\\n', E'\n')
WHERE instructions LIKE '%\\n%';

-- 4. 결과 확인
SELECT COUNT(*) FROM cocktails WHERE instructions LIKE '%\\n%';
-- 예상: 0 또는 4 (정상 데이터만 남음)

-- 5. 변환된 데이터 확인
SELECT id, name,
  LENGTH(instructions) as length,
  instructions LIKE '%' || chr(10) || '%' as has_newline
FROM cocktails
WHERE name = 'Aperol Spritz';
```

### 2. 프론트엔드 테스트
- **테스트 케이스 1**: Aperol Spritz 상세 화면에서 4개 step 모두 표시되는지 확인
- **테스트 케이스 2**: Gin & Tonic에서 4개 step 모두 별도 라인으로 표시
- **테스트 케이스 3**: 기존 정상 데이터 (4개)도 여전히 정상 표시
- **테스트 케이스 4**: 의도적으로 `\\n` 데이터 추가 후 fallback 동작 확인

### 3. Import 스크립트 테스트
```bash
# Dry-run으로 검증
python scripts/import_cocktails.py \
  --local ~/bar-assistant-data/cocktails \
  --dry-run \
  --limit 10

# 실제 import 후 DB 확인
SELECT instructions FROM cocktails
WHERE id IN (SELECT id FROM cocktails ORDER BY created_at DESC LIMIT 5);
```

### 4. 통합 테스트
- 전체 칵테일 목록 로드 → 샘플 선택 → 상세 화면 → instructions 확인
- 검색 기능으로 "Spritz" 검색 → Aperol Spritz 선택 → 4 steps 확인
- 즐겨찾기 추가/제거 → instructions 표시 영향 없음 확인

## 성공 기준

### 즉시 성공 (Phase 1 완료 후)
- [ ] DB에서 `\\n` 포함 레코드 수: 609개 → 0개
- [ ] Aperol Spritz 상세 화면에서 4개 step 모두 표시
- [ ] 기존 정상 데이터 (4개) 영향 없음
- [ ] Migration 실행 시간 < 2초

### 중기 성공 (Phase 2 완료 후)
- [ ] 프론트엔드에서 escaped newline 자동 처리
- [ ] 의도적으로 잘못된 데이터 추가 시에도 정상 표시
- [ ] 앱 성능 영향 없음 (빌드 크기, 렌더링 속도)

### 장기 성공 (Phase 3 완료 후)
- [ ] 새로운 칵테일 import 시 instructions 정상 저장
- [ ] Import 스크립트 dry-run 테스트 통과
- [ ] 향후 6개월간 instructions 파싱 이슈 0건

## 실행 계획

### 1단계: Backup 및 준비 (5분)
```sql
-- Rollback용 백업 테이블 생성 (선택사항)
CREATE TABLE cocktails_instructions_backup AS
SELECT id, name, instructions
FROM cocktails
WHERE instructions LIKE '%\\n%';
```

### 2단계: Migration 실행 (5분)
```bash
# Supabase migration 생성
cd ~/Documents/cockat
supabase migration new fix_cocktail_instructions_newlines

# SQL 작성 및 적용
# → supabase/migrations/XXXXXX_fix_cocktail_instructions_newlines.sql
```

### 3단계: 프론트엔드 수정 (10분)
- `lib/features/cocktails/cocktail_detail_screen.dart` 수정
- Hot reload로 즉시 테스트

### 4단계: Import 스크립트 수정 (10분)
- `scripts/import_cocktails.py` 수정
- Dry-run으로 검증

### 5단계: 통합 테스트 (15분)
- 앱 재시작 후 전체 플로우 테스트
- 다양한 칵테일 샘플 확인

### 6단계: 배포 (자동)
- Git commit 및 push
- Supabase migration 자동 적용

## 참고 자료

### 관련 파일
- `/Users/actav/Documents/cockat/lib/features/cocktails/cocktail_detail_screen.dart` (Line 304-359)
- `/Users/actav/Documents/cockat/scripts/import_cocktails.py` (Line 89-104)
- `/Users/actav/Documents/cockat/lib/data/models/cocktail.dart` (Line 36-58, 61-82)

### PostgreSQL 개행 문자 처리
- `E'\\n'`: Escaped backslash + n (literal `\n` string)
- `E'\n'`: Actual newline character (ASCII 10)
- `chr(10)`: Newline character function
- `REPLACE(text, from, to)`: String replacement function

### Flutter String 처리
- `String.split('\n')`: Split by actual newline
- `String.replaceAll('\\n', '\n')`: Replace literal with actual newline
- `String.trim()`: Remove leading/trailing whitespace

### Bar Assistant 데이터 형식
- JSON에 instructions가 `"1. Step\\n2. Step"` 형식으로 저장
- Python `json.load()`가 자동으로 escape sequence 처리
- 결과: Python string에 literal `\n`이 아닌 `\\n` 포함

## 롤백 계획

### Migration Rollback
```sql
-- Phase 1 롤백: 백업에서 복원
UPDATE cocktails c
SET instructions = b.instructions
FROM cocktails_instructions_backup b
WHERE c.id = b.id;

-- 백업 테이블 삭제
DROP TABLE cocktails_instructions_backup;
```

### 프론트엔드 Rollback
```bash
git revert <commit-hash>
# 또는 변경사항 수동 제거
```

### Import 스크립트 Rollback
```bash
git revert <commit-hash>
# 이전 버전으로 복원
```

## 예상 결과

### Before (현재)
```
Aperol Spritz 상세 화면:

Instructions
─────────────────────
1  1. Fill a wine glass with ice.\n2. Add Aperol and prosecco.\n3. Top with club soda.\n4. Stir gently and garnish.
```

### After (수정 후)
```
Aperol Spritz 상세 화면:

Instructions
─────────────────────
1  Fill a wine glass with ice.
2  Add Aperol and prosecco.
3  Top with club soda.
4  Stir gently and garnish.
```

## 추가 개선 사항 (선택)

### 다국어 지원 준비
- instructions 필드에 `instructions_ko` 추가 고려
- 향후 한국어 레시피 제공 시 활용

### 리치 텍스트 지원
- 현재: Plain text steps
- 향후: Markdown 지원으로 **bold**, *italic* 등 서식 추가

### Step 이미지 지원
- 각 step별 이미지 추가 (선택사항)
- `cocktail_instruction_steps` 테이블 추가 고려

### 동영상 튜토리얼
- YouTube 링크 필드 추가
- 동영상과 텍스트 instructions 동시 제공
