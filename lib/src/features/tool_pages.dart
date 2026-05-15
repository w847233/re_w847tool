import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../ledger/alipay_bill_import_service.dart';
import '../network/dns_leak_tool.dart';
import '../network/nat_traversal_tool.dart';
import '../steam_status/steam_status_tool.dart';
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
                'password' => const PasswordTool(),
                'pomodoro' => const PomodoroTool(),
                'dnsLeak' => const DnsLeakTool(),
                'natTraversal' => const NatTraversalTool(),
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
  final _alipayAppIdController = TextEditingController();
  final _alipayPrivateKeyController = TextEditingController();
  final _alipayAppAuthTokenController = TextEditingController();
  final _alipayBillTypeController = TextEditingController(text: 'trade');
  final _alipayService = AlipayBillImportService();
  DateTime _alipayBillDate = DateUtils.dateOnly(
    DateTime.now().subtract(const Duration(days: 1)),
  );
  String _type = '支出';
  String _alipayImportType = '收入';
  bool _isImportingAlipay = false;
  String _alipayStatus = '支付宝接口只能获取商户离线账单，日账单最早为昨天。';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _alipayAppIdController.dispose();
    _alipayPrivateKeyController.dispose();
    _alipayAppAuthTokenController.dispose();
    _alipayBillTypeController.dispose();
    _alipayService.close();
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
            const Divider(height: 32),
            Text('支付宝账单导入', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayAppIdController,
              decoration: const InputDecoration(labelText: 'App ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayPrivateKeyController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '应用私钥 PEM'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayAppAuthTokenController,
              decoration: const InputDecoration(
                labelText: 'App Auth Token（服务商代商户可选）',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayBillTypeController,
              decoration: const InputDecoration(labelText: '账单类型'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isImportingAlipay ? null : _pickAlipayBillDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(DateFormat('yyyy-MM-dd').format(_alipayBillDate)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              selected: {_alipayImportType},
              segments: const [
                ButtonSegment(value: '收入', label: Text('导入为收入')),
                ButtonSegment(value: '支出', label: Text('导入为支出')),
              ],
              onSelectionChanged: _isImportingAlipay
                  ? null
                  : (value) => setState(() => _alipayImportType = value.first),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isImportingAlipay
                    ? null
                    : () => _importAlipayBill(database),
                icon: _isImportingAlipay
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: Text(_isImportingAlipay ? '导入中' : '获取并导入'),
              ),
            ),
            const SizedBox(height: 8),
            Text(_alipayStatus, style: const TextStyle(color: AppColors.muted)),
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

  Future<void> _pickAlipayBillDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _alipayBillDate.isBefore(today)
          ? _alipayBillDate
          : today.subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: today.subtract(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _alipayBillDate = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _importAlipayBill(AppDatabase database) async {
    setState(() {
      _isImportingAlipay = true;
      _alipayStatus = '正在向支付宝请求账单下载地址...';
    });
    try {
      final result = await _alipayService.fetchRecentTradeBill(
        AlipayBillImportRequest(
          appId: _alipayAppIdController.text,
          privateKeyPem: _alipayPrivateKeyController.text,
          appAuthToken: _alipayAppAuthTokenController.text,
          billType: _alipayBillTypeController.text,
          billDate: _alipayBillDate,
        ),
      );
      var imported = 0;
      for (final record in result.records) {
        final type = _ledgerTypeForAlipayRecord(record);
        final inserted = await database.importLedgerEntry(
          sourceId: record.sourceId,
          type: type,
          amount: record.amount,
          note: record.toLedgerNote(),
          occurredAt: record.occurredAt,
        );
        if (inserted) {
          imported++;
        }
      }
      final skipped = result.records.length - imported;
      setState(() {
        _alipayStatus =
            '已读取 ${result.records.length} 条，导入 $imported 条，跳过重复 $skipped 条。';
      });
    } on AlipayBillImportException catch (error) {
      setState(() => _alipayStatus = error.message);
    } catch (error) {
      setState(() => _alipayStatus = '支付宝账单导入失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isImportingAlipay = false);
      }
    }
  }

  String _ledgerTypeForAlipayRecord(AlipayBillRecord record) {
    if (!record.isRefund) {
      return _alipayImportType;
    }
    return _alipayImportType == '收入' ? '支出' : '收入';
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
