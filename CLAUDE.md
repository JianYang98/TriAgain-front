# CLAUDE.md - TriAgain Frontend (Flutter)

## Role & Persona

너는 Flutter/Dart에 능통한 시니어 모바일 개발자다.
- 피그마 와이어프레임을 정확히 재현한다
- 깔끔하고 재사용 가능한 위젯 구조를 만든다
- 불확실하면 추측하지 말고 질문한다

---

## Project Overview

**TriAgain — Start Small. Try Again.**

작심삼일도 괜찮아. 3일 단위 챌린지 습관 형성 앱.

- 소규모 크루(2~10명)와 함께 3일 챌린지
- 실패해도 새 3일 챌린지 자동 시작
- 크루장이 인증 방식 선택 (텍스트 / 사진 필수)

---

## Tech Stack

- Flutter 3.16+, Dart 3.2+
- 상태관리: Riverpod (또는 Provider)
- HTTP: Dio
- 라우팅: GoRouter
- 이미지: image_picker, cached_network_image
- 실시간 통신: SSE (Server-Sent Events) — 업로드 완료 알림 수신

---

## Design Token

### Colors

| 이름 | 값 | 용도 |
|------|-----|------|
| background | #0A0A0B | 앱 배경 |
| card | #242428 | 카드 배경 |
| cardHover | #2E2E34 | 카드 호버/눌림 |
| main | #FE5027 | 메인 다홍색 |
| mainLight | #FF7A5A | 메인 밝은 버전 |
| mainDark | #D93D1A | 메인 어두운 버전 |
| white | #FFFFFF | 기본 텍스트 |
| grey1 | #2E3034 | 보더, 구분선 |
| grey2 | #4E5067 | 비활성 요소 |
| grey3 | #808996 | 서브텍스트 |
| grey4 | #D5DBE1 | 밝은 텍스트 |
| grey5 | #EBECF1 | 가장 밝은 텍스트 |
| success | #00B991 | 성공, 진행중 |
| warning | #F9D869 | 경고, 모집중 |
| error | #EE0000 | 에러, 실패 |

### Radius

| 이름 | 값 | 용도 |
|------|-----|------|
| cardRadius | 16px | 카드, 배너 |
| buttonRadius | 10px | 버튼, 인풋 |
| badgeRadius | 100px | 뱃지 |

### Typography

- 폰트: Noto Sans KR
- 디자인 기준: iPhone 14 (390 x 844)

---

## 폴더 구조

```
lib/
├── main.dart
├── app/
│   ├── router.dart              // GoRouter 설정
│   └── theme.dart               // 테마, 컬러, 폰트
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      // 색상 상수
│   │   ├── app_text_styles.dart // 텍스트 스타일
│   │   └── app_sizes.dart       // 사이즈, 패딩
│   └── utils/                   // 공통 유틸
├── features/
│   ├── auth/                    // 로그인
│   │   └── screens/
│   │       └── login_screen.dart
│   ├── home/                    // 홈 화면
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── widgets/
│   │       └── crew_card.dart
│   ├── crew/                    // 크루
│   │   ├── screens/
│   │   │   ├── create_crew_screen.dart
│   │   │   ├── crew_success_screen.dart
│   │   │   ├── crew_confirm_screen.dart
│   │   │   └── crew_detail_screen.dart
│   │   └── widgets/
│   │       ├── my_verification_tab.dart
│   │       ├── member_status_tab.dart
│   │       └── feed_tab.dart
│   └── verification/            // 인증하기
│       └── screens/
│           └── verification_screen.dart
├── models/                      // 데이터 모델
│   ├── crew.dart
│   ├── challenge.dart
│   ├── verification.dart
│   └── mock_data.dart           // Mock 데이터
├── services/                    // API 서비스
│   └── api_service.dart
└── widgets/                     // 공통 위젯
    ├── app_button.dart
    ├── app_card.dart
    ├── app_input.dart
    └── toggle_selector.dart
```

---

## 화면 목록 (Phase 1)

| 번호 | 화면 | 파일 | 설명 |
|------|------|------|------|
| 1 | 로그인 | login_screen.dart | 로고 + 슬로건 + 카카오 버튼 |
| 2 | 홈 | home_screen.dart | 크루 카드 목록 + 프로그레스바 + 버튼 |
| 3 | 크루 만들기 | create_crew_screen.dart | 이름, 목표, 인원, 기간, 인증방식, 중간가입 |
| 4 | 크루 생성 완료 | crew_success_screen.dart | 초대코드 + 복사/공유 버튼 |
| 5 | 크루 상세 | crew_detail_screen.dart | 탭 3개 (나의 인증 / 참가자 현황 / 인증 피드) |
| 6 | 인증하기 | verification_screen.dart | 사진 영역 + 텍스트 입력 + 인증 완료 |
| 7 | 크루 확인 | crew_confirm_screen.dart | 초대코드 입력 후 크루 정보 확인 + 참여 |

---

## 화면 흐름

```
로그인 → 홈 → 크루 만들기 → 생성 완료 → 홈
홈 → 크루 카드 클릭 → 크루 상세 (탭 3개)
크루 상세 → 오늘 인증하기 → 인증하기 화면
홈 → 초대코드 버튼 → 코드 입력 → 크루 확인 → 크루 참여 → 홈
```

---

## Coding Convention

### 위젯

- 100줄 넘으면 별도 위젯 파일로 분리
- StatelessWidget 우선, 상태 필요 시 ConsumerWidget (Riverpod)
- build() 안에서 복잡한 로직 금지 → 메서드로 분리

### 네이밍

- 위젯/클래스: PascalCase (`CrewCard`, `HomeScreen`)
- 변수/메서드: camelCase (`crewName`, `onPressed`)
- 파일명: snake_case (`crew_card.dart`, `home_screen.dart`)
- 상수: camelCase in class (`AppColors.main`, `AppSizes.cardRadius`)

### 스타일

- 색상 하드코딩 금지 → `AppColors.main` 사용
- 폰트 사이즈 하드코딩 금지 → `AppTextStyles.title` 사용
- 패딩/마진 하드코딩 최소화 → `AppSizes.padding` 사용
- Mock 데이터는 `models/mock_data.dart`에 분리

---

## Anti-Patterns

- 위젯 안에 `Color(0xFFFE5027)` 하드코딩 금지 → AppColors 사용
- `BuildContext`를 async gap 넘기지 않기
- `setState` 남용 금지 → Riverpod 사용
- 한 파일에 여러 Screen 위젯 몰아넣기 금지
- 비즈니스 로직을 위젯 안에 넣지 않기

---

## 사진 인증 업로드 플로우

### 시퀀스

```
1. POST /upload-sessions → presignedUrl, sessionId 수신
2. GET /upload-sessions/{id}/events → SSE 구독 (업로드 완료 알림용)
3. presignedUrl로 S3에 사진 업로드
4. SSE로 "COMPLETED" 이벤트 수신 (Lambda가 S3 업로드 감지 → session 상태 변경)
5. POST /verifications → 인증 생성
```

### 프론트 구현 포인트

- SSE 구독: `GET /upload-sessions/{id}/events` — presignedUrl 수신 직후 연결
- COMPLETED 이벤트 수신 시 자동으로 `/verifications` 호출
- SSE 타임아웃: 30초 → 실패 시 사용자에게 재시도 안내
- SSE 연결 끊김 fallback: `GET /upload-sessions/{id}`로 폴링하여 상태 확인

---

## 개발 순서

```
Phase 1: Mock 데이터로 전체 화면 완성
Phase 2: 백엔드 API 연동 (Dio + baseUrl 설정)
Phase 3: 카카오 로그인 연동
```

---

## 참고 문서

- 백엔드 API 명세: `/docs/api-spec.md`
- 비즈니스 규칙: `/docs/biz-logic.md`
- ERD / 스키마: `/docs/schema.md`
- 컨텍스트 맵: `/docs/context-map.md`