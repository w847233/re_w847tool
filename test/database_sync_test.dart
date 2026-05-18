import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_toolbox/src/data/app_database.dart';
import 'package:personal_toolbox/src/exchange_rate/exchange_home_widget_repository.dart';
import 'package:personal_toolbox/src/get_token/get_token_models.dart';
import 'package:personal_toolbox/src/get_token/get_token_repository.dart';
import 'package:personal_toolbox/src/home/home_layout_repository.dart';
import 'package:personal_toolbox/src/ledger/alipay_ledger_models.dart';
import 'package:personal_toolbox/src/network/nat_traversal_models.dart';
import 'package:personal_toolbox/src/network/nat_traversal_repository.dart';
import 'package:personal_toolbox/src/settings/settings_repository.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('本地设置和工具数据可以导出并导入同步快照', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await source.setSettingValue(preferredFontWeightKey, '700');
    await HomeLayoutRepository(source).saveLayout([
      const HomeWidgetLayoutItem(
        widgetId: 'quickActions',
        size: HomeWidgetSize.banner,
        order: 0,
        visible: true,
      ),
      const HomeWidgetLayoutItem(
        widgetId: 'todayTodos',
        size: HomeWidgetSize.small,
        order: 1,
        visible: true,
      ),
    ]);
    await source.addNote(title: '测试便签', content: '同步内容');
    await source.addTodo('同步待办');
    await source.addLedgerEntry(type: '支出', amount: 12.5, note: '午餐');
    await source.addCountdownEvent(
      title: '发布日',
      targetDate: DateTime.utc(2026, 6, 1),
    );
    await source.addPomodoroSession(minutes: 25);
    await source.saveSteamStatusPreset(
      text: '在摸鱼 🐟',
      appId: 730,
      richText: '#status_online',
    );
    await source.addSteamStatusHistory(
      text: '认真工作中',
      appId: 570,
      richText: '#status_busy',
    );
    final sourceGetToken = GetTokenRepository(source);
    await sourceGetToken.saveConfig(
      const GetTokenConfig(
        baseUrl: 'http://example.com/v0/management',
        batchSize: 20,
        timeout: 45,
        apiRange: '7d',
        cacheRange: 'today',
        tokenSortMode: 'tokens',
        tokenPollingEnabled: true,
      ),
    );
    await sourceGetToken.saveSecretConfig(
      const GetTokenSecretConfig(managementKey: 'local-secret'),
    );
    await sourceGetToken.saveCollectionSnapshot(
      snapshot: GetTokenCollectionSnapshot(
        status: 'completed',
        message: '采集完成',
        processed: 1,
        total: 1,
        progressPercent: 100,
        createdAt: DateTime.utc(2026, 5, 15, 10),
        updatedAt: DateTime.utc(2026, 5, 15, 10, 5),
        completedAt: DateTime.utc(2026, 5, 15, 10, 5),
        summary: const GetTokenSummary(
          totalCredentials: 1,
          successCount: 1,
          totalRemainingPercent: 77,
        ),
        credentialChanges: const GetTokenCredentialChanges(
          hasPrevious: true,
          previousCount: 1,
          currentCount: 1,
        ),
        refreshStats: const GetTokenRefreshStats(totalCount: 1),
      ),
      credentials: const [
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
    await sourceGetToken.mergeUsageEvents([
      GetTokenUsageEvent(
        id: 'evt-a',
        authIndex: 'auth-a',
        source: 'a@example.com',
        timestamp: DateTime.utc(2026, 5, 15, 11),
        totalTokens: 42,
        inputTokens: 40,
        outputTokens: 2,
        raw: const {'id': 'evt-a'},
      ),
    ]);
    await sourceGetToken.saveUsageSnapshot(
      GetTokenUsageSnapshot(
        updatedAt: DateTime.utc(2026, 5, 15, 11, 5),
        params: const GetTokenUsageQuery(apiRange: '4h', cacheRange: '4h'),
        eventTableCount: 1,
        addedEventCount: 1,
        summary: const GetTokenUsageSummary(
          credentialCount: 1,
          eventCount: 1,
          totalTokens: 42,
        ),
        rows: const [
          GetTokenUsageRow(
            authIndex: 'auth-a',
            source: 'a@example.com',
            totalTokens: 42,
          ),
        ],
        upstream: const GetTokenUpstreamInfo(
          totalCount: 1,
          page: 1,
          pageSize: 500,
        ),
      ),
    );

    final snapshot = await source.exportPlainSnapshot();
    await target.importPlainSnapshot(snapshot);

    expect(await target.getSettingValue(preferredFontWeightKey), '700');
    expect(await target.getSettingValue(homeWidgetLayoutKey), isNot(null));
    expect(await target.watchActiveNotes().first, hasLength(1));
    expect(await target.watchActiveTodos().first, hasLength(1));
    expect(await target.watchActiveLedgerEntries().first, hasLength(1));
    expect(await target.watchActiveCountdownEvents().first, hasLength(1));
    expect(await target.watchPomodoroSessions().first, hasLength(1));
    expect(await target.watchSteamStatusPresets().first, hasLength(1));
    expect(await target.watchSteamStatusHistoryEntries().first, hasLength(1));
    expect(
      (await target.watchSteamStatusPresets().first)
          .single
          .steamStatusDisplayText,
      '在摸鱼 🐟',
    );
    expect(
      (await target.watchSteamStatusHistoryEntries().first)
          .single
          .richPresenceTokenText,
      '#status_busy',
    );
    final targetGetToken = GetTokenRepository(target);
    final targetConfig = await targetGetToken.loadConfig();
    final targetSecret = await targetGetToken.loadSecretConfig();
    final targetCollection = await targetGetToken.loadCollectionSnapshot();
    final targetUsageSnapshot = await targetGetToken.loadUsageSnapshot();
    final targetUsageEvents = await targetGetToken.loadUsageEvents();
    expect(targetConfig.baseUrl, 'http://example.com/v0/management');
    expect(targetConfig.tokenSortMode, 'tokens');
    expect(targetConfig.tokenPollingEnabled, isTrue);
    expect(targetSecret.managementKey, isEmpty);
    expect(targetCollection?.summary?.totalRemainingPercent, 77);
    expect(targetCollection?.credentialChanges?.hasPrevious, isTrue);
    expect(
      (await targetGetToken.loadCredentialRows()).single.email,
      'a@example.com',
    );
    expect(targetUsageSnapshot?.summary.totalTokens, 42);
    expect(targetUsageEvents.single.id, 'evt-a');
  });

  test('快照导入按更新时间保留较新的设置', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.setSettingValue(preferredFontWeightKey, '900');
    final localSnapshot = await database.exportPlainSnapshot();
    final staleRemote = Map<String, dynamic>.from(localSnapshot);
    staleRemote['settings'] = [
      {
        'key': preferredFontWeightKey,
        'value': '100',
        'updatedAt': DateTime.utc(2020).toIso8601String(),
        'deviceId': 'remote',
      },
    ];

    await database.importPlainSnapshot(staleRemote);

    expect(await database.getSettingValue(preferredFontWeightKey), '900');
  });

  test('支付宝配置和授权令牌只保存在本机，不进入同步快照', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.setSettingValue(
      alipayLedgerConfigKey,
      '{"appId":"202100","privateKeyPem":"secret"}',
    );
    await database.setSettingValue(
      alipayOAuthTokenKey,
      '{"accessToken":"token","userId":"2088"}',
    );

    final snapshot = await database.exportPlainSnapshot();
    final settings = snapshot['settings'] as List;

    expect(
      settings.where(
        (row) =>
            row is Map &&
            (row['key'] == alipayLedgerConfigKey ||
                row['key'] == alipayOAuthTokenKey),
      ),
      isEmpty,
    );
  });

  test('NAT 穿透配置和打洞规则会保存到本地设置', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = NatTraversalRepository(database);

    await repository.saveConfig(
      const NatTraversalConfig(
        stunServers: <String>[
          'stun.example.com:3478',
          'tcp-stun.example.com:443',
        ],
        turnServer: 'turn.example.com:3478',
        turnUsername: 'user',
        turnPassword: 'secret',
        tcpKeepAliveServer: 'http.example.com:80',
      ),
    );
    await repository.addRule(
      protocol: NatTunnelProtocol.udp,
      targetAddress: '127.0.0.1',
      targetPort: 5353,
      label: '本机 UDP 服务',
      remoteHost: '203.0.113.10',
      remotePort: 40000,
    );

    final config = await repository.loadConfig();
    final rules = await repository.loadRules();

    expect(config.stunServers, <String>[
      'stun.example.com:3478',
      'tcp-stun.example.com:443',
    ]);
    expect(config.turnUsername, 'user');
    expect(config.tcpKeepAliveServer, 'http.example.com:80');
    expect(rules.single.protocol, NatTunnelProtocol.udp);
    expect(rules.single.targetPort, 5353);
    expect(rules.single.remotePort, 40000);
  });

  test('旧版 NAT 穿透配置会自动迁移为 STUN 列表', () {
    final config = NatTraversalConfig.fromJson(const <String, dynamic>{
      'stunServer': 'stun.example.com:3478',
      'tcpStunServer': 'tcp-stun.example.com:443',
      'turnServer': 'turn.example.com:3478',
    });

    expect(config.stunServers, <String>[
      'stun.example.com:3478',
      'tcp-stun.example.com:443',
    ]);
    expect(config.turnServer, 'turn.example.com:3478');
  });

  test('WebDAV 同步服务器配置会保存到本地设置', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SettingsRepository(database);

    await repository.saveWebDavSyncConfig(
      const WebDavSyncServerConfig(
        baseUrl: 'https://dav.example.com/remote.php/dav/files/demo/',
        username: 'demo-user',
        password: 'demo-password',
      ),
    );

    final config = await repository.loadWebDavSyncConfig();
    final saved = await database.getSettingValue(webDavSyncConfigKey);

    expect(
      config.baseUrl,
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    expect(config.username, 'demo-user');
    expect(config.password, 'demo-password');
    expect(saved, contains('dav.example.com'));
    expect(saved, contains('demo-user'));
  });

  test('同步加密口令会保存到本地设置', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SettingsRepository(database);

    await repository.saveSyncPassphrase('secret-passphrase');

    final saved = await database.getSettingValue(syncPassphraseKey);
    final loaded = await repository.loadSyncPassphrase();

    expect(saved, 'secret-passphrase');
    expect(loaded, 'secret-passphrase');
  });

  test('主页布局缺失、损坏或未知小组件时回退到有效默认布局', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HomeLayoutRepository(database);

    expect(repository.parseLayout(null), hasLength(7));
    expect(repository.parseLayout('not-json'), hasLength(7));

    final withUnknown = repository.parseLayout(
      '{"items":[{"widgetId":"unknown","size":"large","order":0,"visible":true}]}',
    );
    expect(withUnknown.map((item) => item.widgetId), contains('todayTodos'));
    expect(
      withUnknown.map((item) => item.widgetId),
      isNot(contains('unknown')),
    );
  });

  test('主页汇率小组件配置缺失或损坏时回退到默认值', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ExchangeHomeWidgetRepository(database);

    expect(repository.parseConfig(null), const ExchangeHomeWidgetConfig());
    expect(
      repository.parseConfig('not-json'),
      const ExchangeHomeWidgetConfig(),
    );

    final normalized = repository.parseConfig(
      '{"fromCode":"USD","targetCodes":["USD","EUR","EUR","XYZ"],"refreshSeconds":1}',
    );
    expect(normalized.fromCode, 'USD');
    expect(normalized.targetCodes, ['EUR']);
    expect(normalized.refreshSeconds, 5);
  });

  test('主页汇率小组件配置保存后可以恢复', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ExchangeHomeWidgetRepository(database);

    await repository.saveConfig(
      const ExchangeHomeWidgetConfig(
        fromCode: 'USD',
        targetCodes: ['JPY', 'EUR'],
        refreshSeconds: 12,
      ),
    );

    final loaded = await repository.loadConfig();
    expect(loaded.fromCode, 'USD');
    expect(loaded.targetCodes, ['JPY', 'EUR']);
    expect(loaded.refreshSeconds, 12);
  });

  test('主页布局保存后可以恢复顺序和尺寸', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HomeLayoutRepository(database);

    await repository.saveLayout([
      const HomeWidgetLayoutItem(
        widgetId: 'quickActions',
        size: HomeWidgetSize.banner,
        order: 0,
        visible: true,
      ),
      const HomeWidgetLayoutItem(
        widgetId: 'todayTodos',
        size: HomeWidgetSize.small,
        order: 1,
        visible: true,
      ),
    ]);

    final layout = await repository.loadLayout();
    expect(layout.first.widgetId, 'quickActions');
    expect(layout.first.size, HomeWidgetSize.banner);
    expect(layout[1].widgetId, 'todayTodos');
    expect(layout[1].size, HomeWidgetSize.small);
  });
}
