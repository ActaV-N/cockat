# Database Schema Documentation

Cockat 앱의 Supabase 데이터베이스 스키마 문서입니다.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           COCKTAIL DOMAIN                                │
│  ┌─────────────┐       ┌─────────────────────┐                          │
│  │  cocktails  │──────<│ cocktail_ingredients │>──────┐                 │
│  │   (613)     │       │       (2735)         │       │                 │
│  └─────────────┘       └─────────────────────┘       │                 │
│         │                                             │                 │
│         │                                             ▼                 │
│         │              ┌─────────────────────────────────────────┐      │
│         │              │            INGREDIENT DOMAIN            │      │
│         │              │  ┌─────────────┐   ┌──────────────────┐ │      │
│         │              │  │ ingredients │──<│ ingredient_subs  │ │      │
│         │              │  │    (261)    │   │       (6)        │ │      │
│         │              │  └──────┬──────┘   └──────────────────┘ │      │
│         │              │         │                               │      │
│         │              │         │  ┌───────────────────────┐   │      │
│         │              │         └──│ ingredient_misc_map   │   │      │
│         │              │            │         (25)          │   │      │
│         │              │            └───────────┬───────────┘   │      │
│         │              └────────────────────────┼───────────────┘      │
│         │                                       │                       │
└─────────┼───────────────────────────────────────┼───────────────────────┘
          │                                       │
          │              ┌────────────────────────┼───────────────────────┐
          │              │       PRODUCT DOMAIN   │                       │
          │              │  ┌─────────────┐       │                       │
          │              │  │  products   │───────┘ (ingredient_id FK)    │
          │              │  │    (110)    │                               │
          │              │  └─────────────┘                               │
          │              └────────────────────────────────────────────────┘
          │
          │              ┌────────────────────────────────────────────────┐
          │              │       MISC ITEM DOMAIN                         │
          │              │  ┌─────────────┐                               │
          │              │  │ misc_items  │                               │
          │              │  │    (48)     │                               │
          │              │  └─────────────┘                               │
          │              └────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            USER DOMAIN                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │
│  │ user_favorites  │  │  user_products  │  │   user_preferences      │  │
│  │      (1)        │  │      (38)       │  │         (1)             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐                               │
│  │ user_ingredients│  │ user_misc_items │                               │
│  │      (0)        │  │      (28)       │                               │
│  └─────────────────┘  └─────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Cocktail Domain

칵테일과 레시피 관련 테이블입니다.

### 1.1 `cocktails`

칵테일 마스터 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | text | NO | - | Primary Key (slug 형식) |
| `name` | text | NO | - | 영문 이름 |
| `name_ko` | text | YES | - | 한국어 이름 |
| `description` | text | YES | - | 영문 설명 |
| `description_ko` | text | YES | - | 한국어 설명 |
| `instructions` | text | NO | - | 영문 만드는 방법 |
| `instructions_ko` | text | YES | - | 한국어 만드는 방법 |
| `garnish` | text | YES | - | 영문 가니시 |
| `garnish_ko` | text | YES | - | 한국어 가니시 |
| `glass` | text | YES | - | 사용하는 잔 종류 |
| `method` | text | YES | - | 제조 방법 (Stir, Shake 등) |
| `abv` | numeric | YES | - | 알코올 도수 |
| `tags` | text[] | YES | `'{}'` | 태그 배열 |
| `image_url` | text | YES | - | 이미지 URL |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 613 rows

**RLS**: Enabled

---

### 1.2 `cocktail_ingredients`

칵테일-재료 매핑 테이블입니다 (N:M 관계).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto | Primary Key |
| `cocktail_id` | text | NO | - | FK → cocktails.id |
| `ingredient_id` | text | NO | - | FK → ingredients.id |
| `amount` | numeric | YES | - | 양 |
| `units` | text | YES | - | 단위 (ml, oz, dash 등) |
| `sort_order` | integer | YES | `0` | 정렬 순서 |
| `is_optional` | boolean | YES | `false` | 선택 재료 여부 |
| `note` | text | YES | - | 추가 메모 |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 2,735 rows

**Foreign Keys**:
- `cocktail_id` → `cocktails.id`
- `ingredient_id` → `ingredients.id`

---

## 2. Ingredient Domain

재료 관련 테이블입니다.

### 2.1 `ingredients`

재료 마스터 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | text | NO | - | Primary Key (slug 형식) |
| `name` | text | NO | - | 영문 이름 |
| `name_ko` | text | YES | - | 한국어 이름 |
| `category` | text | NO | - | 카테고리 |
| `description` | text | YES | - | 설명 |
| `strength` | numeric | YES | `0` | 알코올 강도 |
| `origin` | text | YES | - | 원산지 |
| `image_url` | text | YES | - | 이미지 URL |
| `thumbnail_url` | text | YES | - | 썸네일 URL |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 261 rows

**Categories**: spirits, liqueurs, bitters, mixers, syrups, juices, uncategorized 등

---

### 2.2 `ingredient_substitutes`

재료 대체품 매핑 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto | Primary Key |
| `ingredient_id` | text | NO | - | FK → ingredients.id (원본) |
| `substitute_id` | text | NO | - | FK → ingredients.id (대체품) |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 6 rows

---

### 2.3 `ingredient_misc_mapping`

재료-기타아이템 매핑 테이블입니다. 칵테일 레시피의 재료(ingredient)가 misc_item과 연결되는 경우 사용됩니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `ingredient_id` | text | NO | - | PK, FK → ingredients.id |
| `misc_item_id` | text | NO | - | FK → misc_items.id |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 25 rows

**Use Case**: 예를 들어 레시피에 "lime juice"가 있을 때, 사용자가 "lime" misc_item을 가지고 있으면 만들 수 있다고 판단하는 데 사용됩니다.

---

## 3. Product Domain

실제 구매 가능한 제품 관련 테이블입니다.

### 3.1 `products`

제품 마스터 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | text | NO | - | Primary Key (slug 형식) |
| `name` | text | NO | - | 영문 이름 |
| `name_ko` | text | YES | - | 한국어 이름 |
| `brand` | text | YES | - | 브랜드 |
| `ingredient_id` | text | YES | - | FK → ingredients.id |
| `description` | text | YES | - | 영문 설명 |
| `description_ko` | text | YES | - | 한국어 설명 |
| `country` | text | YES | - | 원산지 국가 |
| `volume_ml` | integer | YES | - | 용량 (ml) |
| `abv` | numeric | YES | - | 알코올 도수 |
| `image_url` | text | YES | - | 이미지 URL |
| `thumbnail_url` | text | YES | - | 썸네일 URL |
| `barcode` | text | YES | - | 바코드 |
| `external_id` | text | YES | - | 외부 ID |
| `data_source` | text | YES | `'manual'` | 데이터 출처 |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |
| `updated_at` | timestamptz | YES | `now()` | 수정 시간 |

**Statistics**: 110 rows

**Relationship**: 하나의 Product는 하나의 Ingredient에 매핑됩니다. 예: "Tanqueray London Dry Gin" → "gin" ingredient

---

## 4. Misc Item Domain

얼음, 가니시, 신선 재료 등 기타 아이템 관련 테이블입니다.

### 4.1 `misc_items`

기타 아이템 마스터 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | text | NO | - | Primary Key (slug 형식) |
| `name` | text | NO | - | 영문 이름 |
| `name_ko` | text | YES | - | 한국어 이름 |
| `category` | text | NO | - | 카테고리 |
| `description` | text | YES | - | 설명 |
| `image_url` | text | YES | - | 이미지 URL |
| `thumbnail_url` | text | YES | - | 썸네일 URL |
| `sort_order` | integer | YES | `0` | 정렬 순서 |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 48 rows

**Categories**:
- `ice`: 얼음 종류 (ice cubes, crushed ice 등)
- `garnish`: 가니시 (olive, cherry 등)
- `fresh`: 신선 재료 (lime, lemon, mint 등)
- `dairy`: 유제품 (cream, milk 등)
- `syrup`: 시럽 (simple syrup, grenadine 등)
- `mixer`: 믹서 (tonic water, soda water 등)

---

## 5. User Domain

사용자 데이터 관련 테이블입니다. 모든 테이블은 `auth.users`와 연결됩니다.

### 5.1 `user_preferences`

사용자 설정 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `user_id` | uuid | NO | - | PK, FK → auth.users.id |
| `unit_system` | text | NO | `'ml'` | 단위 시스템 (ml, oz, parts) |
| `onboarding_completed` | boolean | NO | `false` | 온보딩 완료 여부 |
| `locale` | text | YES | `'en'` | 언어 설정 |
| `theme` | text | YES | `'system'` | 테마 (light, dark, system) |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |
| `updated_at` | timestamptz | YES | `now()` | 수정 시간 |

**Statistics**: 1 row

---

### 5.2 `user_favorites`

사용자 즐겨찾기 칵테일 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto | Primary Key |
| `user_id` | uuid | NO | - | FK → auth.users.id |
| `cocktail_id` | text | NO | - | FK → cocktails.id |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 1 row

**Unique Constraint**: (user_id, cocktail_id)

---

### 5.3 `user_products`

사용자 소유 제품 테이블입니다 (My Bar).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto | Primary Key |
| `user_id` | uuid | NO | - | FK → auth.users.id |
| `product_id` | text | NO | - | FK → products.id |
| `quantity` | integer | YES | `1` | 수량 |
| `note` | text | YES | - | 메모 |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 38 rows

---

### 5.4 `user_ingredients`

사용자 소유 재료 테이블입니다 (Legacy, 현재 미사용).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto | Primary Key |
| `user_id` | uuid | NO | - | FK → auth.users.id |
| `ingredient_id` | text | NO | - | FK → ingredients.id |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 0 rows

**Note**: 현재는 `user_products`를 통해 재료를 관리합니다.

---

### 5.5 `user_misc_items`

사용자 소유 기타 아이템 테이블입니다.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto | Primary Key |
| `user_id` | uuid | NO | - | FK → auth.users.id |
| `misc_item_id` | text | NO | - | FK → misc_items.id |
| `created_at` | timestamptz | YES | `now()` | 생성 시간 |

**Statistics**: 28 rows

---

## Row Level Security (RLS)

모든 테이블에 RLS가 활성화되어 있습니다.

### Policy 패턴

**마스터 테이블** (cocktails, ingredients, products, misc_items):
- `SELECT`: 모든 사용자에게 허용 (anon, authenticated)
- `INSERT/UPDATE/DELETE`: service_role만 허용

**사용자 테이블** (user_*):
- `SELECT`: 본인 데이터만 조회 가능 (`auth.uid() = user_id`)
- `INSERT`: 본인 데이터만 추가 가능
- `UPDATE`: 본인 데이터만 수정 가능
- `DELETE`: 본인 데이터만 삭제 가능

---

## Entity Relationship Summary

```
cocktails (1) ──────< cocktail_ingredients >────── (N) ingredients
                                                        │
                                                        │ (1)
                                                        ▼
                                                    products (N)
                                                        │
                                                        │ (N)
                                                        ▼
                                                  user_products
                                                        │
                                                        │ (N)
                                                        ▼
                                                  auth.users (1)
                                                        │
          ┌─────────────────┬───────────────────────────┼───────────────────┐
          ▼                 ▼                           ▼                   ▼
    user_favorites    user_misc_items          user_preferences    user_ingredients
```

---

## Data Statistics

| Domain | Table | Rows |
|--------|-------|------|
| Cocktail | cocktails | 613 |
| Cocktail | cocktail_ingredients | 2,735 |
| Ingredient | ingredients | 261 |
| Ingredient | ingredient_substitutes | 6 |
| Ingredient | ingredient_misc_mapping | 25 |
| Product | products | 110 |
| Misc | misc_items | 48 |
| User | user_preferences | 1 |
| User | user_favorites | 1 |
| User | user_products | 38 |
| User | user_misc_items | 28 |
| User | user_ingredients | 0 |
