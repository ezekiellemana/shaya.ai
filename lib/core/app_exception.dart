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
    final serverMessage = _extractServerMessage(details);
    return AppException(
      switch (statusCode) {
        400 =>
          serverMessage ??
              fallbackMessage ??
              'Please review the details and try again.',
        401 => serverMessage ?? 'Please sign in again to continue.',
        402 => 'Your monthly quota is full. Upgrade to continue.',
        403 =>
          serverMessage ?? 'Your current plan does not include this feature.',
        429 => 'Too many requests. Please wait and try again.',
        _ =>
          serverMessage ??
              fallbackMessage ??
              'Something went wrong. Please try again.',
      },
      statusCode: statusCode,
      details: details,
    );
  }

  @override
  String toString() => message;

  static String? _extractServerMessage(Object? details) {
    if (details is Map<dynamic, dynamic>) {
      final error = details['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    }
    return null;
  }
}
