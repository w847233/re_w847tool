import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:personal_toolbox/src/get_token/get_token_models.dart';
import 'package:personal_toolbox/src/get_token/get_token_service.dart';

void main() {
  test('额度采集会生成 summary、增减对比和 refresh stats', () async {
    final service = GetTokenService(
      client: _FakeClient((request, body) async {
        final url = request.url.toString();
        if (url.endsWith('/auth-files')) {
          return _jsonResponse({
            'files': [
              {
                'auth_index': 'keep-auth',
                'email': 'keep@example.com',
                'name': 'keep.json',
                'id_token': {
                  'chatgpt_account_id': 'acct-keep',
                  'plan_type': 'free',
                },
              },
              {
                'auth_index': 'new-auth',
                'email': 'new@example.com',
                'name': 'new.json',
                'id_token': {
                  'chatgpt_account_id': 'acct-new',
                  'plan_type': 'free',
                },
              },
            ],
          });
        }
        if (url.endsWith('/api-call')) {
          final payload = jsonDecode(body!) as Map<String, dynamic>;
          final authIndex = payload['authIndex'];
          if (authIndex == 'keep-auth') {
            return _jsonResponse({
              'status_code': 200,
              'body': jsonEncode({
                'plan_type': 'free',
                'rate_limit': {
                  'limit_reached': false,
                  'primary_window': {
                    'used_percent': 30,
                    'reset_at': '2026-05-16T00:00:00Z',
                    'reset_after_seconds': 7200,
                    'limit_window_seconds': 10800,
                  },
                },
              }),
            });
          }
          return _jsonResponse({
            'status_code': 200,
            'body': jsonEncode({
              'plan_type': 'free',
              'rate_limit': {
                'limit_reached': false,
                'primary_window': {
                  'used_percent': 50,
                  'reset_at': DateTime.utc(2026, 5, 30).millisecondsSinceEpoch,
                  'reset_after_seconds': 200000,
                  'limit_window_seconds': 300000,
                },
              },
            }),
          });
        }
        throw StateError('unexpected url: $url');
      }),
    );
    addTearDown(service.dispose);

    final result = await service.collectCredentials(
      config: const GetTokenConfig(
        baseUrl: 'https://example.com/v0/management',
      ),
      secret: const GetTokenSecretConfig(managementKey: 'secret'),
      previousRows: const [
        GetTokenCredentialRow(
          id: 'keep-auth',
          email: 'keep@example.com',
          status: 'success',
          authIndex: 'keep-auth',
          remainingPercent: 82.5,
          usedPercent: 17.5,
        ),
        GetTokenCredentialRow(
          id: 'removed-auth',
          email: 'removed@example.com',
          status: 'success',
          authIndex: 'removed-auth',
          remainingPercent: 99,
          usedPercent: 1,
        ),
      ],
    );

    expect(result.snapshot.summary?.totalCredentials, 2);
    expect(result.snapshot.summary?.successCount, 2);
    expect(result.snapshot.credentialChanges?.addedCount, 1);
    expect(result.snapshot.credentialChanges?.removedCount, 1);
    expect(result.snapshot.credentialChanges?.quotaDecreaseCount, 1);
    expect(result.snapshot.credentialChanges?.totalQuotaDecrease, 12.5);
    expect(result.snapshot.refreshStats?.refreshIn5DayCount, 0);
    expect(result.snapshot.refreshStats?.unrefreshedCount, 1);
    expect(
      result.credentials
          .singleWhere((row) => row.authIndex == 'new-auth')
          .resetAt,
      DateTime.utc(2026, 5, 30),
    );
    expect(result.credentials.where((row) => row.isFailure), isEmpty);
  });

  test('token usage 会合并本地事件表并带出当前额度', () async {
    final service = GetTokenService(
      client: _FakeClient((request, body) async {
        final url = request.url.toString();
        if (url.startsWith('https://example.com/v0/management/usage/events')) {
          return _jsonResponse({
            'events': [
              {
                'id': 'evt-1',
                'auth_index': 'auth-a',
                'source': 'a@example.com',
                'timestamp': '2099-05-15T10:00:00Z',
                'model': 'gpt-5.5',
                'tokens': {
                  'input_tokens': 10,
                  'output_tokens': 2,
                  'reasoning_tokens': 0,
                  'cached_tokens': 8,
                  'total_tokens': 12,
                },
              },
              {
                'id': 'evt-2',
                'auth_index': 'auth-a',
                'source': 'a@example.com',
                'timestamp': '2099-05-15T11:00:00Z',
                'model': 'gpt-5.5',
                'tokens': {
                  'input_tokens': 20,
                  'output_tokens': 3,
                  'reasoning_tokens': 0,
                  'cached_tokens': 10,
                  'total_tokens': 23,
                },
              },
            ],
            'models': ['gpt-5.5'],
            'sources': [],
            'total_count': 2,
            'page': 1,
            'page_size': 500,
            'total_pages': 1,
          });
        }
        throw StateError('unexpected url: $url');
      }),
    );
    addTearDown(service.dispose);

    final result = await service.collectTokenUsage(
      config: const GetTokenConfig(
        baseUrl: 'https://example.com/v0/management',
      ),
      secret: const GetTokenSecretConfig(managementKey: 'secret'),
      query: const GetTokenUsageQuery(apiRange: '4h', cacheRange: '4h'),
      existingEvents: [
        GetTokenUsageEvent(
          id: 'evt-1',
          authIndex: 'auth-a',
          source: 'a@example.com',
          timestamp: DateTime.utc(2099, 5, 15, 10),
          totalTokens: 12,
        ),
      ],
      previousRows: const [],
      currentCredentialRows: const [
        GetTokenCredentialRow(
          id: 'auth-a',
          email: 'a@example.com',
          status: 'success',
          authIndex: 'auth-a',
          remainingPercent: 77,
          usedPercent: 23,
          planType: 'free',
        ),
      ],
    );

    expect(result.snapshot.eventTableCount, 2);
    expect(result.snapshot.addedEventCount, 1);
    expect(result.snapshot.summary.eventCount, 2);
    expect(result.snapshot.summary.totalTokens, 35);
    expect(result.snapshot.rows, hasLength(1));
    expect(result.snapshot.rows.single.currentUsage?.remainingPercent, 77);
  });

  test('token usage 自定义范围缺少日期时会抛错', () async {
    final service = GetTokenService(
      client: _FakeClient((request, body) async {
        throw StateError('should not request network');
      }),
    );
    addTearDown(service.dispose);

    expect(
      () => service.collectTokenUsage(
        config: const GetTokenConfig(),
        secret: const GetTokenSecretConfig(),
        query: const GetTokenUsageQuery(apiRange: 'custom', cacheRange: '4h'),
        existingEvents: const [],
        previousRows: const [],
        currentCredentialRows: const [],
      ),
      throwsA(isA<GetTokenServiceException>()),
    );
  });

  test('额度采集缺少 Bearer Key 时会直接拒绝请求', () async {
    final service = GetTokenService(
      client: _FakeClient((request, body) async {
        throw StateError('should not request network');
      }),
    );
    addTearDown(service.dispose);

    expect(
      () => service.collectCredentials(
        config: const GetTokenConfig(
          baseUrl: 'https://example.com/v0/management',
        ),
        secret: const GetTokenSecretConfig(),
        previousRows: const [],
      ),
      throwsA(isA<GetTokenServiceException>()),
    );
  });

  test('Token 使用统计通过管理接口请求并允许 http baseUrl', () async {
    final service = GetTokenService(
      client: _FakeClient((request, body) async {
        final url = request.url.toString();
        if (url.startsWith('http://example.com/v0/management/usage/events')) {
          return _jsonResponse({
            'events': const [],
            'models': const [],
            'sources': const [],
            'total_count': 0,
            'page': 1,
            'page_size': 500,
            'total_pages': 0,
          });
        }
        throw StateError('unexpected url: $url');
      }),
    );
    addTearDown(service.dispose);

    final result = await service.collectTokenUsage(
      config: const GetTokenConfig(baseUrl: 'http://example.com/v0/management'),
      secret: const GetTokenSecretConfig(managementKey: 'secret'),
      query: const GetTokenUsageQuery(apiRange: '4h', cacheRange: '4h'),
      existingEvents: const [],
      previousRows: const [],
      currentCredentialRows: const [],
    );

    expect(result.snapshot.eventTableCount, 0);
  });

  test('管理接口 baseUrl 使用非 http(s) 协议时会直接拒绝请求', () async {
    final service = GetTokenService(
      client: _FakeClient((request, body) async {
        throw StateError('should not request network');
      }),
    );
    addTearDown(service.dispose);

    expect(
      () => service.collectTokenUsage(
        config: const GetTokenConfig(
          baseUrl: 'ftp://example.com/v0/management',
        ),
        secret: const GetTokenSecretConfig(managementKey: 'secret'),
        query: const GetTokenUsageQuery(apiRange: '4h', cacheRange: '4h'),
        existingEvents: const [],
        previousRows: const [],
        currentCredentialRows: const [],
      ),
      throwsA(isA<GetTokenServiceException>()),
    );
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request, String? body)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final body = bytes.isEmpty ? null : utf8.decode(bytes);
    final response = await _handler(request, body);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

http.Response _jsonResponse(Map<String, dynamic> payload) {
  return http.Response(
    jsonEncode(payload),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
