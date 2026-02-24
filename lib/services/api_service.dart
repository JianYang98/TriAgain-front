import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'https://api.triagain.com';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Dio get dio => _dio;
}
