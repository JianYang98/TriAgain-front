# 프론트엔드 동기화 수정 지시서

> 생성일: 2026-03-04
> 출처: 오케스트레이션 에이전트 전체 동기화 검증
> 정본: 백엔드 `docs/spec/api-spec.md` + 백엔드 실제 코드

---

## 수정 우선순위 요약

| 순위 | 지시서 | 심각도 | 이유 |
|------|--------|--------|------|
| 1 | #1 Apple 엔드포인트 경로 | CRITICAL | Apple 회원가입 불가 (404) |
| 2 | #2 Apple 응답 모델 | CRITICAL | Apple 신규유저 onboarding 데이터 손실 |
| 3 | #3 AuthService 파싱 | MEDIUM | 잠재적 에러 미감지 |
| 4 | #4 email 필드 추가 | MEDIUM | 데이터 누락 |
| 5 | #7 Apple signup 필드명 | HIGH | 400 Bad Request |
| 6 | #10 CrewMember 필드 누락 | MEDIUM | 멤버 정보 미표시 |
| 7 | #13 Logout 불필요 body | LOW | 코드 정리 (당장 무해) |

---

## [완료] [수정 지시 #1] Apple 회원가입 경로 수정

### 배경

오케스트레이션 검증에서 Apple 회원가입 엔드포인트 경로 불일치 발견. 현재 404 에러 발생.

- 백엔드: `POST /auth/apple-signup`
- 프론트: `POST /auth/signup/apple`

### 수정 사항

1. **파일:** `lib/services/auth_service.dart` (93번째 줄 부근)
   - 변경: `'/auth/signup/apple'` → `'/auth/apple-signup'`

### 검증

- Apple 신규유저 회원가입 플로우 테스트
- 백엔드 `POST /auth/apple-signup` 엔드포인트 정상 호출 확인

---

## [완료] [수정 지시 #2] Apple 로그인 응답 모델 확장

### 배경

Apple 로그인 응답이 카카오와 다른 필드 구조를 가지나, 프론트가 `KakaoLoginResponse`를 재사용하여 Apple 고유 필드(`appleId`, `email`)가 누락됨. Apple 신규유저의 onboarding 플로우에서 `appleId`/`email`이 null → 회원가입 불가.

- 백엔드 Apple 신규유저 응답: `{ "appleId": "xxx", "email": "yyy" }` (최상위 필드)
- 프론트: `KakaoLoginResponse.fromJson`을 재사용 → `json['kakaoId']`와 `json['kakaoProfile']`만 파싱

### 수정 사항

1. **파일:** `lib/models/auth.dart` — `KakaoLoginResponse` 클래스
   - `String? appleId` 필드 추가
   - `String? appleEmail` 필드 추가 (또는 `email` — `kakaoProfile.email`과 구분)
   - `fromJson`에 아래 파싱 추가:
     ```dart
     appleId: json['appleId'] as String?,
     email: json['email'] as String?,
     ```

2. **파일:** Apple 로그인 처리 화면 (onboarding 등)
   - Apple 신규유저일 때 `response.appleId`를 `appleUserIdProvider`에 저장
   - `response.email`을 필요시 표시

### 검증

- Apple 신규유저 로그인 → onboarding → 회원가입 전체 플로우 테스트
- `appleId`가 null이 아닌지 확인
- 회원가입 시 `appleUserId` 파라미터가 정상 전달되는지 확인

---

## [완료] [수정 지시 #3] AuthService 응답 파싱 수정

### 배경

AuthService의 `_parseData`가 존재하지 않는 `status` 필드를 확인. 백엔드 `ApiResponse`는 `success` boolean 사용.

- 백엔드 응답 envelope: `{ "success": true/false, "data": ..., "error": ... }`
- 프론트 AuthService `_parseData()`: `json['status'] == 'ERROR'`를 확인 — 존재하지 않는 필드
- 다른 서비스들이 사용하는 `ApiClient`는 `success` 필드를 정상적으로 확인

### 수정 사항

1. **파일:** `lib/services/auth_service.dart` — `_parseData` 메서드
   - 변경 전:
     ```dart
     final status = json['status'] as String?;
     if (status == 'ERROR') { ... }
     ```
   - 변경 후:
     ```dart
     final success = json['success'] as bool? ?? true;
     if (!success) { ... }
     ```

### 검증

- 카카오/Apple 로그인 성공/실패 케이스 테스트
- 잘못된 토큰으로 로그인 시 에러 메시지 정상 표시 확인
- `200 + success:false` 응답이 정상적으로 에러로 처리되는지 확인

---

## [완료] [수정 지시 #4] AuthUser에 email 필드 추가

### 배경

백엔드 `GET /users/me` 응답에 `email` 필드가 포함되나, 프론트 `AuthUser` 모델에 누락.

- 백엔드 응답: `{ id, nickname, profileImageUrl, email }` — 4개 필드
- 프론트 모델: `{ id, nickname, profileImageUrl }` — 3개 필드 (email 없음)

### 수정 사항

1. **파일:** `lib/models/auth.dart` — `AuthUser` 클래스
   - `final String? email;` 필드 추가
   - 생성자에 `this.email` 추가
   - `fromJson`에 아래 파싱 추가:
     ```dart
     email: json['email'] as String?,
     ```

### 검증

- `GET /users/me` 호출 후 email 값이 `AuthUser`에 정상 저장되는지 확인

---

## [완료] [수정 지시 #7] Apple signup 필드명 불일치

### 배경

오케스트레이션 2차 검증에서 Apple 회원가입 요청 body의 필드명 불일치 발견. 백엔드가 `appleId`를 기대하나 프론트가 `appleUserId`로 전송 → 400 Bad Request.

- 백엔드 api-spec: `POST /auth/apple-signup` body에 `appleId` (String, required)
- 프론트: `'appleUserId': appleUserId` 로 전송

### 수정 사항

1. **파일:** `lib/services/auth_service.dart` (96행 부근)
   - 변경 전:
     ```dart
     'appleUserId': appleUserId,
     ```
   - 변경 후:
     ```dart
     'appleId': appleUserId,
     ```
   - 참고: 파라미터명 `appleUserId`는 프론트 내부 변수명이므로 그대로 유지. data key만 백엔드 스펙에 맞춘다.

### 검증

- Apple 신규유저 회원가입 요청이 400이 아닌 200/201 반환 확인
- 요청 body에 `"appleId"` 키로 전송되는지 네트워크 로그 확인

---

## [완료] [수정 지시 #10] CrewMember 모델 필드 누락

### 배경

오케스트레이션 2차 검증에서 `CrewMember` 모델에 `nickname`, `profileImageUrl` 필드 누락 발견. 크루 상세 화면에서 멤버 이름/프로필 이미지를 표시할 수 없음.

- 백엔드 api-spec: `GET /crews/{crewId}` 응답의 members 배열에 `userId`, `nickname`, `profileImageUrl`, `role`, `joinedAt`, `challengeProgress` 포함
- 프론트 `CrewMember`: `userId`, `role`, `joinedAt`, `challengeProgress` (4개만)

### 수정 사항

1. **파일:** `lib/models/crew.dart` — `CrewMember` 클래스 (108~134행 부근)
   - `nickname` 필드 추가:
     ```dart
     final String nickname;
     ```
   - `profileImageUrl` 필드 추가:
     ```dart
     final String? profileImageUrl;
     ```
   - 생성자에 `required this.nickname`, `this.profileImageUrl` 추가
   - `fromJson`에 파싱 추가:
     ```dart
     nickname: json['nickname'] as String,
     profileImageUrl: json['profileImageUrl'] as String?,
     ```

2. **TODO (백엔드 확인 필요):** `GET /crews/{crewId}` 응답에 멤버별 `nickname`/`profileImageUrl`이 실제로 포함되는지 백엔드 코드 확인. api-spec에는 명시되어 있으나 실제 구현 여부 검증 필요.

### 검증

- 크루 상세 화면에서 멤버 닉네임이 표시되는지 확인
- 프로필 이미지가 있는 멤버의 이미지가 렌더링되는지 확인
- `profileImageUrl`이 null인 경우 기본 아바타가 표시되는지 확인

---

## [완료] [수정 지시 #13] Logout 불필요 body 제거

### 배경

오케스트레이션 2차 검증에서 logout 요청에 불필요한 body 전송 발견. 현재 서버가 body를 무시하므로 동작에는 무해하나, api-spec과 불일치.

- 백엔드 api-spec: `POST /auth/logout` — Authorization 헤더만 필요, body 없음 (Phase 1 no-op)
- 프론트: `data: {'refreshToken': refreshToken}` body 전송

### 수정 사항

1. **파일:** `lib/services/auth_service.dart` — `logout()` 메서드 (142~157행 부근)
   - 변경 전:
     ```dart
     await _dio.post(
       '/auth/logout',
       data: {'refreshToken': refreshToken},
     );
     ```
   - 변경 후:
     ```dart
     // Phase 2에서 Redis 토큰 블랙리스트 구현 시 body 복원 필요
     // data: {'refreshToken': refreshToken}
     await _dio.post('/auth/logout');
     ```

### 검증

- 로그아웃 요청이 정상적으로 200 반환 확인
- 로그아웃 후 토큰 삭제 및 로그인 화면 이동 정상 동작 확인

---

## 일치 확인 항목 (문제 없음)

아래 항목들은 검증 결과 백엔드-프론트 간 일치가 확인됨:

- 닉네임 검증 정규식 `^[가-힣a-zA-Z0-9_]{2,12}$` ✅
- 크루 참여 엔드포인트 (`POST /crews/join`) ✅
- accessToken 메모리 전용 / refreshToken SecureStorage ✅
- `/auth/` 경로 토큰 주입 제외 ✅
- 401 → refresh → retry → 실패 시 로그아웃 플로우 ✅
- 카카오 로그인/회원가입 요청/응답 구조 ✅
- 토큰 갱신 요청/응답 구조 ✅
- 닉네임 변경 요청/응답 구조 ✅
- 인증 생성 요청 (Idempotency-Key 포함) ✅
- 크루 생성 요청 (deadlineTime 포함) ✅
- 백엔드 ApiResponse ↔ 프론트 ApiResponse 구조 ✅
