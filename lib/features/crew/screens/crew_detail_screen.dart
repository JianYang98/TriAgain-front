import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';

class CrewDetailScreen extends StatelessWidget {
  final String crewId;

  const CrewDetailScreen({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '크루 상세',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
      ),
      body: Center(
        child: Text('Crew Detail Screen: $crewId'),
      ),
    );
  }
}
