/// Typed exceptions surfaced by the data layer.
///
/// The UI should render [message] directly to the user (already in Arabic).
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Transport-level failure: no connection, DNS, TLS, or socket errors.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Server responded with an error status code (4xx / 5xx).
class ApiException extends AppException {
  final int statusCode;
  const ApiException(super.message, this.statusCode);
}

/// Request exceeded the allowed duration.
class AppTimeoutException extends AppException {
  const AppTimeoutException() : super('انتهت مهلة الاتصال، حاول مرة أخرى');
}

/// The server returned a payload that could not be parsed.
class ParseException extends AppException {
  const ParseException() : super('استجابة غير متوقعة من الخادم');
}
