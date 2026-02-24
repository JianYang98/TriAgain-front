import 'package:flutter/material.dart';

class MemberStatusTab extends StatelessWidget {
  final String crewId;

  const MemberStatusTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('참가자 현황'),
    );
  }
}
