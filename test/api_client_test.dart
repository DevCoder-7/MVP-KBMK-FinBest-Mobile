import 'dart:convert';
import 'dart:io';

import 'package:finbest_mobile/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late ApiClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('persists the signed session cookie between requests', () async {
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/login') {
        request.response.cookies
            .add(Cookie('finbest-session', 'signed-token')..httpOnly = true);
        request.response.write(jsonEncode({'success': true}));
      } else {
        final authenticated = request.cookies.any(
          (cookie) =>
              cookie.name == 'finbest-session' &&
              cookie.value == 'signed-token',
        );
        request.response.write(jsonEncode({'authenticated': authenticated}));
      }
      await request.response.close();
    });

    await client.post('/login');
    final session = await client.get('/session');

    expect(session['authenticated'], isTrue);
  });

  test('surfaces API error messages', () async {
    server.listen((request) async {
      request.response.statusCode = 422;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': 'Quantity tidak valid'}));
      await request.response.close();
    });

    expect(
      () => client.post('/traction'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
                (error) => error.message, 'message', 'Quantity tidak valid'),
      ),
    );
  });
}
