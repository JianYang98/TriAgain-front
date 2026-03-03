# 프론트엔드 인증 플로우

> 백엔드 인증 설계는 `docs/user.md` 참고. 이 문서는 **Flutter 프론트엔드 구현** 중심.

---

## 1. 유저 플로우 시퀀스

### 1.1 전체 분기

```
카카오 SDK 로그인
    │
    ├─ kakaoAccessToken 획득
    │
    ├─ POST /auth/kakao ─────────────────────────────┐
    │                                                  │
    │         ┌── isNewUser: false ──┐    ┌── isNewUser: true ──┐
    │         │                      │    │                      │
    │    accessToken 저장 (메모리)    │    │  kakaoAccessToken    │
    │    refreshToken 저장 (Storage)  │    │  kakaoId             │  임시 저장
    │    authUser 저장               │    │  kakaoProfile        │  (메모리만)
    │         │                      │    │                      │
    │    context.go('/home')         │    │  context.go('/onboarding')
    │                                │    │         │
    │                                │    │    약관 동의 + 닉네임 입력
    │                                │    │         │
    │                                │    │    POST /auth/signup
    │                                │    │         │
    │                                │    │    accessToken 저장 (메모리)
    │                                │    │    refreshToken 저장 (Storage)
    │                                │    │    kakao 임시 데이터 즉시 null 처리!
    │                                │    │         │
    │                                │    │    context.go('/home')
    │                                │    └──────────┘
    └────────────────────────────────┘
```

### 1.2 핵심 포인트

- **기존 유저**: `POST /auth/kakao` 한 번으로 토큰 즉시 발급 → 홈 이동
- **신규 유저**: `POST /auth/kakao`에서는 **토큰 미발급** → 온보딩 완료 후 `POST /auth/signup`에서 토큰 발급
- 신규 유저는 회원가입 완료 전까지 kakaoAccessToken만 메모리에 임시 보관

---

## 2. 토큰 관리 규칙

| 토큰 | 저장 위치 | Provider | 주의사항 |
|------|----------|----------|---------|
| accessToken | **메모리만** | `authTokenProvider` | SecureStorage 저장 **금지** |
| refreshToken | **flutter_secure_storage** | `secureStorageProvider` | 앱 시작 시 복원 → 자동 로그인 |
| kakaoAccessToken | **메모리만** | `kakaoAccessTokenProvider` | 온보딩 완료 즉시 null 처리. SecureStorage **절대 금지** |

### 왜 이렇게?

- **accessToken**: 30분 유효, 탈취 시 피해 최소화를 위해 메모리만 사용. 앱 종료 시 자연 소멸.
- **refreshToken**: 14일 유효, 앱 재시작 시 자동 로그인을 위해 SecureStorage에 영속 저장.
- **kakaoAccessToken**: 백엔드 전달 용도로만 사용. 회원가입 완료 즉시 폐기.

---

## 3. 화면 전환 흐름

```
/login ──(카카오 로그인)──► /home           (기존 유저)
/login ──(카카오 로그인)──► /onboarding ──► /home  (신규 유저)
/onboarding ──(전문 보기)──► /terms/service  (push)
/onboarding ──(전문 보기)──► /terms/privacy  (push)
/terms/:type ──(뒤로가기)──► /onboarding     (pop)
```

### 관련 파일

| 화면 | 파일 | 라우트 |
|------|------|--------|
| 로그인 | `lib/features/auth/screens/login_screen.dart` | `/login` |
| 온보딩 | `lib/features/auth/screens/onboarding_screen.dart` | `/onboarding` |
| 약관 전문 | `lib/features/auth/screens/terms_detail_screen.dart` | `/terms/:type` |

---

## 4. 자동 로그인 (앱 시작)

`lib/main.dart`에서 앱 시작 시 처리:

```
앱 시작
  │
  ├─ SecureStorage에서 refreshToken 읽기
  │
  ├─ refreshToken 없음 → initialLocation = '/login'
  │
  ├─ refreshToken 있음
  │     │
  │     ├─ POST /auth/refresh 호출
  │     │
  │     ├─ 성공 → accessToken 메모리 저장 → initialLocation = '/home'
  │     │
  │     └─ 실패 → refreshToken 삭제 → initialLocation = '/login'
  │
  └─ runApp(initialLocation)
```

- `UncontrolledProviderScope` + `ProviderContainer`로 앱 시작 전 provider 초기화
- `createRouter(initialLocation:)`로 동적 초기 경로 설정

---

## 5. 401 Interceptor (토큰 자동 갱신)

`lib/core/network/api_client.dart`의 Dio interceptor:

```
API 호출 → 401 응답
  │
  ├─ /auth/* 경로? → 그대로 에러 전달 (무한루프 방지)
  │
  ├─ 이미 refresh 중? → 그대로 에러 전달
  │
  ├─ AuthService.refreshAccessToken() 호출
  │     │
  │     ├─ 성공 → 새 accessToken 저장 → 원래 요청 재시도
  │     │
  │     └─ 실패 → 로그아웃 처리
  │              ├─ authTokenProvider = null
  │              ├─ authUserIdProvider = null
  │              ├─ authUserProvider = null
  │              └─ SecureStorage refreshToken 삭제
  │
  └─ handler.reject(error)
```

---

## 6. 온보딩 상세

### 6.1 닉네임 기본값 처리

카카오 프로필 닉네임에서 기본값 생성:

1. 허용 문자만 필터링: `[가-힣a-zA-Z0-9_]` 이외 제거
2. 12자 초과 시 12자로 자르기
3. 필터링 결과가 2자 미만이면 빈값 (사용자 직접 입력 유도)

### 6.2 가입 조건

- ☑ 서비스 이용약관 동의 (필수)
- ☑ 개인정보 처리방침 동의 (필수)
- 닉네임 유효: `^[가-힣a-zA-Z0-9_]{2,12}$`

세 조건 모두 충족 시 **가입하기 버튼 활성화** (`AppColors.main`)

### 6.3 가입 완료 후 처리

```dart
// 토큰 저장
ref.read(authTokenProvider.notifier).state = result.accessToken;
ref.read(authUserIdProvider.notifier).state = result.user.id;
await saveRefreshToken(storage, result.refreshToken);

// 임시 데이터 즉시 폐기!
ref.read(kakaoAccessTokenProvider.notifier).state = null;
ref.read(kakaoIdProvider.notifier).state = null;
ref.read(kakaoProfileProvider.notifier).state = null;

context.go('/home');
```

---

## 7. API 엔드포인트 요약

### POST /auth/kakao — 카카오 로그인

```
요청: { kakaoAccessToken: "..." }

기존 유저 응답:
{ isNewUser: false, accessToken, refreshToken, accessTokenExpiresIn, user: { id, nickname, profileImageUrl } }

신규 유저 응답:
{ isNewUser: true, kakaoId, kakaoProfile: { nickname, email, profileImageUrl } }
```

### POST /auth/signup — 회원가입

```
요청: { kakaoAccessToken, kakaoId, nickname, termsAgreed: true }
응답: { accessToken, refreshToken, accessTokenExpiresIn, user: { id, nickname, profileImageUrl } }
```

### POST /auth/refresh — 토큰 갱신

```
요청: { refreshToken: "..." }
응답: { accessToken, accessTokenExpiresIn }
```

> 상세 API 명세 및 에러 코드는 `docs/user.md` 참고.

---

## 8. 관련 파일 목록

| 파일 | 역할 |
|------|------|
| `lib/models/auth.dart` | 인증 응답 모델 (KakaoLoginResponse, AuthUser, SignupResponse 등) |
| `lib/providers/auth_provider.dart` | 인증 상태 Provider + SecureStorage 헬퍼 |
| `lib/services/auth_service.dart` | 인증 API 호출 (login, signup, refresh) — 자체 Dio 인스턴스 사용 |
| `lib/core/network/api_client.dart` | Bearer 토큰 자동 주입 + 401 interceptor |
| `lib/features/auth/screens/login_screen.dart` | 카카오 로그인 버튼 + 테스트 버튼 |
| `lib/features/auth/screens/onboarding_screen.dart` | 약관 동의 + 닉네임 입력 + 가입 |
| `lib/features/auth/screens/terms_detail_screen.dart` | 약관 전문 보기 (임시 플레이스홀더) |
| `lib/app/router.dart` | GoRouter 라우트 정의 (createRouter 함수) |
| `lib/main.dart` | 앱 시작 시 자동 로그인 처리 |

---

## 9. 개발 모드 (테스트 유저)

`kDebugMode`에서만 표시되는 테스트 버튼:

- **Test User 1** (`test-user-1`): authUserIdProvider 직접 설정 → 홈 이동
- **Test User 2** (`test-user-2`): 동일
- **커스텀 로그인**: userId 직접 입력

테스트 유저는 `accessToken` 없이 `X-User-Id` 헤더로 인증 (ApiClient에서 Bearer 토큰 없을 때 kDebugMode 폴백).
