import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/network/api_client.dart';
import 'package:triagain/models/crew.dart';

final crewSearchServiceProvider = Provider<CrewSearchService>((ref) {
  return CrewSearchService(ref.watch(apiClientProvider));
});

class CrewSearchService {
  final ApiClient _apiClient;

  CrewSearchService(this._apiClient);

  Future<SearchCrewResult> searchCrews({
    String? keyword,
    CrewCategory? category,
    int page = 0,
    int size = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParameters['keyword'] = keyword;
    }
    if (category != null) {
      queryParameters['category'] = category.toJson();
    }

    final response = await _apiClient.get<SearchCrewResult>(
      '/crews/search',
      queryParameters: queryParameters,
      fromData: (json) =>
          SearchCrewResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<JoinCrewResult> joinPublicCrew(String crewId) async {
    final response = await _apiClient.post<JoinCrewResult>(
      '/crews/$crewId/join',
      fromData: (json) =>
          JoinCrewResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
