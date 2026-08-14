// lib/core/errors/exceptions.dart

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}
