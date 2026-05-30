class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class OtpRequiredException implements Exception {
  final String message;
  OtpRequiredException(this.message);
}
