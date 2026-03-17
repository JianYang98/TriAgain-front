import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/crew_service.dart';
import 'package:triagain/widgets/app_button.dart';

class CrewEditScreen extends ConsumerStatefulWidget {
  final String crewId;

  const CrewEditScreen({super.key, required this.crewId});

  @override
  ConsumerState<CrewEditScreen> createState() => _CrewEditScreenState();
}

class _CrewEditScreenState extends ConsumerState<CrewEditScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _verificationContentController = TextEditingController();

  bool _initialized = false;
  bool _isSubmitting = false;

  String _originalName = '';
  String _originalGoal = '';
  String _originalVerificationContent = '';

  // 사용자가 수정한 적 있는 필드 추적
  bool _nameTouched = false;
  bool _goalTouched = false;
  bool _verificationContentTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _goalController.addListener(_onFieldChanged);
    _verificationContentController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _verificationContentController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // 초기화 전에는 무시
    if (!_initialized) return;

    // touched 플래그 세팅
    if (_nameController.text != _originalName) _nameTouched = true;
    if (_goalController.text != _originalGoal) _goalTouched = true;
    if (_verificationContentController.text != _originalVerificationContent) {
      _verificationContentTouched = true;
    }

    setState(() {});
  }

  String? _getFieldError(String text, bool touched) {
    if (!touched) return null;
    if (text.trim().isEmpty) return '내용을 입력해주세요';
    return null;
  }

  String? get _nameError =>
      _getFieldError(_nameController.text, _nameTouched);
  String? get _goalError =>
      _getFieldError(_goalController.text, _goalTouched);
  String? get _verificationContentError =>
      _getFieldError(_verificationContentController.text, _verificationContentTouched);

  bool get _hasError =>
      _nameError != null || _goalError != null || _verificationContentError != null;

  bool get _hasChanges {
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();
    final vc = _verificationContentController.text.trim();
    return name != _originalName || goal != _originalGoal || vc != _originalVerificationContent;
  }

  bool get _canSubmit => _hasChanges && !_hasError && !_isSubmitting;

  Future<void> _handleSubmit() async {
    // 제출 시 모든 필드 touched 처리
    setState(() {
      _nameTouched = true;
      _goalTouched = true;
      _verificationContentTouched = true;
    });

    if (_hasError || !_hasChanges) return;

    setState(() => _isSubmitting = true);

    try {
      final crewService = ref.read(crewServiceProvider);

      final changes = <String, dynamic>{};
      final name = _nameController.text.trim();
      final goal = _goalController.text.trim();
      final vc = _verificationContentController.text.trim();

      if (name != _originalName) changes['name'] = name;
      if (goal != _originalGoal) changes['goal'] = goal;
      if (vc != _originalVerificationContent) {
        changes['verificationContent'] = vc;
      }

      await crewService.editCrew(widget.crewId, changes);

      ref.invalidate(crewDetailProvider(widget.crewId));
      ref.invalidate(crewListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('크루가 수정되었습니다')),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crewAsync = ref.watch(crewDetailProvider(widget.crewId));

    return crewAsync.when(
      data: (crew) {
        if (!_initialized) {
          _originalName = crew.name;
          _originalGoal = crew.goal;
          _originalVerificationContent = crew.verificationContent ?? '';

          _nameController.text = _originalName;
          _goalController.text = _originalGoal;
          _verificationContentController.text = _originalVerificationContent;

          _initialized = true;
        }

        return _buildForm(context);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.main),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '크루 정보를 불러올 수 없습니다',
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.grey3),
                      ),
                      const SizedBox(height: AppSizes.paddingSM),
                      TextButton(
                        onPressed: () => ref
                            .invalidate(crewDetailProvider(widget.crewId)),
                        child: Text(
                          '다시 시도',
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.main),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.paddingSM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '크루 수정',
            style: AppTextStyles.heading1.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.paddingSM),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '크루 이름',
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey4),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nameController,
                          maxLength: 20,
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: '크루 이름을 입력하세요',
                            hintStyle: AppTextStyles.body2
                                .copyWith(color: AppColors.grey3),
                            counterStyle: AppTextStyles.caption
                                .copyWith(color: AppColors.grey3),
                            filled: true,
                            fillColor: AppColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.grey1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _nameError != null ? AppColors.error : AppColors.grey1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _nameError != null ? AppColors.error : AppColors.grey2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        if (_nameError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 4),
                            child: Text(
                              _nameError!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingMD),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '목표',
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey4),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _goalController,
                          maxLength: 50,
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: '목표를 입력하세요',
                            hintStyle: AppTextStyles.body2
                                .copyWith(color: AppColors.grey3),
                            counterStyle: AppTextStyles.caption
                                .copyWith(color: AppColors.grey3),
                            filled: true,
                            fillColor: AppColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.grey1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _goalError != null ? AppColors.error : AppColors.grey1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _goalError != null ? AppColors.error : AppColors.grey2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        if (_goalError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 4),
                            child: Text(
                              _goalError!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingMD),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '인증 내용',
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey4),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _verificationContentController,
                          maxLength: 50,
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: '예: 운동 완료 인증샷 찍기',
                            hintStyle: AppTextStyles.body2
                                .copyWith(color: AppColors.grey3),
                            counterStyle: AppTextStyles.caption
                                .copyWith(color: AppColors.grey3),
                            filled: true,
                            fillColor: AppColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.grey1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _verificationContentError != null ? AppColors.error : AppColors.grey1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _verificationContentError != null ? AppColors.error : AppColors.grey2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        if (_verificationContentError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 4),
                            child: Text(
                              _verificationContentError!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingLG),
                  ],
                ),
              ),
            ),

            // 하단 고정 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMD,
                AppSizes.paddingSM,
                AppSizes.paddingMD,
                AppSizes.paddingMD,
              ),
              child: AppButton(
                text: '수정 완료',
                isLoading: _isSubmitting,
                onPressed: _canSubmit ? _handleSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
