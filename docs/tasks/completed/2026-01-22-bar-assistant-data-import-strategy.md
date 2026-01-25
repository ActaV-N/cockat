# Bar Assistant 데이터 배치 Import 전략

## 개요

| 항목 | 내용 |
|------|------|
| 목적 | Bar Assistant 데이터를 Supabase DB에 자동 배치 등록 |
| 데이터 소스 | [github.com/bar-assistant/data](https://github.com/bar-assistant/data) |
| 기술 스택 | Python + requests + supabase-py |
| 예상 소요 | 반나절 (스크립트 2-3시간, 테스트 1-2시간) |
| 이미지 처리 | GitHub에서 다운로드 → Supabase Storage 업로드 |

## DB 스키마 요약

```
ingredients (id, name, name_ko, category, description, strength, origin, image_url)
cocktails (id, name, name_ko, description, instructions, garnish, glass, method, abv, tags, image_url)
cocktail_ingredients (cocktail_id, ingredient_id, amount, units, sort_order, is_optional, note)
ingredient_substitutes (ingredient_id, substitute_id)
```

## 구현 전략

### 핵심 접근

```
Phase 1: Ingredients 먼저 import (FK 의존성 해결)
Phase 2: Cocktails + 관계 데이터 import
```

### 디렉토리 구조

```
scripts/
  └── import_cocktails.py   # 단일 파일 스크립트
.env                        # 환경 변수
```

## 구현 코드

### 1. 환경 설정

**.env** (프로젝트 루트):
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
```

### 2. 메인 스크립트

**scripts/import_cocktails.py**:
```python
#!/usr/bin/env python3
"""Bar Assistant 데이터를 Supabase로 Import하는 스크립트 (이미지 포함)"""

import os
import argparse
import requests
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Config
GITHUB_API = "https://api.github.com/repos/bar-assistant/data/contents"
GITHUB_RAW = "https://raw.githubusercontent.com/bar-assistant/data/master"
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
STORAGE_BUCKET = "cockat-images"  # 기존 버킷 사용
STORAGE_PATH = "cocktails/originals"  # products/originals 패턴과 동일

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# ============ GitHub API ============

def get_cocktail_slugs():
    """GitHub에서 칵테일 폴더 목록 가져오기"""
    resp = requests.get(f"{GITHUB_API}/cocktails")
    resp.raise_for_status()
    return [item["name"] for item in resp.json() if item["type"] == "dir"]


def get_cocktail_data(slug: str) -> dict:
    """개별 칵테일 JSON 다운로드"""
    url = f"{GITHUB_RAW}/cocktails/{slug}/{slug}.json"
    resp = requests.get(url)
    resp.raise_for_status()
    return resp.json()


def download_image(slug: str, filename: str) -> bytes:
    """GitHub에서 이미지 바이너리 다운로드"""
    url = f"{GITHUB_RAW}/cocktails/{slug}/{filename}"
    resp = requests.get(url)
    resp.raise_for_status()
    return resp.content


# ============ Supabase Storage ============

def upload_image(slug: str, filename: str, image_bytes: bytes) -> str | None:
    """Supabase Storage에 이미지 업로드 후 Public URL 반환

    저장 경로: cockat-images/cocktails/originals/{slug}.webp
    (기존 products/originals 패턴과 동일)
    """
    try:
        # 파일명을 slug.webp로 통일 (mojito.webp, old-fashioned.webp)
        path = f"{STORAGE_PATH}/{slug}.webp"

        # 기존 파일 있으면 삭제 (upsert)
        supabase.storage.from_(STORAGE_BUCKET).remove([path])

        # 업로드
        supabase.storage.from_(STORAGE_BUCKET).upload(
            path,
            image_bytes,
            {"content-type": "image/webp"}
        )

        # Public URL 반환
        return supabase.storage.from_(STORAGE_BUCKET).get_public_url(path)
    except Exception as e:
        print(f"    ⚠️ 이미지 업로드 실패 ({slug}): {e}")
        return None


# ============ 데이터 매핑 ============

def map_ingredient(ba_ing: dict) -> dict:
    """Bar Assistant → Supabase 재료 매핑"""
    return {
        "id": ba_ing["_id"],
        "name": ba_ing["name"],
        "name_ko": None,
        "category": ba_ing.get("category"),
        "description": ba_ing.get("description"),
        "strength": ba_ing.get("strength"),
        "origin": ba_ing.get("origin"),
        "image_url": None,
    }


def map_cocktail(recipe: dict, image_url: str = None) -> dict:
    """Bar Assistant → Supabase 칵테일 매핑"""
    return {
        "id": recipe["_id"],
        "name": recipe["name"],
        "name_ko": None,
        "description": recipe.get("description"),
        "instructions": recipe.get("instructions"),
        "garnish": recipe.get("garnish"),
        "glass": recipe.get("glass"),
        "method": recipe.get("method"),
        "abv": recipe.get("abv"),
        "tags": recipe.get("tags", []),
        "image_url": image_url,
    }


def map_cocktail_ingredient(cocktail_id: str, ing: dict, sort: int) -> dict:
    """Bar Assistant → Supabase 칵테일-재료 관계 매핑"""
    return {
        "cocktail_id": cocktail_id,
        "ingredient_id": ing["_id"],
        "amount": ing.get("amount"),
        "units": ing.get("units"),
        "sort_order": ing.get("sort", sort),
        "is_optional": ing.get("optional", False),
        "note": ing.get("note"),
    }


# ============ 메인 로직 ============

def import_data(dry_run: bool = False, limit: int = None, skip_images: bool = False):
    """메인 Import 로직"""
    print("🍹 Bar Assistant 데이터 Import 시작\n")

    # 기존 데이터 확인
    existing_ings = {r["id"] for r in supabase.table("ingredients").select("id").execute().data}
    existing_cocktails = {r["id"] for r in supabase.table("cocktails").select("id").execute().data}
    print(f"기존 데이터: 재료 {len(existing_ings)}개, 칵테일 {len(existing_cocktails)}개")

    # 칵테일 목록 가져오기
    slugs = get_cocktail_slugs()
    if limit:
        slugs = slugs[:limit]
    print(f"처리할 칵테일: {len(slugs)}개\n")

    # 수집용 변수
    all_ingredients = {}
    all_cocktails = []
    all_cocktail_ings = []
    all_substitutes = []
    uploaded_images = 0

    # Phase 1 & 2: 데이터 수집
    for slug in slugs:
        try:
            data = get_cocktail_data(slug)
            recipe = data.get("recipe", data)
            ingredients = data.get("ingredients", [])

            # 재료 수집 (중복 제거)
            for ing in ingredients:
                if ing["_id"] not in all_ingredients:
                    all_ingredients[ing["_id"]] = map_ingredient(ing)

            # 칵테일 수집
            if recipe["_id"] not in existing_cocktails:
                image_url = None

                # 이미지 처리
                if not skip_images and recipe.get("images"):
                    first_image = recipe["images"][0]
                    filename = first_image["uri"]

                    if not dry_run:
                        print(f"  📷 {slug}: 이미지 다운로드 중...")
                        image_bytes = download_image(slug, filename)
                        image_url = upload_image(slug, filename, image_bytes)
                        if image_url:
                            uploaded_images += 1
                    else:
                        print(f"  📷 {slug}: 이미지 ({filename}) - dry run")

                all_cocktails.append(map_cocktail(recipe, image_url))

                # 칵테일-재료 관계
                for i, ing in enumerate(recipe.get("ingredients", [])):
                    all_cocktail_ings.append(
                        map_cocktail_ingredient(recipe["_id"], ing, i)
                    )
                    # 대체 재료
                    for sub_id in ing.get("substitutes", []):
                        all_substitutes.append({
                            "ingredient_id": ing["_id"],
                            "substitute_id": sub_id,
                        })

            print(f"  ✓ {slug}")
        except Exception as e:
            print(f"  ✗ {slug}: {e}")

    # 새 재료만 필터링
    new_ingredients = [v for k, v in all_ingredients.items() if k not in existing_ings]

    print(f"\n📊 수집 완료:")
    print(f"  - 새 재료: {len(new_ingredients)}개")
    print(f"  - 새 칵테일: {len(all_cocktails)}개")
    print(f"  - 관계 데이터: {len(all_cocktail_ings)}개")
    print(f"  - 이미지 업로드: {uploaded_images}개")

    if dry_run:
        print("\n🔍 Dry run 모드 - DB 변경 없음")
        return

    # Phase 1: 재료 Insert
    if new_ingredients:
        print(f"\n📦 재료 Insert 중...")
        supabase.table("ingredients").insert(new_ingredients).execute()
        print(f"  ✓ {len(new_ingredients)}개 완료")

    # Phase 2: 칵테일 Insert
    if all_cocktails:
        print(f"\n🍸 칵테일 Insert 중...")
        supabase.table("cocktails").insert(all_cocktails).execute()
        print(f"  ✓ {len(all_cocktails)}개 완료")

    # Phase 2: 관계 데이터 Insert (배치 100개씩)
    if all_cocktail_ings:
        print(f"\n🔗 관계 데이터 Insert 중...")
        for i in range(0, len(all_cocktail_ings), 100):
            batch = all_cocktail_ings[i:i+100]
            supabase.table("cocktail_ingredients").insert(batch).execute()
        print(f"  ✓ {len(all_cocktail_ings)}개 완료")

    if all_substitutes:
        for i in range(0, len(all_substitutes), 100):
            batch = all_substitutes[i:i+100]
            supabase.table("ingredient_substitutes").insert(batch).execute()
        print(f"  ✓ 대체 재료 {len(all_substitutes)}개 완료")

    print("\n✅ Import 완료!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bar Assistant 데이터 Import")
    parser.add_argument("--dry-run", action="store_true", help="실제 DB 변경 없이 테스트")
    parser.add_argument("--limit", type=int, help="처리할 칵테일 수 제한")
    parser.add_argument("--skip-images", action="store_true", help="이미지 업로드 건너뛰기")
    args = parser.parse_args()

    import_data(dry_run=args.dry_run, limit=args.limit, skip_images=args.skip_images)
```

## 실행 방법

### 사전 준비

**Storage 구조** (기존 `cockat-images` 버킷 활용):
```
cockat-images/
  ├── products/           # 기존 제품 이미지
  │   ├── originals/
  │   └── thumbnails/
  └── cocktails/          # 신규 칵테일 이미지
      └── originals/
          ├── mojito.webp
          ├── old-fashioned.webp
          └── ...
```

- 별도 버킷 생성 불필요 (기존 `cockat-images` 사용)
- Policy도 이미 설정되어 있음

### 실행

```bash
# 1. 의존성 설치
pip install requests supabase python-dotenv

# 2. 환경 변수 설정 (.env 파일)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=eyJxxx...  # service_role key 필요 (anon key X)

# 3. 실행
python scripts/import_cocktails.py --dry-run --limit 5   # 테스트
python scripts/import_cocktails.py --limit 10            # 10개
python scripts/import_cocktails.py                       # 전체
python scripts/import_cocktails.py --skip-images         # 이미지 제외
```

## 위험 요소 및 대응

| 위험 | 대응 |
|------|------|
| GitHub Rate Limit (60/hour) | `--limit` 옵션으로 분할 실행 |
| FK 오류 | Phase 1에서 재료 먼저 insert |
| 중복 삽입 | 기존 ID 체크 후 스킵 |
| 네트워크 오류 | 실패 항목 로그 후 계속 진행 |
| Storage 용량 초과 | `--skip-images`로 텍스트만 import |
| 이미지 업로드 실패 | 개별 실패 로그, 칵테일 데이터는 계속 진행 |

## 성공 기준

- [ ] 모든 재료 import 성공
- [ ] 90%+ 칵테일 import 성공
- [ ] 90%+ 이미지 업로드 성공
- [ ] FK 위반 0건
- [ ] 중복 0건

## 검증 SQL

```sql
-- 데이터 확인
SELECT 'ingredients' as tbl, COUNT(*) FROM ingredients
UNION ALL
SELECT 'cocktails', COUNT(*) FROM cocktails
UNION ALL
SELECT 'cocktail_ingredients', COUNT(*) FROM cocktail_ingredients;

-- FK 무결성 검증
SELECT ci.ingredient_id FROM cocktail_ingredients ci
LEFT JOIN ingredients i ON ci.ingredient_id = i.id
WHERE i.id IS NULL;

-- 이미지 URL 있는 칵테일 수
SELECT
  COUNT(*) FILTER (WHERE image_url IS NOT NULL) as with_image,
  COUNT(*) FILTER (WHERE image_url IS NULL) as without_image,
  COUNT(*) as total
FROM cocktails;
```

실행 예시

```sh
source .venv/bin/activate && python scripts/import_cocktails.py --limit 50
```