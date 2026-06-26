import 'package:dio/dio.dart';
import 'package:expense_mate/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dio HTTP client for external API calls (exchange rates, etc.).
class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d('Dio', '${options.method} ${options.uri}');
          handler.next(options);
        },
        onError: (error, handler) {
          AppLogger.e('Dio', error.message ?? 'Request failed', error);
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get instance => _dio;
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
