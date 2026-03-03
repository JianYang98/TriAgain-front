import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';

class TermsDetailScreen extends StatelessWidget {
  final String termsType;

  const TermsDetailScreen({super.key, required this.termsType});

  String get _title =>
      termsType == 'privacy' ? '개인정보 처리방침' : '서비스 이용약관';

  String get _content => termsType == 'privacy'
      ? '''개인정보 처리방침

TriAgain(이하 '서비스')은 사용자의 개인정보를 중요하게 생각합니다.

1. 수집하는 개인정보
- 카카오 계정 정보 (닉네임, 프로필 이미지, 이메일)
- 서비스 이용 기록

2. 개인정보의 이용 목적
- 서비스 제공 및 운영
- 사용자 식별 및 인증
- 서비스 개선

3. 개인정보의 보유 및 파기
- 회원 탈퇴 시 즉시 파기
- 관련 법령에 따른 보존 기간 준수

4. 개인정보의 제3자 제공
- 사용자의 동의 없이 제3자에게 제공하지 않습니다.

본 방침은 서비스 출시 전 임시 버전이며, 정식 출시 시 업데이트됩니다.'''
      : '''서비스 이용약관

TriAgain 서비스 이용약관에 동의해 주셔서 감사합니다.

제1조 (목적)
본 약관은 TriAgain 서비스의 이용과 관련하여 필요한 사항을 규정합니다.

제2조 (서비스의 내용)
- 3일 단위 챌린지 생성 및 참여
- 크루(그룹) 생성 및 관리
- 인증 기록 작성 및 공유

제3조 (이용자의 의무)
- 타인의 개인정보를 부정하게 사용하지 않습니다.
- 서비스의 정상적인 운영을 방해하지 않습니다.
- 허위 인증을 하지 않습니다.

제4조 (서비스 이용 제한)
- 본 약관을 위반한 경우 서비스 이용이 제한될 수 있습니다.

본 약관은 서비스 출시 전 임시 버전이며, 정식 출시 시 업데이트됩니다.''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          _title,
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Text(
          _content,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grey4,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
