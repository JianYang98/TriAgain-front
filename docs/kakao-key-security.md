# 카카오 키 보안 가이드

## 현재 상황

| 항목 | 상태 | 설명 |
|------|------|------|
| `lib/main.dart` | **해결됨** | `--dart-define` 빌드 타임 주입으로 전환 |
| `ios/Runner/Info.plist` | **노출됨** | URL scheme에 키 포함 (`kakao2c3712c...`), 커밋 `2ff449d`에서 유입 |

> iOS URL scheme은 정적 문자열이어야 하므로 Info.plist에서 완전히 제거하기 어려움.
> **키 재발급 후 Info.plist도 새 키로 교체** 필요.

---

## 키 재발급 절차

1. [Kakao Developers](https://developers.kakao.com/) 접속
2. 내 애플리케이션 → TriAgain 선택
3. 앱 키 → **네이티브 앱 키 재발급**
4. 새 키로 아래 파일 업데이트:
   - `dev_run.sh` — `KAKAO_NATIVE_KEY=<새키>`
   - `ios/Runner/Info.plist` — URL scheme `kakao<새키>`로 교체
   - `android/app/src/main/AndroidManifest.xml` — 카카오 관련 scheme 확인
5. CI/CD 환경변수도 새 키로 교체

---

## 로컬 개발

프로젝트 루트에 `dev_run.sh`가 있음 (`.gitignore`에 포함, 커밋되지 않음):

```bash
#!/usr/bin/env bash
set -euo pipefail
flutter run --dart-define=KAKAO_NATIVE_KEY=<실제_카카오_키>
```

**처음 세팅 시:**
1. `dev_run.sh`에서 `__PUT_YOUR_KEY_HERE__`를 실제 키로 교체
2. `./dev_run.sh`로 실행

**`--dart-define` 없이 실행하면:**
- 앱 자체는 정상 실행
- 카카오 로그인 버튼만 동작 안 함 (빈 키)
- 콘솔에 경고 출력: `KAKAO_NATIVE_KEY not provided`

---

## CI/CD 설정

### GitHub Actions 예시

```yaml
- name: Build Flutter
  run: flutter build apk --dart-define=KAKAO_NATIVE_KEY=${{ secrets.KAKAO_NATIVE_KEY }}
```

GitHub repo → Settings → Secrets → `KAKAO_NATIVE_KEY` 추가.

### Xcode Cloud / Fastlane

```bash
flutter build ios --dart-define=KAKAO_NATIVE_KEY=$KAKAO_NATIVE_KEY
```

---

## 코드 구조

```
lib/main.dart
├── const kakaoKey = String.fromEnvironment('KAKAO_NATIVE_KEY');
├── if (kakaoKey.isEmpty) debugPrint('경고');
└── KakaoSdk.init(nativeAppKey: kakaoKey);
```

`String.fromEnvironment`는 컴파일 타임 상수 → `--dart-define`으로만 주입 가능 (런타임 `.env`와 다름).
