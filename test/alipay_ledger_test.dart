import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:personal_toolbox/src/data/app_database.dart';
import 'package:personal_toolbox/src/ledger/alipay_ledger_models.dart';
import 'package:personal_toolbox/src/ledger/alipay_ledger_repository.dart';
import 'package:personal_toolbox/src/ledger/alipay_ledger_service.dart';
import 'package:personal_toolbox/src/ledger/alipay_oauth_service.dart';
import 'package:personal_toolbox/src/ledger/alipay_open_api_client.dart';

const _privateKey = '''
-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAO4D5uMzQMSARuUF
kl8dY0nQ2t4w5dD/1/lGf50jonB1UOt6qmK013OIJURehAeRsl3XZTRhXvC2Sw6V
NrIC5H0iShWQC/WcaHzEyc3hcwJBzxUyhumKXFPoNLCMMwhxC/puwxrwuVV0Z1jO
2vt/CzzVSRE/GORpxmEYOGu9ZbsJAgMBAAECgYBu2U5cnfAaFAvweYnT1mH5bNWi
CW/eyGiTZavlSUVLzrdjE/vqgIKfAdcpYkNnKwnA/qHZpUeMH7oRDpksioBSiPFj
GQ2uwn2js5l0hn1psHzEBtX5zL3cJjIJXqM10ZVDVSbYXMZf53d4Zj1nhjRBEESg
EMCKCPXXIx+/fafjAQJBAP47DifxYQHwfqPcM9w6Rrkjnm5K0/4In4tToKYLLmyu
EqPfT85o+gGI/DbqCpiqrNxRcJX590IcHOT2ppOvtRECQQDvq/TqyiWetZrYVXyh
paIJesMt1PsjfMdNE2PeMxY/qBe28W961AiZcGdzATbr0GfxieaiK8Tu5nhlMCJ8
bsZ5AkBZvsEliokjJSGfeJl6EbxrmM5RwuqJD8Q6a+AXHXVa+iwsWyWSCO7QYeoe
/ImXEREKiVlEKESHuuLcVNHC6tDxAkEAu2mcf8iIuF1L8ySN650oYv9DBmDH7Q0S
j7u82TDbkfVwbdbHlKWe/9T8n9pwRt/Vl/N8jI1rVmCT/pQwM1swCQJAFjpHv9vO
t4YSYPqV1UzjmXfpAoy1GE4oApbowb7eFYd5Kdy84lDPqI4TXTGLwA5NI8wXTWZi
eCOsy4W4o90Hmg==
-----END PRIVATE KEY-----
''';

const _publicKey = '''
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDuA+bjM0DEgEblBZJfHWNJ0Nre
MOXQ/9f5Rn+dI6JwdVDreqpitNdziCVEXoQHkbJd12U0YV7wtksOlTayAuR9IkoV
kAv1nGh8xMnN4XMCQc8VMobpilxT6DSwjDMIcQv6bsMa8LlVdGdYztr7fws81UkR
PxjkacZhGDhrvWW7CQIDAQAB
-----END PUBLIC KEY-----
''';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('OpenAPI 待签名字符串会按参数名排序并排除 sign', () {
    final text = AlipayOpenApiClient.buildSignText({
      'method': 'alipay.test',
      'app_id': '202100',
      'sign': 'ignored',
      'charset': 'utf-8',
    });

    expect(text, 'app_id=202100&charset=utf-8&method=alipay.test');
  });

  test('RSA2 签名可以用对应公钥验签', () {
    final params = {
      'app_id': '202100',
      'charset': 'utf-8',
      'method': 'alipay.test',
    };

    final signature = AlipayOpenApiClient.signParams(params, _privateKey);

    expect(
      AlipayOpenApiClient.verifySignature(
        params: params,
        signature: signature,
        publicKeyPem: _publicKey,
      ),
      isTrue,
    );
  });

  test('OpenAPI 请求会带 auth_token 并验签支付宝响应', () async {
    Map<String, String>? posted;
    const responseJson = '{"code":"10000","value":"ok"}';
    final signature = AlipayOpenApiClient.signTextWithPrivateKey(
      responseJson,
      _privateKey,
    );
    final client = AlipayOpenApiClient(
      config: AlipayLedgerConfig(
        appId: '202100',
        privateKeyPem: _privateKey,
        alipayPublicKeyPem: _publicKey,
      ),
      client: _FakeAlipayHttpClient((request) async {
        posted = Uri.splitQueryString(request.body);
        return _jsonResponse(
          '{"alipay_test_response":$responseJson,"sign":"$signature"}',
        );
      }),
    );

    final result = await client.call(
      'alipay.test',
      const {'foo': 'bar'},
      extraParams: const {'auth_token': 'access-token'},
    );

    expect(posted?['auth_token'], 'access-token');
    expect(posted?['sign'], isNotEmpty);
    expect(result['value'], 'ok');
  });

  test('OpenAPI 响应验签失败时拒绝结果', () async {
    final client = AlipayOpenApiClient(
      config: AlipayLedgerConfig(
        appId: '202100',
        privateKeyPem: _privateKey,
        alipayPublicKeyPem: _publicKey,
      ),
      client: _FakeAlipayHttpClient((_) async {
        return _jsonResponse(
          '{"alipay_test_response":{"code":"10000"},"sign":"bad-sign"}',
        );
      }),
    );

    await expectLater(
      client.call('alipay.test', const {}),
      throwsA(
        isA<AlipayOpenApiException>().having(
          (error) => error.message,
          'message',
          contains('验签失败'),
        ),
      ),
    );
  });

  test('OAuth token 响应会解析身份、令牌和过期时间', () {
    final now = DateTime.utc(2026, 5, 18, 12);
    final service = AlipayOAuthService(
      browserOpener: (_) async {},
      now: () => now,
    );

    final token = service.parseTokenResponse({
      'user_id': '2088',
      'open_id': 'open-a',
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'expires_in': '3600',
    });

    expect(token.userId, '2088');
    expect(token.openId, 'open-a');
    expect(token.accessToken, 'access-token');
    expect(token.refreshToken, 'refresh-token');
    expect(token.expiresAt, now.add(const Duration(hours: 1)));
  });

  test('OAuth state 不匹配时拒绝授权结果', () {
    final service = AlipayOAuthService(browserOpener: (_) async {});

    expect(
      service.isValidState(
        Uri.parse('http://127.0.0.1:39187/alipay/oauth/callback?state=bad'),
        'expected',
      ),
      isFalse,
    );
  });

  test('解析 call-alipay-service 同款 billListItems 响应', () {
    final preview = AlipayLedgerService().parsePreview(
      method: defaultAlipayLedgerMethod,
      response: {
        'code': '10000',
        'billListItems': [
          {
            'gmtCreate': 1770000000000,
            'categoryName': '餐饮',
            'consumeTitle': '午餐',
            'consumeFee': '28.50',
            'bizStateDesc': '交易成功',
            'fundState': '已支付',
            'tradeNo': 'trade-a',
          },
        ],
        'statisticInfo': {'expenditureAmount': '28.50', 'incomeAmount': '0'},
      },
    );

    expect(preview.rows, hasLength(1));
    expect(preview.rows.single.sourceId, contains('trade-a'));
    expect(preview.rows.single.type, '支出');
    expect(preview.rows.single.amount, 28.5);
    expect(preview.expenseAmount, 28.5);
  });

  test('解析公开商户账务 detail_list 响应', () {
    final preview = AlipayLedgerService().parsePreview(
      method: alipayAccountLogMethod,
      response: {
        'code': '10000',
        'detail_list': [
          {
            'trans_dt': '2026-05-18 10:00:00',
            'account_log_id': 'log-a',
            'trans_amount': '100.00',
            'direction': '收入',
            'type': '交易',
            'trans_memo': '收款',
          },
        ],
      },
    );

    expect(preview.rows.single.sourceId, contains('log-a'));
    expect(preview.rows.single.type, '收入');
    expect(preview.rows.single.note, '支付宝｜交易｜收款｜收入');
  });

  test('导入支付宝流水会跳过重复项并忽略无效项', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AlipayLedgerRepository(
      database: database,
      oauthService: AlipayOAuthService(browserOpener: (_) async {}),
      ledgerService: AlipayLedgerService(),
    );
    final row = AlipayBillRow(
      sourceId: 'alipay:test:1',
      type: '支出',
      amount: 12.5,
      title: '午餐',
      category: '餐饮',
      status: '交易成功',
      occurredAt: DateTime.utc(2026, 5, 18, 12),
      raw: const {},
    );

    final result = await repository.importRows([
      row,
      row,
      const AlipayBillRow(
        sourceId: '',
        type: '',
        amount: 0,
        title: '',
        category: '',
        status: '',
        occurredAt: null,
        raw: {},
      ),
    ]);

    expect(result.added, 1);
    expect(result.duplicates, 1);
    expect(result.ignored, 1);
    expect(await database.watchActiveLedgerEntries().first, hasLength(1));
  });
}

typedef _AlipayHandler =
    Future<http.StreamedResponse> Function(http.Request request);

class _FakeAlipayHttpClient extends http.BaseClient {
  _FakeAlipayHttpClient(this._handler);

  final _AlipayHandler _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request as http.Request);
  }
}

http.StreamedResponse _jsonResponse(String body) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    200,
    headers: const {'content-type': 'application/json'},
  );
}
