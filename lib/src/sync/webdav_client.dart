import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

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
  WebDavClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> testConnection(WebDavConfig config) async {
    final request = http.Request('PROPFIND', _resolve(config, ''));
    request.headers.addAll(_headers(config)..['Depth'] = '0');
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<List<WebDavResource>> list(WebDavConfig config, String path) async {
    final request = http.Request('PROPFIND', _resolve(config, path));
    request.headers.addAll(_headers(config)..['Depth'] = '1');
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
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
    final response = await _client.get(
      _resolve(config, path),
      headers: _headers(config),
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
    final response = await _client.put(
      _resolve(config, path),
      headers: {
        ..._headers(config),
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: utf8.encode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavException('WebDAV 写入失败：${response.statusCode}');
    }
  }

  Future<void> makeCollection(WebDavConfig config, String path) async {
    final request = http.Request('MKCOL', _resolve(config, path));
    request.headers.addAll(_headers(config));
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
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
    return Uri.parse(base).resolve(path);
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
