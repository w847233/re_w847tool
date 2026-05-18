import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pointycastle/export.dart';

import 'alipay_ledger_models.dart';

const _alipayGateway = 'https://openapi.alipay.com/gateway.do';
const _sha256RsaOid = '0609608648016503040201';

class AlipayOpenApiClient {
  AlipayOpenApiClient({
    required AlipayLedgerConfig config,
    http.Client? client,
    DateTime Function()? now,
  }) : _config = config,
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final AlipayLedgerConfig _config;
  final http.Client _client;
  final DateTime Function() _now;

  Future<Map<String, dynamic>> call(
    String method,
    Map<String, dynamic> bizContent, {
    Map<String, String> extraParams = const <String, String>{},
    bool wrapBizContent = true,
  }) async {
    final params = <String, String>{
      'app_id': _config.appId.trim(),
      'method': method.trim(),
      'format': 'JSON',
      'charset': 'utf-8',
      'sign_type': 'RSA2',
      'timestamp': _formatTimestamp(_now()),
      'version': '1.0',
      ...extraParams,
    };
    if (wrapBizContent) {
      params['biz_content'] = jsonEncode(_withoutNulls(bizContent));
    } else {
      for (final entry in bizContent.entries) {
        final value = entry.value;
        if (value != null && '$value'.trim().isNotEmpty) {
          params[entry.key] = '$value';
        }
      }
    }
    params['sign'] = signParams(params, _config.privateKeyPem);

    final response = await _client.post(
      Uri.parse(_alipayGateway),
      headers: const <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        'Accept': 'application/json',
      },
      body: params,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AlipayOpenApiException('支付宝网关请求失败：${response.statusCode}');
    }
    final rawBody = utf8.decode(response.bodyBytes);
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map) {
      throw const AlipayOpenApiException('支付宝响应格式错误');
    }
    final root = Map<String, dynamic>.from(decoded);
    final responseKey = '${method.replaceAll('.', '_')}_response';
    final actualResponseKey = root.containsKey(responseKey)
        ? responseKey
        : 'error_response';
    final responseBody = root[actualResponseKey];
    if (responseBody is! Map) {
      throw AlipayOpenApiException('支付宝响应缺少 $responseKey');
    }
    _verifyResponseSignature(
      root: root,
      signText: _jsonValueForKey(rawBody, actualResponseKey),
    );
    final result = Map<String, dynamic>.from(responseBody);
    final code = result['code']?.toString();
    if (code != null && code != '10000') {
      throw AlipayOpenApiException.fromResponse(result);
    }
    return result;
  }

  static String signParams(Map<String, String> params, String privateKeyPem) {
    final signText = buildSignText(params);
    return signTextWithPrivateKey(signText, privateKeyPem);
  }

  static String signTextWithPrivateKey(String signText, String privateKeyPem) {
    final privateKey = _parsePrivateKey(privateKeyPem);
    final signer = RSASigner(SHA256Digest(), _sha256RsaOid)
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(
      Uint8List.fromList(utf8.encode(signText)),
    );
    return base64Encode(signature.bytes);
  }

  static bool verifySignature({
    required Map<String, String> params,
    required String signature,
    required String publicKeyPem,
  }) {
    final signText = buildSignText(params);
    return verifyText(
      signText: signText,
      signature: signature,
      publicKeyPem: publicKeyPem,
    );
  }

  static bool verifyText({
    required String signText,
    required String signature,
    required String publicKeyPem,
  }) {
    final publicKey = _parsePublicKey(publicKeyPem);
    final verifier = RSASigner(SHA256Digest(), _sha256RsaOid)
      ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
    return verifier.verifySignature(
      Uint8List.fromList(utf8.encode(signText)),
      RSASignature(base64Decode(signature)),
    );
  }

  static String buildSignText(Map<String, String> params) {
    final keys =
        params.keys
            .where(
              (key) => key != 'sign' && (params[key] ?? '').trim().isNotEmpty,
            )
            .toList()
          ..sort();
    return keys.map((key) => '$key=${params[key]}').join('&');
  }

  void _verifyResponseSignature({
    required Map<String, dynamic> root,
    required String? signText,
  }) {
    final signature = root['sign']?.toString();
    if (signature == null || signature.trim().isEmpty || signText == null) {
      return;
    }
    try {
      final verified = verifyText(
        signText: signText,
        signature: signature,
        publicKeyPem: _config.alipayPublicKeyPem,
      );
      if (!verified) {
        throw const AlipayOpenApiException('支付宝响应验签失败');
      }
    } on AlipayOpenApiException {
      rethrow;
    } catch (_) {
      throw const AlipayOpenApiException('支付宝响应验签失败');
    }
  }
}

class AlipayOpenApiException implements Exception {
  const AlipayOpenApiException(this.message, {this.code, this.subCode});

  final String message;
  final String? code;
  final String? subCode;

  factory AlipayOpenApiException.fromResponse(Map<String, dynamic> response) {
    final code = response['code']?.toString();
    final subCode = response['sub_code']?.toString();
    final subMsg = response['sub_msg']?.toString();
    final msg = response['msg']?.toString();
    final detail = subMsg?.trim().isNotEmpty == true ? subMsg : msg;
    final permissionHints = <String>[
      'ISV权限不足',
      '接口无权限',
      'method not found',
      '无效接口',
      '权限不足',
    ];
    final raw = [code, subCode, detail].whereType<String>().join(' ');
    final prefix = permissionHints.any(raw.contains)
        ? '支付宝接口无权限或未签约'
        : '支付宝接口调用失败';
    return AlipayOpenApiException(
      '$prefix：${detail ?? code ?? '未知错误'}',
      code: code,
      subCode: subCode,
    );
  }

  @override
  String toString() => message;
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    final value = entry.value;
    if (value != null && '$value'.trim().isNotEmpty) {
      result[entry.key] = value;
    }
  }
  return result;
}

String _formatTimestamp(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
}

String? _jsonValueForKey(String source, String key) {
  final encodedKey = jsonEncode(key);
  var index = source.indexOf(encodedKey);
  while (index >= 0) {
    var cursor = index + encodedKey.length;
    cursor = _skipWhitespace(source, cursor);
    if (cursor < source.length && source.codeUnitAt(cursor) == 0x3a) {
      cursor = _skipWhitespace(source, cursor + 1);
      return _sliceJsonValue(source, cursor);
    }
    index = source.indexOf(encodedKey, index + encodedKey.length);
  }
  return null;
}

int _skipWhitespace(String source, int start) {
  var cursor = start;
  while (cursor < source.length) {
    final code = source.codeUnitAt(cursor);
    if (code != 0x20 && code != 0x0a && code != 0x0d && code != 0x09) {
      break;
    }
    cursor++;
  }
  return cursor;
}

String? _sliceJsonValue(String source, int start) {
  if (start >= source.length) {
    return null;
  }
  var inString = false;
  var escaped = false;
  var depth = 0;
  for (var index = start; index < source.length; index++) {
    final code = source.codeUnitAt(index);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 0x5c) {
        escaped = true;
      } else if (code == 0x22) {
        inString = false;
        if (depth == 0) {
          return source.substring(start, index + 1);
        }
      }
      continue;
    }
    if (code == 0x22) {
      inString = true;
      continue;
    }
    if (code == 0x7b || code == 0x5b) {
      depth++;
      continue;
    }
    if (code == 0x7d || code == 0x5d) {
      depth--;
      if (depth == 0) {
        return source.substring(start, index + 1);
      }
      continue;
    }
    if (depth == 0 && (code == 0x2c || code == 0x7d || code == 0x5d)) {
      return source.substring(start, index).trimRight();
    }
  }
  return source.substring(start).trimRight();
}

RSAPrivateKey _parsePrivateKey(String pem) {
  final bytes = _decodePem(pem);
  final reader = _DerReader(bytes).readSequence();
  reader.readInteger();
  if (reader.peekTag() == 0x30) {
    reader.readElement(0x30);
    final privateKeyBytes = reader.readElement(0x04);
    return _parsePkcs1PrivateKey(privateKeyBytes);
  }
  final modulus = reader.readInteger();
  reader.readInteger();
  final privateExponent = reader.readInteger();
  final p = reader.readInteger();
  final q = reader.readInteger();
  return RSAPrivateKey(modulus, privateExponent, p, q);
}

RSAPrivateKey _parsePkcs1PrivateKey(Uint8List bytes) {
  final reader = _DerReader(bytes).readSequence();
  reader.readInteger();
  final modulus = reader.readInteger();
  reader.readInteger();
  final privateExponent = reader.readInteger();
  final p = reader.readInteger();
  final q = reader.readInteger();
  return RSAPrivateKey(modulus, privateExponent, p, q);
}

RSAPublicKey _parsePublicKey(String pem) {
  final bytes = _decodePem(pem);
  final reader = _DerReader(bytes).readSequence();
  if (reader.peekTag() == 0x30) {
    reader.readElement(0x30);
    final bitString = reader.readElement(0x03);
    if (bitString.isEmpty) {
      throw const FormatException('支付宝公钥格式错误');
    }
    return _parsePkcs1PublicKey(Uint8List.sublistView(bitString, 1));
  }
  return _parsePkcs1PublicKey(bytes);
}

RSAPublicKey _parsePkcs1PublicKey(Uint8List bytes) {
  final reader = _DerReader(bytes).readSequence();
  final modulus = reader.readInteger();
  final exponent = reader.readInteger();
  return RSAPublicKey(modulus, exponent);
}

Uint8List _decodePem(String source) {
  final normalized = source
      .replaceAll(RegExp(r'-----BEGIN [^-]+-----'), '')
      .replaceAll(RegExp(r'-----END [^-]+-----'), '')
      .replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty) {
    throw const FormatException('密钥内容为空');
  }
  return base64Decode(normalized);
}

class _DerReader {
  _DerReader(Uint8List bytes) : _bytes = bytes;

  final Uint8List _bytes;
  int _offset = 0;

  int peekTag() {
    if (_offset >= _bytes.length) {
      return -1;
    }
    return _bytes[_offset];
  }

  _DerReader readSequence() {
    return _DerReader(readElement(0x30));
  }

  BigInt readInteger() {
    final value = readElement(0x02);
    var start = 0;
    while (start < value.length - 1 && value[start] == 0) {
      start++;
    }
    return _bytesToBigInt(Uint8List.sublistView(value, start));
  }

  Uint8List readElement(int expectedTag) {
    if (_offset >= _bytes.length || _bytes[_offset] != expectedTag) {
      throw FormatException('ASN.1 格式错误：期望 tag $expectedTag');
    }
    _offset++;
    final length = _readLength();
    if (_offset + length > _bytes.length) {
      throw const FormatException('ASN.1 长度超出范围');
    }
    final value = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return value;
  }

  int _readLength() {
    final first = _bytes[_offset++];
    if (first < 0x80) {
      return first;
    }
    final count = first & 0x7f;
    if (count == 0 || count > 4 || _offset + count > _bytes.length) {
      throw const FormatException('ASN.1 长度格式错误');
    }
    var length = 0;
    for (var i = 0; i < count; i++) {
      length = (length << 8) | _bytes[_offset++];
    }
    return length;
  }
}

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}
