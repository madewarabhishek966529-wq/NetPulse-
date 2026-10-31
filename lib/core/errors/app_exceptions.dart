class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

class Aria2Exception extends AppException {
  Aria2Exception(super.message, {super.code, super.details});
}

class RpcConnectionException extends AppException {
  RpcConnectionException(super.message, {super.code, super.details});
}

class InvalidUrlException extends AppException {
  InvalidUrlException(super.message, {super.code, super.details});
}

class FileVerificationException extends AppException {
  FileVerificationException(super.message, {super.code, super.details});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code, super.details});
}

class DangerousFileWarningException extends AppException {
  DangerousFileWarningException(super.message, {super.code, super.details});
}
