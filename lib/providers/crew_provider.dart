import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/services/crew_service.dart';

final crewListProvider = FutureProvider<List<CrewSummary>>((ref) async {
  final crewService = ref.watch(crewServiceProvider);
  return crewService.getMyCrews();
});

final crewDetailProvider =
    FutureProvider.family<CrewDetail, String>((ref, crewId) async {
  final crewService = ref.watch(crewServiceProvider);
  return crewService.getCrewDetail(crewId);
});
