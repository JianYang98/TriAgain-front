import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/network/api_client.dart';
import 'package:triagain/models/auth.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(apiClientProvider));
});

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<AuthUser> getMe() async {
    final response = await _apiClient.get<AuthUser>(
      '/users/me',
      fromData: (json) => AuthUser.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AuthUser> updateNickname(String nickname) async {
    final response = await _apiClient.patch<AuthUser>(
      '/users/me/nickname',
      data: {'nickname': nickname},
      fromData: (json) => AuthUser.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
