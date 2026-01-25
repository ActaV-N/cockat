# Cocktail Import Script 성능 최적화 전략

## 개요

| 항목 | 내용 |
|------|------|
| 목적 | Bar Assistant 데이터 Import 스크립트의 성능 대폭 개선 (3-5배 이상 속도 향상) |
| 대상 스크립트 | `scripts/import_cocktails.py` |
| 현재 성능 | 순차 처리 방식으로 인한 네트워크 I/O 병목 |
| 목표 성능 | 비동기 병렬 처리를 통한 3-5배 속도 향상 |
| 예상 소요 기간 | 4-6시간 (구현 3시간, 테스트 1-2시간, 문서화 1시간) |

## 현재 상태 분석

### 기존 구현 현황

**스크립트 구조** (255줄):
```python
# 현재 구조
- GitHub API: 순차 호출 (get_cocktail_slugs → 각 slug별 get_cocktail_data)
- 이미지 처리: 순차 다운로드/업로드 (download_image → upload_image)
- DB Insert: 배치 100개씩 순차 처리
- 메인 루프: 동기 방식 (for slug in slugs)
```

**사용 라이브러리**:
- `requests`: 동기 HTTP 클라이언트
- `supabase-py`: Supabase 클라이언트 (비동기 지원 가능)
- `python-dotenv`: 환경 변수 로드

**가용 비동기 라이브러리**:
- `httpx==0.28.1`: 비동기 HTTP 클라이언트 (이미 설치됨)
- `asyncio`: Python 표준 라이브러리
- `aiohttp`: 추가 설치 가능 (선택사항)

### 주요 병목 지점 분석

#### 1. GitHub API 호출 병목 (가장 큰 병목)
```python
# 현재: 순차 처리
for slug in slugs:  # 예: 500개 칵테일
    data = get_cocktail_data(slug)  # 각각 ~200ms
    # 총 소요 시간: 500 × 200ms = 100초 (1.67분)
```

**문제점**:
- 네트워크 I/O 대기 시간 동안 CPU 유휴
- 단일 스레드로 순차 처리
- GitHub API는 동시 요청 제한이 없음 (Rate limit만 준수하면 됨)

**개선 가능성**: 10-20개 동시 요청 → **10-20배 속도 향상**

#### 2. 이미지 다운로드/업로드 병목
```python
# 현재: 순차 처리
if recipe.get("images"):
    image_bytes = download_image(slug, filename)  # ~500ms
    image_url = upload_image(slug, image_bytes)   # ~300ms
    # 총 소요 시간: 500 × (500+300)ms = 400초 (6.67분)
```

**문제점**:
- 이미지 다운로드와 업로드가 순차적
- 다른 칵테일 처리를 기다림
- 네트워크 I/O 병목

**개선 가능성**: 10-15개 동시 처리 → **10-15배 속도 향상**

#### 3. DB Insert 병목 (상대적으로 작음)
```python
# 현재: 배치 100개씩
for i in range(0, len(all_cocktail_ings), 100):
    batch = all_cocktail_ings[i:i+100]
    supabase.table("cocktail_ingredients").insert(batch).execute()
```

**문제점**:
- 배치 크기가 작음 (100개)
- 순차 처리

**개선 가능성**: 배치 크기 증가 + 병렬 처리 → **2-3배 속도 향상**

#### 4. 에러 핸들링 부족
```python
# 현재: 기본 try-except만
except Exception as e:
    print(f"✗ ERROR: {e}")
```

**문제점**:
- 재시도 로직 없음
- 실패한 항목 복구 불가
- 네트워크 일시 오류 시 전체 스킵

### 성능 예측 분석

**현재 성능** (500개 칵테일 기준):
```
- GitHub API 호출: 500 × 200ms = 100초
- 이미지 처리: 500 × 800ms = 400초
- DB Insert: ~10초
- 총 예상 시간: ~510초 (8.5분)
```

**최적화 후 예측** (동시 처리 15개 기준):
```
- GitHub API 호출: 500 / 15 × 200ms = 6.7초
- 이미지 처리: 500 / 15 × 800ms = 26.7초
- DB Insert: ~5초
- 총 예상 시간: ~40초 (0.67분)
```

**예상 성능 향상**: **12.75배** (8.5분 → 0.67분)

## 구현 전략

### 접근 방식

**핵심 전략**: **비동기 병렬 처리 + 재시도 로직 + 진행 상황 모니터링**

1. **비동기 변환**: `requests` → `httpx.AsyncClient`
2. **병렬 처리**: `asyncio.gather()` + `asyncio.Semaphore` (동시 요청 제한)
3. **재시도 로직**: 지수 백오프 (Exponential Backoff)
4. **진행 표시**: `tqdm` 또는 실시간 카운터
5. **에러 복구**: 실패 항목 별도 저장 및 재시도 옵션

### 세부 구현 단계

#### Step 1: 비동기 HTTP 클라이언트 구현

**목표**: `requests` → `httpx.AsyncClient` 전환

**구현 내용**:
```python
import asyncio
import httpx
from typing import List, Dict, Optional

# 전역 설정
MAX_CONCURRENT_REQUESTS = 15  # 동시 요청 제한
TIMEOUT = 30.0  # 타임아웃 30초
MAX_RETRIES = 3  # 최대 재시도 횟수
RETRY_DELAY = 1.0  # 초기 재시도 대기 시간 (지수 백오프)

async def create_http_client() -> httpx.AsyncClient:
    """비동기 HTTP 클라이언트 생성"""
    return httpx.AsyncClient(
        timeout=httpx.Timeout(TIMEOUT),
        limits=httpx.Limits(
            max_connections=MAX_CONCURRENT_REQUESTS,
            max_keepalive_connections=10
        )
    )

async def get_cocktail_slugs_async() -> List[str]:
    """GitHub에서 칵테일 폴더 목록 가져오기 (비동기)"""
    async with await create_http_client() as client:
        resp = await client.get(GITHUB_API)
        resp.raise_for_status()
        return [item["name"] for item in resp.json() if item["type"] == "dir"]

async def get_cocktail_data_async(
    client: httpx.AsyncClient,
    slug: str,
    semaphore: asyncio.Semaphore
) -> tuple[str, Optional[dict]]:
    """개별 칵테일 JSON 다운로드 (비동기 + 재시도)"""
    url = f"{GITHUB_RAW}/{slug}/data.json"

    async with semaphore:  # 동시 요청 제한
        for attempt in range(MAX_RETRIES):
            try:
                resp = await client.get(url)
                resp.raise_for_status()
                return (slug, resp.json())
            except (httpx.HTTPError, httpx.TimeoutException) as e:
                if attempt == MAX_RETRIES - 1:
                    print(f"⚠️  {slug} 다운로드 실패 (3회 시도): {e}")
                    return (slug, None)

                # 지수 백오프
                delay = RETRY_DELAY * (2 ** attempt)
                await asyncio.sleep(delay)

    return (slug, None)

async def download_image_async(
    client: httpx.AsyncClient,
    slug: str,
    filename: str,
    semaphore: asyncio.Semaphore
) -> tuple[str, Optional[bytes]]:
    """GitHub에서 이미지 바이너리 다운로드 (비동기 + 재시도)"""
    url = f"{GITHUB_RAW}/{slug}/{filename}"

    async with semaphore:
        for attempt in range(MAX_RETRIES):
            try:
                resp = await client.get(url)
                resp.raise_for_status()
                return (slug, resp.content)
            except (httpx.HTTPError, httpx.TimeoutException) as e:
                if attempt == MAX_RETRIES - 1:
                    print(f"⚠️  {slug} 이미지 다운로드 실패: {e}")
                    return (slug, None)

                delay = RETRY_DELAY * (2 ** attempt)
                await asyncio.sleep(delay)

    return (slug, None)
```

#### Step 2: 병렬 데이터 수집 구현

**목표**: 모든 칵테일 데이터를 병렬로 수집

**구현 내용**:
```python
async def fetch_all_cocktails_async(slugs: List[str]) -> Dict[str, Optional[dict]]:
    """모든 칵테일 데이터를 병렬로 수집"""
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

    async with await create_http_client() as client:
        tasks = [
            get_cocktail_data_async(client, slug, semaphore)
            for slug in slugs
        ]

        # 진행 상황 표시와 함께 실행
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # 딕셔너리로 변환 (실패는 None)
        return {
            slug: data for slug, data in results
            if not isinstance(data, Exception) and data is not None
        }

async def download_all_images_async(
    image_tasks: List[tuple[str, str]]
) -> Dict[str, Optional[bytes]]:
    """모든 이미지를 병렬로 다운로드

    Args:
        image_tasks: [(slug, filename), ...]

    Returns:
        {slug: image_bytes or None}
    """
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

    async with await create_http_client() as client:
        tasks = [
            download_image_async(client, slug, filename, semaphore)
            for slug, filename in image_tasks
        ]

        results = await asyncio.gather(*tasks, return_exceptions=True)

        return {
            slug: image_bytes for slug, image_bytes in results
            if not isinstance(image_bytes, Exception) and image_bytes is not None
        }
```

#### Step 3: 진행 상황 모니터링

**목표**: 실시간 진행 표시 및 통계

**구현 내용**:
```python
from dataclasses import dataclass
from datetime import datetime
import time

@dataclass
class ImportStats:
    """Import 통계"""
    total_cocktails: int = 0
    processed_cocktails: int = 0
    failed_cocktails: int = 0
    total_images: int = 0
    downloaded_images: int = 0
    failed_images: int = 0
    start_time: float = 0

    def start(self):
        """타이머 시작"""
        self.start_time = time.time()

    def elapsed(self) -> float:
        """경과 시간 (초)"""
        return time.time() - self.start_time

    def print_progress(self):
        """진행 상황 출력"""
        elapsed = self.elapsed()
        rate = self.processed_cocktails / elapsed if elapsed > 0 else 0

        print(f"\r진행: {self.processed_cocktails}/{self.total_cocktails} "
              f"칵테일 ({rate:.1f}/s) | "
              f"이미지: {self.downloaded_images}/{self.total_images} | "
              f"실패: {self.failed_cocktails} | "
              f"경과: {elapsed:.1f}초", end="")

    def print_summary(self):
        """최종 요약 출력"""
        print(f"\n\n📊 Import 완료:")
        print(f"  - 처리 시간: {self.elapsed():.1f}초")
        print(f"  - 칵테일: {self.processed_cocktails}/{self.total_cocktails} "
              f"(실패: {self.failed_cocktails})")
        print(f"  - 이미지: {self.downloaded_images}/{self.total_images} "
              f"(실패: {self.failed_images})")
        print(f"  - 평균 속도: {self.processed_cocktails / self.elapsed():.1f} 칵테일/초")

# 사용 예시
async def fetch_with_progress(slugs: List[str]) -> Dict[str, dict]:
    """진행 상황 표시와 함께 데이터 수집"""
    stats = ImportStats(total_cocktails=len(slugs))
    stats.start()

    semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

    async with await create_http_client() as client:
        async def fetch_one(slug: str):
            result = await get_cocktail_data_async(client, slug, semaphore)
            stats.processed_cocktails += 1
            if result[1] is None:
                stats.failed_cocktails += 1
            stats.print_progress()
            return result

        results = await asyncio.gather(*[fetch_one(s) for s in slugs])

    stats.print_summary()
    return {slug: data for slug, data in results if data is not None}
```

#### Step 4: 메인 Import 로직 재구성

**목표**: 비동기 함수를 통합한 메인 로직

**구현 내용**:
```python
async def import_data_async(
    dry_run: bool = False,
    limit: Optional[int] = None,
    skip_images: bool = False
):
    """메인 Import 로직 (비동기)"""
    print("🍹 Bar Assistant 데이터 Import 시작 (비동기 모드)\n")

    # 기존 데이터 확인 (동기 - 한 번만 호출)
    existing_ings = {r["id"] for r in supabase.table("ingredients").select("id").execute().data}
    existing_cocktails = {r["id"] for r in supabase.table("cocktails").select("id").execute().data}
    print(f"기존 데이터: 재료 {len(existing_ings)}개, 칵테일 {len(existing_cocktails)}개\n")

    # Phase 1: 칵테일 목록 가져오기
    print("📋 GitHub에서 칵테일 목록 가져오는 중...")
    slugs = await get_cocktail_slugs_async()
    if limit:
        slugs = slugs[:limit]
    print(f"처리할 칵테일: {len(slugs)}개\n")

    # Phase 2: 모든 칵테일 데이터 병렬 수집
    print("📥 칵테일 데이터 다운로드 중...")
    stats = ImportStats(total_cocktails=len(slugs))
    stats.start()

    cocktail_data = await fetch_with_progress(slugs)

    # Phase 3: 이미지 병렬 다운로드
    if not skip_images:
        print("\n\n📷 이미지 다운로드 중...")
        image_tasks = []
        for slug, data in cocktail_data.items():
            if data and data.get("images"):
                filename = data["images"][0]["uri"].replace("file:///", "")
                image_tasks.append((slug, filename))

        stats.total_images = len(image_tasks)
        image_data = await download_all_images_async(image_tasks)
        stats.downloaded_images = len([b for b in image_data.values() if b is not None])
        stats.failed_images = stats.total_images - stats.downloaded_images
    else:
        image_data = {}

    # Phase 4: 데이터 변환 및 수집 (동기)
    all_ingredients = {}
    all_cocktails = []
    all_cocktail_ings = []
    all_substitutes = []

    for slug, data in cocktail_data.items():
        recipe = data

        # 재료 수집
        for ing in recipe.get("ingredients", []):
            if ing["_id"] not in all_ingredients:
                all_ingredients[ing["_id"]] = map_ingredient(ing)

        # 칵테일 수집
        if recipe["_id"] not in existing_cocktails:
            image_url = None

            # 이미지 업로드 (동기 - Supabase Storage API)
            if slug in image_data and image_data[slug] is not None:
                if not dry_run:
                    image_url = upload_image(slug, image_data[slug])

            all_cocktails.append(map_cocktail(recipe, image_url))

            # 관계 데이터
            for idx, ing in enumerate(recipe.get("ingredients", [])):
                all_cocktail_ings.append(
                    map_cocktail_ingredient(recipe["_id"], ing, idx)
                )
                for sub in ing.get("substitutes", []):
                    sub_id = sub["_id"] if isinstance(sub, dict) else sub
                    all_substitutes.append({
                        "ingredient_id": ing["_id"],
                        "substitute_id": sub_id,
                    })

    # Phase 5: DB Insert (기존 로직 유지 - 배치 크기만 증가)
    new_ingredients = [v for k, v in all_ingredients.items() if k not in existing_ings]

    stats.print_summary()
    print(f"\n📦 수집 완료:")
    print(f"  - 새 재료: {len(new_ingredients)}개")
    print(f"  - 새 칵테일: {len(all_cocktails)}개")
    print(f"  - 관계 데이터: {len(all_cocktail_ings)}개")

    if dry_run:
        print("\n🔍 Dry run 모드 - DB 변경 없음")
        return

    # DB Insert (배치 크기 증가: 100 → 500)
    BATCH_SIZE = 500

    if new_ingredients:
        print(f"\n📦 재료 Insert 중...")
        # 배치 처리
        for i in range(0, len(new_ingredients), BATCH_SIZE):
            batch = new_ingredients[i:i+BATCH_SIZE]
            supabase.table("ingredients").insert(batch).execute()
        print(f"  ✓ {len(new_ingredients)}개 완료")

    if all_cocktails:
        print(f"\n🍸 칵테일 Insert 중...")
        for i in range(0, len(all_cocktails), BATCH_SIZE):
            batch = all_cocktails[i:i+BATCH_SIZE]
            supabase.table("cocktails").insert(batch).execute()
        print(f"  ✓ {len(all_cocktails)}개 완료")

    if all_cocktail_ings:
        print(f"\n🔗 관계 데이터 Insert 중...")
        for i in range(0, len(all_cocktail_ings), BATCH_SIZE):
            batch = all_cocktail_ings[i:i+BATCH_SIZE]
            supabase.table("cocktail_ingredients").insert(batch).execute()
        print(f"  ✓ {len(all_cocktail_ings)}개 완료")

    if all_substitutes:
        print(f"\n🔄 대체 재료 Insert 중...")
        for i in range(0, len(all_substitutes), BATCH_SIZE):
            batch = all_substitutes[i:i+BATCH_SIZE]
            try:
                supabase.table("ingredient_substitutes").insert(batch).execute()
            except Exception as e:
                print(f"    ⚠️  일부 대체 재료 실패: {e}")
        print(f"  ✓ {len(all_substitutes)}개 시도")

    print("\n✅ Import 완료!")

# 메인 실행 함수
def main():
    """CLI 진입점"""
    parser = argparse.ArgumentParser(description="Bar Assistant 데이터 Import (최적화 버전)")
    parser.add_argument("--dry-run", action="store_true", help="실제 DB 변경 없이 테스트")
    parser.add_argument("--limit", type=int, help="처리할 칵테일 수 제한")
    parser.add_argument("--skip-images", action="store_true", help="이미지 업로드 건너뛰기")
    parser.add_argument("--max-concurrent", type=int, default=15,
                        help="동시 요청 수 제한 (기본: 15)")
    args = parser.parse_args()

    # 글로벌 설정 업데이트
    global MAX_CONCURRENT_REQUESTS
    MAX_CONCURRENT_REQUESTS = args.max_concurrent

    # 비동기 실행
    asyncio.run(import_data_async(
        dry_run=args.dry_run,
        limit=args.limit,
        skip_images=args.skip_images
    ))

if __name__ == "__main__":
    main()
```

#### Step 5: 실패 항목 복구 기능

**목표**: 실패한 항목을 별도 저장하고 재시도 옵션 제공

**구현 내용**:
```python
import json
from pathlib import Path

FAILED_ITEMS_FILE = "failed_cocktails.json"

def save_failed_items(failed_slugs: List[str]):
    """실패한 항목 저장"""
    if not failed_slugs:
        return

    failed_data = {
        "timestamp": datetime.now().isoformat(),
        "count": len(failed_slugs),
        "slugs": failed_slugs
    }

    Path(FAILED_ITEMS_FILE).write_text(json.dumps(failed_data, indent=2))
    print(f"\n⚠️  실패한 {len(failed_slugs)}개 항목을 {FAILED_ITEMS_FILE}에 저장했습니다.")
    print(f"   재시도: python scripts/import_cocktails.py --retry-failed")

def load_failed_items() -> List[str]:
    """실패한 항목 로드"""
    if not Path(FAILED_ITEMS_FILE).exists():
        print(f"⚠️  {FAILED_ITEMS_FILE} 파일이 없습니다.")
        return []

    data = json.loads(Path(FAILED_ITEMS_FILE).read_text())
    print(f"📋 실패 항목 {data['count']}개를 로드했습니다 (저장 시간: {data['timestamp']})")
    return data["slugs"]

# CLI 옵션 추가
parser.add_argument("--retry-failed", action="store_true",
                    help="실패한 항목만 재시도")

# 메인 로직에 통합
async def import_data_async(...):
    # ... 기존 코드 ...

    # 실패 항목 추적
    failed_slugs = [slug for slug, data in cocktail_data.items() if data is None]

    if failed_slugs:
        save_failed_items(failed_slugs)

    # ... 나머지 코드 ...
```

### 기술적 고려사항

#### 아키텍처 결정

**비동기 vs 멀티스레딩**:
- ✅ **비동기 선택**: I/O 바운드 작업에 최적, GIL 회피
- ❌ 멀티스레딩: GIL로 인한 제한, 복잡한 동기화

**라이브러리 선택**:
- ✅ **httpx**: `requests` 호환 API, 비동기 지원, 이미 설치됨
- ❌ `aiohttp`: 추가 설치 필요, API 다름

#### 동시 요청 제한

**Rate Limit 고려**:
- GitHub API: 인증 없이 60 req/hour (IP 기준)
- 인증 시: 5000 req/hour
- **권장**: `MAX_CONCURRENT_REQUESTS = 15` (안전 마진)

**Semaphore 설정**:
```python
semaphore = asyncio.Semaphore(15)  # 동시 15개 제한

async with semaphore:
    # 동시 실행 제한 영역
    resp = await client.get(url)
```

#### 재시도 로직

**지수 백오프 (Exponential Backoff)**:
```python
for attempt in range(MAX_RETRIES):
    try:
        return await client.get(url)
    except Exception:
        if attempt == MAX_RETRIES - 1:
            raise
        delay = RETRY_DELAY * (2 ** attempt)  # 1초, 2초, 4초
        await asyncio.sleep(delay)
```

**재시도 조건**:
- ✅ 네트워크 타임아웃
- ✅ 일시적 서버 오류 (5xx)
- ❌ 클라이언트 오류 (4xx) - 재시도 불필요

#### 메모리 관리

**문제점**: 모든 이미지를 메모리에 로드하면 OOM 가능

**해결책**: 스트리밍 처리
```python
async def process_image_streaming(slug: str, filename: str):
    """이미지 다운로드 → 즉시 업로드 (메모리 절약)"""
    # 다운로드
    image_bytes = await download_image_async(client, slug, filename, semaphore)

    # 즉시 업로드 (메모리 해제)
    if image_bytes:
        image_url = upload_image(slug, image_bytes)
        return image_url
    return None
```

#### 에러 처리 전략

**계층적 에러 처리**:
1. **네트워크 레벨**: 재시도 로직
2. **데이터 레벨**: 실패 항목 기록
3. **전체 레벨**: 통계 및 요약

**에러 타입별 처리**:
```python
try:
    resp = await client.get(url)
    resp.raise_for_status()
except httpx.TimeoutException:
    # 타임아웃 → 재시도
    pass
except httpx.HTTPStatusError as e:
    if e.response.status_code >= 500:
        # 서버 오류 → 재시도
        pass
    else:
        # 클라이언트 오류 → 스킵
        raise
except httpx.NetworkError:
    # 네트워크 오류 → 재시도
    pass
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| GitHub Rate Limit 초과 | 높음 | Semaphore로 동시 요청 제한 (15개), 인증 토큰 사용 고려 |
| 메모리 부족 (OOM) | 중간 | 스트리밍 처리, 배치 크기 조정, `--limit` 옵션 활용 |
| 네트워크 불안정 | 중간 | 재시도 로직 (3회), 지수 백오프, 실패 항목 저장 |
| Supabase API 제한 | 낮음 | 배치 크기 조정 (500개), 속도 제한 추가 가능 |
| 비동기 코드 복잡도 증가 | 낮음 | 명확한 함수 분리, 타입 힌트, 주석 |
| 기존 코드와 호환성 문제 | 낮음 | 동기/비동기 버전 공존, CLI 플래그로 선택 |

## 테스트 전략

### 단위 테스트

**테스트 대상**:
1. 비동기 HTTP 함수 (모킹)
2. 재시도 로직 검증
3. 데이터 매핑 함수
4. 배치 처리 로직

**테스트 도구**:
```python
import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_get_cocktail_data_async_success():
    """칵테일 데이터 다운로드 성공 케이스"""
    mock_response = {"_id": "test", "name": "Test Cocktail"}

    with patch("httpx.AsyncClient.get") as mock_get:
        mock_get.return_value.json.return_value = mock_response

        client = httpx.AsyncClient()
        semaphore = asyncio.Semaphore(15)

        slug, data = await get_cocktail_data_async(client, "test-slug", semaphore)

        assert slug == "test-slug"
        assert data == mock_response

@pytest.mark.asyncio
async def test_get_cocktail_data_async_retry():
    """재시도 로직 검증"""
    with patch("httpx.AsyncClient.get") as mock_get:
        # 첫 2번 실패, 3번째 성공
        mock_get.side_effect = [
            httpx.TimeoutException("Timeout"),
            httpx.TimeoutException("Timeout"),
            AsyncMock(json=lambda: {"_id": "test"})
        ]

        client = httpx.AsyncClient()
        semaphore = asyncio.Semaphore(15)

        slug, data = await get_cocktail_data_async(client, "test-slug", semaphore)

        assert data is not None
        assert mock_get.call_count == 3
```

### 통합 테스트

**테스트 시나리오**:
1. **소규모 테스트**: `--limit 10 --dry-run`
2. **중규모 테스트**: `--limit 100`
3. **대규모 테스트**: 전체 데이터
4. **실패 복구 테스트**: `--retry-failed`

**성능 벤치마크**:
```bash
# 기존 버전 (동기)
time python scripts/import_cocktails.py --limit 100 --skip-images

# 최적화 버전 (비동기)
time python scripts/import_cocktails_async.py --limit 100 --skip-images

# 속도 비교
```

### E2E 테스트

**검증 항목**:
```sql
-- 1. 데이터 무결성 검증
SELECT COUNT(*) FROM ingredients;
SELECT COUNT(*) FROM cocktails;
SELECT COUNT(*) FROM cocktail_ingredients;

-- 2. FK 무결성 검증
SELECT ci.ingredient_id
FROM cocktail_ingredients ci
LEFT JOIN ingredients i ON ci.ingredient_id = i.id
WHERE i.id IS NULL;

-- 3. 이미지 URL 검증
SELECT
  COUNT(*) FILTER (WHERE image_url IS NOT NULL) as with_image,
  COUNT(*) FILTER (WHERE image_url IS NULL) as without_image
FROM cocktails;

-- 4. 중복 검증
SELECT id, COUNT(*) FROM cocktails GROUP BY id HAVING COUNT(*) > 1;
```

## 성공 기준

### 성능 기준
- [ ] 500개 칵테일 처리 시간: **8.5분 → 2분 이하** (4.25배 이상 향상)
- [ ] 동시 요청 처리: **15개 이상** 안정적 동작
- [ ] 재시도 성공률: **95% 이상**
- [ ] 메모리 사용량: **500MB 이하** (이미지 포함)

### 품질 기준
- [ ] 데이터 무결성: **100%** (FK 위반 0건)
- [ ] 이미지 업로드 성공률: **90% 이상**
- [ ] 실패 항목 복구율: **95% 이상** (재시도 후)
- [ ] 에러 로깅: 모든 실패 항목 기록

### 코드 품질
- [ ] 타입 힌트: **100%** 함수에 적용
- [ ] 단위 테스트: 핵심 함수 **80% 이상** 커버리지
- [ ] 문서화: README 업데이트, 함수 docstring 추가
- [ ] 하위 호환성: 기존 CLI 옵션 유지

## 구현 우선순위

### Phase 1: 핵심 비동기 변환 (2시간)
1. ✅ `httpx.AsyncClient` 도입
2. ✅ 비동기 함수 구현 (get_cocktail_data_async, download_image_async)
3. ✅ Semaphore 기반 동시 요청 제한
4. ✅ 메인 로직 비동기 통합

### Phase 2: 재시도 및 에러 처리 (1시간)
1. ✅ 지수 백오프 재시도 로직
2. ✅ 실패 항목 저장 기능
3. ✅ `--retry-failed` 옵션

### Phase 3: 모니터링 및 최적화 (1시간)
1. ✅ 진행 상황 표시 (ImportStats)
2. ✅ 배치 크기 최적화 (100 → 500)
3. ✅ 메모리 스트리밍 (선택사항)

### Phase 4: 테스트 및 문서화 (1-2시간)
1. ✅ 단위 테스트 작성
2. ✅ 통합 테스트 실행
3. ✅ README 업데이트
4. ✅ 성능 벤치마크 문서화

## 실행 방법

### 기본 사용법

```bash
# 1. 비동기 스크립트 실행 (기본)
python scripts/import_cocktails_async.py

# 2. 소규모 테스트
python scripts/import_cocktails_async.py --dry-run --limit 10

# 3. 동시 요청 수 조정
python scripts/import_cocktails_async.py --max-concurrent 20

# 4. 실패 항목 재시도
python scripts/import_cocktails_async.py --retry-failed

# 5. 이미지 제외 (속도 우선)
python scripts/import_cocktails_async.py --skip-images
```

### 성능 비교 테스트

```bash
# 기존 동기 버전
time python scripts/import_cocktails.py --limit 100 --skip-images

# 최적화 비동기 버전
time python scripts/import_cocktails_async.py --limit 100 --skip-images

# 예상 결과:
# 동기: ~20초
# 비동기: ~2초 (10배 향상)
```

### 대규모 Import

```bash
# 전체 데이터 Import (이미지 포함)
python scripts/import_cocktails_async.py

# 예상 소요 시간:
# - 500개 칵테일 기준: 2-3분
# - 1000개 칵테일 기준: 4-6분
```

## 참고 자료

### Python 비동기 프로그래밍
- [asyncio 공식 문서](https://docs.python.org/3/library/asyncio.html)
- [httpx 비동기 가이드](https://www.python-httpx.org/async/)
- [Real Python - Async IO](https://realpython.com/async-io-python/)

### 성능 최적화
- [Python Async Best Practices](https://docs.python.org/3/library/asyncio-dev.html)
- [Rate Limiting with asyncio.Semaphore](https://docs.python.org/3/library/asyncio-sync.html#asyncio.Semaphore)
- [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff)

### GitHub API
- [GitHub REST API Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
- [GitHub API Best Practices](https://docs.github.com/en/rest/guides/best-practices-for-integrators)

### Supabase
- [Supabase Python Client](https://supabase.com/docs/reference/python/introduction)
- [Supabase Storage](https://supabase.com/docs/guides/storage)

## 마이그레이션 전략

### 단계별 전환

**Option 1: 점진적 마이그레이션**
1. 기존 스크립트 유지 (`import_cocktails.py`)
2. 새 스크립트 추가 (`import_cocktails_async.py`)
3. 병렬 운영 후 안정화되면 기존 스크립트 제거

**Option 2: 즉시 전환**
1. 기존 스크립트를 `import_cocktails_legacy.py`로 백업
2. 새 스크립트를 `import_cocktails.py`로 배포
3. 문제 발생 시 레거시 버전으로 롤백

**권장**: **Option 1** (안정성 우선)

### 하위 호환성

**CLI 인터페이스 유지**:
```bash
# 기존 명령어 모두 작동
python scripts/import_cocktails.py --dry-run
python scripts/import_cocktails.py --limit 10
python scripts/import_cocktails.py --skip-images

# 새 옵션 추가
python scripts/import_cocktails.py --max-concurrent 20
python scripts/import_cocktails.py --retry-failed
```

**환경 변수 호환**:
- `.env` 파일 동일하게 사용
- `SUPABASE_URL`, `SUPABASE_SERVICE_KEY` 변경 없음

## 향후 개선 방안

### 추가 최적화 가능성

1. **Supabase Storage 비동기 업로드**
   - `supabase-py` 비동기 클라이언트 활용
   - 이미지 업로드도 병렬 처리
   - 예상 추가 향상: **2배**

2. **캐싱 레이어 추가**
   - 로컬 파일 캐시 (이미 다운로드한 항목 스킵)
   - Redis 캐시 (분산 환경)
   - 예상 효과: **재실행 시 10배 이상 빠름**

3. **증분 업데이트**
   - 변경된 칵테일만 업데이트
   - GitHub API의 `since` 파라미터 활용
   - 예상 효과: **일일 업데이트 90% 감소**

4. **멀티프로세싱 통합**
   - CPU 집약적 작업 (이미지 리사이징 등)은 별도 프로세스
   - `multiprocessing.Pool` + `asyncio` 조합
   - 예상 추가 향상: **1.5배**

### 모니터링 및 로깅

1. **구조화된 로깅**
   - JSON 형식 로그
   - Timestamp, level, context 포함
   - 분석 및 디버깅 용이

2. **메트릭 수집**
   - Prometheus 형식 메트릭 출력
   - Grafana 대시보드 연동
   - 성능 추이 모니터링

3. **알림 시스템**
   - 실패율 임계값 초과 시 알림
   - Slack/Discord 웹훅 통합
   - 운영 자동화

## 결론

본 전략은 Bar Assistant 데이터 Import 스크립트의 성능을 **3-12배 향상**시킬 수 있는 실행 가능한 최적화 방안을 제시합니다.

**핵심 개선 사항**:
- ✅ 비동기 병렬 처리로 네트워크 I/O 병목 해소
- ✅ 재시도 로직으로 안정성 향상
- ✅ 진행 상황 모니터링으로 사용자 경험 개선
- ✅ 실패 항목 복구 기능으로 완전성 보장

**예상 성능**:
- 500개 칵테일: **8.5분 → 0.67분** (12.75배)
- 100개 칵테일: **1.7분 → 8초** (12.75배)
- 10개 칵테일: **10초 → 1초** (10배)

**구현 우선순위**:
1. **Phase 1**: 핵심 비동기 변환 (가장 큰 효과)
2. **Phase 2**: 재시도 로직 (안정성)
3. **Phase 3**: 모니터링 (사용자 경험)
4. **Phase 4**: 테스트 및 문서화 (품질)

모든 변경 사항은 기존 코드와 하위 호환성을 유지하며, 점진적으로 도입 가능합니다.
