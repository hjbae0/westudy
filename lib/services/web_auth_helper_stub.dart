/// Stub implementation for non-web platforms.
/// 비웹 환경(Android/iOS)에서는 모든 메서드가 no-op 또는 예외를 던진다.

String getOriginImpl() {
  throw UnsupportedError('소셜 로그인은 웹 환경에서만 지원됩니다.');
}

void navigateToImpl(String url) {
  throw UnsupportedError('소셜 로그인은 웹 환경에서만 지원됩니다.');
}

Map<String, String>? getUrlParamsImpl() {
  return null;
}

void cleanUrlImpl() {
  // no-op on non-web
}

Future<Map<String, dynamic>> postFormImpl(
  String url,
  Map<String, String> body,
) async {
  throw UnsupportedError('소셜 로그인은 웹 환경에서만 지원됩니다.');
}
