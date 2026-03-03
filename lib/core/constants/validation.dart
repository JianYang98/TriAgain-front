final nicknameRegex = RegExp(r'^[가-힣a-zA-Z0-9_]{2,12}$');

/// 카카오 닉네임에서 허용 문자만 추출하여 기본값 생성
/// 1. [가-힣a-zA-Z0-9_] 이외 제거
/// 2. 12자 초과 시 12자로 자르기
/// 3. 2자 미만이면 빈값 (사용자 직접 입력 유도)
String filterNickname(String raw) {
  final filtered = raw.replaceAll(RegExp(r'[^가-힣a-zA-Z0-9_]'), '');
  final trimmed = filtered.length > 12 ? filtered.substring(0, 12) : filtered;
  return trimmed.length >= 2 ? trimmed : '';
}
