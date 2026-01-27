#!/usr/bin/env python3
"""칵테일 이미지를 Supabase Storage에 업로드하고 DB를 업데이트하는 스크립트"""

import os
import csv
from pathlib import Path
from io import BytesIO
from PIL import Image
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Config
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_ANON_KEY")
STORAGE_BUCKET = "cockat-images"
STORAGE_PATH_ORIGINAL = "cocktails/originals"
STORAGE_PATH_THUMBNAIL = "cocktails/thumbnails"

# Paths
SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR.parent / "data"
IMAGES_DIR = DATA_DIR / "images" / "cocktails"
CSV_FILE = DATA_DIR / "cocktail_update_plan.csv"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


def load_image(filename: str) -> bytes:
    """로컬 파일에서 이미지 로드"""
    filepath = IMAGES_DIR / filename
    with open(filepath, "rb") as f:
        return f.read()


def convert_to_webp(image_bytes: bytes, max_size: int = 800) -> bytes:
    """이미지를 WebP로 변환 및 리사이즈"""
    img = Image.open(BytesIO(image_bytes))

    # RGBA to RGB if needed
    if img.mode in ('RGBA', 'P'):
        img = img.convert('RGB')

    # Resize maintaining aspect ratio
    img.thumbnail((max_size, max_size * 2), Image.Resampling.LANCZOS)

    # Save as WebP
    output = BytesIO()
    img.save(output, format='WEBP', quality=85)
    return output.getvalue()


def create_thumbnail(image_bytes: bytes, size: int = 200) -> bytes:
    """썸네일 생성"""
    img = Image.open(BytesIO(image_bytes))

    # RGBA to RGB if needed
    if img.mode in ('RGBA', 'P'):
        img = img.convert('RGB')

    # Resize for thumbnail
    img.thumbnail((size, size * 2), Image.Resampling.LANCZOS)

    # Save as WebP
    output = BytesIO()
    img.save(output, format='WEBP', quality=75)
    return output.getvalue()


def upload_image(cocktail_id: str, image_bytes: bytes, storage_path: str) -> str | None:
    """Supabase Storage에 이미지 업로드 후 Public URL 반환"""
    try:
        path = f"{storage_path}/{cocktail_id}.webp"

        # 기존 파일 있으면 삭제 (upsert)
        try:
            supabase.storage.from_(STORAGE_BUCKET).remove([path])
        except:
            pass

        # 업로드
        supabase.storage.from_(STORAGE_BUCKET).upload(
            path,
            image_bytes,
            {"content-type": "image/webp"}
        )

        # Public URL 반환
        return supabase.storage.from_(STORAGE_BUCKET).get_public_url(path)
    except Exception as e:
        print(f"    ⚠️  이미지 업로드 실패 ({cocktail_id}): {e}")
        return None


def insert_cocktail(row: dict):
    """새 칵테일 INSERT"""
    data = {
        "id": row["cocktail_id"],
        "name": row["name"],
        "name_ko": row.get("name_ko") or None,
        "glass": row.get("glass") or None,
        "method": row.get("method") or None,
        "abv": float(row["abv"]) if row.get("abv") else None,
        "instructions": row.get("instructions") or "TBD",
    }
    supabase.table("cocktails").insert(data).execute()


def update_cocktail_images(cocktail_id: str, image_url: str, thumbnail_url: str):
    """칵테일 이미지 URL 업데이트"""
    supabase.table("cocktails").update({
        "image_url": image_url,
        "thumbnail_url": thumbnail_url
    }).eq("id", cocktail_id).execute()


def main():
    print("🍸 칵테일 이미지 업로드 시작\n")

    # CSV 파일 읽기
    with open(CSV_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    for row in rows:
        action = row["action"]
        cocktail_id = row["cocktail_id"]
        image_file = row["image_file"]

        print(f"{'➕' if action == 'INSERT' else '🔄'} {cocktail_id}")

        try:
            # 1. INSERT인 경우 칵테일 먼저 생성
            if action == "INSERT":
                insert_cocktail(row)
                print(f"   ✓ 칵테일 INSERT 완료")

            # 2. 이미지 로드
            image_bytes = load_image(image_file)
            print(f"   ✓ 이미지 로드 ({len(image_bytes) / 1024:.1f} KB)")

            # 3. WebP 변환
            webp_bytes = convert_to_webp(image_bytes)
            print(f"   ✓ WebP 변환 ({len(webp_bytes) / 1024:.1f} KB)")

            # 4. 썸네일 생성
            thumb_bytes = create_thumbnail(image_bytes)
            print(f"   ✓ 썸네일 생성 ({len(thumb_bytes) / 1024:.1f} KB)")

            # 5. 이미지 업로드
            image_url = upload_image(cocktail_id, webp_bytes, STORAGE_PATH_ORIGINAL)
            thumbnail_url = upload_image(cocktail_id, thumb_bytes, STORAGE_PATH_THUMBNAIL)

            if image_url and thumbnail_url:
                print(f"   ✓ Storage 업로드 완료")

                # 6. DB 업데이트
                update_cocktail_images(cocktail_id, image_url, thumbnail_url)
                print(f"   ✓ DB 업데이트 완료\n")
            else:
                print(f"   ✗ 업로드 실패\n")

        except Exception as e:
            print(f"   ✗ 오류: {e}\n")

    print("🎉 완료!")


if __name__ == "__main__":
    main()
