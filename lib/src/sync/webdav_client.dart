import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

final webDavClientProvider = Provider<WebDavClient>((ref) {
  final client = WebDavClient();
  ref.onDispose(client.close);
  return client;
});

class WebDavConfig {
  const WebDavConfig({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String baseUrl;
  final String username;
  final String password;
}

class WebDavResource {
  const WebDavResource({
    required this.path,
    required this.lastModified,
    required this.contentLength,
  });

  final String path;
  final DateTime? lastModified;
  final int? contentLength;
}

class WebDavClient {
  WebDavClient({
    http.Client? client,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _requestTimeout = requestTimeout;

  final http.Client _client;
  final Duration _requestTimeout;

  void close() {
    _client.close();
  }

  Future<bool> testConnection(WebDavConfig config) async {
    final request = http.Request('PROPFIND', _resolve(config, ''));
    request.headers.addAll(_headers(config)..['Depth'] = '0');
    final response = await http.Response.fromStream(await _send(request));
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<List<WebDavResource>> list(WebDavConfig config, String path) async {
    final request = http.Request('PROPFIND', _resolve(config, path));
    request.headers.addAll(_headers(config)..['Depth'] = '1');
    final response = await http.Response.fromStream(await _send(request));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavException('WebDAV 列表失败：${response.statusCode}');
    }
    final document = XmlDocument.parse(response.body);
    return _elementsByLocalName(document, 'response').map((node) {
      final href = _first(_elementsByLocalName(node, 'href'))?.innerText ?? '';
      final modified = _first(
        _elementsByLocalName(node, 'getlastmodified'),
      )?.innerText;
      final length = _first(
        _elementsByLocalName(node, 'getcontentlength'),
      )?.innerText;
      return WebDavResource(
        path: href,
        lastModified: modified == null ? null : HttpDate.parse(modified),
        contentLength: length == null ? null : int.tryParse(length),
      );
    }).toList();
  }

  Future<String?> readText(WebDavConfig config, String path) async {
    final response = await _client
        .get(_resolve(config, path), headers: _headers(config))
        .timeout(
          _requestTimeout,
          onTimeout: () =>
              throw const WebDavException('WebDAV 读取超时，请检查网络或服务器状态。'),
        );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavException('WebDAV 读取失败：${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<void> writeText(WebDavConfig config, String path, String body) async {
    final response = await _client
        .put(
          _resolve(config, path),
          headers: {
            ..._headers(config),
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(body),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () =>
              throw const WebDavException('WebDAV 写入超时，请检查网络或服务器状态。'),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavException('WebDAV 写入失败：${response.statusCode}');
    }
  }

  Future<void> makeCollection(WebDavConfig config, String path) async {
    final request = http.Request('MKCOL', _resolve(config, path));
    request.headers.addAll(_headers(config));
    final response = await http.Response.fromStream(await _send(request));
    if (response.statusCode == 405) {
      return;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavException('WebDAV 目录创建失败：${response.statusCode}');
    }
  }

  Uri _resolve(WebDavConfig config, String path) {
    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl
        : '${config.baseUrl}/';
    final baseUri = Uri.parse(base);
    _ensureAllowedBaseUri(baseUri);
    return baseUri.resolve(path);
  }

  Future<http.StreamedResponse> _send(http.BaseRequest request) {
    return _client
        .send(request)
        .timeout(
          _requestTimeout,
          onTimeout: () =>
              throw const WebDavException('WebDAV 请求超时，请检查网络或服务器状态。'),
        );
  }

  void _ensureAllowedBaseUri(Uri uri) {
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return;
    }
    throw const WebDavException('WebDAV 地址必须使用 http 或 https。');
  }

  Map<String, String> _headers(WebDavConfig config) {
    final token = base64Encode(
      utf8.encode('${config.username}:${config.password}'),
    );
    return <String, String>{
      'Authorization': 'Basic $token',
      'Accept': 'application/xml, application/json, text/plain',
    };
  }
}

XmlElement? _first(Iterable<XmlElement> values) {
  return values.isEmpty ? null : values.first;
}

Iterable<XmlElement> _elementsByLocalName(XmlNode node, String localName) {
  return node.descendants.whereType<XmlElement>().where(
    (element) => element.name.local == localName,
  );
}

class WebDavException implements Exception {
  const WebDavException(this.message);

  final String message;

  @override
  String toString() => message;
}
