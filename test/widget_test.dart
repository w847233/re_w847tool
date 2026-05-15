import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_toolbox/main.dart';
import 'package:personal_toolbox/src/data/app_database.dart';
import 'package:personal_toolbox/src/data/database_provider.dart';
import 'package:personal_toolbox/src/home/home_layout_repository.dart';
import 'package:personal_toolbox/src/settings/settings_repository.dart';
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
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Steam 状态'), findsWidgets);

    await tester.tap(find.text('Steam 状态').first);
    await _pumpUi(tester);

    expect(find.text('连接与账号'), findsOneWidget);
    expect(find.text('Steam 侧车服务已就绪'), findsOneWidget);
    expect(find.text('当前未登录 Steam'), findsOneWidget);

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
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Steam 状态').first);
    await _pumpUi(tester);

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
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Steam 状态').first);
    await _pumpUi(tester);

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
        ],
        child: const PersonalToolboxApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Steam 状态').first);
    await _pumpUi(tester);

    await tester.tap(find.text('离开').first);
    await tester.pump();
    expect(find.text('副状态已切换为离开'), findsOneWidget);

    await tester.tap(find.text('忙碌').first);
    await tester.pump();

    expect(find.text('副状态已切换为离开'), findsNothing);
    expect(find.text('副状态已切换为忙碌'), findsOneWidget);

    await _disposeApp(tester);
  });
}

Future<AppDatabase> _pumpApp(WidgetTester tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const PersonalToolboxApp(),
    ),
  );
  await _pumpUi(tester);
  return database;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
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
      0 => '离线',
      1 => '在线',
      2 => '忙碌',
      3 => '离开',
      4 => '打盹',
      5 => '想交易',
      6 => '想玩游戏',
      _ => '未知',
    };
    return SteamActionResult(success: true, message: '副状态已切换为$label');
  }

  @override
  Future<void> dispose() async {
    await _database.close();
  }
}
