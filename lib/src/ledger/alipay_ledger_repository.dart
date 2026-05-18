import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import 'alipay_ledger_models.dart';
import 'alipay_ledger_service.dart';
import 'alipay_oauth_service.dart';

final alipayOAuthServiceProvider = Provider<AlipayOAuthService>((ref) {
  return AlipayOAuthService();
});

final alipayLedgerServiceProvider = Provider<AlipayLedgerService>((ref) {
  return AlipayLedgerService();
});

final alipayLedgerRepositoryProvider = Provider<AlipayLedgerRepository>((ref) {
  return AlipayLedgerRepository(
    database: ref.watch(appDatabaseProvider),
    oauthService: ref.watch(alipayOAuthServiceProvider),
    ledgerService: ref.watch(alipayLedgerServiceProvider),
  );
});

class AlipayLedgerRepository {
  const AlipayLedgerRepository({
    required AppDatabase database,
    required AlipayOAuthService oauthService,
    required AlipayLedgerService ledgerService,
  }) : _database = database,
       _oauthService = oauthService,
       _ledgerService = ledgerService;

  final AppDatabase _database;
  final AlipayOAuthService _oauthService;
  final AlipayLedgerService _ledgerService;

  Stream<AlipayLedgerConfig> watchConfig() {
    return _database
        .watchSettingValue(alipayLedgerConfigKey)
        .map(AlipayLedgerConfig.parse);
  }

  Stream<AlipayOAuthToken> watchToken() {
    return _database
        .watchSettingValue(alipayOAuthTokenKey)
        .map(AlipayOAuthToken.parse);
  }

  Future<AlipayLedgerConfig> loadConfig() async {
    return AlipayLedgerConfig.parse(
      await _database.getSettingValue(alipayLedgerConfigKey),
    );
  }

  Future<AlipayOAuthToken> loadToken() async {
    return AlipayOAuthToken.parse(
      await _database.getSettingValue(alipayOAuthTokenKey),
    );
  }

  Future<void> saveConfig(AlipayLedgerConfig config) {
    return _database.setSettingValue(
      alipayLedgerConfigKey,
      jsonEncode(config.toJson()),
    );
  }

  Future<void> saveToken(AlipayOAuthToken token) {
    return _database.setSettingValue(
      alipayOAuthTokenKey,
      jsonEncode(token.toJson()),
    );
  }

  Future<void> clearToken() {
    return _database.setSettingValue(alipayOAuthTokenKey, '');
  }

  Future<AlipayOAuthToken> connectWithBrowser() async {
    final config = await loadConfig();
    final authCode = await _oauthService.requestAuthorizationCode(
      config: config,
    );
    return exchangeAuthCode(authCode);
  }

  Future<AlipayOAuthToken> exchangeAuthCode(String authCode) async {
    final config = await loadConfig();
    final token = await _oauthService.exchangeAuthCode(
      config: config,
      authCode: authCode,
    );
    await saveToken(token);
    return token;
  }

  Future<AlipayLedgerPreview> queryPreview(AlipayLedgerQuery query) async {
    final config = await loadConfig();
    var token = await loadToken();
    if (!config.isConfigured) {
      throw const AlipayOAuthException('请先保存完整的支付宝配置');
    }
    if (!token.isAuthorized) {
      throw const AlipayOAuthException('请先连接支付宝并完成授权');
    }
    if (token.isExpired) {
      token = await _oauthService.refreshToken(config: config, token: token);
      await saveToken(token);
    }
    return _ledgerService.queryBills(
      config: config,
      token: token,
      query: query,
    );
  }

  Future<AlipayLedgerImportResult> importRows(List<AlipayBillRow> rows) async {
    var added = 0;
    var duplicates = 0;
    var ignored = 0;
    for (final row in rows) {
      final occurredAt = row.occurredAt;
      if (!row.isImportable || occurredAt == null) {
        ignored++;
        continue;
      }
      final inserted = await _database.importLedgerEntry(
        sourceId: row.sourceId,
        type: row.type,
        amount: row.amount,
        note: row.note,
        occurredAt: occurredAt,
      );
      if (inserted) {
        added++;
      } else {
        duplicates++;
      }
    }
    return AlipayLedgerImportResult(
      added: added,
      duplicates: duplicates,
      ignored: ignored,
    );
  }
}
