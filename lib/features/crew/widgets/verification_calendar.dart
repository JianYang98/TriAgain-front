import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';

enum _StreakPosition { start, middle, end, none }

class VerificationCalendar extends StatefulWidget {
  final DateTime crewStartDate;
  final DateTime crewEndDate;
  final Set<DateTime> verifiedDates;
  final DateTime joinedAt;

  const VerificationCalendar({
    super.key,
    required this.crewStartDate,
    required this.crewEndDate,
    required this.verifiedDates,
    required this.joinedAt,
  });

  @override
  State<VerificationCalendar> createState() => _VerificationCalendarState();
}

class _VerificationCalendarState extends State<VerificationCalendar> {
  late DateTime _currentMonth;
  late List<_StreakBlock> _completedStreaks;

  @override
  void initState() {
    super.initState();
    _currentMonth = _initialMonth();
    _completedStreaks = _computeStreaks();
  }

  @override
  void didUpdateWidget(covariant VerificationCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verifiedDates != widget.verifiedDates ||
        oldWidget.joinedAt != widget.joinedAt) {
      _completedStreaks = _computeStreaks();
    }
  }

  DateTime _initialMonth() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month);
    final startMonth =
        DateTime(widget.crewStartDate.year, widget.crewStartDate.month);
    final endMonth =
        DateTime(widget.crewEndDate.year, widget.crewEndDate.month);

    if (today.isBefore(startMonth)) return startMonth;
    if (today.isAfter(endMonth)) return endMonth;
    return today;
  }

  bool get _canGoPrev {
    final startMonth =
        DateTime(widget.crewStartDate.year, widget.crewStartDate.month);
    return _currentMonth.isAfter(startMonth);
  }

  bool get _canGoNext {
    final endMonth =
        DateTime(widget.crewEndDate.year, widget.crewEndDate.month);
    return _currentMonth.isBefore(endMonth);
  }

  void _goToPrevMonth() {
    if (!_canGoPrev) return;
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  /// joinedAt 기준으로 3일 블록을 생성하고, 3일 모두 인증된 블록만 반환
  List<_StreakBlock> _computeStreaks() {
    final List<_StreakBlock> streaks = [];
    final joined = DateTime(
      widget.joinedAt.year,
      widget.joinedAt.month,
      widget.joinedAt.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      widget.crewEndDate.year,
      widget.crewEndDate.month,
      widget.crewEndDate.day,
    );
    final limit = today.isBefore(end) ? today : end;

    var blockStart = joined;
    while (!blockStart.isAfter(limit)) {
      final day1 = blockStart;
      final day2 = blockStart.add(const Duration(days: 1));
      final day3 = blockStart.add(const Duration(days: 2));

      if (widget.verifiedDates.contains(day1) &&
          widget.verifiedDates.contains(day2) &&
          widget.verifiedDates.contains(day3)) {
        streaks.add(_StreakBlock(day1, day2, day3));
      }

      blockStart = blockStart.add(const Duration(days: 3));
    }
    return streaks;
  }

  int get completedStreakCount => _completedStreaks.length;

  _StreakPosition _streakPositionFor(DateTime date) {
    for (final streak in _completedStreaks) {
      if (date == streak.day1) return _StreakPosition.start;
      if (date == streak.day2) return _StreakPosition.middle;
      if (date == streak.day3) return _StreakPosition.end;
    }
    return _StreakPosition.none;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: AppSizes.paddingSM),
          _buildWeekdayLabels(),
          const SizedBox(height: AppSizes.paddingXS),
          _buildDayGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _canGoPrev ? _goToPrevMonth : null,
          child: Icon(
            Icons.chevron_left,
            color: _canGoPrev ? AppColors.white : AppColors.grey2,
            size: 28,
          ),
        ),
        Text(
          '${_currentMonth.year}년 ${_currentMonth.month}월',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        GestureDetector(
          onTap: _canGoNext ? _goToNextMonth : null,
          child: Icon(
            Icons.chevron_right,
            color: _canGoNext ? AppColors.white : AppColors.grey2,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.grey3),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 일=0, 월=1, ...

    final cells = <Widget>[];

    // 빈 셀 (월 시작 전)
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // 날짜 셀
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      cells.add(_buildDayCell(date, day));
    }

    // 7열 그리드로 행 나누기
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final end = (i + 7 > cells.length) ? cells.length : i + 7;
      final rowCells = cells.sublist(i, end);
      // 마지막 행 빈 셀 채우기
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox());
      }
      rows.add(
        SizedBox(
          height: 44,
          child: Row(
            children: rowCells
                .map((cell) => Expanded(child: cell))
                .toList(),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(DateTime date, int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final crewStart = DateTime(
      widget.crewStartDate.year,
      widget.crewStartDate.month,
      widget.crewStartDate.day,
    );
    final crewEnd = DateTime(
      widget.crewEndDate.year,
      widget.crewEndDate.month,
      widget.crewEndDate.day,
    );

    final isInCrewPeriod =
        !date.isBefore(crewStart) && !date.isAfter(crewEnd);
    final isToday = date == today;
    final isVerified = widget.verifiedDates.contains(date);
    final streakPos = _streakPositionFor(date);

    // 크루 기간 밖
    if (!isInCrewPeriod) {
      return Center(
        child: Text(
          '$day',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.grey2.withValues(alpha: 0.5)),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 스트릭 배경 바
        if (streakPos != _StreakPosition.none)
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.only(
                left: streakPos == _StreakPosition.start ? 6 : 0,
                right: streakPos == _StreakPosition.end ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.15),
                borderRadius: BorderRadius.horizontal(
                  left: streakPos == _StreakPosition.start
                      ? const Radius.circular(20)
                      : Radius.zero,
                  right: streakPos == _StreakPosition.end
                      ? const Radius.circular(20)
                      : Radius.zero,
                ),
              ),
            ),
          ),
        // 날짜 원
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isVerified ? AppColors.main : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isVerified
                ? Border.all(color: AppColors.white, width: 1.5)
                : null,
          ),
          child: Center(
            child: streakPos == _StreakPosition.end
                ? const Icon(Icons.check, color: AppColors.white, size: 16)
                : Text(
                    '$day',
                    style: AppTextStyles.caption.copyWith(
                      color: isVerified
                          ? AppColors.white
                          : isToday
                              ? AppColors.white
                              : AppColors.grey4,
                      fontWeight: isToday ? FontWeight.bold : null,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StreakBlock {
  final DateTime day1;
  final DateTime day2;
  final DateTime day3;

  const _StreakBlock(this.day1, this.day2, this.day3);
}
