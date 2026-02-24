import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';

class CrewSuccessScreen extends StatelessWidget {
  const CrewSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '크루 생성 완료',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
      ),
      body: const Center(
        child: Text('Crew Success Screen'),
      ),
    );
  }
}
