import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/toggle_selector.dart';

class CreateCrewScreen extends StatefulWidget {
  const CreateCrewScreen({super.key});

  @override
  State<CreateCrewScreen> createState() => _CreateCrewScreenState();
}

class _CreateCrewScreenState extends State<CreateCrewScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _maxMembersController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  VerificationType _verificationType = VerificationType.photoRequired;
  bool _allowMidJoin = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더: ← 뒤로가기 + "크루 만들기"
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

                    // 크루 이름
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

                    // 목표
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

                    // 최대 인원
                    _buildSection(
                      label: '최대 인원 (1~10명)',
                      child: TextField(
                        controller: _maxMembersController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: '최대 인원을 입력하세요',
                          hintStyle: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) return;
                          final number = int.tryParse(value);
                          if (number == null) return;
                          final clamped = number.clamp(1, 10);
                          if (clamped != number) {
                            _maxMembersController.text = clamped.toString();
                            _maxMembersController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset:
                                      _maxMembersController.text.length),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    // 시작일 / 종료일
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
                                        color: _startDate != null
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

                    // 인증 방식
                    _buildSection(
                      label: '인증 방식',
                      child: ToggleSelector<VerificationType>(
                        items: VerificationType.values,
                        selectedItem: _verificationType,
                        labelBuilder: (type) => switch (type) {
                          VerificationType.textOnly => '📝 텍스트만',
                          VerificationType.photoRequired => '📸 사진 필수',
                        },
                        onChanged: (type) {
                          setState(() => _verificationType = type);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    // 중간 가입
                    _buildSection(
                      label: '중간 가입',
                      child: ToggleSelector<bool>(
                        items: const [true, false],
                        selectedItem: _allowMidJoin,
                        labelBuilder: (value) => value ? '허용' : '불가',
                        onChanged: (value) {
                          setState(() => _allowMidJoin = value);
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
                onPressed: () => context.push('/crew/success'),
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
