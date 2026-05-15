import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../home/home_layout_repository.dart';
import '../theme/app_theme.dart';

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

    return SafeArea(
      child: Column(
        children: [
          _HomeTopBar(
            editing: _editing,
            onToggleEdit: () => setState(() => _editing = !_editing),
            onReset: _editing
                ? () => ref.read(homeLayoutRepositoryProvider).resetLayout()
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
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.editing,
    required this.onToggleEdit,
    required this.onReset,
  });

  final bool editing;
  final VoidCallback onToggleEdit;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
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
          if (onReset != null) ...[
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('重置布局'),
            ),
            const SizedBox(width: 10),
          ],
          FilledButton.icon(
            onPressed: onToggleEdit,
            icon: Icon(editing ? Icons.check : Icons.edit_outlined),
            label: Text(editing ? '完成编辑' : '编辑主页'),
          ),
        ],
      ),
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
                onPressed: () => context.go('/tools/todos'),
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('添加待办'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/tools/notes'),
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('写便签'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/settings/about'),
                icon: const Icon(Icons.cloud_sync_outlined),
                label: const Text('查看同步说明'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/tools/steamStatus'),
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
}

class _DesktopHomeWidgetTile extends StatelessWidget {
  const _DesktopHomeWidgetTile({
    required this.item,
    required this.editing,
    required this.onAccept,
    required this.onResize,
  });

  final HomeWidgetLayoutItem item;
  final bool editing;
  final ValueChanged<String> onAccept;
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
      onResize: onResize,
      child: _WidgetBody(
        widgetId: item.widgetId,
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
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onResize,
  });

  final HomeWidgetLayoutItem item;
  final bool editing;
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
      child: _WidgetBody(widgetId: item.widgetId, compact: false),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: fullWidth ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ?mobileControls,
                  if (editing && allowedSizes.isNotEmpty)
                    PopupMenuButton<HomeWidgetSize>(
                      tooltip: '调整大小',
                      icon: const Icon(Icons.aspect_ratio_outlined),
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
                    const Icon(Icons.drag_indicator, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              if (fullWidth) child else Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetBody extends ConsumerWidget {
  const _WidgetBody({required this.widgetId, required this.compact});

  final String widgetId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);
    return switch (widgetId) {
      'todayTodos' => _TodayTodosWidget(database: database, compact: compact),
      'recentNotes' => _RecentNotesWidget(database: database, compact: compact),
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
      onPressed: () => context.go(route),
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
