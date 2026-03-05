import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/services/crew_service.dart';

final crewListProvider = FutureProvider<List<CrewSummary>>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return [];
  final crewService = ref.watch(crewServiceProvider);
  return crewService.getMyCrews();
});

final crewDetailProvider =
    FutureProvider.family<CrewDetail, String>((ref, crewId) async {
  final crewService = ref.watch(crewServiceProvider);
  return crewService.getCrewDetail(crewId);
});

final crewByInviteCodeProvider =
    FutureProvider.family<CrewDetail, String>((ref, inviteCode) async {
  final crewService = ref.watch(crewServiceProvider);
  return crewService.getCrewByInviteCode(inviteCode);
});
