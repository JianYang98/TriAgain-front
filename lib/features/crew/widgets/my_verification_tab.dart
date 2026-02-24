import 'package:flutter/material.dart';

class MyVerificationTab extends StatelessWidget {
  final String crewId;

  const MyVerificationTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('나의 인증'),
    );
  }
}
