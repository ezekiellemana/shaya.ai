class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  factory AppException.configuration(String message) {
    return AppException(message);
  }

  factory AppException.fromStatus(
    int statusCode, {
    Object? details,
    String? fallbackMessage,
  }) {
    return AppException(
      switch (statusCode) {
        401 => 'Please sign in again to continue.',
        402 => 'Your monthly quota is full. Upgrade to continue.',
        403 => 'Your current plan does not include this feature.',
        429 => 'Too many requests. Please wait and try again.',
        _ => fallbackMessage ?? 'Something went wrong. Please try again.',
      },
      statusCode: statusCode,
      details: details,
    );
  }

  @override
  String toString() => message;
}
