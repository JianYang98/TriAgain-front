import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/models/upload_session.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/providers/verification_provider.dart';
import 'package:triagain/services/upload_session_service.dart';
import 'package:triagain/services/verification_service.dart';
import 'package:triagain/widgets/app_button.dart';

enum _UploadPhase {
  idle,
  creatingSession,
  uploadingS3,
  waitingConfirm,
  pollingFallback,
  creatingVerification,
}

class VerificationScreen extends ConsumerStatefulWidget {
  final String crewId;
  final String? challengeId;

  const VerificationScreen({
    super.key,
    required this.crewId,
    this.challengeId,
  });

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;

  _UploadPhase _uploadPhase = _UploadPhase.idle;
  double _uploadProgress = 0.0;
  StreamSubscription? _sseSubscription;
  CancelToken? _uploadCancelToken;

  bool get _isSubmitting => _uploadPhase != _UploadPhase.idle;

  @override
  void dispose() {
    _textController.dispose();
    _sseSubscription?.cancel();
    _uploadCancelToken?.cancel();
    super.dispose();
  }

  bool get _isPhotoRequired {
    final crewAsync = ref.read(crewDetailProvider(widget.crewId));
    return crewAsync.whenOrNull(
          data: (crew) => crew.verificationType == VerificationType.photo,
        ) ??
        false;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSubmitting) return;

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
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 70,
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
        const SnackBar(
          content: Text('사진 인증이 필요합니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_isPhotoRequired && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('텍스트 인증을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isPhotoRequired && _selectedImage != null) {
      await _handlePhotoVerification();
    } else {
      await _handleTextVerification();
    }
  }

  Future<void> _handleTextVerification() async {
    setState(() => _uploadPhase = _UploadPhase.creatingVerification);

    try {
      final verificationService = ref.read(verificationServiceProvider);
      final idempotencyKey = const Uuid().v4();
      final textContent = _textController.text.trim();

      await verificationService.createVerification(
        challengeId: widget.challengeId,
        crewId: widget.crewId,
        textContent: textContent.isNotEmpty ? textContent : null,
        idempotencyKey: idempotencyKey,
      );

      _invalidateProviders();
      if (!mounted) return;
      _showSuccessDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _uploadPhase = _UploadPhase.idle);
    }
  }

  Future<void> _handlePhotoVerification() async {
    final file = _selectedImage!;
    final uploadService = ref.read(uploadSessionServiceProvider);
    final verificationService = ref.read(verificationServiceProvider);
    final idempotencyKey = const Uuid().v4();
    _uploadCancelToken = CancelToken();

    try {
      // 1. 업로드 세션 생성
      setState(() => _uploadPhase = _UploadPhase.creatingSession);

      final session = await uploadService.createUploadSession(
        file: file,
        crewId: widget.crewId,
        challengeId: widget.challengeId,
      );

      if (!mounted) return;

      // 2. SSE 구독 시작 (S3 업로드 전에 열어야 이벤트 놓치지 않음)
      setState(() => _uploadPhase = _UploadPhase.waitingConfirm);

      final sseCompleter = Completer<UploadSessionEvent>();
      _sseSubscription = uploadService
          .subscribeToUploadEvents(session.uploadSessionId)
          .timeout(const Duration(seconds: 60))
          .listen(
        (event) {
          if (!sseCompleter.isCompleted) sseCompleter.complete(event);
        },
        onError: (error) {
          if (!sseCompleter.isCompleted) {
            sseCompleter.complete(UploadSessionEvent.error);
          }
        },
      );

      // 3. S3 업로드
      if (!mounted) return;
      setState(() {
        _uploadPhase = _UploadPhase.uploadingS3;
        _uploadProgress = 0.0;
      });

      final mimeType = _getMimeTypeFromFile(file);

      // presignedUrl 만료 확인
      if (session.isExpired) {
        _showErrorSnackBar('업로드 URL이 만료되었습니다. 다시 시도해주세요.');
        return;
      }

      await uploadService.uploadToS3(
        file: file,
        presignedUrl: session.presignedUrl,
        mimeType: mimeType,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
        cancelToken: _uploadCancelToken,
      );

      if (!mounted) return;

      // 4. SSE 이벤트 대기 (이미 구독 중)
      setState(() => _uploadPhase = _UploadPhase.waitingConfirm);

      UploadSessionEvent event;
      try {
        event = await sseCompleter.future
            .timeout(const Duration(seconds: 60));
      } on TimeoutException {
        // SSE 타임아웃 → polling fallback
        if (!mounted) return;
        setState(() => _uploadPhase = _UploadPhase.pollingFallback);
        event = await uploadService.pollUploadSessionStatus(
          session.uploadSessionId,
        );
      }

      if (!mounted) return;

      // 5. 이벤트 타입별 처리
      switch (event) {
        case UploadSessionEvent.completed:
          setState(() => _uploadPhase = _UploadPhase.creatingVerification);
          final textContent = _textController.text.trim();

          await _createVerificationWithRetry(
            verificationService: verificationService,
            crewId: widget.crewId,
            challengeId: widget.challengeId,
            uploadSessionId: session.uploadSessionId,
            textContent: textContent.isNotEmpty ? textContent : null,
            idempotencyKey: idempotencyKey,
          );

          _invalidateProviders();
          if (!mounted) return;
          _showSuccessDialog();

        case UploadSessionEvent.expired:
          if (!mounted) return;
          _showErrorSnackBar('업로드 세션이 만료되었습니다. 다시 시도해주세요.');

        case UploadSessionEvent.error:
          if (!mounted) return;
          _showErrorSnackBar('업로드 확인 중 오류가 발생했습니다.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'PRESIGNED_URL_EXPIRED') {
        _showErrorSnackBar('업로드 URL이 만료되었습니다. 다시 시도해주세요.');
      } else {
        _showErrorSnackBar(e.message);
      }
    } on DioException {
      if (!mounted) return;
      if (_uploadCancelToken?.isCancelled != true) {
        _showErrorSnackBar('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } finally {
      _sseSubscription?.cancel();
      _sseSubscription = null;
      _uploadCancelToken = null;
      if (mounted) {
        setState(() {
          _uploadPhase = _UploadPhase.idle;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// POST /verifications 네트워크 실패 시 최대 3회 재시도
  Future<void> _createVerificationWithRetry({
    required VerificationService verificationService,
    required String crewId,
    String? challengeId,
    required int uploadSessionId,
    String? textContent,
    required String idempotencyKey,
  }) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await verificationService.createVerification(
          challengeId: challengeId,
          crewId: crewId,
          uploadSessionId: uploadSessionId,
          textContent: textContent,
          idempotencyKey: idempotencyKey,
        );
        return;
      } on ApiException catch (e) {
        // 비즈니스 에러(4xx)는 즉시 throw
        if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
          rethrow;
        }
        // 네트워크성 실패만 재시도
        if (attempt == 3) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  void _invalidateProviders() {  
    ref.invalidate(feedProvider(widget.crewId));
    ref.invalidate(myVerificationsProvider(widget.crewId));
    ref.invalidate(crewDetailProvider(widget.crewId));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Text(
          '인증이 완료되었습니다!',
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _getMimeTypeFromFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String get _buttonText {
    switch (_uploadPhase) {
      case _UploadPhase.idle:
        return '인증 완료!';
      case _UploadPhase.creatingSession:
        return '사진 업로드 준비 중...';
      case _UploadPhase.uploadingS3:
        return '사진 업로드 중...';
      case _UploadPhase.waitingConfirm:
        return '업로드 확인 중...';
      case _UploadPhase.pollingFallback:
        return '업로드 확인 중...';
      case _UploadPhase.creatingVerification:
        return '인증 등록 중...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final crewAsync = ref.watch(crewDetailProvider(widget.crewId));
    final verificationContent = crewAsync.whenOrNull(
      data: (crew) => crew.verificationContent,
    );

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
                    if (verificationContent != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.paddingMD),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                          border: Border.all(color: AppColors.grey1),
                        ),
                        child: Row(
                          children: [
                            Text('📋  ', style: AppTextStyles.body2),
                            Expanded(
                              child: Text(
                                verificationContent,
                                style: AppTextStyles.body2
                                    .copyWith(color: AppColors.grey4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                    ],
                    if (_isPhotoRequired) ...[
                      Text(
                        '📸 사진 인증',
                        style: AppTextStyles.heading3
                            .copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: AppSizes.paddingSM),
                      _buildPhotoArea(),
                      const SizedBox(height: AppSizes.paddingSM),
                      _buildPhotoButtons(),
                      if (_uploadPhase == _UploadPhase.uploadingS3) ...[
                        const SizedBox(height: AppSizes.paddingSM),
                        _buildUploadProgress(),
                      ],
                      const SizedBox(height: AppSizes.paddingLG),
                    ],
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      maxLength: 200,
                      enabled: !_isSubmitting,
                      style:
                          AppTextStyles.body1.copyWith(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: '오늘 어땠나요?',
                        hintStyle: AppTextStyles.body1
                            .copyWith(color: AppColors.grey3),
                        counterStyle: AppTextStyles.caption
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
                    text: _buttonText,
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
            onTap: _isSubmitting ? null : () => context.pop(),
            child: Icon(
              Icons.arrow_back,
              color: _isSubmitting ? AppColors.grey2 : AppColors.white,
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
      onTap: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
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
              onPressed:
                  _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
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
              onPressed:
                  _isSubmitting ? null : () => _pickImage(ImageSource.camera),
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

  Widget _buildUploadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.grey1,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.main),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(_uploadProgress * 100).toInt()}%',
          style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
        ),
      ],
    );
  }
}
