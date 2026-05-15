import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_toolbox/src/data/app_database.dart';
import 'package:personal_toolbox/src/home/home_layout_repository.dart';
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

  test('NAT 穿透配置和打洞规则会保存到本地设置', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = NatTraversalRepository(database);

    await repository.saveConfig(
      const NatTraversalConfig(
        stunServer: 'stun.example.com:3478',
        tcpStunServer: 'tcp-stun.example.com:443',
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

    expect(config.stunServer, 'stun.example.com:3478');
    expect(config.tcpStunServer, 'tcp-stun.example.com:443');
    expect(config.turnUsername, 'user');
    expect(config.tcpKeepAliveServer, 'http.example.com:80');
    expect(rules.single.protocol, NatTunnelProtocol.udp);
    expect(rules.single.targetPort, 5353);
    expect(rules.single.remotePort, 40000);
  });

  test('主页布局缺失、损坏或未知小组件时回退到有效默认布局', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HomeLayoutRepository(database);

    expect(repository.parseLayout(null), hasLength(6));
    expect(repository.parseLayout('not-json'), hasLength(6));

    final withUnknown = repository.parseLayout(
      '{"items":[{"widgetId":"unknown","size":"large","order":0,"visible":true}]}',
    );
    expect(withUnknown.map((item) => item.widgetId), contains('todayTodos'));
    expect(
      withUnknown.map((item) => item.widgetId),
      isNot(contains('unknown')),
    );
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
