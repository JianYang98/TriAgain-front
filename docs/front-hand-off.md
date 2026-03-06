# TriAgain Frontend — AI 에이전트 인수인계 지시서

> **작성일**: 2026-03-04
> **프로젝트**: triagain-front (Flutter)
> **현재 브랜치**: `main`
> **현재 Phase**: Phase 2 (백엔드 API 연동 진행중)

---

## 1. 프로젝트 개요

**TriAgain — Start Small. Try Again.**

> "작심삼일도 괜찮아" — 3일 단위 챌린지 습관 형성 앱

- 소규모 크루(2~10명)가 함께 **3일 챌린지** 수행
- 실패해도 **자동으로 새 3일 챌린지** 시작 (리스타트 메커니즘)
- 크루장이 인증 방식 선택: **텍스트** / **사진 필수**
- 초대코드로 크루 참여

**디자인 기준**: iPhone 14 (390 x 844), 다크 테마 전용

---

## 2. 기술 스택 및 패키지

### 런타임
| 항목 | 버전 |
|------|------|
| Flutter | 3.16+ |
| Dart SDK | ^3.11.0 |

### 핵심 패키지 (pubspec.yaml)
```yaml
flutter_riverpod: ^2.6.1       # 상태관리
go_router: ^14.8.1              # 라우팅
dio: ^5.7.0                     # HTTP 클라이언트
image_picker: ^1.1.2            # 이미지 선택 (카메라/갤러리)
cached_network_image: ^3.4.1   # 네트워크 이미지 캐싱
google_fonts: ^6.2.1            # Noto Sans KR 폰트
kakao_flutter_sdk: ^1.9.6      # 카카오 로그인
sign_in_with_apple: ^6.1.0     # Apple 로그인 (iOS)
flutter_secure_storage: ^9.2.4 # refreshToken 안전 저장
share_plus: ^12.0.1             # 초대코드 공유
uuid: ^4.5.1                    # 멱등성 키 생성

# dev
riverpod_generator: ^2.6.3     # @riverpod 코드 생성
riverpod_annotation: ^2.6.1
build_runner: ^2.4.14
custom_lint: ^0.7.5
riverpod_lint: ^2.6.3
```

### 빌드 실행 방법
```bash
# 카카오 네이티브 키 주입 필수
flutter run --dart-define=KAKAO_NATIVE_KEY=<key>

# 코드 생성 (riverpod_generator)
dart run build_runner build --delete-conflicting-outputs
```

---

## 3. 폴더 구조 (실제 현황)

```
lib/
├── main.dart                          # 앱 진입점 + 자동 로그인 처리
├── app/
│   ├── router.dart                    # GoRouter 라우트 정의
│   └── theme.dart                     # AppTheme.darkTheme
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # AppColors (색상 토큰)
│   │   ├── app_text_styles.dart       # AppTextStyles
│   │   ├── app_sizes.dart             # AppSizes (패딩, 라디우스)
│   │   └── validation.dart            # nicknameRegex 등 유효성 정규식
│   └── network/
│       ├── api_client.dart            # ApiClient (Dio 래퍼 + 인터셉터)
│       ├── api_exception.dart         # ApiException
│       └── api_response.dart          # ApiResponse<T> 공통 응답 모델
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart      # 로그인 (카카오/Apple/테스트)
│   │       ├── onboarding_screen.dart # 신규유저 닉네임 입력 + 약관 동의
│   │       └── terms_detail_screen.dart # 약관 상세
│   ├── home/
│   │   ├── screens/home_screen.dart   # 크루 목록 + 프로그레스바
│   │   └── widgets/crew_card.dart     # 크루 카드 위젯
│   ├── crew/
│   │   ├── screens/
│   │   │   ├── create_crew_screen.dart   # 크루 만들기
│   │   │   ├── crew_success_screen.dart  # 생성 완료 + 초대코드
│   │   │   ├── crew_confirm_screen.dart  # 초대코드 입력 → 크루 참여
│   │   │   └── crew_detail_screen.dart   # 크루 상세 (탭 3개)
│   │   └── widgets/
│   │       ├── my_verification_tab.dart   # 나의 인증 탭
│   │       ├── member_status_tab.dart     # 참가자 현황 탭
│   │       ├── feed_tab.dart              # 인증 피드 탭
│   │       ├── verification_calendar.dart # 인증 달력 위젯
│   │       └── crew_info_bottom_sheet.dart# 크루 정보 바텀시트
│   ├── verification/
│   │   └── screens/verification_screen.dart # 인증하기 (사진+텍스트)
│   └── mypage/
│       └── screens/mypage_screen.dart # 마이페이지 (닉네임변경, 로그아웃)
├── models/
│   ├── auth.dart          # KakaoLoginResponse, AuthUser, SignupResponse, KakaoProfile
│   ├── crew.dart          # CrewSummary, CrewDetail, CrewMember, CreateCrewResult, JoinCrewResult
│   └── verification.dart  # FeedVerification, MyProgress, FeedResult, VerificationResult
├── providers/
│   ├── auth_provider.dart         # 인증 상태 (StateProvider들)
│   ├── crew_provider.dart         # crewListProvider, crewDetailProvider
│   └── verification_provider.dart # feedProvider, myVerificationDatesProvider
├── services/
│   ├── auth_service.dart          # AuthService (로그인/회원가입/토큰갱신)
│   ├── crew_service.dart          # CrewService (크루 CRUD)
│   ├── user_service.dart          # UserService (getMe, updateNickname)
│   └── verification_service.dart  # VerificationService (피드, 인증생성)
└── widgets/                       # 공통 위젯
    ├── app_button.dart
    ├── app_card.dart
    ├── app_input.dart
    └── toggle_selector.dart
```

---

## 4. 상태 관리 방식

### Riverpod 패턴

**인증 상태** (`lib/providers/auth_provider.dart`)
```dart
// 메모리 전용 — SecureStorage 저장 금지!
final authTokenProvider = StateProvider<String?>((ref) => null);   // JWT accessToken
final authUserIdProvider = StateProvider<String?>((ref) => null);  // userId
final authUserProvider = StateProvider<AuthUser?>((ref) => null);  // 유저 정보

// 온보딩 임시 (signup 후 즉시 null 처리 필수)
final kakaoAccessTokenProvider = StateProvider<String?>((ref) => null);
final kakaoIdProvider = StateProvider<String?>((ref) => null);
final kakaoProfileProvider = StateProvider<KakaoProfile?>((ref) => null);
final appleIdentityTokenProvider = StateProvider<String?>((ref) => null);
final appleUserIdProvider = StateProvider<String?>((ref) => null);
final appleProfileProvider = StateProvider<KakaoProfile?>((ref) => null);

// SecureStorage (refreshToken만 저장)
final secureStorageProvider = Provider<FlutterSecureStorage>(...)
```

**데이터 상태** (`lib/providers/`)
```dart
// 크루 목록/상세 — FutureProvider
final crewListProvider = FutureProvider<List<CrewSummary>>(...)
final crewDetailProvider = FutureProvider.family<CrewDetail, String>(...)

// 피드/나의 인증 날짜
final feedProvider = FutureProvider.family<FeedResult, String>(...)
final myVerificationDatesProvider = FutureProvider.family<Set<DateTime>, String>(...)
```

### 토큰 전략
| 토큰 | 저장 위치 | 이유 |
|------|-----------|------|
| accessToken | 메모리(`StateProvider`) | XSS/SecureStorage 성능 |
| refreshToken | `FlutterSecureStorage` | 앱 재시작 후 자동 로그인 |

### ApiClient 자동 토큰 갱신
- 모든 API 요청에 `Authorization: Bearer <accessToken>` 자동 주입
- 401 응답 → `POST /auth/refresh` 자동 호출 → 원래 요청 재시도
- refresh 실패 → 전체 로그아웃 처리 (토큰 삭제 + 캐시 invalidate)

---

## 5. 구현된 화면과 기능

### 라우트 맵
| 경로 | 화면 | 파라미터 |
|------|------|---------|
| `/login` | LoginScreen | - |
| `/onboarding` | OnboardingScreen | - (Provider에서 카카오/Apple 정보 읽음) |
| `/terms/:type` | TermsDetailScreen | `type`: 'service' or 'privacy' |
| `/home` | HomeScreen | - |
| `/mypage` | MyPageScreen | - |
| `/crew/create` | CreateCrewScreen | - |
| `/crew/success` | CrewSuccessScreen | `?inviteCode=&startDate=&crewName=` |
| `/crew/confirm` | CrewConfirmScreen | `?crewId=` |
| `/crew/:id` | CrewDetailScreen | `:id` (crewId) |
| `/verification` | VerificationScreen | `?crewId=&challengeId=` |

### 화면별 구현 현황
| 화면 | 백엔드 연동 | 비고 |
|------|------------|------|
| 로그인 | ✅ 완료 | 카카오/테스트 로그인. Apple은 버튼만 (미연동) |
| 온보딩 | ✅ 완료 | 카카오/Apple 겸용, 닉네임 입력 + 약관 동의 |
| 홈 | ✅ 완료 | `GET /crews` 실데이터 표시 |
| 크루 만들기 | ✅ 완료 | `POST /crews` |
| 크루 생성 완료 | ✅ 완료 | 초대코드 복사/공유 |
| 크루 확인/참여 | ✅ 완료 | `POST /crews/join` |
| 크루 상세 | ✅ 완료 | 탭 3개 + 멤버 현황 + 피드 |
| 인증하기 | ⚠️ 부분 | 텍스트 인증만 완료. **사진(S3 업로드 + SSE) 미구현** |
| 마이페이지 | ✅ 완료 | 닉네임 변경 + 로그아웃 (회원탈퇴 미구현) |

### 인증 플로우
```
앱 시작
  → SecureStorage에서 refreshToken 확인
    → 있음: POST /auth/refresh → GET /users/me → /home (자동 로그인)
    → 없음: /login

카카오 로그인
  → 카카오 SDK → accessToken 획득
  → POST /auth/kakao
    → 기존 유저 (isNewUser=false): 토큰 저장 → /home
    → 신규 유저 (isNewUser=true): 임시 저장 → /onboarding → POST /auth/signup → /home
```

---

## 6. 진행중 / 예정 작업

### 6-1. 즉시 필요 (버그/검증)
- [ ] 로그아웃 → 다른 유저 로그인: 이전 크루 캐시가 제대로 초기화되는지 테스트
- [ ] 앱 재시작 자동 로그인: `authUserProvider`/`authUserIdProvider` 복원 확인
- [ ] 토큰 만료 → 갱신 실패: 로그인 화면으로 이동 + 캐시 초기화 확인

### 6-2. Apple 로그인 (프론트 완료, 백엔드 대기)
- [ ] Xcode: Runner Target → Signing & Capabilities → "Sign in with Apple" 추가
- [ ] Apple Developer: App ID에 Sign in with Apple capability 활성화
- [ ] 백엔드: `POST /auth/apple` (identityToken 검증) 구현
- [ ] 백엔드: `POST /auth/apple-signup` 구현
- [ ] login_screen.dart 의 `_loginWithApple()` 활성화 (현재 TODO 주석)

### 6-3. 사진 인증 업로드 (핵심 미구현)
```
현재: 텍스트 인증만 동작
목표: 사진 선택 → S3 업로드 → SSE 수신 → 인증 생성
```

**구현할 시퀀스:**
```
1. POST /upload-sessions → { presignedUrl, sessionId }
2. GET /upload-sessions/{id}/events → SSE 구독 (업로드 완료 알림)
3. PUT presignedUrl ← 이미지 바이너리 (S3 직접 업로드)
4. SSE "COMPLETED" 이벤트 수신
5. POST /verifications { challengeId, uploadSessionId }
```

**구현 포인트:**
- `verification_screen.dart`의 `_handleSubmit()` 수정 필요
- SSE 타임아웃: 30초 → fallback으로 `GET /upload-sessions/{id}` 폴링
- Dio는 SSE 미지원 → `http` 패키지 또는 `EventSource` 구현 필요

### 6-4. 기타 예정
- [x] `baseUrl` 환경변수화 → `AppConfig.baseUrl` + `--dart-define=BASE_URL=...` 적용 완료 (docs/env-config.md 참고)
- [ ] 회원탈퇴 기능 (`DELETE /users/me`)
- [ ] 크루 상세 → 챌린지 ID 연동 (현재 동적 challengeId 전달 방식 확인 필요)
- [ ] 무한 스크롤 (피드 페이지네이션 `hasNext` 처리)

---

## 7. 코드 컨벤션 및 규칙

### 네이밍
```
위젯/클래스: PascalCase      → CrewCard, HomeScreen
변수/메서드: camelCase       → crewName, onPressed
파일명:      snake_case      → crew_card.dart
상수:        AppColors.main  → 클래스 내 camelCase
```

### 위젯 작성 원칙
- **100줄 초과 → 별도 파일로 분리** (강제)
- `StatelessWidget` 우선 → 상태 필요 시 `ConsumerWidget`/`ConsumerStatefulWidget`
- `build()` 안에서 복잡한 로직 금지 → `_buildXxx()` 메서드로 분리
- 비즈니스 로직은 위젯 바깥(Service/Provider)에 위치

### 스타일 토큰 사용 (하드코딩 절대 금지)
```dart
// ✅ 올바른 사용
color: AppColors.main
style: AppTextStyles.heading1
padding: EdgeInsets.all(AppSizes.paddingMD)

// ❌ 금지
color: Color(0xFFFE5027)
fontSize: 24
padding: EdgeInsets.all(16)
```

### API 응답 규격
```json
{
  "success": true,
  "data": { ... }
}
// 에러
{
  "success": false,
  "error": { "code": "ERROR_CODE", "message": "..." }
}
```
→ `ApiClient._parseResponse()` 에서 자동 파싱

### 보안 규칙
- `accessToken` → 메모리만. SecureStorage 저장 금지
- `kakaoAccessToken` 등 임시 Provider → signup 완료 즉시 `null` 세팅
- `BuildContext` → async gap 이후 사용 시 `if (!context.mounted) return;` 필수

---

## 8. 주의사항

### ❗ 중요 이슈 및 트랩

**1. baseUrl 이중 관리**
`api_client.dart`와 `auth_service.dart` 양쪽에 `const _baseUrl = 'http://localhost:8080'` 중복 존재.
→ `AuthService`는 자체 Dio 인스턴스 사용 (401 자동갱신 루프 방지 목적). 변경 시 양쪽 수정 필요.

**2. Apple 로그인 버튼 비활성화 상태**
`login_screen.dart`의 Apple 로그인 버튼 `onPressed`는 현재 SnackBar만 표시.
실제 로직 `_loginWithApple()`은 구현 완료지만 `// ignore: unused_element` 처리됨.
백엔드 준비 완료 시 `onPressed: () => _loginWithApple(context, ref)` 로 복원.

**3. 사진 인증 UI는 있지만 실제 S3 업로드 미구현**
`verification_screen.dart`의 `_handleSubmit()`이 텍스트 인증만 처리.
사진 선택(`_selectedImage`)은 로컬 미리보기만 동작, 서버 전송 없음.

**4. myVerificationDatesProvider 폴링 방식**
피드 API를 최대 5페이지까지 순회해서 내 인증 날짜를 추출하는 임시 구현.
백엔드에 전용 API (`GET /crews/{id}/my-verifications`) 있다면 교체 권장.

**5. 크루 상세 → 인증하기 challengeId 전달**
`/verification?crewId=&challengeId=` 로 이동 시 `challengeId`는 크루 상세에서 동적으로 결정되어야 함. 현재 플로우 확인 필요.

**6. 카카오 키는 dart-define 필수**
`--dart-define=KAKAO_NATIVE_KEY=<key>` 없이 실행 시 카카오 로그인 불가.
`.vscode/launch.json` 또는 IDE run configuration에 등록해두어야 함.

**7. Android vs iOS 분기**
Apple 로그인 버튼은 `Platform.isIOS` 조건부 렌더링.
테스트 로그인 버튼은 `!kReleaseMode` 조건부 (릴리즈 빌드에서 숨겨짐).

### 참고 문서
```
docs/api-spec.md      # 백엔드 API 명세
docs/biz-logic.md     # 비즈니스 규칙
docs/schema.md        # ERD / 스키마
docs/context-map.md   # 컨텍스트 맵
docs/todo-0304.md     # 최근 작업 내역 (2026-03-04)
```
