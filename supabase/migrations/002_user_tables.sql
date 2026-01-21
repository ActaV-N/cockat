-- Phase 2: 회원 연동 테이블
-- Run this in Supabase SQL Editor or via MCP

-- 회원 보유 상품
CREATE TABLE IF NOT EXISTS user_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- 회원 선택 재료 (직접 선택, fallback)
CREATE TABLE IF NOT EXISTS user_ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, ingredient_id)
);

-- 회원 즐겨찾기
CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cocktail_id TEXT NOT NULL REFERENCES cocktails(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, cocktail_id)
);

-- RLS 정책 활성화
ALTER TABLE user_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 사용자는 자신의 데이터만 접근 가능
CREATE POLICY "Users can manage own products" ON user_products
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own ingredients" ON user_ingredients
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own favorites" ON user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_user_products_user ON user_products(user_id);
CREATE INDEX IF NOT EXISTS idx_user_ingredients_user ON user_ingredients(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user ON user_favorites(user_id);
