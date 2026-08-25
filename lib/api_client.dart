import 'dart:convert';
import 'dart:io';

const defaultApiBaseUrl = String.fromEnvironment(
  'FINBEST_API_BASE_URL',
  defaultValue: 'https://mvp-kbmk-fin-best.vercel.app',
);

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String baseUrl = defaultApiBaseUrl})
      : baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');

  final Uri baseUri;
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);
  final List<Cookie> _cookies = [];

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) =>
      _request('POST', path, body);

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('PUT', path, body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final request = await _http.openUrl(method, baseUri.resolve(cleanPath));
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.headers.contentType = ContentType.json;
    request.headers.set('User-Agent', 'FinBest-Mobile/1.0');
    request.cookies.addAll(_cookies);
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    _rememberCookies(response.cookies);
    final text = await utf8.decoder.bind(response).join();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    final payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload['error']?.toString() ??
          payload['message']?.toString() ??
          'Permintaan gagal (${response.statusCode}).';
      throw ApiException(message, response.statusCode);
    }
    return payload;
  }

  void _rememberCookies(List<Cookie> incoming) {
    for (final cookie in incoming) {
      _cookies.removeWhere((item) => item.name == cookie.name);
      if (cookie.maxAge != 0) {
        _cookies.add(cookie);
      }
    }
  }

  void clearSession() => _cookies.clear();

  void close() => _http.close(force: true);
}
