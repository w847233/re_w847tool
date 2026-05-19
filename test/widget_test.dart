import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:personal_toolbox/main.dart';
import 'package:personal_toolbox/src/data/app_database.dart';
import 'package:personal_toolbox/src/data/database_provider.dart';
import 'package:personal_toolbox/src/exchange_rate/exchange_home_widget_repository.dart';
import 'package:personal_toolbox/src/exchange_rate/sina_forex_market_service.dart';
import 'package:personal_toolbox/src/get_token/get_token_repository.dart';
import 'package:personal_toolbox/src/get_token/get_token_tool.dart';
import 'package:personal_toolbox/src/home/home_layout_repository.dart';
import 'package:personal_toolbox/src/ledger/alipay_ledger_models.dart';
import 'package:personal_toolbox/src/network/nat_traversal_models.dart';
import 'package:personal_toolbox/src/network/nat_traversal_repository.dart';
import 'package:personal_toolbox/src/network/nat_traversal_service.dart';
import 'package:personal_toolbox/src/network/nat_traversal_tool.dart';
import 'package:personal_toolbox/src/settings/settings_repository.dart';
import 'package:personal_toolbox/src/sync/sync_service.dart';
import 'package:personal_toolbox/src/theme/app_theme.dart';
import 'package:personal_toolbox/src/ui/deferred_navigation.dart';
import 'package:personal_toolbox/src/sync/webdav_client.dart';
import 'package:personal_toolbox/src/steam_status/steam_status_models.dart';
import 'package:personal_toolbox/src/steam_status/steam_status_repository.dart';
import 'package:personal_toolbox/src/steam_status/steam_status_service.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('启动后默认进入主页并显示生活概览小组件', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester);

    expect(find.text('主页'), findsWidgets);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('今日待办'), findsOneWidget);
    expect(find.text('最近便签'), findsOneWidget);
    expect(find.text('本月收支'), findsOneWidget);
    expect(find.text('倒数日'), findsWidgets);
    expect(find.text('番茄钟统计'), findsOneWidget);
    expect(find.text('快捷工具'), findsOneWidget);
    expect(find.text('汇率速览'), findsOneWidget);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
    );
    expect(find.text('100 CNY'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('主页编辑模式显示尺寸和重置控件，完成后隐藏', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester);

    expect(find.text('重置布局'), findsNothing);
    expect(find.byIcon(Icons.aspect_ratio_outlined), findsNothing);

    await tester.tap(find.text('编辑主页'));
    await _pumpUi(tester);

    expect(find.text('重置布局'), findsOneWidget);
    expect(find.byIcon(Icons.aspect_ratio_outlined), findsWidgets);

    await tester.tap(find.text('完成编辑'));
    await _pumpUi(tester);

    expect(find.text('重置布局'), findsNothing);
    expect(find.byIcon(Icons.aspect_ratio_outlined), findsNothing);

    await _disposeApp(tester);
  });

  testWidgets('桌面编辑模式可直接拖动小组件调整顺序', (tester) async {
    await _setDesktopSize(tester);
    final database = await _pumpApp(tester);

    await tester.tap(find.text('编辑主页'));
    await _pumpUi(tester);

    await tester.dragFrom(
      tester.getCenter(
        find.byKey(const ValueKey('home-widget-drag-todayTodos')),
      ),
      tester.getCenter(
            find.byKey(const ValueKey('home-widget-drop-quickActions')),
          ) -
          tester.getCenter(
            find.byKey(const ValueKey('home-widget-drag-todayTodos')),
          ),
    );
    await _pumpUi(tester);

    final layout = await HomeLayoutRepository(database).loadLayout();
    expect(layout.last.widgetId, 'todayTodos');

    await _disposeApp(tester);
  });

  testWidgets('手机宽度下主页小组件按单列显示并可进入编辑模式', (tester) async {
    await _setMobileSize(tester);
    await _pumpApp(tester);

    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('今日待办'), findsOneWidget);

    await tester.tap(find.text('编辑主页'));
    await _pumpUi(tester);

    expect(find.byIcon(Icons.keyboard_arrow_down), findsWidgets);
    expect(tester.takeException(), isNull);

    await _disposeApp(tester);
  });

  testWidgets('记账页可以保存支付宝配置并在未授权时阻止查询', (tester) async {
    await _setDesktopSize(tester);
    final database = await _pumpApp(tester);

    await _tapToolNav(tester, '记账');
    await tester.ensureVisible(find.text('支付宝导入'));
    await _pumpUi(tester);

    await tester.enterText(find.widgetWithText(TextField, 'appId'), '202100');
    await tester.enterText(
      find.widgetWithText(TextField, 'privateKeyPem'),
      'private-key',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'alipayPublicKeyPem'),
      'public-key',
    );
    await tester.ensureVisible(find.text('保存配置'));
    await tester.tap(find.text('保存配置'));
    await _pumpUi(tester);

    final saved = await database.getSettingValue(alipayLedgerConfigKey);
    expect(saved, contains('202100'));
    expect(saved, contains(defaultAlipayLedgerMethod));

    await tester.ensureVisible(find.text('查询预览'));
    await tester.tap(find.text('查询预览'));
    await _pumpUi(tester);

    expect(find.text('请先连接支付宝并完成授权'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('桌面左侧导航底部展示设置入口并可进入个性化页', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester);

    expect(find.text('设置'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);

    expect(find.text('设置 · 个性化'), findsOneWidget);
    expect(find.text('字体粗细'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('字体粗细设置会写入本地设置表', (tester) async {
    await _setDesktopSize(tester);
    final database = await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('粗体'));
    await _pumpUi(tester);

    expect(await database.getSettingValue(preferredFontWeightKey), '700');

    await _disposeApp(tester);
  });

  testWidgets('关于页展示字体和同步说明', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('关于'));
    await _pumpUi(tester);

    expect(find.text('设置 · 关于'), findsOneWidget);
    expect(find.textContaining('HarmonyOS Sans'), findsWidgets);
    expect(find.textContaining('WebDAV'), findsWidgets);
    expect(find.text('当前项目技术链'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('flutter_riverpod'), findsOneWidget);
    expect(find.text('go_router'), findsOneWidget);
    expect(find.text('Drift + SQLite'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('汇率换算可以添加多个兑换货币并显示独立涨跌图', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = _FakeSinaForexMarketService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          sinaForexMarketServiceProvider.overrideWithValue(service),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await _pumpUi(tester);

    await tester.tap(find.text('汇率换算').first);
    await _pumpUi(tester);
    await tester.tap(find.byTooltip('添加兑换货币'));
    await _pumpUi(tester);

    expect(find.text('CNY / USD'), findsOneWidget);
    expect(find.text('CNY / EUR'), findsOneWidget);
    expect(find.textContaining('-7.69%'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('主页汇率速览支持点击刷新并更新显示数据', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await ExchangeHomeWidgetRepository(database).saveConfig(
      const ExchangeHomeWidgetConfig(
        fromCode: 'CNY',
        targetCodes: ['JPY'],
        refreshSeconds: 30,
      ),
    );
    final service = _FakeSinaForexMarketService(
      latestUsdLegsSequence: [
        const {'USD': 1, 'CNY': 0.14, 'JPY': 0.0070},
        const {'USD': 1, 'CNY': 0.14, 'JPY': 0.0065},
      ],
    );
    await _pumpApp(tester, database: database, exchangeService: service);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
    );

    expect(find.text('2000.0000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exchange-snapshot-widget')));
    await _pumpUi(tester);

    expect(find.text('2153.8462'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('主页汇率速览首次刷新失败时显示真实错误原因', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await ExchangeHomeWidgetRepository(database).saveConfig(
      const ExchangeHomeWidgetConfig(
        fromCode: 'CNY',
        targetCodes: ['JPY'],
        refreshSeconds: 30,
      ),
    );
    final service = _FakeSinaForexMarketService(
      latestUsdLegsSequence: [const SinaForexMarketException('测试网络故障')],
    );
    await _pumpApp(tester, database: database, exchangeService: service);
    await _pumpUi(tester);

    expect(find.text('更新失败：测试网络故障'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('汇率图表悬浮卡片会根据左右半区切换显示位置', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester, exchangeService: _FakeSinaForexMarketService());

    await _tapToolNav(tester, '汇率换算');
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('exchange-interactive-chart-USD')),
    );

    final chartFinder = find.byKey(
      const ValueKey('exchange-interactive-chart-USD'),
    );
    final chartRect = tester.getRect(chartFinder);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: chartRect.center);

    await gesture.moveTo(
      Offset(chartRect.left + chartRect.width * 0.25, chartRect.center.dy),
    );
    await tester.pump();

    Rect hoverCardRect = tester.getRect(
      find.byKey(const ValueKey('exchange-hover-card')),
    );
    expect(hoverCardRect.center.dx, greaterThan(chartRect.center.dx));

    await gesture.moveTo(
      Offset(chartRect.left + chartRect.width * 0.75, chartRect.center.dy),
    );
    await tester.pump();

    hoverCardRect = tester.getRect(
      find.byKey(const ValueKey('exchange-hover-card')),
    );
    expect(hoverCardRect.center.dx, lessThan(chartRect.center.dx));

    await _disposeApp(tester);
  });

  testWidgets('汇率工具可以保存主页汇率小组件配置并更新主页展示', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = _FakeSinaForexMarketService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          sinaForexMarketServiceProvider.overrideWithValue(service),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('exchange-snapshot-value-USD')),
    );

    await _tapToolNav(tester, '汇率换算');
    await tester.tap(
      find.byKey(const ValueKey('exchange-widget-config-button')),
    );
    await _pumpUi(tester);

    expect(find.text('主页汇率小组件'), findsOneWidget);
    await tester.tap(find.byTooltip('删除小组件货币').last);
    await _pumpUi(tester);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('保存')),
    );
    await _pumpUi(tester);

    await _tapToolNav(tester, '主页');

    expect(
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('exchange-snapshot-value-USD')),
      findsNothing,
    );

    await _tapToolNav(tester, '汇率换算');
    await tester.tap(
      find.byKey(const ValueKey('exchange-widget-config-button')),
    );
    await _pumpUi(tester);
    await tester.tap(find.byTooltip('添加小组件货币'));
    await _pumpUi(tester);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('保存')),
    );
    await _pumpUi(tester);

    final config = await ExchangeHomeWidgetRepository(database).loadConfig();
    expect(config.targetCodes, ['JPY', 'USD']);

    await _tapToolNav(tester, '主页');
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('exchange-snapshot-value-USD')),
    );
    expect(
      find.byKey(const ValueKey('exchange-snapshot-value-USD')),
      findsOneWidget,
    );

    await _disposeApp(tester);
  });

  testWidgets('主页汇率小组件会按涨跌显示文字颜色', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await ExchangeHomeWidgetRepository(database).saveConfig(
      const ExchangeHomeWidgetConfig(
        fromCode: 'CNY',
        targetCodes: ['JPY', 'EUR'],
        refreshSeconds: 5,
      ),
    );
    final service = _FakeSinaForexMarketService(
      latestUsdLegsResponses: [
        const {'USD': 1, 'CNY': 0.14, 'JPY': 0.0070, 'EUR': 1.10},
        const {'USD': 1, 'CNY': 0.14, 'JPY': 0.0069, 'EUR': 1.11},
        const {'USD': 1, 'CNY': 0.14, 'JPY': 0.0069, 'EUR': 1.11},
      ],
    );
    await _pumpApp(tester, database: database, exchangeService: service);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
    );

    Text jpyValue = tester.widget(
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
    );
    Text eurValue = tester.widget(
      find.byKey(const ValueKey('exchange-snapshot-value-EUR')),
    );
    expect(jpyValue.style?.color, AppColors.muted);
    expect(eurValue.style?.color, AppColors.muted);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    jpyValue = tester.widget(
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
    );
    eurValue = tester.widget(
      find.byKey(const ValueKey('exchange-snapshot-value-EUR')),
    );
    expect(jpyValue.style?.color, AppColors.bad);
    expect(eurValue.style?.color, AppColors.good);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    jpyValue = tester.widget(
      find.byKey(const ValueKey('exchange-snapshot-value-JPY')),
    );
    eurValue = tester.widget(
      find.byKey(const ValueKey('exchange-snapshot-value-EUR')),
    );
    expect(jpyValue.style?.color, AppColors.muted);
    expect(eurValue.style?.color, AppColors.muted);

    await _disposeApp(tester);
  });

  testWidgets('导航中包含 Steam 状态工具并可进入页面', (tester) async {
    await _setDesktopSize(tester);
    final controller = _FakeSteamStatusController();
    addTearDown(controller.dispose);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          steamStatusControllerProvider.overrideWithValue(controller),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Steam 状态'), findsWidgets);

    await _tapToolNav(tester, 'Steam 状态');

    await _pumpUntilFound(tester, find.text('Steam 侧车服务已就绪'));
    expect(find.text('连接与账号'), findsOneWidget);
    expect(find.text('Steam 侧车服务已就绪'), findsOneWidget);
    expect(find.text('当前未登录 Steam'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('工具导航会延迟挂载内容以保留点击反馈', (tester) async {
    await _setDesktopSize(tester);
    final controller = _FakeSteamStatusController();
    addTearDown(controller.dispose);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          steamStatusControllerProvider.overrideWithValue(controller),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await _pumpUi(tester);
    await tester.tap(find.text('Steam 状态').first);

    await tester.pump(deferredNavigationDelay ~/ 2);
    expect(find.text('连接与账号'), findsNothing);

    await tester.pump(deferredNavigationDelay);
    await tester.pump();
    expect(find.text('正在打开 Steam 状态'), findsOneWidget);
    expect(find.text('连接与账号'), findsNothing);

    await tester.pump(deferredToolContentDelay);
    await tester.pump();
    expect(find.text('连接与账号'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('Get Token 工具页可以保存配置', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: GetTokenTool(),
            ),
          ),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('采集配置'), findsOneWidget);
    expect(find.widgetWithText(TextField, '管理接口 baseUrl'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Bearer Key'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '管理接口 baseUrl'),
      'http://example.com/v0/management',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Bearer Key'),
      'local-secret',
    );
    await tester.tap(find.text('保存配置').first);
    await _pumpUi(tester);
    await tester.tap(find.text('保存密钥').first);
    await _pumpUi(tester);

    final repository = GetTokenRepository(database);
    final config = await repository.loadConfig();
    final secret = await repository.loadSecretConfig();
    expect(config.baseUrl, 'http://example.com/v0/management');
    expect(secret.managementKey, 'local-secret');

    await _disposeApp(tester);
  });

  testWidgets('导航中包含检测DNS泄露工具并可进入页面', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester);

    expect(find.text('网络'), findsOneWidget);
    expect(find.text('检测DNS泄露'), findsWidgets);

    await tester.tap(find.text('检测DNS泄露').first);
    await _pumpUi(tester);

    expect(find.text('DNS 泄露检测'), findsOneWidget);
    expect(find.text('全球 DNS 优选'), findsOneWidget);
    expect(find.text('将优选测试的域名'), findsOneWidget);
    expect(find.text('只优选国内 DNS 与国内域名'), findsOneWidget);
    expect(find.text('百度 · baidu.com'), findsOneWidget);
    expect(find.text('设置系统 DNS'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('设置页可以保存 NAT 穿透服务器配置', (tester) async {
    await _setDesktopSize(tester);
    final database = await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('网络').last);
    await _pumpUi(tester);

    expect(find.text('设置 · 网络'), findsOneWidget);
    expect(find.text('NAT 穿透服务器'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'STUN 服务器列表'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'TCP HTTP 保活服务器'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'STUN 服务器列表'),
      'stun.example.com:3478\ntcp-stun.example.com:443',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'TURN 服务器'),
      'turn.example.com:3478',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'TCP HTTP 保活服务器'),
      'http.example.com:80',
    );
    await tester.tap(find.text('保存 NAT 设置'));
    await _pumpUi(tester);

    final saved = await database.getSettingValue(natTraversalConfigKey);
    expect(saved, contains('stun.example.com:3478'));
    expect(saved, contains('tcp-stun.example.com:443'));
    expect(saved, contains('stunServers'));
    expect(saved, contains('turn.example.com:3478'));
    expect(saved, contains('http.example.com:80'));

    await _disposeApp(tester);
  });

  testWidgets('设置页可以保存 WebDAV 同步服务器配置', (tester) async {
    await _setDesktopSize(tester);
    final database = await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('网络').last);
    await _pumpUi(tester);

    expect(find.text('WebDAV 同步服务器'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'WebDAV 服务器地址'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'WebDAV 用户名'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'WebDAV 密码'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 服务器地址'),
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 用户名'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 密码'),
      'demo-password',
    );
    await tester.ensureVisible(find.text('保存 WebDAV 设置'));
    await tester.tap(find.text('保存 WebDAV 设置'));
    await _pumpUi(tester);

    final saved = await database.getSettingValue(webDavSyncConfigKey);
    expect(saved, contains('dav.example.com'));
    expect(saved, contains('demo-user'));
    expect(saved, contains('demo-password'));

    await _disposeApp(tester);
  });

  testWidgets('设置页可以测试 WebDAV 同步服务器连接', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final client = _FakeWebDavClient(result: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          webDavClientProvider.overrideWithValue(client),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('网络').last);
    await _pumpUi(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 服务器地址'),
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 用户名'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 密码'),
      'demo-password',
    );
    await tester.ensureVisible(find.text('测试连接'));
    await tester.tap(find.text('测试连接'));
    await _pumpUi(tester);

    expect(find.text('WebDAV 连接成功'), findsOneWidget);
    expect(
      client.lastConfig?.baseUrl,
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    expect(client.lastConfig?.username, 'demo-user');
    expect(client.lastConfig?.password, 'demo-password');

    await _disposeApp(tester);
  });

  testWidgets('设置页可以上传同步快照到 WebDAV', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final syncService = _FakeSyncService();
    addTearDown(syncService.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          syncServiceProvider.overrideWithValue(syncService),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('网络').last);
    await _pumpUi(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 服务器地址'),
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 用户名'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 密码'),
      'demo-password',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '同步加密口令'),
      'secret-passphrase',
    );
    await tester.ensureVisible(find.text('上传同步'));
    await tester.tap(find.text('上传同步'));
    await _pumpUi(tester);

    expect(find.text('同步快照已上传到 WebDAV'), findsOneWidget);
    expect(syncService.uploadCalls, 1);
    expect(
      syncService.lastConfig?.baseUrl,
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    expect(syncService.lastConfig?.username, 'demo-user');
    expect(syncService.lastConfig?.password, 'demo-password');
    expect(syncService.lastPassphrase, 'secret-passphrase');

    await _disposeApp(tester);
  });

  testWidgets('设置页可以从 WebDAV 下载同步快照', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final syncService = _FakeSyncService(downloadResult: true);
    addTearDown(syncService.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          syncServiceProvider.overrideWithValue(syncService),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('设置'));
    await _pumpUi(tester);
    await tester.tap(find.text('网络').last);
    await _pumpUi(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 服务器地址'),
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 用户名'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WebDAV 密码'),
      'demo-password',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '同步加密口令'),
      'secret-passphrase',
    );
    await tester.ensureVisible(find.text('下载同步'));
    await tester.tap(find.text('下载同步'));
    await _pumpUi(tester);

    expect(find.text('已从 WebDAV 下载并导入同步快照'), findsOneWidget);
    expect(syncService.downloadCalls, 1);
    expect(
      syncService.lastConfig?.baseUrl,
      'https://dav.example.com/remote.php/dav/files/demo/',
    );
    expect(syncService.lastPassphrase, 'secret-passphrase');

    await _disposeApp(tester);
  });

  testWidgets('导航中包含 NAT 隧道打洞工具并可进入页面', (tester) async {
    await _setDesktopSize(tester);
    await _pumpApp(tester);

    expect(find.text('网络'), findsOneWidget);
    expect(find.text('NAT隧道打洞'), findsWidgets);

    await tester.tap(find.text('NAT隧道打洞').first);
    await _pumpUi(tester);

    expect(find.text('NAT 类型检测'), findsOneWidget);
    expect(find.text('添加打洞转发'), findsOneWidget);
    expect(find.text('打洞列表'), findsOneWidget);
    expect(find.text('连通性测试'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('nat traversal start button shows feedback', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = NatTraversalRepository(database);
    final now = DateTime.utc(2026, 5, 15);
    await repository.saveRules([
      NatTunnelRule(
        id: 'tcp-without-peer',
        protocol: NatTunnelProtocol.tcp,
        targetAddress: '127.0.0.1',
        targetPort: 9,
        label: 'TCP 无远端',
        enabled: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    expect((await repository.loadRules()).single.label, 'TCP 无远端');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: NatTraversalTool(),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('TCP 无远端'));

    expect(find.text('打洞列表'), findsOneWidget);
    expect(find.text('TCP 无远端'), findsOneWidget);
    expect(find.text('已保存'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '启动').first);
    await _pumpUntilFound(tester, find.textContaining('当前运行环境没有加载原生 TCP 映射模块'));

    expect(find.text('受限'), findsOneWidget);
    expect(find.textContaining('当前运行环境没有加载原生 TCP 映射模块'), findsWidgets);

    await _disposeApp(tester);
  });

  testWidgets('nat traversal save only button persists rule without starting', (
    tester,
  ) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = _RecordingNatTraversalService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: NatTraversalTool(service: service),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('添加打洞转发'));

    await tester.enterText(find.widgetWithText(TextField, '名称'), '仅保存规则');
    await tester.enterText(find.widgetWithText(TextField, '本地端口'), '8080');
    final saveButton = find.widgetWithText(OutlinedButton, '保存');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await _pumpUi(tester);
    await _pumpUntilFound(tester, find.text('仅保存规则'));

    final repository = NatTraversalRepository(database);
    final rules = await repository.loadRules();
    expect(rules, hasLength(1));
    expect(rules.single.label, '仅保存规则');
    expect(rules.single.enabled, isFalse);
    expect(service.startTunnelCalls, 0);
    expect(find.text('已保存'), findsOneWidget);
    expect(find.text('运行中'), findsNothing);

    await _disposeApp(tester);
  });

  testWidgets('nat traversal auto start toggle only updates saved state', (
    tester,
  ) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = NatTraversalRepository(database);
    final service = _RecordingNatTraversalService();
    addTearDown(service.dispose);
    final now = DateTime.utc(2026, 5, 15);
    await repository.saveRules([
      NatTunnelRule(
        id: 'auto-start-rule',
        protocol: NatTunnelProtocol.tcp,
        targetAddress: '127.0.0.1',
        targetPort: 9,
        label: '自动打洞规则',
        enabled: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: NatTraversalTool(service: service),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('自动打洞规则'));

    expect(find.widgetWithText(OutlinedButton, '自动打洞：关'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '自动打洞：关'));
    await _pumpUntilFound(
      tester,
      find.widgetWithText(OutlinedButton, '自动打洞：开'),
    );

    final updatedRules = await repository.loadRules();
    expect(updatedRules.single.enabled, isTrue);
    expect(service.startTunnelCalls, 0);

    await _disposeApp(tester);
  });

  testWidgets('NAT 页面慢速地址和端口加载不会阻塞规则列表', (tester) async {
    await _setDesktopSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = NatTraversalRepository(database);
    final service = _SlowNatTraversalService();
    addTearDown(service.dispose);
    final now = DateTime.utc(2026, 5, 15);
    await repository.saveRules([
      NatTunnelRule(
        id: 'async-load-rule',
        protocol: NatTunnelProtocol.tcp,
        targetAddress: '127.0.0.1',
        targetPort: 8080,
        label: '异步加载规则',
        enabled: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: NatTraversalTool(service: service),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('异步加载规则'));

    expect(find.text('NAT 类型检测'), findsOneWidget);
    expect(find.text('异步加载规则'), findsOneWidget);
    expect(service.addressesCompleted, isFalse);

    service.completeAddresses();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(service.portsRequested, isTrue);

    await _disposeApp(tester);
  });

  testWidgets('Steam 登录处理中会禁用登录入口并显示进度', (tester) async {
    await _setDesktopSize(tester);
    final controller = _FakeSteamStatusController(
      state: const SteamToolState(
        backendPhase: SteamBackendPhase.ready,
        remoteState: SteamRemoteState.empty,
        savedAccounts: <SteamAccount>[SteamAccount(username: 'saved_user')],
        loginInProgress: true,
        loginMessage: '正在向 Steam 提交登录请求...',
      ),
    );
    addTearDown(controller.dispose);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          steamStatusControllerProvider.overrideWithValue(controller),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await _tapToolNav(tester, 'Steam 状态');

    expect(find.text('正在向 Steam 提交登录请求...'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final loginButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '正在登录...'),
    );
    expect(loginButton.onPressed, isNull);
    final savedLoginButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '免密登录'),
    );
    expect(savedLoginButton.onPressed, isNull);

    await _disposeApp(tester);
  });

  testWidgets('Steam 运行期错误会显示在页面横幅', (tester) async {
    await _setDesktopSize(tester);
    final controller = _FakeSteamStatusController(
      state: const SteamToolState(
        backendPhase: SteamBackendPhase.ready,
        backendError: '连接 Steam CM 服务器失败：测试错误',
        remoteState: SteamRemoteState.empty,
        savedAccounts: <SteamAccount>[],
      ),
    );
    addTearDown(controller.dispose);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          steamStatusControllerProvider.overrideWithValue(controller),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await _tapToolNav(tester, 'Steam 状态');

    expect(find.text('Steam 操作失败'), findsOneWidget);
    expect(find.text('连接 Steam CM 服务器失败：测试错误'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('Steam 状态提示会用最新一次结果覆盖旧提示', (tester) async {
    await _setDesktopSize(tester);
    final controller = _FakeSteamStatusController(
      state: const SteamToolState(
        backendPhase: SteamBackendPhase.ready,
        remoteState: SteamRemoteState(
          loggedIn: true,
          username: 'tester',
          personaState: 1,
          personaStateName: 'Online',
          personaStateFlags: 0,
        ),
        savedAccounts: <SteamAccount>[],
      ),
    );
    addTearDown(controller.dispose);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          steamStatusControllerProvider.overrideWithValue(controller),
          sinaForexMarketServiceProvider.overrideWithValue(
            _FakeSinaForexMarketService(),
          ),
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await _tapToolNav(tester, 'Steam 状态');

    final awayChip = find.widgetWithText(ChoiceChip, '离开');
    final busyChip = find.widgetWithText(ChoiceChip, '忙碌');
    await tester.ensureVisible(awayChip);
    await tester.tap(awayChip);
    await tester.pump();
    expect(find.text('副状态已切换为离开'), findsOneWidget);

    await tester.ensureVisible(busyChip);
    await tester.tap(busyChip);
    await tester.pump();

    expect(find.text('副状态已切换为离开'), findsNothing);
    expect(find.text('副状态已切换为忙碌'), findsOneWidget);

    await _disposeApp(tester);
  });
}

Future<AppDatabase> _pumpApp(
  WidgetTester tester, {
  AppDatabase? database,
  SinaForexMarketService? exchangeService,
}) async {
  final resolvedDatabase = database ?? AppDatabase(NativeDatabase.memory());
  if (database == null) {
    addTearDown(resolvedDatabase.close);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(resolvedDatabase),
        sinaForexMarketServiceProvider.overrideWithValue(
          exchangeService ?? _FakeSinaForexMarketService(),
        ),
      ],
      child: const PersonalToolboxApp(),
    ),
  );
  await _pumpUi(tester);
  return resolvedDatabase;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final step = const Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(step);
    });
    elapsed += step;
  }
  await tester.pump();
}

Future<void> _tapToolNav(WidgetTester tester, String label) async {
  final navList = find.byType(ListView).first;
  final item = find.text(label);
  if (item.evaluate().isEmpty) {
    for (final offset in [const Offset(0, -160), const Offset(0, 160)]) {
      for (var i = 0; i < 12 && item.evaluate().isEmpty; i++) {
        await tester.drag(navList, offset);
        await _pumpUi(tester);
      }
      if (item.evaluate().isNotEmpty) {
        break;
      }
    }
  } else {
    await tester.ensureVisible(item.first);
  }
  expect(item, findsWidgets);
  await tester.ensureVisible(item.first);
  await _pumpUi(tester);
  await tester.tap(item.first);
  await _pumpUi(tester);
  await tester.pump(deferredNavigationDelay);
  await tester.pump();
  await tester.pump(deferredToolContentDelay);
  await tester.pump();
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _setDesktopSize(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _setMobileSize(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeSteamStatusController extends SteamStatusController {
  _FakeSteamStatusController._(this._database, this._state)
    : super(repository: SteamStatusRepository(_database));

  factory _FakeSteamStatusController({SteamToolState? state}) {
    final database = AppDatabase(NativeDatabase.memory());
    return _FakeSteamStatusController._(
      database,
      state ??
          const SteamToolState(
            backendPhase: SteamBackendPhase.ready,
            remoteState: SteamRemoteState.empty,
            savedAccounts: <SteamAccount>[],
          ),
    );
  }

  final AppDatabase _database;
  final SteamToolState _state;

  @override
  Stream<SteamToolState> get stream => Stream.value(_state);

  @override
  void start() {}

  @override
  Future<SteamActionResult> setPersonaState(int state) async {
    final label = switch (state) {
      1 => '在线',
      2 => '忙碌',
      3 => '离开',
      4 => '打盹',
      5 => '找交易',
      6 => '找伙伴',
      7 => '隐身',
      _ => '未知',
    };
    return SteamActionResult(success: true, message: '副状态已切换为$label');
  }

  @override
  Future<void> dispose() async {
    await _database.close();
  }
}

class _FakeSinaForexMarketService extends SinaForexMarketService {
  _FakeSinaForexMarketService({
    List<Map<String, double>> latestUsdLegsResponses = const [],
    List<Object> latestUsdLegsSequence = const [],
  }) : _latestUsdLegsResponses = latestUsdLegsResponses,
       _latestUsdLegsSequence = latestUsdLegsSequence,
       super(client: _NeverUsedHttpClient());

  final List<Map<String, double>> _latestUsdLegsResponses;
  final List<Object> _latestUsdLegsSequence;
  int _latestUsdLegIndex = 0;

  @override
  Future<ExchangeRateSeries> fetchSeries({
    required String fromCode,
    required String toCode,
    required ExchangeTimeRange range,
  }) async {
    final now = DateTime(2026, 5, 16, 10);
    final rates = switch (toCode) {
      'EUR' => (0.13, 0.12),
      'JPY' => (20.0, 21.0),
      _ => (0.14, 0.15),
    };
    final points = [
      ExchangeRatePoint(
        time: now.subtract(const Duration(hours: 1)),
        rate: rates.$1,
      ),
      ExchangeRatePoint(time: now, rate: rates.$2),
    ];
    return ExchangeRateSeries(
      fromCode: fromCode,
      toCode: toCode,
      points: points,
      latestRate: points.last.rate,
      source: SinaForexMarketService.sourceName,
    );
  }

  @override
  Future<Map<String, double>> fetchLatestUsdLegs(
    Set<String> currencyCodes,
  ) async {
    if (_latestUsdLegsSequence.isNotEmpty) {
      final index =
          _latestUsdLegIndex.clamp(0, _latestUsdLegsSequence.length - 1) as int;
      final next = _latestUsdLegsSequence[index];
      _latestUsdLegIndex++;
      if (next is Map<String, double>) {
        return next;
      }
      if (next is SinaForexMarketException) {
        throw next;
      }
      if (next is Exception) {
        throw next;
      }
      if (next is Error) {
        throw next;
      }
      throw StateError('unsupported fake latest legs payload: $next');
    }
    if (_latestUsdLegsResponses.isNotEmpty) {
      final index =
          _latestUsdLegIndex.clamp(0, _latestUsdLegsResponses.length - 1)
              as int;
      _latestUsdLegIndex++;
      return _latestUsdLegsResponses[index];
    }
    return const {
      'USD': 1,
      'CNY': 0.14,
      'EUR': 1.16,
      'JPY': 0.006875,
      'GBP': 1.27,
      'HKD': 0.128,
    };
  }
}

class _NeverUsedHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream<Uint8List>.empty(), 500);
  }
}

class _SlowNatTraversalService extends NatTraversalService {
  final Completer<List<NatLocalAddress>> _addressesCompleter =
      Completer<List<NatLocalAddress>>();

  bool portsRequested = false;
  bool get addressesCompleted => _addressesCompleter.isCompleted;

  void completeAddresses() {
    if (_addressesCompleter.isCompleted) {
      return;
    }
    _addressesCompleter.complete(const [
      NatLocalAddress(address: '127.0.0.1', label: '127.0.0.1 · 本机回环'),
      NatLocalAddress(address: '192.168.1.10', label: '192.168.1.10 · 测试网卡'),
    ]);
  }

  @override
  Future<List<NatLocalAddress>> listLocalAddresses() {
    return _addressesCompleter.future;
  }

  @override
  Future<List<NatPortCandidate>> listOpenPorts() async {
    portsRequested = true;
    return const <NatPortCandidate>[];
  }
}

class _RecordingNatTraversalService extends NatTraversalService {
  int startTunnelCalls = 0;

  @override
  Future<NatTunnelSnapshot> startTunnel(
    NatTunnelRule rule,
    NatTraversalConfig config,
  ) async {
    startTunnelCalls++;
    return NatTunnelSnapshot(
      ruleId: rule.id,
      protocol: rule.protocol,
      status: NatTunnelStatus.active,
      message: 'recorded start',
      publicIp: '203.0.113.10',
      publicPort: 12345,
    );
  }
}

class _FakeWebDavClient extends WebDavClient {
  _FakeWebDavClient({required this.result});

  final bool result;
  WebDavConfig? lastConfig;

  @override
  Future<bool> testConnection(WebDavConfig config) async {
    lastConfig = config;
    return result;
  }

  @override
  void close() {}
}

class _FakeSyncService extends SyncService {
  _FakeSyncService._(this._database, {this.downloadResult = false})
    : super(database: _database, webDavClient: _FakeWebDavClient(result: true));

  factory _FakeSyncService({bool downloadResult = false}) {
    return _FakeSyncService._(
      AppDatabase(NativeDatabase.memory()),
      downloadResult: downloadResult,
    );
  }

  final AppDatabase _database;
  final bool downloadResult;
  int uploadCalls = 0;
  int downloadCalls = 0;
  WebDavConfig? lastConfig;
  String? lastPassphrase;

  @override
  Future<void> uploadEncryptedSnapshot({
    required WebDavConfig config,
    required String passphrase,
  }) async {
    uploadCalls++;
    lastConfig = config;
    lastPassphrase = passphrase;
  }

  @override
  Future<bool> downloadEncryptedSnapshot({
    required WebDavConfig config,
    required String passphrase,
  }) async {
    downloadCalls++;
    lastConfig = config;
    lastPassphrase = passphrase;
    return downloadResult;
  }

  Future<void> close() async {
    await _database.close();
  }
}
