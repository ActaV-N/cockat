#!/usr/bin/env python3
"""Featured 칵테일 이미지를 Unsplash에서 다운로드하여 Supabase에 업로드하는 스크립트"""

import os
import requests
from io import BytesIO
from PIL import Image
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Config
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_ANON_KEY")
STORAGE_BUCKET = "cockat-images"
STORAGE_PATH = "cocktails/originals"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Featured cocktails with Unsplash image URLs (free to use)
# Using direct Unsplash photo URLs
FEATURED_COCKTAILS = {
    "negroni": "https://images.unsplash.com/photo-1609951651556-5334e2706168?w=800",
    "mojito": "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=800",
    "margarita": "https://images.unsplash.com/photo-1556855810-ac404aa91e85?w=800",
    "old-fashioned": "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800",
    "espresso-martini": "https://images.unsplash.com/photo-1545438102-799c3991ffb2?w=800",
    "cosmopolitan": "https://images.unsplash.com/photo-1587223962930-cb7f31384c19?w=800",
    "aperol-spritz": "https://images.unsplash.com/photo-1560512823-829485b8bf24?w=800",
    "moscow-mule": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=800",
}


def download_image(url: str) -> bytes:
    """URL에서 이미지 다운로드"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    }
    resp = requests.get(url, headers=headers, timeout=30)
    resp.raise_for_status()
    return resp.content


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


def upload_image(slug: str, image_bytes: bytes) -> str | None:
    """Supabase Storage에 이미지 업로드 후 Public URL 반환"""
    try:
        path = f"{STORAGE_PATH}/{slug}.webp"

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
        print(f"    ⚠️  이미지 업로드 실패 ({slug}): {e}")
        return None


def update_cocktail_image(cocktail_id: str, image_url: str):
    """칵테일 image_url 업데이트"""
    supabase.table("cocktails").update({"image_url": image_url}).eq("id", cocktail_id).execute()


def main():
    print("🍸 Featured 칵테일 이미지 업로드 시작\n")

    for slug, url in FEATURED_COCKTAILS.items():
        print(f"📥 {slug} 다운로드 중...")
        try:
            # 다운로드
            image_bytes = download_image(url)
            print(f"   ✓ 다운로드 완료 ({len(image_bytes) / 1024:.1f} KB)")

            # WebP 변환
            webp_bytes = convert_to_webp(image_bytes)
            print(f"   ✓ WebP 변환 완료 ({len(webp_bytes) / 1024:.1f} KB)")

            # 업로드
            public_url = upload_image(slug, webp_bytes)
            if public_url:
                print(f"   ✓ 업로드 완료")

                # DB 업데이트
                update_cocktail_image(slug, public_url)
                print(f"   ✓ DB 업데이트 완료: {public_url}\n")
            else:
                print(f"   ✗ 업로드 실패\n")

        except Exception as e:
            print(f"   ✗ 오류: {e}\n")

    print("🎉 완료!")


if __name__ == "__main__":
    main()
