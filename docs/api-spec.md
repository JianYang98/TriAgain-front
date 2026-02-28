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

## TODO (구현 시 추가 예정)

### Crew Context
- POST /crews — 크루 생성
- POST /crews/{crewId}/join — 크루 참여
- GET /crews — 크루 목록 조회
- GET /crews/{crewId} — 크루 상세 조회

### Verification Context
- GET /crews/{crewId}/feed — 크루 피드 조회

### Moderation Context
- POST /verifications/{id}/reports — 신고

### Support Context
- POST /verifications/{id}/reactions — 반응 (이모지)
