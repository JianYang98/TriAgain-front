import 'package:flutter/cupertino.dart';
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
  final _nameFocus = FocusNode();
  final _goalFocus = FocusNode();
  final _nameKey = GlobalKey();
  final _goalKey = GlobalKey();
  final _endDateKey = GlobalKey();
  int _maxMembers = 5;
  late DateTime _startDate;
  DateTime? _endDate;
  VerificationType _verificationType = VerificationType.photo;
  bool _allowLateJoin = false;
  bool _hasDeadlineTime = false;
  int _deadlineHour = 23;
  int _deadlineMinute = 0;
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
    _nameFocus.dispose();
    _goalFocus.dispose();
    super.dispose();
  }

  Future<void> _scrollToAndFocus(GlobalKey key, FocusNode focus) async {
    final ctx = key.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      focus.requestFocus();
    }
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('크루 이름을 입력해주세요')),
      );
      _scrollToAndFocus(_nameKey, _nameFocus);
      return;
    }
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표를 입력해주세요')),
      );
      _scrollToAndFocus(_goalKey, _goalFocus);
      return;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일을 선택해주세요')),
      );
      final ctx = _endDateKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _pickDate(isStart: false);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final crewService = ref.read(crewServiceProvider);
      final deadlineTime = _hasDeadlineTime
          ? '${_deadlineHour.toString().padLeft(2, '0')}:${_deadlineMinute.toString().padLeft(2, '0')}'
          : null;

      final result = await crewService.createCrew(
        name: name,
        goal: goal,
        verificationType: _verificationType,
        maxMembers: _maxMembers,
        startDate: _startDate,
        endDate: _endDate!,
        allowLateJoin: _allowLateJoin,
        deadlineTime: deadlineTime,
      );

      ref.invalidate(crewListProvider);

      if (!mounted) return;

      final dateStr =
          '${result.startDate.year}.${result.startDate.month.toString().padLeft(2, '0')}.${result.startDate.day.toString().padLeft(2, '0')}';
      context.go(
          '/crew/success?inviteCode=${result.inviteCode}&startDate=$dateStr&crewName=${Uri.encodeComponent(name)}');
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
                      key: _nameKey,
                      label: '크루 이름',
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        maxLength: 20,
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: '크루 이름을 입력하세요',
                          hintStyle: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                          counterStyle: AppTextStyles.caption
                              .copyWith(color: AppColors.grey3),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),

                    _buildSection(
                      key: _goalKey,
                      label: '목표',
                      child: TextField(
                        controller: _goalController,
                        focusNode: _goalFocus,
                        maxLength: 50,
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: '목표를 입력하세요',
                          hintStyle: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                          counterStyle: AppTextStyles.caption
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
                            key: _endDateKey,
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
                      label: '인증 마감 시간',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _hasDeadlineTime
                                ? () => _showTimePickerSheet()
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _hasDeadlineTime
                                      ? _formatDeadlineLabel()
                                      : '자정 기준',
                                  style: AppTextStyles.body1.copyWith(
                                    color: _hasDeadlineTime
                                        ? AppColors.white
                                        : AppColors.grey3,
                                  ),
                                ),
                                if (_hasDeadlineTime) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.edit,
                                    color: AppColors.grey3,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Switch(
                            value: _hasDeadlineTime,
                            activeTrackColor: AppColors.main,
                            onChanged: (value) async {
                              if (value) {
                                setState(() => _hasDeadlineTime = true);
                                _showTimePickerSheet();
                              } else {
                                setState(() {
                                  _hasDeadlineTime = false;
                                  _deadlineHour = 23;
                                  _deadlineMinute = 0;
                                });
                              }
                            },
                          ),
                        ],
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
    Key? key,
    required String label,
    required Widget child,
  }) {
    return Container(
      key: key,
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

  Future<void> _showTimePickerSheet() async {
    var tempHour = _deadlineHour;
    var tempMinute = _deadlineMinute;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    SizedBox(
                      height: 150,
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: tempHour,
                              ),
                              itemExtent: 36,
                              onSelectedItemChanged: (index) {
                                tempHour = index;
                              },
                              children: List.generate(
                                24,
                                (i) => Center(
                                  child: Text(
                                    '$i시',
                                    style: AppTextStyles.body1
                                        .copyWith(color: AppColors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ':',
                            style: AppTextStyles.heading2
                                .copyWith(color: AppColors.white),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: tempMinute ~/ 5,
                              ),
                              itemExtent: 36,
                              onSelectedItemChanged: (index) {
                                tempMinute = index * 5;
                              },
                              children: List.generate(
                                12,
                                (i) => Center(
                                  child: Text(
                                    '${(i * 5).toString().padLeft(2, '0')}분',
                                    style: AppTextStyles.body1
                                        .copyWith(color: AppColors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _deadlineHour = tempHour;
                            _deadlineMinute = tempMinute;
                          });
                          Navigator.of(sheetContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.main,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                          ),
                          textStyle: AppTextStyles.button,
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // 바텀시트를 확인 없이 닫은 경우 토글 OFF로 롤백
    if (confirmed != true && mounted) {
      setState(() {
        _hasDeadlineTime = false;
        _deadlineHour = 23;
        _deadlineMinute = 0;
      });
    }
  }

  String _formatDeadlineLabel() {
    final period = _deadlineHour < 12 ? '오전' : '오후';
    final displayHour = _deadlineHour == 0
        ? 12
        : _deadlineHour > 12
            ? _deadlineHour - 12
            : _deadlineHour;
    final minuteStr =
        _deadlineMinute > 0 ? ' $_deadlineMinute분' : '';
    return '$period $displayHour시$minuteStr까지';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '연도. 월. 일.';
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y. $m. $d.';
  }
}
