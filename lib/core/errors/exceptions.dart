/// Data-layer exceptions mapped to [Failure] in repositories.
class ServerException implements Exception {
  const ServerException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  const CacheException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  const NetworkException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  const AuthException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException: $message';
}

class SyncException implements Exception {
  const SyncException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'SyncException: $message';
}
