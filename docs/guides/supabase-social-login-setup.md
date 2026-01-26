# Supabase 소셜 로그인 연동 가이드

Cockat 앱의 Google 및 Apple 로그인 연동을 위한 설정 가이드입니다.

## 목차
1. [사전 요구사항](#사전-요구사항)
2. [Supabase 대시보드 설정](#supabase-대시보드-설정)
3. [Google 로그인 설정](#google-로그인-설정)
4. [Apple 로그인 설정](#apple-로그인-설정)
5. [iOS 앱 설정](#ios-앱-설정)
6. [Android 앱 설정](#android-앱-설정)
7. [테스트 및 검증](#테스트-및-검증)
8. [문제 해결](#문제-해결)

---

## 사전 요구사항

- Supabase 프로젝트 생성 완료
- Apple Developer 계정 (Apple 로그인용, 연 $99)
- Google Cloud 프로젝트 (Google 로그인용, 무료)
- Xcode 설치 (iOS 설정용)

### 현재 앱 설정값
```
Bundle ID: io.supabase.cockat
Redirect URL: io.supabase.cockat://login-callback
```

---

## Supabase 대시보드 설정

### 1. Authentication 설정 페이지 접속
1. [Supabase Dashboard](https://supabase.com/dashboard) 로그인
2. 프로젝트 선택
3. 좌측 메뉴 **Authentication** → **Providers**

### 2. Site URL 설정
1. **Authentication** → **URL Configuration**
2. **Site URL** 설정: `io.supabase.cockat://login-callback`
3. **Redirect URLs**에 추가:
   - `io.supabase.cockat://login-callback`
   - `io.supabase.cockat://**` (와일드카드)

---

## Google 로그인 설정

### Step 1: Google Cloud Console 설정

#### 1.1 프로젝트 생성/선택
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택

#### 1.2 OAuth 동의 화면 설정
1. **APIs & Services** → **OAuth consent screen**
2. User Type: **External** 선택
3. 앱 정보 입력:
   - **App name**: Cockat
   - **User support email**: 본인 이메일
   - **Developer contact email**: 본인 이메일
4. **Scopes** 단계: 기본값 유지 (email, profile, openid)
5. **Test users**: 테스트용 이메일 추가 (개발 중일 때)
6. **PUBLISH APP** 클릭 (프로덕션 배포 시)

#### 1.3 OAuth 2.0 Client ID 생성

##### Web Client (Supabase용)
1. **APIs & Services** → **Credentials** → **CREATE CREDENTIALS** → **OAuth client ID**
2. Application type: **Web application**
3. Name: `Cockat Web Client`
4. **Authorized redirect URIs** 추가:
   ```
   https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback
   ```
   > Supabase Dashboard → Settings → API에서 Project URL 확인
5. **CREATE** 클릭
6. **Client ID**와 **Client Secret** 복사 (Supabase에 입력용)

##### iOS Client
1. **CREATE CREDENTIALS** → **OAuth client ID**
2. Application type: **iOS**
3. Name: `Cockat iOS`
4. **Bundle ID**: `io.supabase.cockat`
5. **CREATE** 클릭
6. **Client ID** 복사

##### Android Client
1. **CREATE CREDENTIALS** → **OAuth client ID**
2. Application type: **Android**
3. Name: `Cockat Android`
4. **Package name**: `io.supabase.cockat`
5. **SHA-1 certificate fingerprint** 입력:
   ```bash
   # Debug keystore (개발용)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # Release keystore (배포용)
   keytool -list -v -keystore <your-release-key.keystore> -alias <your-key-alias>
   ```
6. **CREATE** 클릭

### Step 2: Supabase에 Google Provider 설정

1. Supabase Dashboard → **Authentication** → **Providers**
2. **Google** 클릭하여 활성화
3. 입력:
   - **Client ID**: Web Client의 Client ID
   - **Client Secret**: Web Client의 Client Secret
4. **Save** 클릭

---

## Apple 로그인 설정

### Step 1: Apple Developer Console 설정

#### 1.1 App ID 설정
1. [Apple Developer Console](https://developer.apple.com/) 로그인
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. 앱의 App ID 선택 (또는 새로 생성)
4. **Capabilities** 섹션에서 **Sign In with Apple** 활성화
5. **Edit** 클릭 → **Enable as a primary App ID** 선택
6. **Save**

#### 1.2 Services ID 생성 (Web용)
1. **Identifiers** → **+** 버튼 → **Services IDs** 선택
2. Description: `Cockat Web Service`
3. Identifier: `io.supabase.cockat.web` (앱 Bundle ID와 달라야 함)
4. **Continue** → **Register**
5. 생성된 Services ID 클릭 → **Sign In with Apple** 체크
6. **Configure** 클릭:
   - **Primary App ID**: 앱의 App ID 선택
   - **Domains**: `<YOUR_SUPABASE_PROJECT_REF>.supabase.co`
   - **Return URLs**: `https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback`
7. **Save**

#### 1.3 Key 생성
1. **Keys** → **+** 버튼
2. Key Name: `Cockat Auth Key`
3. **Sign In with Apple** 체크 → **Configure**
4. Primary App ID: 앱의 App ID 선택
5. **Save** → **Continue** → **Register**
6. **Download** 클릭하여 `.p8` 파일 저장 (한 번만 다운로드 가능!)
7. **Key ID** 기록

### Step 2: Supabase에 Apple Provider 설정

1. Supabase Dashboard → **Authentication** → **Providers**
2. **Apple** 클릭하여 활성화
3. 입력:
   - **Client ID (Services ID)**: `io.supabase.cockat.web`
   - **Secret Key**: `.p8` 파일 내용 전체 복사
   - **Key ID**: Apple에서 발급받은 Key ID
   - **Team ID**: Apple Developer 계정의 Team ID
     > Membership 페이지 또는 우측 상단 계정에서 확인
4. **Save** 클릭

---

## iOS 앱 설정

### 1. URL Scheme 설정 (Info.plist)

`ios/Runner/Info.plist`에 추가:

```xml
<!-- Deep Link URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>io.supabase.cockat</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.cockat</string>
        </array>
    </dict>
</array>

<!-- Google Sign-In (선택사항 - 네이티브 Google 로그인용) -->
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

### 2. Associated Domains 설정 (Universal Links용, 선택)

Xcode에서:
1. Runner 타겟 선택
2. **Signing & Capabilities** 탭
3. **+ Capability** → **Associated Domains** 추가
4. 도메인 추가:
   ```
   applinks:<YOUR_SUPABASE_PROJECT_REF>.supabase.co
   ```

### 3. Sign In with Apple Capability 추가

Xcode에서:
1. Runner 타겟 선택
2. **Signing & Capabilities** 탭
3. **+ Capability** → **Sign In with Apple** 추가

---

## Android 앱 설정

### 1. Deep Link Intent Filter 설정

`android/app/src/main/AndroidManifest.xml`의 `<activity>` 태그 내에 추가:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.cockat"
        android:host="login-callback" />
</intent-filter>
```

### 2. 전체 AndroidManifest.xml 예시

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application ...>
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            ...>

            <!-- 기존 intent-filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- OAuth Callback용 Deep Link -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="io.supabase.cockat"
                    android:host="login-callback" />
            </intent-filter>

        </activity>
    </application>
</manifest>
```

---

## 테스트 및 검증

### 1. 로컬 테스트

```bash
# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android

# 실제 기기 (권장)
flutter run -d <device_id>
```

### 2. 테스트 체크리스트

#### Google 로그인
- [ ] 로그인 버튼 클릭 시 Google 로그인 페이지 표시
- [ ] Google 계정 선택/로그인 완료
- [ ] 앱으로 리다이렉트되어 로그인 완료
- [ ] Supabase Dashboard에서 사용자 생성 확인

#### Apple 로그인
- [ ] 로그인 버튼 클릭 시 Apple 로그인 시트 표시
- [ ] Face ID/Touch ID 또는 비밀번호 인증
- [ ] 이메일 공유/숨김 선택 화면 표시
- [ ] 앱으로 리다이렉트되어 로그인 완료
- [ ] Supabase Dashboard에서 사용자 생성 확인

### 3. Supabase 로그 확인

1. Supabase Dashboard → **Logs** → **Auth**
2. 로그인 시도 및 결과 확인
3. 에러 발생 시 상세 메시지 확인

---

## 문제 해결

### Google 로그인 문제

#### "redirect_uri_mismatch" 에러
- Google Cloud Console의 Authorized redirect URIs 확인
- Supabase 프로젝트 URL과 정확히 일치하는지 확인
- `https://`로 시작하는지 확인

#### "access_denied" 에러
- OAuth 동의 화면이 "Testing" 상태인 경우, 테스트 사용자로 등록되어 있는지 확인
- 프로덕션 배포 시 "PUBLISH APP" 완료 확인

#### iOS에서 로그인 후 앱으로 돌아오지 않음
- Info.plist의 URL Scheme 설정 확인
- Bundle ID가 정확한지 확인

### Apple 로그인 문제

#### "invalid_client" 에러
- Services ID (Client ID)가 정확한지 확인
- Secret Key가 `.p8` 파일 전체 내용인지 확인 (BEGIN/END 포함)
- Team ID와 Key ID가 정확한지 확인

#### "redirect_uri_mismatch" 에러
- Services ID의 Return URLs 설정 확인
- Supabase 콜백 URL과 정확히 일치하는지 확인

#### Xcode에서 "Sign In with Apple" capability 관련 에러
- Apple Developer 계정에서 App ID의 Sign In with Apple이 활성화되어 있는지 확인
- Provisioning Profile 재생성 필요할 수 있음

### 공통 문제

#### 로그인 후 앱으로 돌아오지 않음 (Android)
- AndroidManifest.xml의 intent-filter 확인
- `android:host`와 `android:scheme`이 정확한지 확인

#### 로그인은 되지만 사용자 정보가 없음
- Supabase Dashboard → Authentication → Users에서 확인
- 앱에서 `currentUserProvider` 상태 확인

---

## 참고 자료

### 공식 문서
- [Supabase Auth - Social Login](https://supabase.com/docs/guides/auth/social-login)
- [Supabase Auth - Google](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase Auth - Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Google Identity - OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)
- [Apple Developer - Sign In with Apple](https://developer.apple.com/sign-in-with-apple/)

### Flutter 패키지
- [supabase_flutter](https://pub.dev/packages/supabase_flutter)

---

## 설정 요약 체크리스트

### Google 로그인
- [ ] Google Cloud Console에서 OAuth 동의 화면 설정
- [ ] Web Client ID 생성 (Supabase용)
- [ ] iOS Client ID 생성
- [ ] Android Client ID 생성 (SHA-1 포함)
- [ ] Supabase에 Google Provider 활성화 및 Client ID/Secret 입력

### Apple 로그인
- [ ] App ID에서 Sign In with Apple 활성화
- [ ] Services ID 생성 및 도메인/Return URL 설정
- [ ] Key 생성 및 .p8 파일 다운로드
- [ ] Supabase에 Apple Provider 활성화 및 설정값 입력
- [ ] Xcode에서 Sign In with Apple capability 추가

### 앱 설정
- [ ] iOS: Info.plist에 URL Scheme 추가
- [ ] iOS: Sign In with Apple capability 추가
- [ ] Android: AndroidManifest.xml에 intent-filter 추가

### Supabase 설정
- [ ] Site URL 설정
- [ ] Redirect URLs에 앱 스킴 추가
