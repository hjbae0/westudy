import 'dart:convert';
import 'dart:html' as html;

/// Web implementation using dart:html.
/// 웹 환경에서 OAuth redirect 및 토큰 교환을 처리한다.

String getOriginImpl() {
  return html.window.location.origin;
}

void navigateToImpl(String url) {
  html.window.location.href = url;
}

Map<String, String>? getUrlParamsImpl() {
  final uri = Uri.parse(html.window.location.href);
  if (uri.queryParameters.isEmpty) return null;
  return uri.queryParameters;
}

void cleanUrlImpl() {
  final uri = Uri.parse(html.window.location.href);
  final cleanUrl = '${uri.scheme}://${uri.authority}${uri.path}';
  html.window.history.replaceState(null, '', cleanUrl);
}

/// HTTP POST (application/x-www-form-urlencoded) - OAuth 토큰 교환용
/// dart:html의 HttpRequest를 사용하여 CORS 제약 없이 요청
Future<Map<String, dynamic>> postFormImpl(
  String url,
  Map<String, String> body,
) async {
  final encodedBody = body.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  final request = await html.HttpRequest.request(
    url,
    method: 'POST',
    requestHeaders: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    sendData: encodedBody,
  );

  if (request.status != 200) {
    throw Exception(
        'HTTP POST 실패: ${request.status} ${request.responseText}');
  }

  return json.decode(request.responseText!) as Map<String, dynamic>;
}
