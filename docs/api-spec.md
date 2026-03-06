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

## 구현 완료

### POST /upload-sessions (이미지 업로드 세션 생성)

클라이언트가 S3에 직접 업로드할 수 있도록 Presigned URL을 발급받는 API

**요청 (Request)**
```json
POST /upload-sessions HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json

{
  "fileName": "verification_image.jpg",
  "fileType": "image/jpeg",
  "fileSize": 2048576
}
```

**성공 응답 (201 Created)**
```json
{
  "uploadSessionId": "upload_123",
  "presignedUrl": "https://s3.amazonaws.com/bucket/verifications/user_456/2026-02-18/abc123.jpg?X-Amz-Algorithm=...",
  "imageUrl": "https://s3.amazonaws.com/bucket/verifications/user_456/2026-02-18/abc123.jpg",
  "expiresAt": "2026-02-18T15:00:00Z",
  "maxFileSize": 5242880,
  "allowedTypes": ["image/jpeg"]
}
```

**필드 설명:**
- `uploadSessionId`: 업로드 세션 ID (추적용)
- `presignedUrl`: S3에 직접 업로드할 URL (15분 유효)
- `imageUrl`: 업로드 완료 후 사용할 이미지 URL
- `expiresAt`: Presigned URL 만료 시간
- `maxFileSize`: 최대 파일 크기 (5MB)
- `allowedTypes`: 허용된 파일 타입

**실패 응답**
```json
// 400 Bad Request - 파일 타입 불허
{
  "code": "INVALID_FILE_TYPE",
  "message": "지원하지 않는 파일 형식입니다.",
  "allowedTypes": ["image/jpeg", "image/png", "image/webp"]
}

// 400 Bad Request - 파일 크기 초과
{
  "code": "FILE_TOO_LARGE",
  "message": "파일 크기가 너무 큽니다.",
  "maxFileSize": 5242880,
  "requestedSize": 10485760
}

// 401 Unauthorized
{
  "code": "UNAUTHORIZED",
  "message": "로그인이 필요합니다."
}

// 429 Too Many Requests
{
  "code": "UPLOAD_RATE_LIMIT",
  "message": "업로드 요청이 너무 많습니다.",
  "retryAfter": 60
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
  "challengeId": "chal_123",
  "imageUrl": "https://s3.../abc123.jpg",
  "uploadSessionId": "upload_123",
  "textContent": "오늘도 달리기 완료!"
}
```

**성공 응답 (201 Created)**
```json
{
  "verificationId": "ver_789",
  "challengeId": "chal_123",
  "userId": "user_456",
  "imageUrl": "https://s3.../image.jpg",
  "status": "APPROVED",
  "reviewStatus": "AUTO_APPROVED",
  "reportCount": 0,
  "targetDate": "2026-02-18",
  "createdAt": "2026-02-18T14:30:00Z"
}
```

**실패 응답**
```json
// 400 Bad Request - 잘못된 요청
{
  "code": "INVALID_REQUEST",
  "message": "필수 입력값이 누락되었습니다.",
  "field": "challengeId"
}

// 400 Bad Request - 유효하지 않은 세션
{
  "code": "INVALID_UPLOAD_SESSION",
  "message": "유효하지 않은 업로드 세션입니다."
}

// 401 Unauthorized
{
  "code": "UNAUTHORIZED",
  "message": "로그인이 필요합니다."
}

// 403 Forbidden
{
  "code": "FORBIDDEN",
  "message": "크루 멤버만 인증할 수 있습니다."
}

// 409 Conflict - 중복 인증
{
  "code": "DUPLICATE_VERIFICATION",
  "message": "이미 해당 날짜에 인증을 완료했습니다.",
  "existingVerificationId": "ver_123"
}

// 422 Unprocessable Entity - 마감 초과
{
  "code": "VERIFICATION_DEADLINE_PASSED",
  "message": "인증 마감 시간이 지났습니다.",
  "deadline": "2026-02-18T23:59:59Z"
}

// 429 Too Many Requests
{
  "code": "TOO_MANY_REQUESTS",
  "message": "잠시 후 다시 시도해주세요.",
  "retryAfter": 3
}
```

**핵심 규칙:**
- upload_session이 COMPLETED 상태일 때만 호출 가능 (Lambda가 S3 업로드 감지 후 COMPLETED 처리)
- 텍스트 인증 크루인 경우 uploadSessionId, imageUrl 없이 호출 가능
- 마감 시간 기준: upload_session.requested_at (서버 기록, 조작 불가)

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
data: {"uploadSessionId": "upload_123", "status": "COMPLETED"}

event: EXPIRED
data: {"uploadSessionId": "upload_123", "status": "EXPIRED"}

event: ERROR
data: {"uploadSessionId": "upload_123", "message": "처리 중 오류가 발생했습니다."}
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
  "code": "UPLOAD_SESSION_NOT_FOUND",
  "message": "업로드 세션을 찾을 수 없습니다."
}

// 401 Unauthorized
{
  "code": "UNAUTHORIZED",
  "message": "로그인이 필요합니다."
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
  "uploadSessionId": "upload_123",
  "status": "COMPLETED",
  "imageUrl": "https://s3.../abc123.jpg",
  "requestedAt": "2026-02-18T14:30:00Z"
}
```

**status 값:**

| 상태 | 의미 | 클라이언트 동작 |
|------|------|----------------|
| PENDING | 아직 S3 업로드 미완료 | 2~3초 후 재폴링 |
| COMPLETED | 업로드 완료 | POST /verifications 호출 |
| EXPIRED | 만료 | 재시도 안내 |

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
        "nickname": "크루장닉네임",
        "profileImageUrl": "https://...",
        "role": "LEADER"
      },
      {
        "nickname": "멤버닉네임",
        "profileImageUrl": null,
        "role": "MEMBER"
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
| 403 | — | 크루 멤버만 조회할 수 있습니다. | 비멤버 접근 |
| 404 | — | 존재하지 않는 크루입니다. | 잘못된 crewId |

---

## TODO (구현 시 추가 예정)

### Crew Context
- POST /crews — 크루 생성
- GET /crews — 크루 목록 조회

### Verification Context
- GET /crews/{crewId}/feed — 크루 피드 조회

### Moderation Context
- POST /verifications/{id}/reports — 신고

### Support Context
- POST /verifications/{id}/reactions — 반응 (이모지)
