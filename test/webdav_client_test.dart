import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:personal_toolbox/src/sync/webdav_client.dart';

void main() {
  test('WebDAV 允许普通远端地址使用 http', () async {
    final client = WebDavClient(client: _StaticClient(_multiStatusResponse()));

    final ok = await client.testConnection(
      const WebDavConfig(
        baseUrl: 'http://dav.example.com/remote.php/dav/files/demo/',
        username: 'demo-user',
        password: 'demo-password',
      ),
    );

    expect(ok, isTrue);
  });

  test('WebDAV 允许 localhost 使用 http 进行本机调试', () async {
    final client = WebDavClient(client: _StaticClient(_multiStatusResponse()));

    final ok = await client.testConnection(
      const WebDavConfig(
        baseUrl: 'http://localhost:8080/remote.php/dav/files/demo/',
        username: 'demo-user',
        password: 'demo-password',
      ),
    );

    expect(ok, isTrue);
  });

  test('WebDAV 仍然会拒绝非 http(s) 协议', () async {
    final client = WebDavClient(client: _StaticClient(_multiStatusResponse()));

    await expectLater(
      client.testConnection(
        const WebDavConfig(
          baseUrl: 'ftp://dav.example.com/remote.php/dav/files/demo/',
          username: 'demo-user',
          password: 'demo-password',
        ),
      ),
      throwsA(isA<WebDavException>()),
    );
  });

  test('WebDAV 请求超时时会返回明确错误', () async {
    final client = WebDavClient(
      client: _HangingClient(),
      requestTimeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      client.readText(
        const WebDavConfig(
          baseUrl: 'http://dav.example.com/remote.php/dav/files/demo/',
          username: 'demo-user',
          password: 'demo-password',
        ),
        'state.v1.enc.json',
      ),
      throwsA(isA<WebDavException>()),
    );
  });
}

class _StaticClient extends http.BaseClient {
  _StaticClient(this._response);

  final http.StreamedResponse _response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _response;
  }
}

class _HangingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Completer<http.StreamedResponse>().future;
  }
}

http.StreamedResponse _multiStatusResponse() {
  final body = utf8.encode(jsonEncode({'ok': true}));
  return http.StreamedResponse(
    Stream.value(body),
    207,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
