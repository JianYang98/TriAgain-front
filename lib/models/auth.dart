class KakaoLoginResponse {
  final bool isNewUser;
  final String? accessToken;
  final String? refreshToken;
  final int? accessTokenExpiresIn;
  final AuthUser? user;
  final String? kakaoId;
  final KakaoProfile? kakaoProfile;
  final String? appleId;
  final String? email;

  const KakaoLoginResponse({
    required this.isNewUser,
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpiresIn,
    this.user,
    this.kakaoId,
    this.kakaoProfile,
    this.appleId,
    this.email,
  });

  factory KakaoLoginResponse.fromJson(Map<String, dynamic> json) {
    return KakaoLoginResponse(
      isNewUser: json['isNewUser'] as bool,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      accessTokenExpiresIn: json['accessTokenExpiresIn'] as int?,
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      kakaoId: json['kakaoId'] as String?,
      kakaoProfile: json['kakaoProfile'] != null
          ? KakaoProfile.fromJson(
              json['kakaoProfile'] as Map<String, dynamic>)
          : null,
      appleId: json['appleId'] as String?,
      email: json['email'] as String?,
    );
  }
}

class AuthUser {
  final String id;
  final String nickname;
  final String? profileImageUrl;
  final String? email;

  const AuthUser({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
    this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      email: json['email'] as String?,
    );
  }
}

class KakaoProfile {
  final String nickname;
  final String? email;
  final String? profileImageUrl;

  const KakaoProfile({
    required this.nickname,
    this.email,
    this.profileImageUrl,
  });

  factory KakaoProfile.fromJson(Map<String, dynamic> json) {
    return KakaoProfile(
      nickname: json['nickname'] as String,
      email: json['email'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}

class SignupResponse {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final AuthUser user;

  const SignupResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.user,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresIn: json['accessTokenExpiresIn'] as int,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
