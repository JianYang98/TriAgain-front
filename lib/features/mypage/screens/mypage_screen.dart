import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:triagain/services/auth_service.dart';
import 'package:triagain/services/user_service.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  AuthUser? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // 인증 가드
    final token = ref.read(authTokenProvider);
    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
      // authUserProvider 동기화
      ref.read(authUserProvider.notifier).state = user;
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '사용자 정보를 불러올 수 없습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '마이페이지',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.main),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.grey3),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      TextButton(
                        onPressed: _loadUser,
                        child: Text(
                          '다시 시도',
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.main),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingMD),

          // 프로필 영역
          _buildProfileSection(),

          const SizedBox(height: AppSizes.paddingXL),

          // 메뉴 항목들
          _buildMenuItem(
            icon: Icons.edit,
            label: '닉네임 변경',
            onTap: () => _showNicknameDialog(),
          ),
          _buildMenuItem(
            icon: Icons.logout,
            label: '로그아웃',
            onTap: () => _showLogoutDialog(),
          ),
          _buildMenuItem(
            icon: Icons.delete_outline,
            label: '회원탈퇴',
            textColor: AppColors.grey3,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('준비 중입니다')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        // 프로필 이미지
        ClipOval(
          child: _user?.profileImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: _user!.profileImageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.card,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.grey3,
                      size: 32,
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.card,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.grey3,
                      size: 32,
                    ),
                  ),
                )
              : Container(
                  width: 64,
                  height: 64,
                  color: AppColors.card,
                  child: const Icon(
                    Icons.person,
                    color: AppColors.grey3,
                    size: 32,
                  ),
                ),
        ),
        const SizedBox(width: AppSizes.paddingMD),
        Text(
          _user?.nickname ?? '',
          style: AppTextStyles.heading2.copyWith(color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.paddingMD,
          horizontal: AppSizes.paddingSM,
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.grey4, size: 22),
            const SizedBox(width: AppSizes.paddingMD),
            Text(
              label,
              style: AppTextStyles.body1
                  .copyWith(color: textColor ?? AppColors.grey4),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: textColor ?? AppColors.grey3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showNicknameDialog() {
    final currentNickname = _user?.nickname ?? '';
    final controller = TextEditingController(text: currentNickname);
    String? errorText;
    bool canSave = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void validate() {
              final value = controller.text.trim();
              setDialogState(() {
                if (value.isEmpty) {
                  errorText = null;
                  canSave = false;
                } else if (!nicknameRegex.hasMatch(value)) {
                  if (value.length < 2) {
                    errorText = '닉네임은 2자 이상이어야 합니다';
                  } else if (value.length > 12) {
                    errorText = '닉네임은 12자 이하여야 합니다';
                  } else {
                    errorText = '한글, 영문, 숫자, 밑줄(_)만 사용 가능합니다';
                  }
                  canSave = false;
                } else if (value == currentNickname) {
                  errorText = null;
                  canSave = false;
                } else {
                  errorText = null;
                  canSave = true;
                }
              });
            }

            controller.addListener(validate);

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              ),
              title: Text(
                '닉네임 변경',
                style:
                    AppTextStyles.heading3.copyWith(color: AppColors.white),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 12,
                style: AppTextStyles.body1.copyWith(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: '새 닉네임 입력 (2~12자)',
                  hintStyle:
                      AppTextStyles.body2.copyWith(color: AppColors.grey3),
                  counterStyle:
                      AppTextStyles.caption.copyWith(color: AppColors.grey3),
                  errorText: errorText,
                  errorStyle:
                      AppTextStyles.caption.copyWith(color: AppColors.error),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.grey1),
                  ),
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    '취소',
                    style:
                        AppTextStyles.body2.copyWith(color: AppColors.grey3),
                  ),
                ),
                TextButton(
                  onPressed: canSave
                      ? () async {
                          final nickname = controller.text.trim();
                          Navigator.of(dialogContext).pop();
                          await _updateNickname(nickname);
                        }
                      : null,
                  child: Text(
                    '저장',
                    style: AppTextStyles.body2.copyWith(
                      color: canSave ? AppColors.main : AppColors.grey3,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateNickname(String nickname) async {
    try {
      final userService = ref.read(userServiceProvider);
      final updatedUser = await userService.updateNickname(nickname);

      // authUserProvider 갱신 → 화면 즉시 반영
      ref.read(authUserProvider.notifier).state = updatedUser;
      if (!mounted) return;
      setState(() => _user = updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임이 변경되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        title: Text(
          '로그아웃',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        content: Text(
          '로그아웃 하시겠습니까?',
          style: AppTextStyles.body1.copyWith(color: AppColors.grey4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '취소',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performLogout();
            },
            child: Text(
              '확인',
              style: AppTextStyles.body2.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // best-effort: 서버 호출 실패해도 로컬 정리는 항상 수행
    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
    } catch (_) {
      // 무시
    }

    // 로컬 토큰 정리 (항상 수행)
    ref.read(authTokenProvider.notifier).state = null;
    ref.read(authUserIdProvider.notifier).state = null;
    ref.read(authUserProvider.notifier).state = null;
    final storage = ref.read(secureStorageProvider);
    await deleteRefreshToken(storage);

    if (!mounted) return;
    context.go('/login'); // go()로 back stack 교체 → 뒤로가기 방지
  }
}
