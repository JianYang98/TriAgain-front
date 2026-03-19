import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/network/api_client.dart';
import 'package:triagain/models/crew.dart';

final crewServiceProvider = Provider<CrewService>((ref) {
  return CrewService(ref.watch(apiClientProvider));
});

class CrewService {
  final ApiClient _apiClient;

  CrewService(this._apiClient);

  Future<List<CrewSummary>> getMyCrews() async {
    final response = await _apiClient.get<List<CrewSummary>>(
      '/crews',
      fromData: (json) => (json as List)
          .map((e) => CrewSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data!;
  }

  Future<CrewDetail> getCrewDetail(String crewId) async {
    final response = await _apiClient.get<CrewDetail>(
      '/crews/$crewId',
      fromData: (json) => CrewDetail.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<CreateCrewResult> createCrew({
    required String name,
    required String goal,
    required String verificationContent,
    required VerificationType verificationType,
    required int maxMembers,
    required DateTime startDate,
    required DateTime endDate,
    required bool allowLateJoin,
    required CrewCategory category,
    CrewVisibility visibility = CrewVisibility.private,
    String? deadlineTime,
  }) async {
    final response = await _apiClient.post<CreateCrewResult>(
      '/crews',
      data: {
        'name': name,
        'goal': goal,
        'verificationContent': verificationContent,
        'verificationType': verificationType.toJson(),
        'maxMembers': maxMembers,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
        'allowLateJoin': allowLateJoin,
        'category': category.toJson(),
        'visibility': visibility.toJson(),
        if (deadlineTime != null) 'deadlineTime': deadlineTime,
      },
      fromData: (json) =>
          CreateCrewResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<CrewDetail> getCrewByInviteCode(String inviteCode) async {
    final response = await _apiClient.get<CrewDetail>(
      '/crews/invite/$inviteCode',
      fromData: (json) => CrewDetail.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<JoinCrewResult> joinCrew(String inviteCode) async {
    final response = await _apiClient.post<JoinCrewResult>(
      '/crews/join',
      data: {'inviteCode': inviteCode},
      fromData: (json) =>
          JoinCrewResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> editCrew(String crewId, Map<String, dynamic> changes) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/crews/$crewId',
      data: changes,
      fromData: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteCrew(String crewId) async {
    await _apiClient.delete('/crews/$crewId');
  }

  Future<CrewDetail> getCrewPreview(String crewId) async {
    final response = await _apiClient.get<CrewDetail>(
      '/crews/$crewId/preview',
      fromData: (json) => CrewDetail.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<JoinCrewResult> joinCrewById(String crewId) async {
    final response = await _apiClient.post<JoinCrewResult>(
      '/crews/$crewId/join',
      fromData: (json) =>
          JoinCrewResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> leaveCrew(String crewId) async {
    await _apiClient.delete('/crews/$crewId/members/me');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
