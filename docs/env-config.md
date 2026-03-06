# 환경 설정 가이드

## 개요

`--dart-define`으로 빌드 시 환경 변수를 주입한다.
코드에 IP/키를 하드코딩하지 않으므로, 서버 변경 시 코드 수정 없이 스크립트만 수정하면 된다.

## 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `BASE_URL` | 백엔드 서버 URL | `http://localhost:8080` |
| `KAKAO_NATIVE_KEY` | 카카오 네이티브 앱 키 | (없음, 필수) |

## 실행 방법

```bash
# 로컬 개발
./dev_run.sh

# 운영 서버 (EC2)
./prod_run.sh
```

## 스크립트 설정

`*_run.sh` 파일은 `.gitignore`에 포함되어 커밋되지 않는다.
처음 세팅 시 `.example` 파일을 복사하여 실제 키를 채운다:

```bash
cp dev_run.sh.example dev_run.sh
cp prod_run.sh.example prod_run.sh
chmod +x dev_run.sh prod_run.sh

# 각 파일에서 YOUR_KAKAO_KEY, YOUR_SERVER_IP를 실제 값으로 교체
```

## 코드 구조

`lib/core/constants/app_config.dart`:

```dart
class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
```

`api_client.dart`, `auth_service.dart`에서 `AppConfig.baseUrl`을 사용한다.

## 네이밍 컨벤션

| 위치 | 로컬 | 운영 |
|------|------|------|
| Flutter (프론트) | `dev_run.sh` | `prod_run.sh` |
| EC2 (서버) | `dev_start.sh` | `prod_start.sh` |
