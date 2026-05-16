import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../exchange_rate/sina_forex_market_service.dart';
import '../get_token/get_token_tool.dart';
import '../network/dns_leak_tool.dart';
import '../network/nat_traversal_tool.dart';
import '../phone_manager/phone_manager_tool.dart';
import '../steam_status/steam_status_tool.dart';
import '../system_control/system_control_tool.dart';
import '../theme/app_theme.dart';
import '../tools/tool_registry.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';

class ToolPage extends StatelessWidget {
  const ToolPage({super.key, required this.toolId});

  final String toolId;

  @override
  Widget build(BuildContext context) {
    final tool = toolById(toolId);
    return SafeArea(
      child: Column(
        children: [
          _ToolTopBar(tool: tool),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: switch (tool.id) {
                'notes' => const NotesTool(),
                'todos' => const TodosTool(),
                'ledger' => const LedgerTool(),
                'countdown' => const CountdownTool(),
                'converter' => const ConverterTool(),
                'exchangeRate' => const ExchangeRateTool(),
                'password' => const PasswordTool(),
                'getToken' => const GetTokenTool(),
                'pomodoro' => const PomodoroTool(),
                'dnsLeak' => const DnsLeakTool(),
                'natTraversal' => const NatTraversalTool(),
                'phoneManager' || 'bluetoothAudio' => const PhoneManagerTool(),
                'systemControl' => const SystemControlTool(),
                'steamStatus' => const SteamStatusTool(),
                _ => EmptyState(
                  icon: tool.icon,
                  title: '工具暂不可用',
                  message: '当前工具尚未实现，请从左侧选择其他工具。',
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTopBar extends StatelessWidget {
  const _ToolTopBar({required this.tool});

  final ToolDefinition tool;

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
          Icon(tool.icon, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tool.name, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  tool.description,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          _SyncPill(syncEnabled: tool.syncEnabled),
        ],
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.syncEnabled});

  final bool syncEnabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          syncEnabled ? '可同步' : '本地临时',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    );
  }
}

class NotesTool extends ConsumerStatefulWidget {
  const NotesTool({super.key});

  @override
  ConsumerState<NotesTool> createState() => _NotesToolState();
}

class _NotesToolState extends ConsumerState<NotesTool> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Note? _editingNote;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    final isEditing = _editingNote != null;
    return _ResponsiveGrid(
      left: AppPanel(
        title: isEditing ? '修改便签' : '新增便签',
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(labelText: '内容'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isEditing)
                    OutlinedButton.icon(
                      onPressed: _resetEditing,
                      icon: const Icon(Icons.close),
                      label: const Text('取消编辑'),
                    ),
                  FilledButton.icon(
                    onPressed: () => _saveNote(database),
                    icon: Icon(isEditing ? Icons.check : Icons.add),
                    label: Text(isEditing ? '更新便签' : '保存便签'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      right: StreamBuilder<List<Note>>(
        stream: database.watchActiveNotes(),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? const <Note>[];
          if (notes.isEmpty) {
            return const EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: '还没有便签',
              message: '添加第一条便签后，它会保存在本机并进入同步快照。',
            );
          }
          return Column(
            children: [
              for (final note in notes) ...[
                AppPanel(
                  title: note.title,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '编辑便签',
                        onPressed: () => _startEditing(note),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: '删除便签',
                        onPressed: () => database.deleteNote(note.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  child: Text(note.content.isEmpty ? '无内容' : note.content),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  void _startEditing(Note note) {
    setState(() {
      _editingNote = note;
      _titleController.text = note.title;
      _contentController.text = note.content;
    });
  }

  void _resetEditing() {
    setState(() {
      _editingNote = null;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _saveNote(AppDatabase database) async {
    final editingNote = _editingNote;
    if (editingNote == null) {
      await database.addNote(
        title: _titleController.text,
        content: _contentController.text,
      );
    } else {
      await database.updateNote(
        editingNote.id,
        title: _titleController.text,
        content: _contentController.text,
      );
    }
    _resetEditing();
  }
}

class TodosTool extends ConsumerStatefulWidget {
  const TodosTool({super.key});

  @override
  ConsumerState<TodosTool> createState() => _TodosToolState();
}

class _TodosToolState extends ConsumerState<TodosTool> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    return AppPanel(
      title: '待办事项',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: '待办内容'),
                  onSubmitted: (_) => _addTodo(database),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _addTodo(database),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Todo>>(
            stream: database.watchActiveTodos(),
            builder: (context, snapshot) {
              final todos = snapshot.data ?? const <Todo>[];
              if (todos.isEmpty) {
                return const EmptyState(
                  icon: Icons.checklist_outlined,
                  title: '暂无待办',
                  message: '输入事项后按添加即可创建。',
                );
              }
              return Column(
                children: [
                  for (final todo in todos)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: todo.completed,
                        onChanged: (_) => database.toggleTodo(todo),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: todo.completed
                              ? AppColors.muted
                              : AppColors.fg,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: '删除待办',
                        onPressed: () => database.deleteTodo(todo.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addTodo(AppDatabase database) async {
    await database.addTodo(_controller.text);
    _controller.clear();
  }
}

class LedgerTool extends ConsumerStatefulWidget {
  const LedgerTool({super.key});

  @override
  ConsumerState<LedgerTool> createState() => _LedgerToolState();
}

class _LedgerToolState extends ConsumerState<LedgerTool> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = '支出';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    return _ResponsiveGrid(
      left: AppPanel(
        title: '新增账目',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                SegmentedButton<String>(
                  selected: {_type},
                  segments: const [
                    ButtonSegment(value: '支出', label: Text('支出')),
                    ButtonSegment(value: '收入', label: Text('收入')),
                  ],
                  onSelectionChanged: (value) =>
                      setState(() => _type = value.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金额'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await database.addLedgerEntry(
                        type: _type,
                        amount: double.tryParse(_amountController.text) ?? 0,
                        note: _noteController.text,
                      );
                      _amountController.clear();
                      _noteController.clear();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('记一笔'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      right: StreamBuilder<List<LedgerEntry>>(
        stream: database.watchActiveLedgerEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <LedgerEntry>[];
          final income = entries
              .where((entry) => entry.type == '收入')
              .fold<double>(0, (sum, entry) => sum + entry.amount);
          final expense = entries
              .where((entry) => entry.type == '支出')
              .fold<double>(0, (sum, entry) => sum + entry.amount);
          return Column(
            children: [
              AppPanel(
                title: '本地汇总',
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: '收入',
                        value: '¥${income.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: '支出',
                        value: '¥${expense.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: '结余',
                        value: '¥${(income - expense).toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: '暂无账目',
                  message: '记录收入或支出后会在这里显示。',
                )
              else
                AppPanel(
                  title: '最近账目',
                  child: Column(
                    children: [
                      for (final entry in entries)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.note.isEmpty ? entry.type : entry.note,
                          ),
                          subtitle: Text(
                            DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(entry.occurredAt.toLocal()),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${entry.type == '支出' ? '-' : '+'}¥${entry.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: entry.type == '支出'
                                      ? AppColors.bad
                                      : AppColors.good,
                                ),
                              ),
                              IconButton(
                                tooltip: '删除账目',
                                onPressed: () =>
                                    database.deleteLedgerEntry(entry.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CountdownTool extends ConsumerStatefulWidget {
  const CountdownTool({super.key});

  @override
  ConsumerState<CountdownTool> createState() => _CountdownToolState();
}

class _CountdownToolState extends ConsumerState<CountdownTool> {
  final _titleController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    return _ResponsiveGrid(
      left: AppPanel(
        title: '新增倒数日',
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '事件名称'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _targetDate = picked);
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(DateFormat('yyyy-MM-dd').format(_targetDate)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  await database.addCountdownEvent(
                    title: _titleController.text,
                    targetDate: _targetDate,
                  );
                  _titleController.clear();
                },
                icon: const Icon(Icons.add),
                label: const Text('保存事件'),
              ),
            ),
          ],
        ),
      ),
      right: StreamBuilder<List<CountdownEvent>>(
        stream: database.watchActiveCountdownEvents(),
        builder: (context, snapshot) {
          final events = snapshot.data ?? const <CountdownEvent>[];
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icons.event_outlined,
              title: '暂无倒数日',
              message: '添加重要日期后会在这里显示剩余天数。',
            );
          }
          return Column(
            children: [
              for (final event in events) ...[
                AppPanel(
                  title: event.title,
                  trailing: IconButton(
                    tooltip: '删除事件',
                    onPressed: () => database.deleteCountdownEvent(event.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  child: Text(
                    '${DateFormat('yyyy-MM-dd').format(event.targetDate.toLocal())} · ${_daysUntil(event.targetDate)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  String _daysUntil(DateTime targetDate) {
    final today = DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(targetDate.toLocal());
    final days = target.difference(today).inDays;
    if (days > 0) {
      return '还有 $days 天';
    }
    if (days == 0) {
      return '就是今天';
    }
    return '已过去 ${days.abs()} 天';
  }
}

class ExchangeRateTool extends ConsumerStatefulWidget {
  const ExchangeRateTool({super.key});

  @override
  ConsumerState<ExchangeRateTool> createState() => _ExchangeRateToolState();
}

class _ExchangeRateToolState extends ConsumerState<ExchangeRateTool> {
  static const _panelBg = Color(0xFF07090D);
  static const _panelSurface = Color(0xFF10141C);
  static const _panelBorder = Color(0xFF263142);
  static const _panelText = Color(0xFFE8EEF7);
  static const _panelMuted = Color(0xFF92A0B4);
  static const _riseColor = Color(0xFFFF5A67);
  static const _fallColor = Color(0xFF24C46B);

  final _amountController = TextEditingController(text: '1');
  String _fromCode = 'CNY';
  final List<String> _targetCodes = ['USD'];
  ExchangeTimeRange _range = exchangeTimeRanges.first;
  final Map<String, Future<ExchangeRateSeries>> _seriesFutures = {};

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(_refreshAll);
      }
    });
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_onAmountChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _panelBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _panelBorder),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: _panelSurface,
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _panelText, onSurface: _panelText),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: _panelMuted),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _panelText),
              ),
            ),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: _panelText),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ExchangeHeader(
                  amountController: _amountController,
                  fromCode: _fromCode,
                  targetCodes: _targetCodes,
                  onFromChanged: _changeFromCode,
                  onSwap: _swapPrimaryTarget,
                  onAddTarget: _addTarget,
                  onTargetChanged: _changeTargetCode,
                  onRemoveTarget: _removeTarget,
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < _targetCodes.length; i++) ...[
                  _ExchangeChartCard(
                    key: ValueKey(
                      'exchange-chart-${_fromCode}_${_targetCodes[i]}',
                    ),
                    fromCode: _fromCode,
                    toCode: _targetCodes[i],
                    amount: amount,
                    seriesFuture: _seriesFutures[_targetCodes[i]],
                    showRangeSelector: i == 0,
                    selectedRange: _range,
                    onRangeChanged: _changeRange,
                    onRetry: () =>
                        setState(() => _refreshTarget(_targetCodes[i])),
                  ),
                  if (i != _targetCodes.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                const Text(
                  '数据源：新浪财经外汇。非官方接口仅供参考，以实际交易报价为准。',
                  style: TextStyle(color: _panelMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _changeFromCode(String code) {
    setState(() {
      _fromCode = code;
      _targetCodes.removeWhere((target) => target == code);
      if (_targetCodes.isEmpty) {
        _targetCodes.add(_firstAvailableTarget() ?? 'USD');
      }
      _refreshAll();
    });
  }

  void _changeTargetCode(int index, String code) {
    if (_targetCodes.contains(code) && _targetCodes[index] != code) {
      ScaffoldMessenger.of(
        context,
      ).showLatestSnackBar(const SnackBar(content: Text('该货币已添加')));
      return;
    }
    setState(() {
      _targetCodes[index] = code;
      _refreshTarget(code);
    });
  }

  void _addTarget() {
    final next = _firstAvailableTarget();
    if (next == null) {
      ScaffoldMessenger.of(
        context,
      ).showLatestSnackBar(const SnackBar(content: Text('没有更多可添加的货币')));
      return;
    }
    setState(() {
      _targetCodes.add(next);
      _refreshTarget(next);
    });
  }

  void _removeTarget(int index) {
    if (_targetCodes.length == 1) {
      ScaffoldMessenger.of(
        context,
      ).showLatestSnackBar(const SnackBar(content: Text('至少保留一种兑换货币')));
      return;
    }
    setState(() {
      final removed = _targetCodes.removeAt(index);
      _seriesFutures.remove(removed);
    });
  }

  void _swapPrimaryTarget() {
    final nextFrom = _targetCodes.first;
    setState(() {
      final previousFrom = _fromCode;
      _fromCode = nextFrom;
      _targetCodes[0] = previousFrom;
      final seen = <String>{};
      _targetCodes.removeWhere(
        (target) => !seen.add(target) || target == _fromCode,
      );
      if (_targetCodes.isEmpty) {
        _targetCodes.add(_firstAvailableTarget() ?? 'USD');
      }
      _refreshAll();
    });
  }

  void _changeRange(ExchangeTimeRange range) {
    setState(() {
      _range = range;
      _refreshAll();
    });
  }

  void _refreshAll() {
    for (final target in _targetCodes) {
      _seriesFutures[target] = _loadSeries(target);
    }
  }

  void _refreshTarget(String target) {
    _seriesFutures[target] = _loadSeries(target);
  }

  Future<ExchangeRateSeries> _loadSeries(String target) {
    return ref
        .read(sinaForexMarketServiceProvider)
        .fetchSeries(fromCode: _fromCode, toCode: target, range: _range);
  }

  String? _firstAvailableTarget() {
    for (final code in exchangeCurrencies.map((currency) => currency.code)) {
      if (code != _fromCode && !_targetCodes.contains(code)) {
        return code;
      }
    }
    return null;
  }
}

class _ExchangeHeader extends StatelessWidget {
  const _ExchangeHeader({
    required this.amountController,
    required this.fromCode,
    required this.targetCodes,
    required this.onFromChanged,
    required this.onSwap,
    required this.onAddTarget,
    required this.onTargetChanged,
    required this.onRemoveTarget,
  });

  final TextEditingController amountController;
  final String fromCode;
  final List<String> targetCodes;
  final ValueChanged<String> onFromChanged;
  final VoidCallback onSwap;
  final VoidCallback onAddTarget;
  final void Function(int index, String code) onTargetChanged;
  final ValueChanged<int> onRemoveTarget;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ExchangeRateToolState._panelSurface,
        border: Border.all(color: _ExchangeRateToolState._panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '汇率换算',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ExchangeRateToolState._panelText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: _ExchangeRateToolState._panelText,
                    ),
                    decoration: const InputDecoration(labelText: '金额'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: _CurrencyDropdown(
                    label: '卖出货币',
                    value: fromCode,
                    excluded: const {},
                    onChanged: onFromChanged,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '互换卖出货币与第一种兑换货币',
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_horiz),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (var i = 0; i < targetCodes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CurrencyDropdown(
                            label: '兑换货币',
                            value: targetCodes[i],
                            excluded: {fromCode},
                            onChanged: (code) => onTargetChanged(i, code),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: '移除兑换货币',
                          onPressed: () => onRemoveTarget(i),
                          icon: const Icon(Icons.delete_outline),
                          color: _ExchangeRateToolState._panelMuted,
                        ),
                        if (i == targetCodes.length - 1)
                          IconButton.filled(
                            tooltip: '添加兑换货币',
                            onPressed: onAddTarget,
                            icon: const Icon(Icons.add),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.excluded,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Set<String> excluded;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: _ExchangeRateToolState._panelSurface,
      style: const TextStyle(color: _ExchangeRateToolState._panelText),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final currency in exchangeCurrencies)
          if (!excluded.contains(currency.code) || currency.code == value)
            DropdownMenuItem(value: currency.code, child: Text(currency.label)),
      ],
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }
}

class _ExchangeChartCard extends StatelessWidget {
  const _ExchangeChartCard({
    super.key,
    required this.fromCode,
    required this.toCode,
    required this.amount,
    required this.seriesFuture,
    required this.showRangeSelector,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onRetry,
  });

  final String fromCode;
  final String toCode;
  final double amount;
  final Future<ExchangeRateSeries>? seriesFuture;
  final bool showRangeSelector;
  final ExchangeTimeRange selectedRange;
  final ValueChanged<ExchangeTimeRange> onRangeChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ExchangeRateToolState._panelSurface,
        border: Border.all(color: _ExchangeRateToolState._panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<ExchangeRateSeries>(
          future: seriesFuture,
          builder: (context, snapshot) {
            final series = snapshot.data;
            final change = series?.change;
            final trendColor = change == null
                ? _ExchangeRateToolState._panelMuted
                : change.isUp
                ? _ExchangeRateToolState._riseColor
                : _ExchangeRateToolState._fallColor;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$fromCode / $toCode',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _ExchangeRateToolState._panelText,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            series == null
                                ? '正在获取新浪财经行情...'
                                : '${amount.toStringAsFixed(2)} $fromCode = ${(amount * series.latestRate).toStringAsFixed(4)} $toCode',
                            style: const TextStyle(
                              color: _ExchangeRateToolState._panelMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showRangeSelector)
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<ExchangeTimeRange>(
                          initialValue: selectedRange,
                          dropdownColor: _ExchangeRateToolState._panelSurface,
                          style: const TextStyle(
                            color: _ExchangeRateToolState._panelText,
                          ),
                          decoration: const InputDecoration(labelText: '总时间'),
                          items: [
                            for (final range in exchangeTimeRanges)
                              DropdownMenuItem(
                                value: range,
                                child: Text(range.label),
                              ),
                          ],
                          onChanged: (range) {
                            if (range != null) {
                              onRangeChanged(range);
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(
                    height: 178,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (snapshot.hasError)
                  _ExchangeErrorState(error: snapshot.error, onRetry: onRetry)
                else if (series == null || series.points.isEmpty)
                  _ExchangeErrorState(error: '该货币对暂时无法获取行情。', onRetry: onRetry)
                else ...[
                  Row(
                    children: [
                      Text(
                        series.latestRate.toStringAsFixed(6),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: _ExchangeRateToolState._panelText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatPercent(change!.percentChange),
                        style: TextStyle(
                          color: trendColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label:
                        '$fromCode 到 $toCode ${selectedRange.label}涨跌幅 ${_formatPercent(change.percentChange)}',
                    child: SizedBox(
                      height: 170,
                      child: CustomPaint(
                        painter: _ExchangeLineChartPainter(
                          points: series.points,
                          lineColor: trendColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPointTime(series.points.first.time)} - ${_formatPointTime(series.points.last.time)} · ${series.source}',
                    style: const TextStyle(
                      color: _ExchangeRateToolState._panelMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatPercent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  String _formatPointTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time.toLocal());
  }
}

class _ExchangeErrorState extends StatelessWidget {
  const _ExchangeErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF190D12),
        border: Border.all(color: _ExchangeRateToolState._riseColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ExchangeRateToolState._panelText),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _ExchangeLineChartPainter extends CustomPainter {
  const _ExchangeLineChartPainter({
    required this.points,
    required this.lineColor,
  });

  final List<ExchangeRatePoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rates = points.map((point) => point.rate).toList();
    final minRate = rates.reduce(min);
    final maxRate = rates.reduce(max);
    final range = max(maxRate - minRate, 0.0000001);
    final chartRect = Rect.fromLTWH(0, 8, size.width, size.height - 16);

    final gridPaint = Paint()
      ..color = _ExchangeRateToolState._panelBorder
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + chartRect.height / 3 * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * i / (points.length - 1);
      final y =
          chartRect.bottom -
          ((points[i].rate - minRate) / range) * chartRect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = lineColor;
    for (final index in [0, points.length - 1]) {
      final x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * index / (points.length - 1);
      final y =
          chartRect.bottom -
          ((points[index].rate - minRate) / range) * chartRect.height;
      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExchangeLineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}

class ConverterTool extends StatefulWidget {
  const ConverterTool({super.key});

  @override
  State<ConverterTool> createState() => _ConverterToolState();
}

class _ConverterToolState extends State<ConverterTool> {
  final _controller = TextEditingController(text: '1');
  String _category = '长度';
  String _from = '米';
  String _to = '厘米';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = _units[_category]!;
    if (!units.containsKey(_from)) {
      _from = units.keys.first;
    }
    if (!units.containsKey(_to)) {
      _to = units.keys.skip(1).firstOrNull ?? units.keys.first;
    }

    final input = double.tryParse(_controller.text) ?? 0;
    final result = _convert(input, _category, _from, _to);

    return AppPanel(
      title: '单位换算',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: '类型'),
                  items: [
                    for (final category in _units.keys)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                        _from = _units[value]!.keys.first;
                        _to =
                            _units[value]!.keys.skip(1).firstOrNull ??
                            _units[value]!.keys.first;
                      });
                    }
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '数值'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 180,
                child: _UnitDropdown(
                  label: '从',
                  value: _from,
                  units: units.keys,
                  onChanged: (value) => setState(() => _from = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: _UnitDropdown(
                  label: '到',
                  value: _to,
                  units: units.keys,
                  onChanged: (value) => setState(() => _to = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${input.toStringAsFixed(2)} $_from = ${result.toStringAsFixed(4)} $_to',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Iterable<String> units;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final unit in units)
          DropdownMenuItem(value: unit, child: Text(unit)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class PasswordTool extends StatefulWidget {
  const PasswordTool({super.key});

  @override
  State<PasswordTool> createState() => _PasswordToolState();
}

class _PasswordToolState extends State<PasswordTool> {
  int _length = 16;
  bool _includeSymbols = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '密码生成',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('长度：$_length'),
          Slider(
            min: 8,
            max: 32,
            divisions: 24,
            value: _length.toDouble(),
            label: '$_length',
            onChanged: (value) => setState(() => _length = value.round()),
            onChangeEnd: (_) => _generate(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('包含符号'),
            value: _includeSymbols,
            onChanged: (value) {
              setState(() => _includeSymbols = value);
              _generate();
            },
          ),
          const SizedBox(height: 12),
          SelectableText(
            _password,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh),
                label: const Text('重新生成'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _password));
                  ScaffoldMessenger.of(
                    context,
                  ).showLatestSnackBar(const SnackBar(content: Text('密码已复制')));
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('复制'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _generate() {
    const letters = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const symbols = '!@#\$%^&*()-_=+[]{};:,.?';
    final alphabet = _includeSymbols ? '$letters$symbols' : letters;
    final random = Random.secure();
    setState(() {
      _password = List.generate(
        _length,
        (_) => alphabet[random.nextInt(alphabet.length)],
      ).join();
    });
  }
}

class PomodoroTool extends ConsumerStatefulWidget {
  const PomodoroTool({super.key});

  @override
  ConsumerState<PomodoroTool> createState() => _PomodoroToolState();
}

class _PomodoroToolState extends ConsumerState<PomodoroTool> {
  static const _focusSeconds = 25 * 60;
  Timer? _timer;
  int _remainingSeconds = _focusSeconds;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return _ResponsiveGrid(
      left: AppPanel(
        title: '专注计时',
        child: Column(
          children: [
            Text(
              '$minutes:$seconds',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _running ? _pause : _start,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? '暂停' : '开始'),
                ),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.replay),
                  label: const Text('重置'),
                ),
                OutlinedButton.icon(
                  onPressed: () => database.addPomodoroSession(minutes: 25),
                  icon: const Icon(Icons.check),
                  label: const Text('记录完成'),
                ),
              ],
            ),
          ],
        ),
      ),
      right: StreamBuilder<List<PomodoroSession>>(
        stream: database.watchPomodoroSessions(),
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? const <PomodoroSession>[];
          if (sessions.isEmpty) {
            return const EmptyState(
              icon: Icons.timer_outlined,
              title: '暂无专注记录',
              message: '完成番茄钟后会记录到本地数据库。',
            );
          }
          return AppPanel(
            title: '最近完成',
            child: Column(
              children: [
                for (final session in sessions.take(8))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${session.minutes} 分钟专注'),
                    subtitle: Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(session.completedAt.toLocal()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _start() {
    if (_running) {
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _pause();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _running = false);
  }

  void _reset() {
    _pause();
    setState(() => _remainingSeconds = _focusSeconds);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

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
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

const _units = <String, Map<String, double>>{
  '长度': {
    '米': 1,
    '厘米': 0.01,
    '毫米': 0.001,
    '千米': 1000,
    '英寸': 0.0254,
    '英尺': 0.3048,
  },
  '重量': {'千克': 1, '克': 0.001, '斤': 0.5, '吨': 1000, '磅': 0.45359237},
  '温度': {'摄氏度': 1, '华氏度': 1, '开尔文': 1},
};

double _convert(double value, String category, String from, String to) {
  if (category == '温度') {
    final celsius = switch (from) {
      '华氏度' => (value - 32) * 5 / 9,
      '开尔文' => value - 273.15,
      _ => value,
    };
    return switch (to) {
      '华氏度' => celsius * 9 / 5 + 32,
      '开尔文' => celsius + 273.15,
      _ => celsius,
    };
  }
  final units = _units[category]!;
  final base = value * units[from]!;
  return base / units[to]!;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
