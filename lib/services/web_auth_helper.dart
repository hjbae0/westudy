import 'package:westudy/services/web_auth_helper_stub.dart'
    if (dart.library.html) 'package:westudy/services/web_auth_helper_web.dart';

/// 웹 전용 인증 헬퍼 (조건부 import로 플랫폼 분리)
///
/// 웹 환경: web_auth_helper_web.dart (dart:html 사용)
/// 비웹 환경: web_auth_helper_stub.dart (no-op stub)
class WebAuthHelper {
  /// 현재 페이지의 origin (예: https://westudy-bfcb4.web.app)
  static String getOrigin() => getOriginImpl();

  /// URL로 페이지 이동 (redirect)
  static void navigateTo(String url) => navigateToImpl(url);

  /// 현재 URL의 쿼리 파라미터 반환 (웹이 아니면 null)
  static Map<String, String>? getUrlParams() => getUrlParamsImpl();

  /// URL에서 쿼리 파라미터 제거 (히스토리 정리)
  static void cleanUrl() => cleanUrlImpl();

  /// HTTP POST (application/x-www-form-urlencoded) - 토큰 교환용
  static Future<Map<String, dynamic>> postForm(
    String url,
    Map<String, String> body,
  ) => postFormImpl(url, body);
}
