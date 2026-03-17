import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/constants/app_config.dart';
import 'package:triagain/core/network/api_client.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/upload_session.dart';

final uploadSessionServiceProvider = Provider<UploadSessionService>((ref) {
  return UploadSessionService(ref.watch(apiClientProvider));
});

class UploadSessionService {
  final ApiClient _apiClient;

  late final Dio _s3Dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 30),
  ));

  late final Dio _sseDio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 90),
  ));

  static const _allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const _maxFileSize = 1 * 1024 * 1024; // 1MB

  UploadSessionService(this._apiClient);

  /// 파일 사전 검증 + 업로드 세션 생성
  Future<UploadSession> createUploadSession({
    required File file,
    required String crewId,
    String? challengeId,
  }) async {
    // 클라이언트 사전 검증
    final fileSize = await file.length();
    final fileName = file.path.split('/').last.toLowerCase();
    final ext = fileName.contains('.')
        ? '.${fileName.split('.').last}'
        : '';

    if (!_allowedExtensions.contains(ext)) {
      throw const ApiException(
        code: 'INVALID_FILE_TYPE',
        message: '지원하지 않는 파일 형식입니다. JPEG, PNG, WebP만 가능합니다.',
      );
    }

    if (fileSize > _maxFileSize) {
      throw const ApiException(
        code: 'FILE_TOO_LARGE',
        message: '파일 크기가 1MB를 초과합니다. 다시 시도해주세요.',
      );
    }

    final mimeType = _getMimeType(ext);

    final response = await _apiClient.post<UploadSession>(
      '/upload-sessions',
      data: {
        'crewId': crewId,
        if (challengeId != null) 'challengeId': challengeId,
        'fileName': fileName,
        'fileType': mimeType,
        'fileSize': fileSize,
      },
      fromData: (json) =>
          UploadSession.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  /// presigned URL로 S3에 파일 업로드 (최대 3회 재시도)
  Future<void> uploadToS3({
    required File file,
    required String presignedUrl,
    required String mimeType,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final bytes = await file.readAsBytes();

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _s3Dio.put<void>(
          presignedUrl,
          data: Stream.fromIterable([bytes]),
          options: Options(
            headers: {
              'Content-Type': mimeType,
              'Content-Length': bytes.length,
            },
            // presigned URL 자체 인증 — extra headers 넣지 않음
          ),
          onSendProgress: (sent, total) {
            if (total > 0 && onProgress != null) {
              onProgress(sent / total);
            }
          },
          cancelToken: cancelToken,
        );
        return; // 성공
      } on DioException catch (e) {
        if (cancelToken?.isCancelled == true) rethrow;

        // presigned URL 만료 (403 Forbidden 또는 서명 관련 에러)
        if (_isPresignedUrlExpired(e)) {
          throw const ApiException(
            code: 'PRESIGNED_URL_EXPIRED',
            message: '업로드 URL이 만료되었습니다. 다시 시도해주세요.',
          );
        }

        if (attempt == 3) {
          throw const ApiException(
            code: 'S3_UPLOAD_FAILED',
            message: 'S3 업로드에 실패했습니다. 다시 시도해주세요.',
          );
        }
        // 재시도 전 짧은 대기
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// SSE 구독 — upload-complete 이벤트 대기
  Stream<UploadSessionEvent> subscribeToUploadEvents(
    int uploadSessionId,
  ) async* {
    try {
      final response = await _sseDio.get<ResponseBody>(
        '/upload-sessions/$uploadSessionId/events',
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        // SSE 이벤트는 빈 줄(\n\n)로 구분
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventBlock = buffer.substring(0, eventEnd);
          buffer = buffer.substring(eventEnd + 2);

          final event = _parseSseEvent(eventBlock);
          if (event != null) {
            yield event;
            return; // completed/expired/error 수신 시 즉시 종료
          }
        }
      }
      // 스트림 종료됐는데 이벤트 못 받음 → error
      yield UploadSessionEvent.error;
    } on DioException {
      // 연결 실패 / 타임아웃 → polling fallback으로 전환
      yield UploadSessionEvent.error;
    }
  }

  /// SSE 실패 시 polling fallback — 최대 6회, 3초 간격
  Future<UploadSessionEvent> pollUploadSessionStatus(
    int uploadSessionId,
  ) async {
    for (var i = 0; i < 6; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(seconds: 3));
      }

      try {
        final response = await _apiClient.get<UploadSessionStatus>(
          '/upload-sessions/$uploadSessionId',
          fromData: (json) =>
              UploadSessionStatus.fromJson(json as Map<String, dynamic>),
        );

        final status = response.data!.status;
        if (status == 'COMPLETED') return UploadSessionEvent.completed;
        if (status == 'EXPIRED') return UploadSessionEvent.expired;
        // PENDING → 아직 처리 중, 계속 폴링
      } on ApiException {
        // 개별 폴링 실패는 무시하고 다음 시도
      }
    }
    return UploadSessionEvent.error;
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  UploadSessionEvent? _parseSseEvent(String block) {
    String? eventType;
    String? data;

    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data = line.substring(5).trim();
      }
    }

    if (eventType == 'upload-complete' && data == 'COMPLETED') {
      return UploadSessionEvent.completed;
    }

    // 서버가 만료/에러 이벤트를 보낼 수 있음
    if (data == 'EXPIRED') return UploadSessionEvent.expired;
    if (data == 'ERROR') return UploadSessionEvent.error;

    return null; // heartbeat 등 무시
  }

  bool _isPresignedUrlExpired(DioException e) {
    if (e.response?.statusCode == 403) return true;
    final body = e.response?.data?.toString() ?? '';
    return body.contains('Request has expired') ||
        body.contains('AccessDenied') ||
        body.contains('SignatureDoesNotMatch');
  }
}
