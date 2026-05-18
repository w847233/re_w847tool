import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../exchange_rate/exchange_home_widget_repository.dart';
import '../exchange_rate/sina_forex_market_service.dart';
import '../home/home_layout_repository.dart';
import '../theme/app_theme.dart';
import '../ui/deferred_navigation.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(homeWidgetLayoutProvider);
    final layoutItems = layout.when(
      data: (items) => items,
      loading: () => const <HomeWidgetLayoutItem>[],
      error: (_, _) => const <HomeWidgetLayoutItem>[],
    );
    final hiddenItems = layoutItems.where((item) => !item.visible).toList();

    return SafeArea(
      child: Column(
        children: [
          _HomeTopBar(
            editing: _editing,
            onToggleEdit: () => setState(() => _editing = !_editing),
            onReset: _editing
                ? () => ref.read(homeLayoutRepositoryProvider).resetLayout()
                : null,
            hiddenItems: hiddenItems,
            onRestoreHidden: _editing && layoutItems.isNotEmpty
                ? (widgetId) => ref
                      .read(homeLayoutRepositoryProvider)
                      .saveLayout(
                        _setWidgetVisibility(layoutItems, widgetId, true),
                      )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _WelcomePanel(),
                  const SizedBox(height: 16),
                  layout.when(
                    data: (items) => _HomeWidgetBoard(
                      layout: items,
                      editing: _editing,
                      onLayoutChanged: (next) => ref
                          .read(homeLayoutRepositoryProvider)
                          .saveLayout(next),
                    ),
                    loading: () => const _BoardLoading(),
                    error: (error, stackTrace) => _HomeWidgetBoard(
                      layout: ref
                          .read(homeLayoutRepositoryProvider)
                          .defaultLayout,
                      editing: _editing,
                      onLayoutChanged: (next) => ref
                          .read(homeLayoutRepositoryProvider)
                          .saveLayout(next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<HomeWidgetLayoutItem> _setWidgetVisibility(
    List<HomeWidgetLayoutItem> source,
    String widgetId,
    bool visible,
  ) {
    return [
      for (final item in source)
        if (item.widgetId == widgetId)
          item.copyWith(visible: visible)
        else
          item,
    ];
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.editing,
    required this.onToggleEdit,
    required this.onReset,
    required this.hiddenItems,
    required this.onRestoreHidden,
  });

  final bool editing;
  final VoidCallback onToggleEdit;
  final VoidCallback? onReset;
  final List<HomeWidgetLayoutItem> hiddenItems;
  final ValueChanged<String>? onRestoreHidden;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (onReset != null) ...[
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('重置布局'),
        ),
        const SizedBox(width: 10),
      ],
      if (editing) ...[
        _HiddenWidgetsMenu(
          hiddenItems: hiddenItems,
          onRestore: onRestoreHidden,
        ),
        const SizedBox(width: 10),
      ],
      FilledButton.icon(
        onPressed: onToggleEdit,
        icon: Icon(editing ? Icons.check : Icons.edit_outlined),
        label: Text(editing ? '完成编辑' : '编辑主页'),
      ),
    ];

    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('主页', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenWidgetsMenu extends StatelessWidget {
  const _HiddenWidgetsMenu({
    required this.hiddenItems,
    required this.onRestore,
  });

  final List<HomeWidgetLayoutItem> hiddenItems;
  final ValueChanged<String>? onRestore;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: hiddenItems.isEmpty
          ? [
              const MenuItemButton(
                onPressed: null,
                leadingIcon: Icon(Icons.visibility_outlined),
                child: Text('暂无隐藏组件'),
              ),
            ]
          : [
              for (final item in hiddenItems)
                MenuItemButton(
                  onPressed: onRestore == null
                      ? null
                      : () => onRestore!(item.widgetId),
                  leadingIcon: Icon(dashboardWidgetById(item.widgetId).icon),
                  child: Text('恢复 ${dashboardWidgetById(item.widgetId).title}'),
                ),
            ],
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.visibility_off_outlined),
          label: Text(
            hiddenItems.isEmpty ? '已隐藏组件' : '已隐藏组件 (${hiddenItems.length})',
          ),
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(now);
    return _DashboardCard(
      title: '欢迎回来',
      icon: Icons.waving_hand_outlined,
      size: HomeWidgetSize.banner,
      editing: false,
      fullWidth: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今天适合把零散事项整理到一个地方。',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(dateText, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => goAfterTapFeedback(context, '/tools/todos'),
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('添加待办'),
              ),
              OutlinedButton.icon(
                onPressed: () => goAfterTapFeedback(context, '/tools/notes'),
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('写便签'),
              ),
              OutlinedButton.icon(
                onPressed: () => goAfterTapFeedback(context, '/settings/about'),
                icon: const Icon(Icons.cloud_sync_outlined),
                label: const Text('查看同步说明'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    goAfterTapFeedback(context, '/tools/steamStatus'),
                icon: const Icon(Icons.sports_esports_outlined),
                label: const Text('Steam 状态'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeWidgetBoard extends ConsumerWidget {
  const _HomeWidgetBoard({
    required this.layout,
    required this.editing,
    required this.onLayoutChanged,
  });

  final List<HomeWidgetLayoutItem> layout;
  final bool editing;
  final ValueChanged<List<HomeWidgetLayoutItem>> onLayoutChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleItems = layout.where((item) => item.visible).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              for (var index = 0; index < visibleItems.length; index++) ...[
                _MobileHomeWidgetTile(
                  item: visibleItems[index],
                  editing: editing,
                  onHide: () => onLayoutChanged(
                    _setVisibility(
                      layout,
                      visibleItems[index].widgetId,
                      visible: false,
                    ),
                  ),
                  onMoveUp: index == 0
                      ? null
                      : () => onLayoutChanged(
                          _move(
                            layout,
                            visibleItems[index].widgetId,
                            index - 1,
                          ),
                        ),
                  onMoveDown: index == visibleItems.length - 1
                      ? null
                      : () => onLayoutChanged(
                          _move(
                            layout,
                            visibleItems[index].widgetId,
                            index + 1,
                          ),
                        ),
                  onResize: (size) => onLayoutChanged(
                    _resize(layout, visibleItems[index].widgetId, size),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var index = 0; index < visibleItems.length; index++)
              _DesktopHomeWidgetTile(
                item: visibleItems[index],
                editing: editing,
                onAccept: (draggedId) =>
                    onLayoutChanged(_move(layout, draggedId, index)),
                onHide: () => onLayoutChanged(
                  _setVisibility(
                    layout,
                    visibleItems[index].widgetId,
                    visible: false,
                  ),
                ),
                onResize: (size) => onLayoutChanged(
                  _resize(layout, visibleItems[index].widgetId, size),
                ),
              ),
          ],
        );
      },
    );
  }

  List<HomeWidgetLayoutItem> _move(
    List<HomeWidgetLayoutItem> source,
    String widgetId,
    int targetIndex,
  ) {
    final ordered = [...source]..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = ordered.indexWhere(
      (item) => item.widgetId == widgetId,
    );
    if (currentIndex < 0) {
      return source;
    }
    final item = ordered.removeAt(currentIndex);
    ordered.insert(targetIndex.clamp(0, ordered.length), item);
    return [
      for (var index = 0; index < ordered.length; index++)
        ordered[index].copyWith(order: index),
    ];
  }

  List<HomeWidgetLayoutItem> _resize(
    List<HomeWidgetLayoutItem> source,
    String widgetId,
    HomeWidgetSize size,
  ) {
    return [
      for (final item in source)
        if (item.widgetId == widgetId) item.copyWith(size: size) else item,
    ];
  }

  List<HomeWidgetLayoutItem> _setVisibility(
    List<HomeWidgetLayoutItem> source,
    String widgetId, {
    required bool visible,
  }) {
    return [
      for (final item in source)
        if (item.widgetId == widgetId)
          item.copyWith(visible: visible)
        else
          item,
    ];
  }
}

class _DesktopHomeWidgetTile extends StatelessWidget {
  const _DesktopHomeWidgetTile({
    required this.item,
    required this.editing,
    required this.onAccept,
    required this.onHide,
    required this.onResize,
  });

  final HomeWidgetLayoutItem item;
  final bool editing;
  final ValueChanged<String> onAccept;
  final VoidCallback onHide;
  final ValueChanged<HomeWidgetSize> onResize;

  @override
  Widget build(BuildContext context) {
    final definition = dashboardWidgetById(item.widgetId);
    final card = _DashboardCard(
      title: definition.title,
      icon: definition.icon,
      size: item.size,
      editing: editing,
      allowedSizes: definition.allowedSizes,
      onHide: onHide,
      onResize: onResize,
      child: _WidgetBody(
        widgetId: item.widgetId,
        size: item.size,
        compact: item.size == HomeWidgetSize.small,
      ),
    );

    if (!editing) {
      return card;
    }

    return Draggable<String>(
      key: ValueKey('home-widget-drag-${item.widgetId}'),
      data: item.widgetId,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.88, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: DragTarget<String>(
        key: ValueKey('home-widget-drop-${item.widgetId}'),
        onAcceptWithDetails: (details) => onAccept(details.data),
        builder: (context, candidateData, rejectedData) {
          final highlighted = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: card,
          );
        },
      ),
    );
  }
}

class _MobileHomeWidgetTile extends StatelessWidget {
  const _MobileHomeWidgetTile({
    required this.item,
    required this.editing,
    required this.onHide,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onResize,
  });

  final HomeWidgetLayoutItem item;
  final bool editing;
  final VoidCallback onHide;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final ValueChanged<HomeWidgetSize> onResize;

  @override
  Widget build(BuildContext context) {
    final definition = dashboardWidgetById(item.widgetId);
    return _DashboardCard(
      title: definition.title,
      icon: definition.icon,
      size: item.size,
      fullWidth: true,
      editing: editing,
      allowedSizes: definition.allowedSizes,
      onHide: onHide,
      onResize: onResize,
      mobileControls: editing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '上移',
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: '下移',
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            )
          : null,
      child: _WidgetBody(
        widgetId: item.widgetId,
        size: item.size,
        compact: false,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.size,
    required this.editing,
    required this.child,
    this.allowedSizes = const [],
    this.onHide,
    this.onResize,
    this.mobileControls,
    this.fullWidth = false,
  });

  final String title;
  final IconData icon;
  final HomeWidgetSize size;
  final bool editing;
  final Widget child;
  final List<HomeWidgetSize> allowedSizes;
  final VoidCallback? onHide;
  final ValueChanged<HomeWidgetSize>? onResize;
  final Widget? mobileControls;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final width = fullWidth
        ? double.infinity
        : 160.0 * size.columns + 16.0 * (size.columns - 1);
    final height = 170.0 * size.rows + 16.0 * (size.rows - 1);
    return SizedBox(
      width: width,
      height: fullWidth ? null : height,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeader = constraints.maxWidth < 180;
              final actionConstraints = BoxConstraints.tightFor(
                width: compactHeader ? 24 : 40,
                height: compactHeader ? 24 : 40,
              );
              final compactPadding = EdgeInsets.zero;
              final headerActions = [
                if (mobileControls != null) mobileControls!,
                if (editing && onHide != null)
                  IconButton(
                    tooltip: '隐藏小组件',
                    onPressed: onHide,
                    padding: compactPadding,
                    constraints: actionConstraints,
                    visualDensity: VisualDensity.compact,
                    iconSize: compactHeader ? 16 : 20,
                    icon: const Icon(Icons.visibility_off_outlined),
                  ),
                if (editing && allowedSizes.isNotEmpty)
                  PopupMenuButton<HomeWidgetSize>(
                    tooltip: '调整大小',
                    padding: compactPadding,
                    constraints: actionConstraints,
                    icon: Icon(
                      Icons.aspect_ratio_outlined,
                      size: compactHeader ? 16 : 20,
                    ),
                    onSelected: onResize,
                    itemBuilder: (context) => [
                      for (final option in allowedSizes)
                        PopupMenuItem(
                          value: option,
                          child: Text(
                            '${option.label} ${option == size ? '（当前）' : ''}',
                          ),
                        ),
                    ],
                  ),
                if (editing)
                  Padding(
                    padding: EdgeInsets.only(right: compactHeader ? 0 : 4),
                    child: Icon(
                      Icons.drag_indicator,
                      color: AppColors.muted,
                      size: compactHeader ? 16 : 20,
                    ),
                  ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: fullWidth ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: compactHeader ? 16 : 20,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: compactHeader ? 6 : 8),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: compactHeader
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...headerActions,
                    ],
                  ),
                  SizedBox(height: compactHeader ? 8 : 12),
                  if (fullWidth) child else Flexible(child: child),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WidgetBody extends ConsumerWidget {
  const _WidgetBody({
    required this.widgetId,
    required this.size,
    required this.compact,
  });

  final String widgetId;
  final HomeWidgetSize size;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);
    final exchangeWidgetConfigState = ref.watch(
      exchangeHomeWidgetConfigProvider,
    );
    return switch (widgetId) {
      'todayTodos' => _TodayTodosWidget(database: database, compact: compact),
      'recentNotes' => _RecentNotesWidget(database: database, compact: compact),
      'exchangeSnapshot' => exchangeWidgetConfigState.when(
        data: (config) => _ExchangeSnapshotWidget(size: size, config: config),
        loading: () =>
            const Text('正在加载汇率配置...', style: TextStyle(color: AppColors.muted)),
        error: (_, _) => _ExchangeSnapshotWidget(
          size: size,
          config: const ExchangeHomeWidgetConfig(),
        ),
      ),
      'monthlyLedger' => _MonthlyLedgerWidget(database: database),
      'countdown' => _CountdownWidget(database: database, compact: compact),
      'pomodoro' => _PomodoroStatsWidget(database: database),
      'quickActions' => const _QuickActionsWidget(),
      _ => const Text('小组件不可用', style: TextStyle(color: AppColors.muted)),
    };
  }
}

class _TodayTodosWidget extends StatelessWidget {
  const _TodayTodosWidget({required this.database, required this.compact});

  final AppDatabase database;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
      stream: database.watchActiveTodos(),
      builder: (context, snapshot) {
        final todos = (snapshot.data ?? const <Todo>[])
            .where((todo) => !todo.completed)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BigNumber(value: '${todos.length}', label: '项未完成'),
            if (!compact) ...[
              const SizedBox(height: 10),
              for (final todo in todos.take(3))
                Text('• ${todo.title}', overflow: TextOverflow.ellipsis),
              if (todos.isEmpty)
                const Text('今天还没有待办', style: TextStyle(color: AppColors.muted)),
            ],
          ],
        );
      },
    );
  }
}

class _RecentNotesWidget extends StatelessWidget {
  const _RecentNotesWidget({required this.database, required this.compact});

  final AppDatabase database;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: database.watchActiveNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? const <Note>[];
        if (notes.isEmpty) {
          return const Text('暂无便签', style: TextStyle(color: AppColors.muted));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final note in notes.take(compact ? 1 : 3)) ...[
              Text(note.title, overflow: TextOverflow.ellipsis),
              if (!compact)
                Text(
                  note.content.isEmpty ? '无内容' : note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

enum _ExchangeTrend { up, down, flat }

class _ExchangeSnapshotWidget extends ConsumerStatefulWidget {
  const _ExchangeSnapshotWidget({required this.size, required this.config});

  final HomeWidgetSize size;
  final ExchangeHomeWidgetConfig config;

  @override
  ConsumerState<_ExchangeSnapshotWidget> createState() =>
      _ExchangeSnapshotWidgetState();
}

class _ExchangeSnapshotWidgetState
    extends ConsumerState<_ExchangeSnapshotWidget> {
  Timer? _timer;
  int _requestId = 0;
  Map<String, double> _ratesByCode = const {};
  Map<String, _ExchangeTrend> _trendsByCode = const {};
  DateTime? _lastUpdatedAt;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restartPolling();
  }

  @override
  void didUpdateWidget(covariant _ExchangeSnapshotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      setState(() {
        _ratesByCode = const {};
        _trendsByCode = const {};
        _lastUpdatedAt = null;
        _errorMessage = null;
        _loading = true;
      });
      _restartPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.size == HomeWidgetSize.wide;
    final maxTargets = widget.size == HomeWidgetSize.large ? 4 : 2;
    final visibleTargets = widget.config.targetCodes.take(maxTargets).toList();
    final hiddenCount =
        widget.config.targetCodes.length - visibleTargets.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${ExchangeHomeWidgetConfig.defaultAmount.toStringAsFixed(0)} ${widget.config.fromCode}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : null,
                  height: compact ? 1.05 : null,
                ),
              ),
            ),
            Text(
              '${widget.config.refreshSeconds}s',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: compact ? 11 : 12,
                height: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        if (_loading && _ratesByCode.isEmpty)
          Text(
            '正在获取汇率...',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: compact ? 11 : 12,
              height: 1,
            ),
          )
        else ...[
          for (final code in visibleTargets) ...[
            _ExchangeSnapshotRow(
              code: code,
              value: _ratesByCode[code],
              trend: _trendsByCode[code] ?? _ExchangeTrend.flat,
              compact: compact,
            ),
            SizedBox(height: compact ? 2 : 4),
          ],
          if (hiddenCount > 0)
            Text(
              '还有 $hiddenCount 个币种',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: compact ? 11 : 12,
                height: 1,
              ),
            ),
        ],
        SizedBox(height: compact ? 2 : 4),
        Text(
          _buildFooterText(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _errorMessage == null ? AppColors.muted : AppColors.bad,
            fontSize: compact ? 11 : 12,
            height: 1,
          ),
        ),
      ],
    );
  }

  void _restartPolling() {
    _timer?.cancel();
    _refreshRates(resetLoading: true);
    _timer = Timer.periodic(
      Duration(seconds: widget.config.refreshSeconds),
      (_) => _refreshRates(),
    );
  }

  Future<void> _refreshRates({bool resetLoading = false}) async {
    final requestId = ++_requestId;
    if (resetLoading && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final requiredCodes = {
        'USD',
        widget.config.fromCode,
        ...widget.config.targetCodes,
      };
      final legs = await ref
          .read(sinaForexMarketServiceProvider)
          .fetchLatestUsdLegs(requiredCodes);
      if (!mounted || requestId != _requestId) {
        return;
      }
      final fromLeg = legs[widget.config.fromCode];
      if (fromLeg == null || fromLeg <= 0) {
        throw const SinaForexMarketException('基准货币汇率缺失。');
      }

      final nextRates = <String, double>{};
      final nextTrends = <String, _ExchangeTrend>{};
      for (final code in widget.config.targetCodes) {
        final toLeg = legs[code];
        if (toLeg == null || toLeg <= 0) {
          throw SinaForexMarketException('$code 汇率缺失。');
        }
        final nextValue =
            ExchangeHomeWidgetConfig.defaultAmount * fromLeg / toLeg;
        nextRates[code] = nextValue;
        final previous = _ratesByCode[code];
        nextTrends[code] = _compareTrend(previous, nextValue);
      }

      setState(() {
        _ratesByCode = nextRates;
        _trendsByCode = nextTrends;
        _lastUpdatedAt = DateTime.now();
        _errorMessage = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _errorMessage = '更新失败，已保留上次结果';
        _loading = false;
      });
    }
  }

  _ExchangeTrend _compareTrend(double? previous, double next) {
    if (previous == null) {
      return _ExchangeTrend.flat;
    }
    const epsilon = 0.0000001;
    if ((next - previous).abs() <= epsilon) {
      return _ExchangeTrend.flat;
    }
    return next > previous ? _ExchangeTrend.up : _ExchangeTrend.down;
  }

  String _buildFooterText() {
    if (_errorMessage != null) {
      return _errorMessage!;
    }
    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) {
      return '${widget.config.refreshSeconds} 秒刷新';
    }
    return '${widget.config.refreshSeconds} 秒刷新 · ${DateFormat('HH:mm:ss').format(updatedAt)}';
  }
}

class _ExchangeSnapshotRow extends StatelessWidget {
  const _ExchangeSnapshotRow({
    required this.code,
    required this.value,
    required this.trend,
    required this.compact,
  });

  final String code;
  final double? value;
  final _ExchangeTrend trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final valueColor = switch (trend) {
      _ExchangeTrend.up => AppColors.bad,
      _ExchangeTrend.down => AppColors.good,
      _ExchangeTrend.flat => AppColors.muted,
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            code,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: compact ? 11 : null,
              height: compact ? 1 : null,
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Text(
          value == null ? '--' : value!.toStringAsFixed(4),
          key: ValueKey('exchange-snapshot-value-$code'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 11 : null,
            height: compact ? 1 : null,
          ),
        ),
      ],
    );
  }
}

class _MonthlyLedgerWidget extends StatelessWidget {
  const _MonthlyLedgerWidget({required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LedgerEntry>>(
      stream: database.watchActiveLedgerEntries(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final entries = (snapshot.data ?? const <LedgerEntry>[]).where((entry) {
          final local = entry.occurredAt.toLocal();
          return local.year == now.year && local.month == now.month;
        });
        final income = entries
            .where((entry) => entry.type == '收入')
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        final expense = entries
            .where((entry) => entry.type == '支出')
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        return Row(
          children: [
            Expanded(
              child: _MoneyMetric(
                label: '收入',
                value: income,
                color: AppColors.good,
              ),
            ),
            Expanded(
              child: _MoneyMetric(
                label: '支出',
                value: expense,
                color: AppColors.bad,
              ),
            ),
            Expanded(
              child: _MoneyMetric(
                label: '结余',
                value: income - expense,
                color: AppColors.fg,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountdownWidget extends StatelessWidget {
  const _CountdownWidget({required this.database, required this.compact});

  final AppDatabase database;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CountdownEvent>>(
      stream: database.watchActiveCountdownEvents(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <CountdownEvent>[];
        if (events.isEmpty) {
          return const Text('暂无倒数日', style: TextStyle(color: AppColors.muted));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final event in events.take(compact ? 1 : 3))
              Text(
                '${event.title} · ${_daysUntil(event.targetDate)}',
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      },
    );
  }

  String _daysUntil(DateTime targetDate) {
    final today = DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(targetDate.toLocal());
    final days = target.difference(today).inDays;
    if (days > 0) {
      return '$days 天';
    }
    if (days == 0) {
      return '今天';
    }
    return '已过 ${days.abs()} 天';
  }
}

class _PomodoroStatsWidget extends StatelessWidget {
  const _PomodoroStatsWidget({required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PomodoroSession>>(
      stream: database.watchPomodoroSessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <PomodoroSession>[];
        final totalMinutes = sessions.fold<int>(
          0,
          (sum, row) => sum + row.minutes,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BigNumber(value: '${sessions.length}', label: '次完成'),
            const SizedBox(height: 8),
            Text(
              '累计 $totalMinutes 分钟',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionsWidget extends StatelessWidget {
  const _QuickActionsWidget();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickAction(
          label: '待办',
          icon: Icons.checklist_outlined,
          route: '/tools/todos',
        ),
        _QuickAction(
          label: '便签',
          icon: Icons.sticky_note_2_outlined,
          route: '/tools/notes',
        ),
        _QuickAction(
          label: '记账',
          icon: Icons.account_balance_wallet_outlined,
          route: '/tools/ledger',
        ),
        _QuickAction(
          label: '番茄钟',
          icon: Icons.timer_outlined,
          route: '/tools/pomodoro',
        ),
        _QuickAction(
          label: 'Steam',
          icon: Icons.sports_esports_outlined,
          route: '/tools/steamStatus',
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => goAfterTapFeedback(context, route),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
      ],
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          '¥${value.toStringAsFixed(2)}',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _BoardLoading extends StatelessWidget {
  const _BoardLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('正在加载主页布局...', style: TextStyle(color: AppColors.muted)),
      ),
    );
  }
}
