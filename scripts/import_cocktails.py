#!/usr/bin/env python3
"""Bar Assistant 데이터를 Supabase로 Import하는 스크립트 (이미지 포함)"""

import os
import json
import argparse
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Config
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_ANON_KEY")
STORAGE_BUCKET = "cockat-images"
STORAGE_PATH = "cocktails/originals"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# ============ 로컬 파일 읽기 ============

def get_cocktail_slugs(local_path: Path) -> list[str]:
    """로컬 디렉토리에서 칵테일 폴더 목록 가져오기"""
    return sorted([d.name for d in local_path.iterdir() if d.is_dir()])


def get_cocktail_data(local_path: Path, slug: str) -> dict:
    """로컬 JSON 파일 읽기"""
    json_file = local_path / slug / "data.json"
    with open(json_file, "r", encoding="utf-8") as f:
        return json.load(f)


def read_image(local_path: Path, slug: str, filename: str) -> bytes:
    """로컬 이미지 파일 읽기"""
    image_file = local_path / slug / filename
    with open(image_file, "rb") as f:
        return f.read()


# ============ Supabase Storage ============

def upload_image(slug: str, image_bytes: bytes) -> str | None:
    """Supabase Storage에 이미지 업로드 후 Public URL 반환

    저장 경로: cockat-images/cocktails/originals/{slug}.webp
    """
    try:
        path = f"{STORAGE_PATH}/{slug}.webp"

        # 기존 파일 있으면 삭제 (upsert)
        try:
            supabase.storage.from_(STORAGE_BUCKET).remove([path])
        except:
            pass  # 파일이 없으면 무시

        # 업로드
        supabase.storage.from_(STORAGE_BUCKET).upload(
            path,
            image_bytes,
            {"content-type": "image/webp"}
        )

        # Public URL 반환
        return supabase.storage.from_(STORAGE_BUCKET).get_public_url(path)
    except Exception as e:
        print(f"    ⚠️  이미지 업로드 실패 ({slug}): {e}")
        return None


# ============ 데이터 매핑 ============

def map_ingredient(ba_ing: dict) -> dict:
    """Bar Assistant → Supabase 재료 매핑"""
    return {
        "id": ba_ing["_id"],
        "name": ba_ing["name"],
        "name_ko": None,
        "category": ba_ing.get("category") or "uncategorized",  # NOT NULL 대응
        "description": ba_ing.get("description"),
        "strength": ba_ing.get("strength") or 0,  # NOT NULL 대응
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

def import_data(local_path: str, dry_run: bool = False, limit: int = None, skip_images: bool = False):
    """메인 Import 로직"""
    print("🍹 Bar Assistant 데이터 Import 시작\n")

    local_path = Path(local_path)
    if not local_path.exists():
        print(f"❌ 경로를 찾을 수 없습니다: {local_path}")
        return

    # 기존 데이터 확인
    existing_ings = {r["id"] for r in supabase.table("ingredients").select("id").execute().data}
    existing_cocktails = {r["id"] for r in supabase.table("cocktails").select("id").execute().data}
    print(f"기존 데이터: 재료 {len(existing_ings)}개, 칵테일 {len(existing_cocktails)}개")

    # 칵테일 목록 가져오기
    print(f"로컬 경로에서 칵테일 목록 가져오는 중: {local_path}")
    slugs = get_cocktail_slugs(local_path)
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
    for i, slug in enumerate(slugs):
        try:
            print(f"[{i+1}/{len(slugs)}] {slug}...", end=" ")

            data = get_cocktail_data(local_path, slug)
            recipe = data  # v5에서는 recipe wrapper 없음

            # 재료 수집 (중복 제거) - recipe 안에 ingredients 있음
            for ing in recipe.get("ingredients", []):
                if ing["_id"] not in all_ingredients:
                    all_ingredients[ing["_id"]] = map_ingredient(ing)

            # 칵테일 수집
            if recipe["_id"] not in existing_cocktails:
                image_url = None

                # 이미지 처리
                if not skip_images and recipe.get("images"):
                    first_image = recipe["images"][0]
                    # file:///filename.jpg 형식에서 파일명 추출
                    filename = first_image["uri"].replace("file:///", "")

                    if not dry_run:
                        image_bytes = read_image(local_path, slug, filename)
                        image_url = upload_image(slug, image_bytes)
                        if image_url:
                            uploaded_images += 1
                            print("📷", end=" ")

                all_cocktails.append(map_cocktail(recipe, image_url))

                # 칵테일-재료 관계
                for idx, ing in enumerate(recipe.get("ingredients", [])):
                    all_cocktail_ings.append(
                        map_cocktail_ingredient(recipe["_id"], ing, idx)
                    )
                    # 대체 재료 (객체 배열에서 _id 추출)
                    for sub in ing.get("substitutes", []):
                        sub_id = sub["_id"] if isinstance(sub, dict) else sub
                        all_substitutes.append({
                            "ingredient_id": ing["_id"],
                            "substitute_id": sub_id,
                        })

                print("✓")
            else:
                print("(skip - exists)")

        except Exception as e:
            print(f"✗ ERROR: {e}")

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
        print(f"\n🔄 대체 재료 Insert 중...")
        for i in range(0, len(all_substitutes), 100):
            batch = all_substitutes[i:i+100]
            try:
                supabase.table("ingredient_substitutes").insert(batch).execute()
            except Exception as e:
                print(f"    ⚠️  일부 대체 재료 실패: {e}")
        print(f"  ✓ {len(all_substitutes)}개 시도")

    print("\n✅ Import 완료!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bar Assistant 데이터 Import (로컬 모드)")
    parser.add_argument("--local", required=True, help="로컬 cocktails 디렉토리 경로")
    parser.add_argument("--dry-run", action="store_true", help="실제 DB 변경 없이 테스트")
    parser.add_argument("--limit", type=int, help="처리할 칵테일 수 제한")
    parser.add_argument("--skip-images", action="store_true", help="이미지 업로드 건너뛰기")
    args = parser.parse_args()

    import_data(
        local_path=args.local,
        dry_run=args.dry_run,
        limit=args.limit,
        skip_images=args.skip_images
    )
