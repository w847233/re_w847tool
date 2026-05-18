import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../exchange_rate/exchange_home_widget_repository.dart';
import '../exchange_rate/sina_forex_market_service.dart';
import '../get_token/get_token_tool.dart';
import '../ledger/alipay_ledger_models.dart';
import '../ledger/alipay_ledger_repository.dart';
import '../network/dns_leak_tool.dart';
import '../network/nat_traversal_tool.dart';
import '../phone_manager/phone_manager_tool.dart';
import '../steam_status/steam_status_tool.dart';
import '../system_control/system_control_tool.dart';
import '../theme/app_theme.dart';
import '../tools/tool_registry.dart';
import '../ui/app_panel.dart';
import '../ui/deferred_navigation.dart';
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
              child: _DeferredToolContent(tool: tool),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeferredToolContent extends StatefulWidget {
  const _DeferredToolContent({required this.tool});

  final ToolDefinition tool;

  @override
  State<_DeferredToolContent> createState() => _DeferredToolContentState();
}

class _DeferredToolContentState extends State<_DeferredToolContent> {
  Timer? _mountTimer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _scheduleMount();
  }

  @override
  void didUpdateWidget(covariant _DeferredToolContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tool.id != widget.tool.id) {
      _ready = false;
      _scheduleMount();
    }
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return _ToolLoadingState(tool: widget.tool);
    }
    return KeyedSubtree(
      key: ValueKey('tool-content-${widget.tool.id}'),
      child: switch (widget.tool.id) {
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
          icon: widget.tool.icon,
          title: '工具暂不可用',
          message: '当前工具尚未实现，请从左侧选择其他工具。',
        ),
      },
    );
  }

  void _scheduleMount() {
    _mountTimer?.cancel();
    _mountTimer = Timer(deferredToolContentDelay, () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }
}

class _ToolLoadingState extends StatelessWidget {
  const _ToolLoadingState({required this.tool});

  final ToolDefinition tool;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '正在打开 ${tool.name}',
      child: const LinearProgressIndicator(minHeight: 2),
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
  final _alipayPublicKeyController = TextEditingController();
  final _alipayMethodController = TextEditingController(
    text: defaultAlipayLedgerMethod,
  );
  final _alipayAuthCodeController = TextEditingController();
  String _type = '支出';
  AlipayLedgerConfig _alipayConfig = const AlipayLedgerConfig();
  AlipayOAuthToken _alipayToken = const AlipayOAuthToken();
  List<AlipayBillRow> _alipayPreviewRows = const <AlipayBillRow>[];
  DateTime _alipayStart = DateTime.now().subtract(const Duration(days: 6));
  DateTime _alipayEnd = DateTime.now();
  bool _alipayLoading = false;
  bool _showPrivateKey = false;

  @override
  void initState() {
    super.initState();
    _loadAlipayState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _alipayAppIdController.dispose();
    _alipayPrivateKeyController.dispose();
    _alipayPublicKeyController.dispose();
    _alipayMethodController.dispose();
    _alipayAuthCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    return _ResponsiveGrid(
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            title: '新增账目',
            child: Column(
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
          ),
          const SizedBox(height: 12),
          AppPanel(title: '支付宝导入', child: _buildAlipayImportPanel()),
        ],
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

  Widget _buildAlipayImportPanel() {
    final status = _alipayStatusText();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(status)),
            if (_alipayLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: !_alipayConfig.isConfigured,
          title: const Text('支付宝配置'),
          children: [
            TextField(
              controller: _alipayAppIdController,
              decoration: const InputDecoration(labelText: 'appId'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayPrivateKeyController,
              maxLines: _showPrivateKey ? 5 : 1,
              obscureText: !_showPrivateKey,
              decoration: InputDecoration(
                labelText: 'privateKeyPem',
                suffixIcon: IconButton(
                  tooltip: _showPrivateKey ? '隐藏私钥' : '显示私钥',
                  onPressed: () =>
                      setState(() => _showPrivateKey = !_showPrivateKey),
                  icon: Icon(
                    _showPrivateKey
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayPublicKeyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'alipayPublicKeyPem',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alipayMethodController,
              decoration: const InputDecoration(labelText: 'methodName'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _alipayLoading ? null : _saveAlipayConfig,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存配置'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _alipayLoading ? null : _connectAlipay,
              icon: const Icon(Icons.link_outlined),
              label: Text(_alipayToken.isAuthorized ? '重新授权' : '连接支付宝'),
            ),
            OutlinedButton.icon(
              onPressed: _alipayLoading ? null : _disconnectAlipay,
              icon: const Icon(Icons.link_off_outlined),
              label: const Text('断开连接'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _alipayAuthCodeController,
          decoration: InputDecoration(
            labelText: '手动粘贴 auth_code',
            suffixIcon: IconButton(
              tooltip: '换取授权',
              onPressed: _alipayLoading ? null : _exchangeManualAuthCode,
              icon: const Icon(Icons.key_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _alipayLoading ? null : () => _pickAlipayDate(true),
                icon: const Icon(Icons.event_outlined),
                label: Text(DateFormat('MM-dd').format(_alipayStart)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _alipayLoading ? null : () => _pickAlipayDate(false),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(DateFormat('MM-dd').format(_alipayEnd)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _alipayLoading ? null : _queryAlipayPreview,
              icon: const Icon(Icons.search_outlined),
              label: const Text('查询预览'),
            ),
            OutlinedButton.icon(
              onPressed: _alipayLoading || _alipayPreviewRows.isEmpty
                  ? null
                  : _importAlipayRows,
              icon: const Icon(Icons.download_done_outlined),
              label: const Text('导入全部'),
            ),
          ],
        ),
        if (_alipayPreviewRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          for (final row in _alipayPreviewRows.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                row.title.isEmpty ? row.category : row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${row.category.isEmpty ? '未分类' : row.category} · ${row.status.isEmpty ? '未知状态' : row.status}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${row.type == '收入' ? '+' : '-'}¥${row.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: row.type == '收入' ? AppColors.good : AppColors.bad,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_alipayPreviewRows.length > 8)
            Text('还有 ${_alipayPreviewRows.length - 8} 条未显示，导入时会一起处理。'),
        ],
      ],
    );
  }

  Future<void> _loadAlipayState() async {
    final repository = ref.read(alipayLedgerRepositoryProvider);
    final config = await repository.loadConfig();
    final token = await repository.loadToken();
    if (!mounted) {
      return;
    }
    setState(() {
      _alipayConfig = config;
      _alipayToken = token;
      _alipayAppIdController.text = config.appId;
      _alipayPrivateKeyController.text = config.privateKeyPem;
      _alipayPublicKeyController.text = config.alipayPublicKeyPem;
      _alipayMethodController.text = config.methodName.trim().isEmpty
          ? defaultAlipayLedgerMethod
          : config.methodName;
    });
  }

  Future<void> _saveAlipayConfig() async {
    final config = AlipayLedgerConfig(
      appId: _alipayAppIdController.text,
      privateKeyPem: _alipayPrivateKeyController.text,
      alipayPublicKeyPem: _alipayPublicKeyController.text,
      methodName: _alipayMethodController.text.trim().isEmpty
          ? defaultAlipayLedgerMethod
          : _alipayMethodController.text,
    );
    await ref.read(alipayLedgerRepositoryProvider).saveConfig(config);
    if (!mounted) {
      return;
    }
    setState(() => _alipayConfig = config);
    _showLedgerSnack('支付宝配置已保存到本机');
  }

  Future<void> _connectAlipay() async {
    await _runAlipayAction(() async {
      await _saveAlipayConfig();
      final token = await ref
          .read(alipayLedgerRepositoryProvider)
          .connectWithBrowser();
      setState(() => _alipayToken = token);
      _showLedgerSnack('支付宝授权成功');
    });
  }

  Future<void> _exchangeManualAuthCode() async {
    final code = _alipayAuthCodeController.text.trim();
    if (code.isEmpty) {
      _showLedgerSnack('请先粘贴 auth_code');
      return;
    }
    await _runAlipayAction(() async {
      await _saveAlipayConfig();
      final token = await ref
          .read(alipayLedgerRepositoryProvider)
          .exchangeAuthCode(code);
      setState(() {
        _alipayToken = token;
        _alipayAuthCodeController.clear();
      });
      _showLedgerSnack('支付宝授权成功');
    });
  }

  Future<void> _disconnectAlipay() async {
    await ref.read(alipayLedgerRepositoryProvider).clearToken();
    if (!mounted) {
      return;
    }
    setState(() {
      _alipayToken = const AlipayOAuthToken();
      _alipayPreviewRows = const <AlipayBillRow>[];
    });
    _showLedgerSnack('已断开支付宝授权');
  }

  Future<void> _pickAlipayDate(bool isStart) async {
    final initial = isStart ? _alipayStart : _alipayEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isStart) {
        _alipayStart = DateTime(picked.year, picked.month, picked.day);
      } else {
        _alipayEnd = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      }
    });
  }

  Future<void> _queryAlipayPreview() async {
    await _runAlipayAction(() async {
      final preview = await ref
          .read(alipayLedgerRepositoryProvider)
          .queryPreview(
            AlipayLedgerQuery(startTime: _alipayStart, endTime: _alipayEnd),
          );
      setState(() => _alipayPreviewRows = preview.rows);
      _showLedgerSnack(
        preview.rows.isEmpty
            ? '该时间段没有可导入的支付宝账单'
            : '已查询到 ${preview.rows.length} 条支付宝账单',
      );
    });
  }

  Future<void> _importAlipayRows() async {
    await _runAlipayAction(() async {
      final result = await ref
          .read(alipayLedgerRepositoryProvider)
          .importRows(_alipayPreviewRows);
      setState(() => _alipayPreviewRows = const <AlipayBillRow>[]);
      _showLedgerSnack(result.message);
    });
  }

  Future<void> _runAlipayAction(Future<void> Function() action) async {
    if (_alipayLoading) {
      return;
    }
    setState(() => _alipayLoading = true);
    try {
      await action();
    } catch (error) {
      _showLedgerSnack('$error');
    } finally {
      if (mounted) {
        setState(() => _alipayLoading = false);
      }
    }
  }

  String _alipayStatusText() {
    if (!_alipayConfig.isConfigured) {
      return '连接状态：未配置';
    }
    if (!_alipayToken.isAuthorized) {
      return '连接状态：未授权';
    }
    if (_alipayToken.isExpired) {
      return '连接状态：授权过期';
    }
    final id = _alipayToken.userId.isNotEmpty
        ? _maskId(_alipayToken.userId)
        : _maskId(_alipayToken.openId);
    return '连接状态：已授权 $id';
  }

  String _maskId(String value) {
    if (value.length <= 8) {
      return value;
    }
    return '${value.substring(0, 4)}****${value.substring(value.length - 4)}';
  }

  void _showLedgerSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showLatestSnackBar(SnackBar(content: Text(message)));
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
  static const _riseColor = Color(0xFFC5534C);
  static const _fallColor = AppColors.good;

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
      title: '汇率换算',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: _ExchangeHeader(
              amountController: _amountController,
              fromCode: _fromCode,
              targetCodes: _targetCodes,
              onFromChanged: _changeFromCode,
              onSwap: _swapPrimaryTarget,
              onWidgetConfigPressed: _showWidgetConfigDialog,
              onAddTarget: _addTarget,
              onTargetChanged: _changeTargetCode,
              onRemoveTarget: _removeTarget,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _targetCodes.length; i++) ...[
            _ExchangeChartCard(
              key: ValueKey('exchange-chart-${_fromCode}_${_targetCodes[i]}'),
              fromCode: _fromCode,
              toCode: _targetCodes[i],
              amount: amount,
              seriesFuture: _seriesFutures[_targetCodes[i]],
              showRangeSelector: i == 0,
              selectedRange: _range,
              onRangeChanged: _changeRange,
              onRetry: () => setState(() => _refreshTarget(_targetCodes[i])),
            ),
            if (i != _targetCodes.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text(
            '数据源：新浪财经外汇。非官方接口仅供参考，以实际交易报价为准。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showWidgetConfigDialog() async {
    final initialConfig = await ref
        .read(exchangeHomeWidgetRepositoryProvider)
        .loadConfig();
    if (!mounted) {
      return;
    }
    final nextConfig = await showDialog<ExchangeHomeWidgetConfig>(
      context: context,
      builder: (context) =>
          _ExchangeWidgetConfigDialog(initialConfig: initialConfig),
    );
    if (nextConfig == null || !mounted) {
      return;
    }
    await ref.read(exchangeHomeWidgetRepositoryProvider).saveConfig(nextConfig);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showLatestSnackBar(const SnackBar(content: Text('主页汇率小组件配置已保存')));
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
    required this.onWidgetConfigPressed,
    required this.onAddTarget,
    required this.onTargetChanged,
    required this.onRemoveTarget,
  });

  final TextEditingController amountController;
  final String fromCode;
  final List<String> targetCodes;
  final ValueChanged<String> onFromChanged;
  final VoidCallback onSwap;
  final VoidCallback onWidgetConfigPressed;
  final VoidCallback onAddTarget;
  final void Function(int index, String code) onTargetChanged;
  final ValueChanged<int> onRemoveTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '同时查看多个目标货币的实时汇率和历史涨跌。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '金额'),
              ),
            ),
            SizedBox(
              width: 220,
              child: _CurrencyDropdown(
                label: '基准货币',
                value: fromCode,
                excluded: const {},
                onChanged: onFromChanged,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('与首个目标互换'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('exchange-widget-config-button'),
              onPressed: onWidgetConfigPressed,
              icon: const Icon(Icons.widgets_outlined),
              label: const Text('小组件'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < targetCodes.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CurrencyDropdown(
                    label: '目标货币 ${i + 1}',
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
                  color: AppColors.muted,
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
          if (i != targetCodes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ExchangeWidgetConfigDialog extends StatefulWidget {
  const _ExchangeWidgetConfigDialog({required this.initialConfig});

  final ExchangeHomeWidgetConfig initialConfig;

  @override
  State<_ExchangeWidgetConfigDialog> createState() =>
      _ExchangeWidgetConfigDialogState();
}

class _ExchangeWidgetConfigDialogState
    extends State<_ExchangeWidgetConfigDialog> {
  late final TextEditingController _refreshController;
  late String _fromCode;
  late List<String> _targetCodes;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _fromCode = widget.initialConfig.fromCode;
    _targetCodes = [...widget.initialConfig.targetCodes];
    _refreshController = TextEditingController(
      text: widget.initialConfig.refreshSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextTarget = _firstAvailableTarget();
    return AlertDialog(
      title: const Text('主页汇率小组件'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CurrencyDropdown(
                label: '基准货币',
                value: _fromCode,
                excluded: const {},
                onChanged: _changeFromCode,
              ),
              const SizedBox(height: 12),
              Text(
                '主页小组件固定显示 100 单位基准货币。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _targetCodes.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: _CurrencyDropdown(
                        label: '显示货币 ${i + 1}',
                        value: _targetCodes[i],
                        excluded: {_fromCode},
                        onChanged: (code) => _changeTargetCode(i, code),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: '删除小组件货币',
                      onPressed: () => _removeTarget(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                if (i != _targetCodes.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filled(
                  key: const ValueKey('exchange-widget-add-target'),
                  tooltip: '添加小组件货币',
                  onPressed: nextTarget == null ? null : _addTarget,
                  icon: const Icon(Icons.add),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('exchange-widget-refresh-seconds'),
                controller: _refreshController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '更新汇率秒数'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.bad, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  void _changeFromCode(String code) {
    setState(() {
      _fromCode = code;
      _targetCodes.removeWhere((target) => target == code);
      if (_targetCodes.isEmpty) {
        _targetCodes.add(_firstAvailableTarget() ?? 'USD');
      }
      _errorText = null;
    });
  }

  void _changeTargetCode(int index, String code) {
    if (_targetCodes.contains(code) && _targetCodes[index] != code) {
      setState(() {
        _errorText = '该货币已添加到小组件中。';
      });
      return;
    }
    setState(() {
      _targetCodes[index] = code;
      _errorText = null;
    });
  }

  void _addTarget() {
    final next = _firstAvailableTarget();
    if (next == null) {
      setState(() {
        _errorText = '没有更多可添加的货币。';
      });
      return;
    }
    setState(() {
      _targetCodes.add(next);
      _errorText = null;
    });
  }

  void _removeTarget(int index) {
    if (_targetCodes.length == 1) {
      setState(() {
        _errorText = '至少保留一种货币。';
      });
      return;
    }
    setState(() {
      _targetCodes.removeAt(index);
      _errorText = null;
    });
  }

  void _save() {
    final refreshSeconds = int.tryParse(_refreshController.text.trim());
    if (refreshSeconds == null || refreshSeconds <= 0) {
      setState(() {
        _errorText = '更新汇率秒数请输入正整数。';
      });
      return;
    }
    Navigator.of(context).pop(
      ExchangeHomeWidgetConfig(
        fromCode: _fromCode,
        targetCodes: _targetCodes,
        refreshSeconds: max(
          refreshSeconds,
          ExchangeHomeWidgetConfig.minRefreshSeconds,
        ),
      ),
    );
  }

  String? _firstAvailableTarget() {
    for (final currency in exchangeCurrencies) {
      if (currency.code != _fromCode && !_targetCodes.contains(currency.code)) {
        return currency.code;
      }
    }
    return null;
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
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
                ? AppColors.muted
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
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            series == null
                                ? '正在获取新浪财经行情...'
                                : '${amount.toStringAsFixed(2)} $fromCode = ${(amount * series.latestRate).toStringAsFixed(4)} $toCode',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (showRangeSelector)
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<ExchangeTimeRange>(
                          initialValue: selectedRange,
                          decoration: const InputDecoration(labelText: '时间范围'),
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: _ExchangeMetricTile(
                          label: '当前汇率',
                          value: series.latestRate.toStringAsFixed(6),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: _ExchangeMetricTile(
                          label: '涨跌幅',
                          value: _formatPercent(change!.percentChange),
                          emphasisColor: trendColor,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: _ExchangeMetricTile(
                          label: '换算结果',
                          value:
                              '${(amount * series.latestRate).toStringAsFixed(4)} $toCode',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Semantics(
                      label:
                          '$fromCode 到 $toCode ${selectedRange.label}涨跌幅 ${_formatPercent(change.percentChange)}',
                      child: _InteractiveExchangeChart(
                        points: series.points,
                        lineColor: trendColor,
                        range: selectedRange,
                        fromCode: fromCode,
                        toCode: toCode,
                        amount: amount,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPointLabel(series.points.first)} - ${_formatPointLabel(series.points.last)} · ${series.source}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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

  String _formatPointLabel(ExchangeRatePoint point) {
    if (selectedRange.showsCalendarRange &&
        !point.periodStart.isAtSameMomentAs(point.periodEnd)) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      return '${dateFormat.format(point.periodStart.toLocal())} ~ ${dateFormat.format(point.periodEnd.toLocal())}';
    }
    if (selectedRange.usesIntradayLabel) {
      return _formatPointTime(point.time);
    }
    return DateFormat('yyyy-MM-dd').format(point.time.toLocal());
  }
}

class _ExchangeMetricTile extends StatelessWidget {
  const _ExchangeMetricTile({
    required this.label,
    required this.value,
    this.emphasisColor,
  });

  final String label;
  final String value;
  final Color? emphasisColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasisColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveExchangeChart extends StatefulWidget {
  const _InteractiveExchangeChart({
    required this.points,
    required this.lineColor,
    required this.range,
    required this.fromCode,
    required this.toCode,
    required this.amount,
  });

  final List<ExchangeRatePoint> points;
  final Color lineColor;
  final ExchangeTimeRange range;
  final String fromCode;
  final String toCode;
  final double amount;

  @override
  State<_InteractiveExchangeChart> createState() =>
      _InteractiveExchangeChartState();
}

class _InteractiveExchangeChartState extends State<_InteractiveExchangeChart> {
  int? _hoveredIndex;
  bool _showHoverCardOnLeftSide = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('exchange-interactive-chart-${widget.toCode}'),
      height: 170,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 170);
          final hoveredPoint = _hoveredIndex == null
              ? null
              : widget.points[_hoveredIndex!];
          return MouseRegion(
            cursor: SystemMouseCursors.precise,
            onExit: (_) => setState(() {
              _hoveredIndex = null;
              _showHoverCardOnLeftSide = false;
            }),
            onHover: (event) {
              final index = _resolveHoveredIndex(event.localPosition, size);
              final showHoverCardOnLeftSide = _shouldShowHoverCardOnLeftSide(
                event.localPosition,
                size,
              );
              if (index != _hoveredIndex ||
                  showHoverCardOnLeftSide != _showHoverCardOnLeftSide) {
                setState(() {
                  _hoveredIndex = index;
                  _showHoverCardOnLeftSide = showHoverCardOnLeftSide;
                });
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ExchangeLineChartPainter(
                      points: widget.points,
                      lineColor: widget.lineColor,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                ),
                if (hoveredPoint != null)
                  Positioned(
                    key: const ValueKey('exchange-hover-card'),
                    top: 8,
                    left: _showHoverCardOnLeftSide ? 8 : null,
                    right: _showHoverCardOnLeftSide ? null : 8,
                    child: IgnorePointer(
                      child: _ExchangeHoverCard(
                        fromCode: widget.fromCode,
                        toCode: widget.toCode,
                        amount: widget.amount,
                        range: widget.range,
                        point: hoveredPoint,
                        previousPoint: _hoveredIndex! > 0
                            ? widget.points[_hoveredIndex! - 1]
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _resolveHoveredIndex(Offset localPosition, Size size) {
    if (widget.points.length == 1) {
      return 0;
    }
    final chartRect = _exchangeChartRect(size);
    final clampedX = localPosition.dx.clamp(chartRect.left, chartRect.right);
    final progress = (clampedX - chartRect.left) / chartRect.width;
    return (progress * (widget.points.length - 1)).round();
  }

  bool _shouldShowHoverCardOnLeftSide(Offset localPosition, Size size) {
    final chartRect = _exchangeChartRect(size);
    return localPosition.dx >= chartRect.center.dx;
  }
}

class _ExchangeHoverCard extends StatelessWidget {
  const _ExchangeHoverCard({
    required this.fromCode,
    required this.toCode,
    required this.amount,
    required this.range,
    required this.point,
    required this.previousPoint,
  });

  final String fromCode;
  final String toCode;
  final double amount;
  final ExchangeTimeRange range;
  final ExchangeRatePoint point;
  final ExchangeRatePoint? previousPoint;

  @override
  Widget build(BuildContext context) {
    final absoluteChange = previousPoint == null
        ? null
        : point.rate - previousPoint!.rate;
    final percentChange = absoluteChange == null || previousPoint!.rate == 0
        ? null
        : absoluteChange / previousPoint!.rate * 100;
    final changeColor = absoluteChange == null
        ? AppColors.muted
        : absoluteChange >= 0
        ? _ExchangeRateToolState._riseColor
        : _ExchangeRateToolState._fallColor;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$fromCode / $toCode',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _ExchangeHoverRow(label: '时间', value: _formatPointLabel()),
          _ExchangeHoverRow(
            label: '当前汇率',
            value: point.rate.toStringAsFixed(6),
          ),
          _ExchangeHoverRow(
            label: '涨跌额',
            value: absoluteChange == null
                ? '--'
                : _formatSignedNumber(absoluteChange, 6),
            valueColor: changeColor,
          ),
          _ExchangeHoverRow(
            label: '涨跌幅',
            value: percentChange == null
                ? '--'
                : '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
            valueColor: changeColor,
          ),
          _ExchangeHoverRow(
            label: '换算结果',
            value: '${(amount * point.rate).toStringAsFixed(4)} $toCode',
          ),
        ],
      ),
    );
  }

  String _formatPointLabel() {
    if (range.showsCalendarRange &&
        !point.periodStart.isAtSameMomentAs(point.periodEnd)) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      return '${dateFormat.format(point.periodStart.toLocal())} ~ ${dateFormat.format(point.periodEnd.toLocal())}';
    }
    if (range.usesIntradayLabel) {
      return DateFormat('yyyy-MM-dd HH:mm').format(point.time.toLocal());
    }
    return DateFormat('yyyy-MM-dd').format(point.time.toLocal());
  }

  String _formatSignedNumber(double value, int digits) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(digits)}';
  }
}

class _ExchangeHoverRow extends StatelessWidget {
  const _ExchangeHoverRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
        color: _ExchangeRateToolState._riseColor.withOpacity(0.08),
        border: Border.all(color: _ExchangeRateToolState._riseColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_wifi_connected_no_internet_4_outlined,
            color: _ExchangeRateToolState._riseColor,
          ),
          const SizedBox(height: 10),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.fg),
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
    this.hoveredIndex,
  });

  final List<ExchangeRatePoint> points;
  final Color lineColor;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _buildExchangeChartScale(points);
    final chartRect = _exchangeChartRect(size);

    final gridPaint = Paint()
      ..color = AppColors.border
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
      final offset = _exchangePointOffset(
        points: points,
        index: i,
        chartRect: chartRect,
        scale: scale,
      );
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
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
      final offset = _exchangePointOffset(
        points: points,
        index: index,
        chartRect: chartRect,
        scale: scale,
      );
      canvas.drawCircle(offset, 3.5, pointPaint);
    }

    final hovered = hoveredIndex;
    if (hovered != null && hovered >= 0 && hovered < points.length) {
      final hoverOffset = _exchangePointOffset(
        points: points,
        index: hovered,
        chartRect: chartRect,
        scale: scale,
      );
      final guidePaint = Paint()
        ..color = AppColors.muted.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      _drawDashedVerticalLine(
        canvas,
        x: hoverOffset.dx,
        top: chartRect.top,
        bottom: chartRect.bottom,
        paint: guidePaint,
      );
      final haloPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      final selectedPaint = Paint()..color = lineColor;
      canvas.drawCircle(hoverOffset, 8, haloPaint);
      canvas.drawCircle(hoverOffset, 4, selectedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExchangeLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

class _ExchangeChartScale {
  const _ExchangeChartScale({
    required this.minRate,
    required this.maxRate,
    required this.range,
  });

  final double minRate;
  final double maxRate;
  final double range;
}

_ExchangeChartScale _buildExchangeChartScale(List<ExchangeRatePoint> points) {
  final rates = points.map((point) => point.rate).toList();
  final minRate = rates.reduce(min);
  final maxRate = rates.reduce(max);
  return _ExchangeChartScale(
    minRate: minRate,
    maxRate: maxRate,
    range: max(maxRate - minRate, 0.0000001),
  );
}

Rect _exchangeChartRect(Size size) {
  return Rect.fromLTWH(0, 8, size.width, size.height - 16);
}

Offset _exchangePointOffset({
  required List<ExchangeRatePoint> points,
  required int index,
  required Rect chartRect,
  required _ExchangeChartScale scale,
}) {
  final x = points.length == 1
      ? chartRect.center.dx
      : chartRect.left + chartRect.width * index / (points.length - 1);
  final y =
      chartRect.bottom -
      ((points[index].rate - scale.minRate) / scale.range) * chartRect.height;
  return Offset(x, y);
}

void _drawDashedVerticalLine(
  Canvas canvas, {
  required double x,
  required double top,
  required double bottom,
  required Paint paint,
}) {
  const dash = 4.0;
  const gap = 4.0;
  var y = top;
  while (y < bottom) {
    final next = min(y + dash, bottom);
    canvas.drawLine(Offset(x, y), Offset(x, next), paint);
    y = next + gap;
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
