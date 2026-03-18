import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/features/crew/widgets/search_crew_card.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/services/crew_search_service.dart';

class CrewSearchScreen extends ConsumerStatefulWidget {
  const CrewSearchScreen({super.key});

  @override
  ConsumerState<CrewSearchScreen> createState() => _CrewSearchScreenState();
}

class _CrewSearchScreenState extends ConsumerState<CrewSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  CrewCategory? _selectedCategory;
  List<SearchCrewItem> _crews = [];
  bool _isLoading = false;
  bool _hasNext = false;
  int _page = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _page = 0;
      _crews.clear();
      _search();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasNext) {
      _page++;
      _search(append: true);
    }
  }

  void _onCategorySelected(CrewCategory? category) {
    setState(() {
      _selectedCategory = category;
      _page = 0;
      _crews.clear();
    });
    _search();
  }

  Future<void> _search({bool append = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(crewSearchServiceProvider);
      final result = await service.searchCrews(
        keyword: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        category: _selectedCategory,
        page: _page,
      );

      if (!mounted) return;
      setState(() {
        if (append) {
          _crews.addAll(result.crews);
        } else {
          _crews = result.crews;
        }
        _hasNext = result.hasNext;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (append) _page--;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (append) _page--;
      setState(() {
        _errorMessage = '검색 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryFilter(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            '크루 찾기',
            style: AppTextStyles.heading1.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.paddingSM,
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.body2.copyWith(color: AppColors.white),
        decoration: InputDecoration(
          hintText: '크루 이름 또는 목표로 검색',
          hintStyle: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey3),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
      ),
      child: Row(
        children: [
          Expanded(child: _buildCategoryChip(null, '전체')),
          ...CrewCategory.values.map(
            (cat) => Expanded(child: _buildCategoryChip(cat, cat.label)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CrewCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: () => _onCategorySelected(category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main : AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.badgeRadius),
            border: isSelected ? null : Border.all(color: AppColors.grey1),
          ),
          child: Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: isSelected ? AppColors.white : AppColors.grey3,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null && _crews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            TextButton(
              onPressed: () {
                _page = 0;
                _crews.clear();
                _search();
              },
              child: Text(
                '다시 시도',
                style: AppTextStyles.body2.copyWith(color: AppColors.main),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoading && _crews.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없습니다',
          style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      itemCount: _crews.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _crews.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.main),
            ),
          );
        }
        final crew = _crews[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingMD),
          child: SearchCrewCard(
            crew: crew,
            onTap: () => context.push('/crew/confirm?crewId=${crew.id}'),
          ),
        );
      },
    );
  }

}
