import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'alipay_ledger_models.dart';
import 'alipay_open_api_client.dart';

typedef BrowserOpener = Future<void> Function(Uri uri);

class AlipayOAuthService {
  AlipayOAuthService({BrowserOpener? browserOpener, DateTime Function()? now})
    : _browserOpener = browserOpener ?? _openInSystemBrowser,
      _now = now ?? DateTime.now;

  final BrowserOpener _browserOpener;
  final DateTime Function() _now;

  Uri buildAuthorizationUri({
    required String appId,
    required String state,
    String redirectUri = alipayOAuthRedirectUri,
  }) {
    return Uri.https('openauth.alipay.com', '/oauth2/publicAppAuthorize.htm', {
      'app_id': appId.trim(),
      'scope': 'auth_user',
      'redirect_uri': redirectUri,
      'state': state,
    });
  }

  Future<String> requestAuthorizationCode({
    required AlipayLedgerConfig config,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (!config.isConfigured) {
      throw const AlipayOAuthException('请先保存完整的支付宝配置');
    }
    final state = _randomState();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 39187);
    final completer = Completer<String>();
    late StreamSubscription<HttpRequest> subscription;
    subscription = server.listen((request) async {
      if (request.uri.path != '/alipay/oauth/callback') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final code =
          request.uri.queryParameters['auth_code'] ??
          request.uri.queryParameters['code'];
      final returnedState = request.uri.queryParameters['state'];
      if (code == null || code.trim().isEmpty) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(_html('未收到授权码，请从应用重新发起授权。'));
        await request.response.close();
        return;
      }
      if (returnedState != state) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(_html('授权校验失败，请回到应用重新授权。'));
        await request.response.close();
        if (!completer.isCompleted) {
          completer.completeError(
            const AlipayOAuthException('授权校验失败：state 不匹配'),
          );
        }
        return;
      }
      request.response.headers.contentType = ContentType.html;
      request.response.write(_html('授权成功，可以回到个人工具箱继续导入账单。'));
      await request.response.close();
      if (!completer.isCompleted) {
        completer.complete(code.trim());
      }
    });

    try {
      await _browserOpener(
        buildAuthorizationUri(appId: config.appId, state: state),
      );
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      throw const AlipayOAuthException('等待支付宝授权超时，请重试或手动粘贴 auth_code');
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  }

  Future<AlipayOAuthToken> exchangeAuthCode({
    required AlipayLedgerConfig config,
    required String authCode,
  }) async {
    final client = AlipayOpenApiClient(config: config, now: _now);
    final response = await client.call(
      alipayOAuthTokenMethod,
      <String, dynamic>{
        'grant_type': 'authorization_code',
        'code': authCode.trim(),
      },
      wrapBizContent: false,
    );
    return parseTokenResponse(response);
  }

  Future<AlipayOAuthToken> refreshToken({
    required AlipayLedgerConfig config,
    required AlipayOAuthToken token,
  }) async {
    if (token.refreshToken.trim().isEmpty) {
      throw const AlipayOAuthException('缺少 refresh_token，请重新授权');
    }
    final client = AlipayOpenApiClient(config: config, now: _now);
    final response = await client.call(
      alipayOAuthTokenMethod,
      <String, dynamic>{
        'grant_type': 'refresh_token',
        'refresh_token': token.refreshToken.trim(),
      },
      wrapBizContent: false,
    );
    final refreshed = parseTokenResponse(response);
    return refreshed.copyWith(
      userId: refreshed.userId.isEmpty ? token.userId : refreshed.userId,
      openId: refreshed.openId.isEmpty ? token.openId : refreshed.openId,
      refreshToken: refreshed.refreshToken.isEmpty
          ? token.refreshToken
          : refreshed.refreshToken,
    );
  }

  bool isValidState(Uri callbackUri, String expectedState) {
    return callbackUri.queryParameters['state'] == expectedState;
  }

  AlipayOAuthToken parseTokenResponse(Map<String, dynamic> response) {
    final expiresIn = int.tryParse(response['expires_in']?.toString() ?? '');
    final token = AlipayOAuthToken(
      userId: response['user_id']?.toString() ?? '',
      openId: response['open_id']?.toString() ?? '',
      accessToken: response['access_token']?.toString() ?? '',
      refreshToken: response['refresh_token']?.toString() ?? '',
      expiresAt: expiresIn == null
          ? null
          : _now().toUtc().add(Duration(seconds: expiresIn)),
    );
    if (token.accessToken.trim().isEmpty) {
      throw const AlipayOAuthException('支付宝授权响应缺少 access_token');
    }
    return token;
  }
}

class AlipayOAuthException implements Exception {
  const AlipayOAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _randomState() {
  final random = Random.secure();
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
}

String _html(String message) {
  return '''
<!doctype html>
<html lang="zh-CN">
<meta charset="utf-8">
<title>支付宝授权</title>
<body style="font-family: sans-serif; padding: 32px;">
  <h2>$message</h2>
</body>
</html>
''';
}

Future<void> _openInSystemBrowser(Uri uri) async {
  if (Platform.isWindows) {
    await Process.run('rundll32', ['url.dll,FileProtocolHandler', '$uri']);
    return;
  }
  if (Platform.isMacOS) {
    await Process.run('open', ['$uri']);
    return;
  }
  await Process.run('xdg-open', ['$uri']);
}
