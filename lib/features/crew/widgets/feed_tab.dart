import 'package:flutter/material.dart';

class FeedTab extends StatelessWidget {
  final String crewId;

  const FeedTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('인증 피드'),
    );
  }
}
