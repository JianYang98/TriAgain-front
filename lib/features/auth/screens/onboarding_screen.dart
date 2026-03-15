import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/validation.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/auth.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/auth_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nicknameController;
  bool _serviceTermsAgreed = false;
  bool _privacyTermsAgreed = false;
  bool _isLoading = false;
  String? _nicknameError;

  @override
  void initState() {
    super.initState();
    final kakaoProfile = ref.read(kakaoProfileProvider);
    final appleProfile = ref.read(appleProfileProvider);
    final profile = kakaoProfile ?? appleProfile;
    final defaultNickname =
        profile != null ? filterNickname(profile.nickname) : '';
    _nicknameController = TextEditingController(text: defaultNickname);
    _nicknameController.addListener(_validateNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _validateNickname() {
    final value = _nicknameController.text;
    setState(() {
      if (value.isEmpty) {
        _nicknameError = null;
      } else if (!nicknameRegex.hasMatch(value)) {
        if (value.length < 2) {
          _nicknameError = '닉네임은 2자 이상이어야 합니다';
        } else if (value.length > 12) {
          _nicknameError = '닉네임은 12자 이하여야 합니다';
        } else {
          _nicknameError = '한글, 영문, 숫자, 밑줄(_)만 사용 가능합니다';
        }
      } else {
        _nicknameError = null;
      }
    });
  }

  bool get _isFormValid =>
      _serviceTermsAgreed &&
      _privacyTermsAgreed &&
      nicknameRegex.hasMatch(_nicknameController.text);

  Future<void> _signup() async {
    if (!_isFormValid || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final kakaoAccessToken = ref.read(kakaoAccessTokenProvider);
      final kakaoId = ref.read(kakaoIdProvider);
      final appleIdentityToken = ref.read(appleIdentityTokenProvider);
      final appleUserId = ref.read(appleUserIdProvider);

      final authService = ref.read(authServiceProvider);
      final SignupResponse result;

      if (kakaoAccessToken != null && kakaoId != null) {
        // 카카오 회원가입
        result = await authService.signup(
          kakaoAccessToken: kakaoAccessToken,
          kakaoId: kakaoId,
          nickname: _nicknameController.text,
          termsAgreed: true,
        );
      } else if (appleIdentityToken != null && appleUserId != null) {
        // Apple 회원가입
        result = await authService.signupWithApple(
          identityToken: appleIdentityToken,
          appleUserId: appleUserId,
          nickname: _nicknameController.text,
          termsAgreed: true,
        );
      } else {
        if (mounted) context.go('/login');
        return;
      }

      // 토큰 저장
      ref.read(authTokenProvider.notifier).state = result.accessToken;
      ref.read(authUserIdProvider.notifier).state = result.user.id;
      ref.read(authUserProvider.notifier).state = result.user;

      // refreshToken → SecureStorage
      final storage = ref.read(secureStorageProvider);
      await saveRefreshToken(storage, result.refreshToken);

      // 임시 데이터 즉시 폐기 (카카오 + Apple 모두)
      ref.read(kakaoAccessTokenProvider.notifier).state = null;
      ref.read(kakaoIdProvider.notifier).state = null;
      ref.read(kakaoProfileProvider.notifier).state = null;
      ref.read(appleIdentityTokenProvider.notifier).state = null;
      ref.read(appleUserIdProvider.notifier).state = null;
      ref.read(appleProfileProvider.notifier).state = null;

      // 크루 캐시 초기화
      ref.invalidate(crewListProvider);

      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '회원가입',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingMD),

              // 약관 동의
              Text(
                '약관 동의',
                style: AppTextStyles.heading3.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              _buildTermsRow(
                label: '서비스 이용약관 동의 (필수)',
                value: _serviceTermsAgreed,
                onChanged: (v) =>
                    setState(() => _serviceTermsAgreed = v ?? false),
                onDetailTap: () => context.push('/terms/service'),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              _buildTermsRow(
                label: '개인정보 처리방침 동의 (필수)',
                value: _privacyTermsAgreed,
                onChanged: (v) =>
                    setState(() => _privacyTermsAgreed = v ?? false),
                onDetailTap: () => context.push('/terms/privacy'),
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // 닉네임 입력
              Text(
                '닉네임',
                style: AppTextStyles.heading3.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              TextField(
                controller: _nicknameController,
                style: AppTextStyles.body1.copyWith(color: AppColors.white),
                maxLength: 12,
                decoration: InputDecoration(
                  hintText: '닉네임을 입력해주세요 (2~12자)',
                  hintStyle:
                      AppTextStyles.body1.copyWith(color: AppColors.grey3),
                  counterStyle:
                      AppTextStyles.caption.copyWith(color: AppColors.grey3),
                  errorText: _nicknameError,
                  errorStyle:
                      AppTextStyles.caption.copyWith(color: AppColors.error),
                  filled: true,
                  fillColor: AppColors.card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.grey1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.main),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              Text(
                '한글, 영문, 숫자, 밑줄(_)만 사용 가능',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
              ),

              const Spacer(),

              // 가입하기 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _signup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isFormValid ? AppColors.main : AppColors.grey2,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.grey2,
                    disabledForegroundColor: AppColors.grey3,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.buttonRadius),
                    ),
                    textStyle: AppTextStyles.button,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('가입하기'),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onDetailTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.main,
            checkColor: AppColors.white,
            side: const BorderSide(color: AppColors.grey3),
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              label,
              style: AppTextStyles.body2.copyWith(color: AppColors.grey4),
            ),
          ),
        ),
        GestureDetector(
          onTap: onDetailTap,
          child: Text(
            '전문 보기 >',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
          ),
        ),
      ],
    );
  }
}
