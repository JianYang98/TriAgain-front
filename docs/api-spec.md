# API 명세 (API Specification)

## 개요

인증 사용자 플로우 (사진 필수 크루인 경우)
→ 텍스트만 인증 가능한 크루라면 바로 POST /verifications

```
1. POST /upload-sessions → presignedUrl, uploadSessionId 수신
2. GET /upload-sessions/{id}/events → SSE 구독 (업로드 완료 알림용)
3. S3에 직접 업로드 (PUT {presignedUrl})
4. SSE로 "COMPLETED" 이벤트 수신 (Lambda가 S3 업로드 감지 → session 상태 변경)
5. POST /verifications → 인증 생성
```

---

## Auth Context

### POST /auth/kakao (카카오 로그인)

카카오 Access Token으로 기존 유저 여부를 확인한다.
- **기존 유저** → JWT 발급 (로그인 완료)
- **신규 유저** → `isNewUser=true` + 카카오 프로필 반환 (JWT 미발급, 유저 미생성)

**요청 (Request)**
```
POST /auth/kakao HTTP/1.1
Content-Type: application/json
```
```json
{
  "kakaoAccessToken": "카카오_SDK에서_받은_access_token"
}
```

**시나리오 1: 기존 유저 로그인 성공 (200 OK)**
```json
{
  "success": true,
  "data": {
    "isNewUser": false,
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "accessTokenExpiresIn": 1800,
    "user": {
      "id": "1234567890",
      "nickname": "김철수",
      "profileImageUrl": "https://img.kakao.com/profile.jpg"
    },
    "kakaoId": null,
    "kakaoProfile": null
  },
  "error": null
}
```

**시나리오 2: 신규 유저 — 회원가입 필요 (200 OK)**
```json
{
  "success": true,
  "data": {
    "isNewUser": true,
    "accessToken": null,
    "refreshToken": null,
    "accessTokenExpiresIn": null,
    "user": null,
    "kakaoId": "1234567890",
    "kakaoProfile": {
      "nickname": "카카오닉네임",
      "email": "user@kakao.com",
      "profileImageUrl": "https://img.kakao.com/profile.jpg"
    }
  },
  "error": null
}
```

**프론트 분기 로직:**
```
1. POST /auth/kakao 호출
2. if (data.isNewUser == false):
     → accessToken/refreshToken 저장 → 메인 화면 이동
3. if (data.isNewUser == true):
     → data.kakaoId, data.kakaoProfile 저장
     → 약관 동의 + 닉네임 입력 화면 이동
     → POST /auth/signup 호출
```

**에러 응답**
| HTTP | 코드 | 메시지 |
|------|------|--------|
| 401 | A001 | 유효하지 않은 카카오 토큰입니다. |
| 502 | A002 | 카카오 API 호출 중 오류가 발생했습니다. |

---

### POST /auth/signup (회원가입)

카카오 인증 + 약관 동의 + 닉네임으로 신규 유저를 생성하고 JWT를 발급한다.

**요청 (Request)**
```
POST /auth/signup HTTP/1.1
Content-Type: application/json
```
```json
{
  "kakaoAccessToken": "카카오_SDK에서_받은_access_token",
  "kakaoId": "1234567890",
  "nickname": "내닉네임",
  "termsAgreed": true
}
```

**필드 설명:**
- `kakaoAccessToken`: (필수) 카카오 SDK에서 받은 Access Token
- `kakaoId`: (필수) POST /auth/kakao 응답의 `kakaoId` 값
- `nickname`: (필수) 2~12자, 한글/영문/숫자/언더스코어만 허용
- `termsAgreed`: (필수) 약관 동의 여부 (true만 허용)

**성공 응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "accessTokenExpiresIn": 1800,
    "user": {
      "id": "1234567890",
      "nickname": "내닉네임",
      "profileImageUrl": "https://img.kakao.com/profile.jpg"
    }
  },
  "error": null
}
```

**에러 응답**
| HTTP | 코드 | 메시지 | 설명 |
|------|------|--------|------|
| 400 | U005 | 약관에 동의해야 회원가입이 가능합니다. | termsAgreed=false |
| 400 | U004 | 닉네임은 필수입니다. | 빈값/null |
| 400 | U007 | 닉네임은 2~12자의 한글, 영문, 숫자, 언더스코어만 사용할 수 있습니다. | 형식 불일치 |
| 400 | U008 | 카카오 계정 정보가 일치하지 않습니다. | kakaoId 불일치 |
| 401 | A001 | 유효하지 않은 카카오 토큰입니다. | 만료/잘못된 토큰 |
| 409 | U006 | 이미 가입된 사용자입니다. | 중복 가입 |

---

### POST /auth/apple (Apple 로그인)

Apple Identity Token으로 기존 유저 여부를 확인한다.
- **기존 유저** → JWT 발급 (로그인 완료)
- **신규 유저** → `isNewUser=true` + appleId/email 반환 (JWT 미발급, 유저 미생성)

**요청 (Request)**
```
POST /auth/apple HTTP/1.1
Content-Type: application/json
```
```json
{
  "identityToken": "Apple_SDK에서_받은_identity_token"
}
```

**시나리오 1: 기존 유저 로그인 성공 (200 OK)**
```json
{
  "success": true,
  "data": {
    "isNewUser": false,
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "accessTokenExpiresIn": 1800,
    "user": {
      "id": "001234.abcdef.5678",
      "nickname": "유저닉네임",
      "profileImageUrl": null
    },
    "appleId": null,
    "email": null
  },
  "error": null
}
```

**시나리오 2: 신규 유저 — 회원가입 필요 (200 OK)**
```json
{
  "success": true,
  "data": {
    "isNewUser": true,
    "accessToken": null,
    "refreshToken": null,
    "accessTokenExpiresIn": null,
    "user": null,
    "appleId": "001234.abcdef.5678",
    "email": "user@privaterelay.appleid.com"
  },
  "error": null
}
```

**프론트 분기 로직:**
```
1. POST /auth/apple 호출
2. if (data.isNewUser == false):
     → accessToken/refreshToken 저장 → 메인 화면 이동
3. if (data.isNewUser == true):
     → data.appleId 저장
     → 약관 동의 + 닉네임 입력 화면 이동
     → POST /auth/apple-signup 호출
```

**참고:**
- Apple은 email을 최초 로그인 시에만 제공. 재로그인 시 email은 null일 수 있음
- Apple은 프로필 이미지를 제공하지 않음 (profileImageUrl은 항상 null)

**에러 응답**
| HTTP | 코드 | 메시지 |
|------|------|--------|
| 401 | A005 | 유효하지 않은 애플 토큰입니다. |
| 502 | A006 | 애플 토큰 검증 중 오류가 발생했습니다. |

---

### POST /auth/apple-signup (Apple 회원가입)

Apple 인증 + 약관 동의 + 닉네임으로 신규 유저를 생성하고 JWT를 발급한다.

**요청 (Request)**
```
POST /auth/apple-signup HTTP/1.1
Content-Type: application/json
```
```json
{
  "identityToken": "Apple_SDK에서_받은_identity_token",
  "appleId": "001234.abcdef.5678",
  "nickname": "내닉네임",
  "termsAgreed": true
}
```

**필드 설명:**
- `identityToken`: (필수) Apple SDK에서 받은 Identity Token (JWT)
- `appleId`: (필수) POST /auth/apple 응답의 `appleId` 값
- `nickname`: (필수) 2~12자, 한글/영문/숫자/언더스코어만 허용
- `termsAgreed`: (필수) 약관 동의 여부 (true만 허용)

**성공 응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "accessTokenExpiresIn": 1800,
    "user": {
      "id": "001234.abcdef.5678",
      "nickname": "내닉네임",
      "profileImageUrl": null
    }
  },
  "error": null
}
```

**에러 응답**
| HTTP | 코드 | 메시지 | 설명 |
|------|------|--------|------|
| 400 | U005 | 약관에 동의해야 회원가입이 가능합니다. | termsAgreed=false |
| 400 | U004 | 닉네임은 필수입니다. | 빈값/null |
| 400 | U007 | 닉네임은 2~12자의 한글, 영문, 숫자, 언더스코어만 사용할 수 있습니다. | 형식 불일치 |
| 400 | U009 | 애플 계정 정보가 일치하지 않습니다. | appleId 불일치 |
| 401 | A005 | 유효하지 않은 애플 토큰입니다. | 만료/잘못된 토큰 |
| 409 | U006 | 이미 가입된 사용자입니다. | 중복 가입 |

---

### POST /auth/refresh (토큰 갱신)

Refresh Token으로 새 Access Token을 발급한다.

**요청 (Request)**
```
POST /auth/refresh HTTP/1.1
Content-Type: application/json
```
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "accessTokenExpiresIn": 1800
  },
  "error": null
}
```

**에러 응답**
| HTTP | 코드 | 메시지 |
|------|------|--------|
| 401 | A004 | 유효하지 않은 리프레시 토큰입니다. |
| 404 | U001 | 사용자를 찾을 수 없습니다. |

---

### POST /auth/logout (로그아웃)

Phase 1에서는 서버 no-op. 클라이언트가 로컬 토큰을 삭제하여 로그아웃 처리한다.
Phase 2에서 Redis 기반 토큰 블랙리스트 도입 예정.

**요청 (Request)**
```
POST /auth/logout HTTP/1.1
Authorization: Bearer <token>
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": null,
  "error": null
}
```

**프론트 처리:**
1. `POST /auth/logout` 호출
2. 로컬 저장소에서 accessToken, refreshToken 삭제
3. 로그인 화면으로 이동

---

## User Context

### GET /users/me (내 프로필 조회)

인증된 사용자의 프로필 정보를 조회한다.

**요청 (Request)**
```
GET /users/me HTTP/1.1
Authorization: Bearer <token>
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "1234567890",
    "nickname": "내닉네임",
    "profileImageUrl": "https://img.kakao.com/profile.jpg",
    "email": "user@kakao.com"
  },
  "error": null
}
```

**에러 응답**
| HTTP | 코드 | 메시지 |
|------|------|--------|
| 401 | A003 | 인증이 필요합니다. |

---

### PATCH /users/me/nickname (닉네임 변경)

닉네임을 변경하고 변경된 전체 프로필을 반환한다.

**요청 (Request)**
```
PATCH /users/me/nickname HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json
```
```json
{
  "nickname": "새닉네임"
}
```

**필드 설명:**
- `nickname`: (필수) 2~12자, 한글/영문/숫자/언더스코어만 허용

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "1234567890",
    "nickname": "새닉네임",
    "profileImageUrl": "https://img.kakao.com/profile.jpg",
    "email": "user@kakao.com"
  },
  "error": null
}
```

**에러 응답**
| HTTP | 코드 | 메시지 |
|------|------|--------|
| 400 | U007 | 닉네임은 2~12자의 한글, 영문, 숫자, 언더스코어만 사용할 수 있습니다. |
| 401 | A003 | 인증이 필요합니다. |

---

## Crew Context

### POST /crews (크루 생성)

**요청 (Request)**
```json
POST /crews HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "새벽 러닝 크루",
  "goal": "매일 아침 5km 러닝",
  "maxMembers": 5,
  "startDate": "2026-03-10",
  "endDate": "2026-03-24",
  "verificationType": "PHOTO",
  "allowLateJoin": true,
  "deadlineTime": "23:59:59"
}
```

**성공 응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "crewId": "crew_123",
    "creatorId": "user_456",
    "name": "새벽 러닝 크루",
    "goal": "매일 아침 5km 러닝",
    "verificationType": "PHOTO",
    "maxMembers": 5,
    "currentMembers": 1,
    "status": "RECRUITING",
    "startDate": "2026-03-10",
    "endDate": "2026-03-24",
    "allowLateJoin": true,
    "inviteCode": "ABC123",
    "createdAt": "2026-03-09T10:00:00",
    "deadlineTime": "23:59:59"
  },
  "error": null
}
```

---

### GET /crews/invite/{inviteCode} (초대코드로 크루 미리보기)

초대코드로 크루 정보를 미리 조회한다. 가입하지 않고 조회만 수행하며, 가입 가능 여부(joinable)와 차단 사유(joinBlockedReason)를 함께 반환한다.

**요청 (Request)**
```
GET /crews/invite/ABC123 HTTP/1.1
Authorization: Bearer <token>
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "crew_123",
    "name": "작심삼일 크루",
    "goal": "매일 운동하기",
    "verificationType": "PHOTO",
    "maxMembers": 10,
    "currentMembers": 3,
    "status": "RECRUITING",
    "startDate": "2026-03-10",
    "endDate": "2026-03-24",
    "allowLateJoin": true,
    "deadlineTime": "23:59:59",
    "members": [
      {
        "userId": "user-uuid-1",
        "nickname": "크루장닉네임",
        "profileImageUrl": "https://...",
        "role": "LEADER",
        "joinedAt": "2026-03-01T10:00:00"
      },
      {
        "userId": "user-uuid-2",
        "nickname": "멤버닉네임",
        "profileImageUrl": null,
        "role": "MEMBER",
        "joinedAt": "2026-03-02T14:00:00"
      }
    ],
    "joinable": true,
    "joinBlockedReason": null
  },
  "error": null
}
```

**필드 설명:**
- `joinable`: 현재 유저가 이 크루에 가입 가능한지 여부
- `joinBlockedReason`: 가입 불가 시 사유 (joinable=true이면 null)

**joinBlockedReason 값:**

| 값 | 설명 |
|------|------|
| `ALREADY_MEMBER` | 이미 가입한 크루 |
| `CREW_ENDED` | 크루가 종료(COMPLETED)됨 |
| `CREW_FULL` | 정원 초과 |
| `LATE_JOIN_NOT_ALLOWED` | 중간 가입 비허용 (ACTIVE 크루) |
| `CREW_JOIN_DEADLINE_PASSED` | 참여 마감 기한 초과 |

**에러 응답**
| HTTP | 코드 | 메시지 | 설명 |
|------|------|--------|------|
| 404 | CR006 | 유효하지 않은 초대 코드입니다. | 존재하지 않는 초대코드 |

---

### POST /crews/join (초대코드로 크루 참여)

초대코드를 사용하여 크루에 참여한다. 크루가 RECRUITING 상태이고, 정원이 남아있는 경우에만 참여 가능.

**요청 (Request)**
```
POST /crews/join HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json
```
```json
{
  "inviteCode": "ABC123"
}
```

**필드 설명:**
- `inviteCode`: (필수) 크루 초대코드 (6자리)

**성공 응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "userId": "1234567890",
    "crewId": "crew_123",
    "role": "MEMBER",
    "currentMembers": 3,
    "joinedAt": "2026-03-04T10:00:00Z"
  },
  "error": null
}
```

**에러 응답**
| HTTP | 코드 | 메시지 | 설명 |
|------|------|--------|------|
| 400 | CR003 | 모집 중인 크루가 아닙니다. | 크루 상태가 RECRUITING이 아님 |
| 400 | CR008 | 크루 참여 마감 기한이 지났습니다. | 중간 가입 불가 시 기한 초과 |
| 404 | CR006 | 유효하지 않은 초대 코드입니다. | 존재하지 않는 초대코드 |
| 409 | CR002 | 크루 정원이 가득 찼습니다. | 정원 초과 |
| 409 | CR004 | 이미 참여 중인 크루입니다. | 중복 참여 |

---

### GET /crews/{crewId} (크루 상세 조회)

크루 멤버가 크루 상세 화면을 볼 때 사용. 멤버별 챌린지 현황과 달성 횟수를 포함한다.

**요청 (Request)**
```
GET /crews/{crewId} HTTP/1.1
Authorization: Bearer <token>
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "crew-uuid",
    "creatorId": "user-uuid",
    "name": "새벽 러닝 크루",
    "goal": "매일 아침 5km 러닝",
    "verificationType": "PHOTO",
    "maxMembers": 5,
    "currentMembers": 3,
    "status": "ACTIVE",
    "startDate": "2026-03-10",
    "endDate": "2026-03-24",
    "allowLateJoin": true,
    "inviteCode": "ABC123",
    "createdAt": "2026-03-01T10:00:00",
    "deadlineTime": "23:59:59",
    "members": [
      {
        "userId": "user-uuid-1",
        "nickname": "크루장닉네임",
        "profileImageUrl": "https://...",
        "role": "LEADER",
        "joinedAt": "2026-03-01T10:00:00",
        "successCount": 2,
        "challengeProgress": {
          "challengeStatus": "IN_PROGRESS",
          "completedDays": 1,
          "targetDays": 3
        }
      },
      {
        "userId": "user-uuid-2",
        "nickname": "멤버닉네임",
        "profileImageUrl": null,
        "role": "MEMBER",
        "joinedAt": "2026-03-02T14:00:00",
        "successCount": 0,
        "challengeProgress": null
      }
    ]
  },
  "error": null
}
```

**필드 설명:**
- `successCount`: 해당 크루에서의 작심삼일(3일 연속 인증) 달성 횟수. 활성 챌린지 유무와 무관하게 항상 표시
- `challengeProgress`: 현재 진행 중인 챌린지 (없으면 null)
  - `challengeStatus`: IN_PROGRESS / SUCCESS / FAILED / ENDED
  - `completedDays`: 현재 사이클 진행일 (0~3)
  - `targetDays`: 3

**에러 응답**
| HTTP | 코드 | 메시지 | 설명 |
|------|------|--------|------|
| 403 | CR009 | 크루 멤버만 접근할 수 있습니다. | 비멤버 접근 |
| 404 | CR001 | 크루를 찾을 수 없습니다. | 존재하지 않는 crewId |

---

## Verification Context

### POST /upload-sessions (이미지 업로드 세션 생성)

클라이언트가 S3에 직접 업로드할 수 있도록 Presigned URL을 발급받는 API

**요청 (Request)**
```json
POST /upload-sessions HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json

{
  "crewId": "crew-uuid",
  "fileName": "verification_image.jpg",
  "fileType": "image/jpeg",
  "fileSize": 2048576
}
```

**성공 응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "uploadSessionId": 123,
    "presignedUrl": "https://s3.amazonaws.com/bucket/verifications/user_456/2026-02-18/abc123.jpg?X-Amz-Algorithm=...",
    "imageUrl": "https://s3.amazonaws.com/bucket/verifications/user_456/2026-02-18/abc123.jpg",
    "expiresAt": "2026-02-18T15:00:00Z",
    "maxFileSize": 5242880,
    "allowedTypes": ["image/jpeg"]
  },
  "error": null
}
```

**필드 설명:**
- `uploadSessionId`: 업로드 세션 ID (Long 타입)
- `presignedUrl`: S3에 직접 업로드할 URL (15분 유효)
- `imageUrl`: 업로드 완료 후 사용할 이미지 URL
- `expiresAt`: Presigned URL 만료 시간
- `maxFileSize`: 최대 파일 크기 (5MB)
- `allowedTypes`: 허용된 파일 타입

**실패 응답**
```json
// 400 Bad Request - 파일 타입 불허
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_FILE_TYPE",
    "message": "지원하지 않는 파일 형식입니다."
  }
}

// 400 Bad Request - 파일 크기 초과
{
  "success": false,
  "data": null,
  "error": {
    "code": "FILE_TOO_LARGE",
    "message": "파일 크기가 너무 큽니다."
  }
}

// 401 Unauthorized
{
  "success": false,
  "data": null,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "로그인이 필요합니다."
  }
}

// 429 Too Many Requests
{
  "success": false,
  "data": null,
  "error": {
    "code": "UPLOAD_RATE_LIMIT",
    "message": "업로드 요청이 너무 많습니다."
  }
}
```

**제약 사항:**
- 최대 크기: 5MB
- 허용 타입: JPEG, PNG, WebP
- 파일명: UUID 기반 자동 생성
- Presigned URL 유효기간: 15분
- Rate Limit: 사용자당 10건/분
- 미사용 이미지: 업로드 후 7일 경과 시 자동 삭제

---

### POST /verifications (인증 생성)

**요청 (Request)**
```json
POST /verifications HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json
Idempotency-Key: <uuid>

{
  "crewId": "crew-uuid",
  "uploadSessionId": 123,
  "textContent": "오늘도 달리기 완료!"
}
```

**핵심 규칙:**
- 텍스트 인증 크루인 경우 `uploadSessionId` 없이 호출 가능
- 사진 인증 크루인 경우 `uploadSessionId` 필수 (upload_session이 COMPLETED 상태일 때만 유효)
- 마감 시간 기준: upload_session.requested_at (서버 기록, 조작 불가)

**성공 응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "verificationId": "ver_789",
    "challengeId": "chal_123",
    "userId": "user_456",
    "crewId": "crew-uuid",
    "imageUrl": "https://s3.../image.jpg",
    "textContent": "오늘도 달리기 완료!",
    "status": "APPROVED",
    "reviewStatus": "NOT_REQUIRED",
    "reportCount": 0,
    "targetDate": "2026-02-18",
    "createdAt": "2026-02-18T14:30:00Z"
  },
  "error": null
}
```

**실패 응답**
```json
// 400 Bad Request - 잘못된 입력
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_INPUT",
    "message": "필수 입력값이 누락되었습니다."
  }
}

// 400 Bad Request - 미완료 업로드 세션
{
  "success": false,
  "data": null,
  "error": {
    "code": "UPLOAD_SESSION_NOT_COMPLETED",
    "message": "업로드가 완료되지 않은 세션입니다."
  }
}

// 400 Bad Request - 마감 초과
{
  "success": false,
  "data": null,
  "error": {
    "code": "VERIFICATION_DEADLINE_EXCEEDED",
    "message": "인증 마감 시간이 지났습니다."
  }
}

// 401 Unauthorized
{
  "success": false,
  "data": null,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "로그인이 필요합니다."
  }
}

// 403 Forbidden
{
  "success": false,
  "data": null,
  "error": {
    "code": "CREW_ACCESS_DENIED",
    "message": "크루 멤버만 인증할 수 있습니다."
  }
}

// 409 Conflict - 중복 인증
{
  "success": false,
  "data": null,
  "error": {
    "code": "VERIFICATION_ALREADY_EXISTS",
    "message": "이미 해당 날짜에 인증을 완료했습니다."
  }
}

// 429 Too Many Requests
{
  "success": false,
  "data": null,
  "error": {
    "code": "TOO_MANY_REQUESTS",
    "message": "잠시 후 다시 시도해주세요."
  }
}
```

---

### GET /upload-sessions/{id}/events (SSE — 업로드 완료 알림)

클라이언트가 S3 업로드 완료 여부를 실시간으로 수신하는 SSE 엔드포인트.
presignedUrl 수신 직후, S3 업로드 전에 구독한다.

**요청 (Request)**
```
GET /upload-sessions/{uploadSessionId}/events HTTP/1.1
Authorization: Bearer <token>
Accept: text/event-stream
```

**SSE 이벤트 형식:**
```
event: COMPLETED
data: {"uploadSessionId": 123, "status": "COMPLETED"}

event: EXPIRED
data: {"uploadSessionId": 123, "status": "EXPIRED"}

event: ERROR
data: {"uploadSessionId": 123, "message": "처리 중 오류가 발생했습니다."}
```

**이벤트 타입:**

| 이벤트 | 의미 | 클라이언트 동작 |
|--------|------|----------------|
| COMPLETED | Lambda가 S3 업로드 감지, session COMPLETED 처리 완료 | POST /verifications 호출 |
| EXPIRED | session 시간 초과 / 만료 | 재시도 안내 |
| ERROR | 처리 중 오류 | 에러 표시 + 재시도 안내 |

**타임아웃:**
- 서버: 60초
- 클라이언트 권장: 30초 (30초 내 COMPLETED 미수신 시 재시도 안내)

**실패 응답:**
```json
// 404 Not Found
{
  "success": false,
  "data": null,
  "error": {
    "code": "UPLOAD_SESSION_NOT_FOUND",
    "message": "업로드 세션을 찾을 수 없습니다."
  }
}
```

---

### GET /upload-sessions/{id} (업로드 세션 상태 조회 — 폴링 fallback)

SSE 연결이 끊긴 경우 폴링으로 session 상태를 확인하는 fallback 엔드포인트.

**요청 (Request)**
```
GET /upload-sessions/{uploadSessionId} HTTP/1.1
Authorization: Bearer <token>
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "uploadSessionId": 123,
    "status": "COMPLETED",
    "imageUrl": "https://s3.../abc123.jpg",
    "requestedAt": "2026-02-18T14:30:00Z"
  },
  "error": null
}
```

**status 값:**

| 상태 | 의미 | 클라이언트 동작 |
|------|------|----------------|
| PENDING | 아직 S3 업로드 미완료 | 2~3초 후 재폴링 |
| COMPLETED | 업로드 완료 | POST /verifications 호출 |
| EXPIRED | 만료 | 재시도 안내 |

---

### GET /crews/{crewId}/feed (크루 피드 조회)

**요청 (Request)**
```
GET /crews/{crewId}/feed HTTP/1.1
Authorization: Bearer <token>
```

**쿼리 파라미터:**
- `page`: 페이지 번호 (기본값: 0)
- `size`: 페이지 크기 (기본값: 20)

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "verifications": [
      {
        "id": "ver-uuid",
        "userId": "user-uuid",
        "nickname": "닉네임",
        "profileImageUrl": "https://...",
        "imageUrl": "https://s3.../image.jpg",
        "textContent": "오늘도 완료!",
        "targetDate": "2026-03-10",
        "createdAt": "2026-03-10T09:30:00Z"
      }
    ],
    "myProgress": {
      "challengeId": "chal-uuid",
      "status": "IN_PROGRESS",
      "completedDays": 1,
      "targetDays": 3
    },
    "hasNext": false
  },
  "error": null
}
```

---

### GET /crews/{crewId}/my-verifications (나의 인증 이력 조회)

**요청 (Request)**
```
GET /crews/{crewId}/my-verifications HTTP/1.1
Authorization: Bearer <token>
```

**성공 응답 (200 OK)**
```json
{
  "success": true,
  "data": {
    "verifiedDates": ["2026-03-08", "2026-03-09", "2026-03-10"],
    "streakCount": 3,
    "completedChallenges": 2,
    "myProgress": {
      "challengeId": "chal-uuid",
      "status": "IN_PROGRESS",
      "completedDays": 1,
      "targetDays": 3
    }
  },
  "error": null
}
```

---

## Moderation Context (Phase 2)

- POST /verifications/{id}/reports — 신고
- POST /verifications/{id}/reactions — 반응 (이모지)
