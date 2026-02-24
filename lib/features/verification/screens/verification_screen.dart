import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/models/mock_data.dart';
import 'package:triagain/widgets/app_button.dart';

class VerificationScreen extends StatefulWidget {
  final String crewId;

  const VerificationScreen({super.key, required this.crewId});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isPhotoRequired {
    try {
      final crew = MockData.crews.firstWhere((c) => c.id == widget.crewId);
      return crew.verificationType == VerificationType.photoRequired;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasCamera = _imagePicker.supportsImageSource(ImageSource.camera);
      if (!hasCamera) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카메라를 사용할 수 없습니다 (시뮬레이터)'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? '카메라를 사용할 수 없습니다'
                : '갤러리를 열 수 없습니다',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_isPhotoRequired && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진 인증이 필요합니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Mock 딜레이
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Text(
          '인증이 완료되었습니다! 🎉',
          style: AppTextStyles.body1.copyWith(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('확인', style: TextStyle(color: AppColors.main)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPhotoRequired ? '📸 사진 인증' : '📸 사진 인증 (선택)',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    _buildPhotoArea(),
                    const SizedBox(height: AppSizes.paddingSM),
                    _buildPhotoButtons(),
                    const SizedBox(height: AppSizes.paddingLG),
                    Text(
                      '✍️ 오늘의 한마디 (선택)',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      style:
                          AppTextStyles.body1.copyWith(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: '오늘 어땠나요?',
                        hintStyle: AppTextStyles.body1
                            .copyWith(color: AppColors.grey3),
                        filled: true,
                        fillColor: AppColors.card,
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD,
              ),
              child: Column(
                children: [
                  AppButton(
                    text: '인증 완료! ✅',
                    isLoading: _isSubmitting,
                    onPressed: _handleSubmit,
                  ),
                  const SizedBox(height: AppSizes.paddingSM),
                ],
              ),
            ),
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
            '오늘 인증하기',
            style: AppTextStyles.heading1.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(
        width: double.infinity,
        height: 240,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.grey2),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: _selectedImage != null
            ? Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 240,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 48,
                    color: AppColors.grey3,
                  ),
                  const SizedBox(height: AppSizes.paddingSM),
                  Text(
                    '탭하여 사진 추가',
                    style:
                        AppTextStyles.body2.copyWith(color: AppColors.grey3),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('갤러리'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.grey1),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.buttonRadius),
                ),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('카메라'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.grey1),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.buttonRadius),
                ),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
