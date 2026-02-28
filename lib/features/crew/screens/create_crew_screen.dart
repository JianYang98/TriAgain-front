import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/crew_service.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/toggle_selector.dart';

class CreateCrewScreen extends ConsumerStatefulWidget {
  const CreateCrewScreen({super.key});

  @override
  ConsumerState<CreateCrewScreen> createState() => _CreateCrewScreenState();
}

class _CreateCrewScreenState extends ConsumerState<CreateCrewScreen> {
  static const _minDurationDays = 6; // 작심삼일 최소 2회

  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  int _maxMembers = 5;
  late DateTime _startDate;
  DateTime? _endDate;
  VerificationType _verificationType = VerificationType.photo;
  bool _allowLateJoin = false;
  bool _isSubmitting = false;

  DateTime get _tomorrow {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime get _minEndDate =>
      _startDate.add(const Duration(days: _minDurationDays));

  @override
  void initState() {
    super.initState();
    _startDate = _tomorrow;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();

    if (name.isEmpty || goal.isEmpty || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final crewService = ref.read(crewServiceProvider);
      final result = await crewService.createCrew(
        name: name,
        goal: goal,
        verificationType: _verificationType,
        maxMembers: _maxMembers,
        startDate: _startDate,
        endDate: _endDate!,
        allowLateJoin: _allowLateJoin,
      );

      ref.invalidate(crewListProvider);

      if (!mounted) return;

      final dateStr =
          '${result.startDate.year}.${result.startDate.month.toString().padLeft(2, '0')}.${result.startDate.day.toString().padLeft(2, '0')}';
      context.go(
          '/crew/success?inviteCode=${result.inviteCode}&startDate=$dateStr');
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
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
                    '크루 만들기',
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),

            // 스크롤 가능한 폼 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.paddingSM),

                    _buildSection(
                      label: '크루 이름',
                      child: TextField(
                        controller: _nameController,
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: '크루 이름을 입력하세요',
                          hintStyle: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    _buildSection(
                      label: '목표',
                      child: TextField(
                        controller: _goalController,
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: '목표를 입력하세요',
                          hintStyle: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    _buildSection(
                      label: '최대 인원',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _maxMembers > 2
                                ? () => setState(() => _maxMembers--)
                                : null,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.grey1),
                              ),
                              child: Icon(
                                Icons.remove,
                                color: _maxMembers > 2
                                    ? AppColors.white
                                    : AppColors.grey2,
                                size: 20,
                              ),
                            ),
                          ),
                          Text(
                            '$_maxMembers명',
                            style: AppTextStyles.heading2
                                .copyWith(color: AppColors.white),
                          ),
                          GestureDetector(
                            onTap: _maxMembers < 10
                                ? () => setState(() => _maxMembers++)
                                : null,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.grey1),
                              ),
                              child: Icon(
                                Icons.add,
                                color: _maxMembers < 10
                                    ? AppColors.white
                                    : AppColors.grey2,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSection(
                            label: '시작일',
                            child: GestureDetector(
                              onTap: () => _pickDate(isStart: true),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(_startDate),
                                      style: AppTextStyles.body1.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.grey3,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSM),
                        Expanded(
                          child: _buildSection(
                            label: '종료일',
                            child: GestureDetector(
                              onTap: () => _pickDate(isStart: false),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(_endDate),
                                      style: AppTextStyles.body1.copyWith(
                                        color: _endDate != null
                                            ? AppColors.white
                                            : AppColors.grey3,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.grey3,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    _buildSection(
                      label: '인증 방식',
                      child: ToggleSelector<VerificationType>(
                        items: VerificationType.values,
                        selectedItem: _verificationType,
                        labelBuilder: (type) => switch (type) {
                          VerificationType.text => '📝 텍스트만',
                          VerificationType.photo => '📸 사진 필수',
                        },
                        onChanged: (type) {
                          setState(() => _verificationType = type);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    _buildSection(
                      label: '중간 가입',
                      child: ToggleSelector<bool>(
                        items: const [true, false],
                        selectedItem: _allowLateJoin,
                        labelBuilder: (value) => value ? '허용' : '불가',
                        onChanged: (value) {
                          setState(() => _allowLateJoin = value);
                        },
                      ),
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
                text: '크루 생성하기 🚀',
                isLoading: _isSubmitting,
                onPressed: _handleCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.grey1),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey4),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime firstDate;
    final DateTime initialDate;

    if (isStart) {
      firstDate = _tomorrow;
      initialDate = _startDate;
    } else {
      firstDate = _minEndDate;
      initialDate = _endDate != null && !_endDate!.isBefore(_minEndDate)
          ? _endDate!
          : _minEndDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.main,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // 종료일이 새 시작일+6일 미만이면 리셋
          if (_endDate != null && _endDate!.isBefore(_minEndDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '연도. 월. 일.';
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y. $m. $d.';
  }
}
