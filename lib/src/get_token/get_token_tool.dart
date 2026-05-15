import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'get_token_models.dart';
import 'get_token_service.dart';

class GetTokenTool extends ConsumerStatefulWidget {
  const GetTokenTool({super.key});

  @override
  ConsumerState<GetTokenTool> createState() => _GetTokenToolState();
}

class _GetTokenToolState extends ConsumerState<GetTokenTool> {
  final _baseUrlController = TextEditingController();
  final _batchSizeController = TextEditingController(text: '30');
  final _timeoutController = TextEditingController(text: '30');
  final _limitController = TextEditingController();
  final _managementKeyController = TextEditingController();
  final _apiStartController = TextEditingController();
  final _apiEndController = TextEditingController();
  final _cacheStartController = TextEditingController();
  final _cacheEndController = TextEditingController();
  final _pageSizeController = TextEditingController(text: '500');
  final _pollIntervalController = TextEditingController(text: '10');
  final _quotaTtlController = TextEditingController(text: '60');

  String _apiRange = '4h';
  String _cacheRange = '4h';
  String _tokenSortMode = 'latest';
  bool _tokenSortDescending = true;
  String _credentialSortMode = 'remaining';
  bool _credentialSortDescending = false;
  int _credentialDisplayLimit = 0;
  bool _refreshQuota = false;
  bool _pollingEnabled = false;
  String _configStateSignature = '';
  String _secretStateSignature = '';
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _baseUrlController.dispose();
    _batchSizeController.dispose();
    _timeoutController.dispose();
    _limitController.dispose();
    _managementKeyController.dispose();
    _apiStartController.dispose();
    _apiEndController.dispose();
    _cacheStartController.dispose();
    _cacheEndController.dispose();
    _pageSizeController.dispose();
    _pollIntervalController.dispose();
    _quotaTtlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(getTokenToolStateProvider);
    final controller = ref.watch(getTokenControllerProvider);
    final state = stateAsync.asData?.value ?? GetTokenToolState.initial;
    _syncConfigControllersFromState(state);
    _syncSecretControllerFromState(state);
    _syncPollingWithConfig(state, controller);

    final sortedCredentials = _sortCredentials(state.credentials);
    final sortedUsageRows = _sortUsageRows(
      state.usageSnapshot?.rows ?? const [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBanner(
          state: state,
          onRun: state.collecting
              ? null
              : () async {
                  await _persistConfig(controller);
                  await _showResult(await controller.runCollection());
                },
          onSaveConfig: () async =>
              _showResult(await _persistConfig(controller)),
          onSaveSecret: () async =>
              _showResult(await _persistSecret(controller)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final left = Column(
              children: [
                _buildConfigPanel(controller),
                const SizedBox(height: 16),
                _buildCollectionSummary(state),
                const SizedBox(height: 16),
                _buildChangesPanel(state),
                const SizedBox(height: 16),
                _buildRefreshStatsPanel(state),
                const SizedBox(height: 16),
                _buildCredentialPanel(state, controller, sortedCredentials),
              ],
            );
            final right = Column(
              children: [
                _buildTokenUsagePanel(state, controller, sortedUsageRows),
                const SizedBox(height: 16),
                _buildFailurePanel(state),
              ],
            );
            if (!wide) {
              return Column(
                children: [left, const SizedBox(height: 16), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfigPanel(GetTokenController controller) {
    return AppPanel(
      title: '采集配置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SizedField(
                width: 220,
                child: TextField(
                  controller: _baseUrlController,
                  decoration: const InputDecoration(labelText: '管理接口 baseUrl'),
                ),
              ),
              _SizedField(
                width: 180,
                child: TextField(
                  controller: _managementKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Bearer Key'),
                ),
              ),
              _SizedField(
                width: 120,
                child: TextField(
                  controller: _batchSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '并发批次'),
                ),
              ),
              _SizedField(
                width: 120,
                child: TextField(
                  controller: _timeoutController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '超时(秒)'),
                ),
              ),
              _SizedField(
                width: 120,
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '试跑数量'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'baseUrl、批次、超时、范围和排序会参与同步；管理密钥只保存在本机。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await _showResult(await _persistSecret(controller));
                  },
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('保存密钥'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await _showResult(await _persistConfig(controller));
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存配置'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionSummary(GetTokenToolState state) {
    final snapshot = state.collection;
    final summary = snapshot?.summary ?? const GetTokenSummary();
    final progress = snapshot?.progressPercent ?? 0;
    return AppPanel(
      title: '采集概览',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressStrip(
            label: snapshot?.message ?? '等待开始',
            processed: snapshot?.processed ?? 0,
            total: snapshot?.total ?? 0,
            progressPercent: progress,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: '成功', value: '${summary.successCount}'),
              _MetricCard(label: '失败', value: '${summary.failureCount}'),
              _MetricCard(
                label: '总剩余额度',
                value: '${summary.totalRemainingPercent.toStringAsFixed(2)}%',
              ),
              _MetricCard(label: '低于 50%', value: '${summary.below50Count}'),
              _MetricCard(
                label: '额度总和参考',
                value: '${summary.totalRemainingSum.toStringAsFixed(2)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DistributionBar(summary: summary),
        ],
      ),
    );
  }

  Widget _buildChangesPanel(GetTokenToolState state) {
    final changes = state.collection?.credentialChanges;
    return AppPanel(
      title: '变化对比',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: '新增凭证', value: '${changes?.addedCount ?? 0}'),
              _MetricCard(
                label: '减少凭证',
                value: '${changes?.removedCount ?? 0}',
              ),
              _MetricCard(label: '本次失败', value: '${state.failures.length}'),
              _MetricCard(
                label: '额度下降',
                value:
                    '${changes?.quotaDecreaseCount ?? 0} / ${(changes?.totalQuotaDecrease ?? 0).toStringAsFixed(2)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChangeList(
            title: '新增',
            emptyMessage: '当前没有新增凭证',
            items: changes?.added ?? const [],
          ),
          const SizedBox(height: 10),
          _ChangeList(
            title: '减少',
            emptyMessage: '当前没有减少凭证',
            items: changes?.removed ?? const [],
          ),
          const SizedBox(height: 10),
          _QuotaDecreaseList(changes: changes),
        ],
      ),
    );
  }

  Widget _buildRefreshStatsPanel(GetTokenToolState state) {
    final stats =
        state.collection?.refreshStats ?? const GetTokenRefreshStats();
    return AppPanel(
      title: '刷新时间统计',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: '5 天以上', value: '${stats.unrefreshedCount}'),
              _MetricCard(label: '1 天内', value: '${stats.refreshIn1DayCount}'),
              _MetricCard(label: '1-3 天', value: '${stats.refreshIn3DayCount}'),
              _MetricCard(label: '3-5 天', value: '${stats.refreshIn5DayCount}'),
              _MetricCard(
                label: '失败/未知',
                value: '${stats.failedOrUnknownCount}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RefreshDetailSection(title: '5 天以上刷新', details: stats.unrefreshed),
          _RefreshDetailSection(title: '1 天内刷新', details: stats.refreshIn1Day),
          _RefreshDetailSection(
            title: '1-3 天内刷新',
            details: stats.refreshIn3Day,
          ),
          _RefreshDetailSection(
            title: '3-5 天内刷新',
            details: stats.refreshIn5Day,
          ),
          _RefreshDetailSection(
            title: '失败 / 未知',
            details: stats.failedOrUnknown,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialPanel(
    GetTokenToolState state,
    GetTokenController controller,
    List<GetTokenCredentialRow> rows,
  ) {
    final displayRows = _credentialDisplayLimit == 0
        ? rows
        : rows.take(_credentialDisplayLimit).toList();
    return AppPanel(
      title: '凭证明细',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SizedField(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _credentialSortMode,
                  decoration: const InputDecoration(labelText: '凭证排序'),
                  items: const [
                    DropdownMenuItem(value: 'remaining', child: Text('按剩余额度')),
                    DropdownMenuItem(value: 'plan', child: Text('按套餐')),
                    DropdownMenuItem(value: 'email', child: Text('按邮箱')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _credentialSortMode = value);
                  },
                ),
              ),
              _SizedField(
                width: 160,
                child: DropdownButtonFormField<int>(
                  initialValue: _credentialDisplayLimit,
                  decoration: const InputDecoration(labelText: '每次显示多少条'),
                  items: _credentialDisplayLimitItems,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _credentialDisplayLimit = value);
                  },
                ),
              ),
              FilterChip(
                label: Text(_credentialSortDescending ? '降序' : '升序'),
                selected: _credentialSortDescending,
                onSelected: (_) {
                  setState(() {
                    _credentialSortDescending = !_credentialSortDescending;
                  });
                },
              ),
              Text(
                _credentialDisplayLimit == 0
                    ? '共 ${rows.length} 条'
                    : '显示 ${displayRows.length} / 共 ${rows.length} 条',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('邮箱')),
                DataColumn(label: Text('套餐')),
                DataColumn(label: Text('已用%')),
                DataColumn(label: Text('剩余%')),
                DataColumn(label: Text('刷新时间')),
                DataColumn(label: Text('状态')),
              ],
              rows: [
                for (final row in displayRows)
                  DataRow(
                    color: WidgetStatePropertyAll(
                      row.authIndex != null &&
                              row.authIndex == state.refreshingAuthIndex
                          ? AppColors.bg
                          : Colors.transparent,
                    ),
                    onSelectChanged: row.authIndex == null
                        ? null
                        : (_) async {
                            await _showResult(
                              await controller.refreshCredentialQuota(
                                row.authIndex!,
                              ),
                            );
                          },
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            row.email,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(row.planType ?? '-')),
                      DataCell(Text(_percentOrDash(row.usedPercent))),
                      DataCell(Text(_percentOrDash(row.remainingPercent))),
                      DataCell(Text(_formatCredentialResetTime(row))),
                      DataCell(
                        Text(
                          row.isFailure ? '失败' : '成功',
                          style: TextStyle(
                            color: row.isFailure
                                ? Colors.redAccent
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击某一行可单独刷新该凭证当前额度。',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenUsagePanel(
    GetTokenToolState state,
    GetTokenController controller,
    List<GetTokenUsageRow> rows,
  ) {
    final summary =
        state.usageSnapshot?.summary ?? const GetTokenUsageSummary();
    return AppPanel(
      title: 'Token 使用统计',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SizedField(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _apiRange,
                  decoration: const InputDecoration(labelText: 'API 范围'),
                  items: _rangeItems,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _apiRange = value);
                    }
                  },
                ),
              ),
              _SizedField(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _cacheRange,
                  decoration: const InputDecoration(labelText: '缓存范围'),
                  items: _rangeItems,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _cacheRange = value);
                    }
                  },
                ),
              ),
              _SizedField(
                width: 120,
                child: TextField(
                  controller: _pageSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Page Size'),
                ),
              ),
              _SizedField(
                width: 120,
                child: TextField(
                  controller: _pollIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '轮询秒数'),
                ),
              ),
              _SizedField(
                width: 120,
                child: TextField(
                  controller: _quotaTtlController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '额度 TTL'),
                ),
              ),
              FilterChip(
                label: const Text('刷新当前额度'),
                selected: _refreshQuota,
                onSelected: (value) {
                  setState(() => _refreshQuota = value);
                },
              ),
              FilterChip(
                label: Text(_pollingEnabled ? '持续请求中' : '开启持续请求'),
                selected: _pollingEnabled,
                onSelected: (_) async {
                  await _togglePolling(controller);
                },
              ),
            ],
          ),
          if (_apiRange == 'custom' || _cacheRange == 'custom') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_apiRange == 'custom') ...[
                  _SizedField(
                    width: 160,
                    child: TextField(
                      controller: _apiStartController,
                      decoration: const InputDecoration(labelText: 'API 开始日期'),
                    ),
                  ),
                  _SizedField(
                    width: 160,
                    child: TextField(
                      controller: _apiEndController,
                      decoration: const InputDecoration(labelText: 'API 结束日期'),
                    ),
                  ),
                ],
                if (_cacheRange == 'custom') ...[
                  _SizedField(
                    width: 160,
                    child: TextField(
                      controller: _cacheStartController,
                      decoration: const InputDecoration(labelText: '缓存开始日期'),
                    ),
                  ),
                  _SizedField(
                    width: 160,
                    child: TextField(
                      controller: _cacheEndController,
                      decoration: const InputDecoration(labelText: '缓存结束日期'),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: '凭证数', value: '${summary.credentialCount}'),
              _MetricCard(label: '事件数', value: '${summary.eventCount}'),
              _MetricCard(label: '失败事件', value: '${summary.failedEventCount}'),
              _MetricCard(label: '总 token', value: '${summary.totalTokens}'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SizedField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _tokenSortMode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Token 排序'),
                  items: const [
                    DropdownMenuItem(value: 'latest', child: Text('按最近更新')),
                    DropdownMenuItem(value: 'remaining', child: Text('按额度剩余')),
                    DropdownMenuItem(
                      value: 'tokens',
                      child: Text('按 token 总量'),
                    ),
                    DropdownMenuItem(value: 'failed', child: Text('按失败次数')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tokenSortMode = value);
                    }
                  },
                ),
              ),
              FilterChip(
                label: Text(_tokenSortDescending ? '降序' : '升序'),
                selected: _tokenSortDescending,
                onSelected: (_) {
                  setState(() => _tokenSortDescending = !_tokenSortDescending);
                },
              ),
              FilledButton.icon(
                onPressed: state.queryingTokenUsage
                    ? null
                    : () async {
                        await _persistConfig(controller);
                        await _showResult(
                          await controller.queryTokenUsage(
                            query: _buildUsageQuery(),
                          ),
                        );
                      },
                icon: state.queryingTokenUsage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bar_chart_outlined),
                label: Text(state.queryingTokenUsage ? '查询中...' : '查询一次'),
              ),
              OutlinedButton.icon(
                onPressed: state.queryingTokenUsage
                    ? null
                    : () async {
                        await _showResult(
                          await controller.clearTokenUsageCache(),
                        );
                      },
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('清除缓存'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              '当前范围内没有 token 使用结果。',
              style: TextStyle(color: AppColors.muted),
            )
          else
            Column(
              children: [
                for (final row in rows) ...[
                  _UsageRowCard(row: row),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFailurePanel(GetTokenToolState state) {
    final rows = state.failures;
    return AppPanel(
      title: '失败明细',
      child: rows.isEmpty
          ? const Text('当前没有失败凭证。', style: TextStyle(color: AppColors.muted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in rows) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.email,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          row.error ?? '未知错误',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  void _syncConfigControllersFromState(GetTokenToolState state) {
    if (state.loading) {
      return;
    }
    final signature = state.config.toJson().toString();
    if (signature == _configStateSignature) {
      return;
    }
    _configStateSignature = signature;
    _baseUrlController.text = state.config.baseUrl;
    _batchSizeController.text = '${state.config.batchSize}';
    _timeoutController.text = '${state.config.timeout}';
    _limitController.text = state.config.limit?.toString() ?? '';
    _apiRange = state.config.apiRange;
    _cacheRange = state.config.cacheRange;
    _apiStartController.text = state.config.apiStart ?? '';
    _apiEndController.text = state.config.apiEnd ?? '';
    _cacheStartController.text = state.config.cacheStart ?? '';
    _cacheEndController.text = state.config.cacheEnd ?? '';
    _pageSizeController.text = '${state.config.pageSize}';
    _pollIntervalController.text = '${state.config.tokenIntervalSeconds}';
    _quotaTtlController.text = '${state.config.quotaCacheTtlSeconds}';
    _refreshQuota = state.config.refreshQuota;
    _tokenSortMode = state.config.tokenSortMode;
    _tokenSortDescending = state.config.tokenSortDescending;
    _credentialSortMode = state.config.credentialSortMode;
    _credentialSortDescending = state.config.credentialSortDescending;
    _credentialDisplayLimit = _normalizeCredentialDisplayLimit(
      state.config.credentialDisplayLimit,
    );
    _pollingEnabled = state.config.tokenPollingEnabled;
  }

  void _syncSecretControllerFromState(GetTokenToolState state) {
    if (state.loading) {
      return;
    }
    final signature = state.secret.toJson().toString();
    if (signature == _secretStateSignature) {
      return;
    }
    _secretStateSignature = signature;
    _managementKeyController.text = state.secret.managementKey;
  }

  void _syncPollingWithConfig(
    GetTokenToolState state,
    GetTokenController controller,
  ) {
    if (!mounted || state.loading) {
      return;
    }
    if (_pollingEnabled && _pollTimer == null) {
      _startPolling(controller);
    }
    if (!_pollingEnabled && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<GetTokenActionResult> _persistConfig(
    GetTokenController controller,
  ) async {
    final config = GetTokenConfig(
      baseUrl: _baseUrlController.text.trim(),
      batchSize: _intFrom(_batchSizeController.text, fallback: 30),
      timeout: _intFrom(_timeoutController.text, fallback: 30),
      limit: _optionalIntFrom(_limitController.text),
      apiRange: _apiRange,
      cacheRange: _cacheRange,
      apiStart: _textOrNull(_apiStartController.text),
      apiEnd: _textOrNull(_apiEndController.text),
      cacheStart: _textOrNull(_cacheStartController.text),
      cacheEnd: _textOrNull(_cacheEndController.text),
      pageSize: _intFrom(_pageSizeController.text, fallback: 500),
      tokenIntervalSeconds: _intFrom(
        _pollIntervalController.text,
        fallback: 10,
      ),
      quotaCacheTtlSeconds: _intFrom(_quotaTtlController.text, fallback: 60),
      refreshQuota: _refreshQuota,
      tokenSortMode: _tokenSortMode,
      tokenSortDescending: _tokenSortDescending,
      credentialSortMode: _credentialSortMode,
      credentialSortDescending: _credentialSortDescending,
      credentialDisplayLimit: _credentialDisplayLimit,
      tokenPollingEnabled: _pollingEnabled,
    );
    return controller.saveConfig(config);
  }

  Future<GetTokenActionResult> _persistSecret(GetTokenController controller) {
    return controller.saveSecretConfig(
      GetTokenSecretConfig(managementKey: _managementKeyController.text),
    );
  }

  GetTokenUsageQuery _buildUsageQuery() {
    return GetTokenUsageQuery(
      apiRange: _apiRange,
      apiStart: _textOrNull(_apiStartController.text),
      apiEnd: _textOrNull(_apiEndController.text),
      cacheRange: _cacheRange,
      cacheStart: _textOrNull(_cacheStartController.text),
      cacheEnd: _textOrNull(_cacheEndController.text),
      pageSize: _intFrom(_pageSizeController.text, fallback: 500),
      refreshQuota: _refreshQuota,
      quotaCacheTtlSeconds: _intFrom(_quotaTtlController.text, fallback: 60),
    );
  }

  Future<void> _togglePolling(GetTokenController controller) async {
    setState(() => _pollingEnabled = !_pollingEnabled);
    await _persistConfig(controller);
    if (_pollingEnabled) {
      _startPolling(controller);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showLatestSnackBar(const SnackBar(content: Text('已开启持续请求')));
      }
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showLatestSnackBar(const SnackBar(content: Text('已关闭持续请求')));
      }
    }
  }

  void _startPolling(GetTokenController controller) {
    _pollTimer?.cancel();
    final seconds = _intFrom(
      _pollIntervalController.text,
      fallback: 10,
    ).clamp(1, 3600);
    _pollTimer = Timer.periodic(Duration(seconds: seconds), (_) async {
      await controller.queryTokenUsage(query: _buildUsageQuery());
    });
  }

  List<GetTokenCredentialRow> _sortCredentials(
    List<GetTokenCredentialRow> rows,
  ) {
    final sorted = [...rows];
    switch (_credentialSortMode) {
      case 'plan':
        sorted.sort((a, b) {
          final result = (a.planType ?? '').compareTo(b.planType ?? '');
          return result == 0 ? a.email.compareTo(b.email) : result;
        });
        break;
      case 'email':
        sorted.sort((a, b) => a.email.compareTo(b.email));
        break;
      default:
        sorted.sort((a, b) {
          final left = a.remainingPercent ?? 101;
          final right = b.remainingPercent ?? 101;
          return left.compareTo(right);
        });
        break;
    }
    if (_credentialSortDescending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  int _normalizeCredentialDisplayLimit(int value) {
    return _credentialDisplayLimitValues.contains(value) ? value : 0;
  }

  List<GetTokenUsageRow> _sortUsageRows(List<GetTokenUsageRow> rows) {
    final sorted = [...rows];
    switch (_tokenSortMode) {
      case 'remaining':
        sorted.sort((a, b) {
          final left = a.currentUsage?.remainingPercent ?? -1;
          final right = b.currentUsage?.remainingPercent ?? -1;
          return left.compareTo(right);
        });
        break;
      case 'tokens':
        sorted.sort((a, b) => a.totalTokens.compareTo(b.totalTokens));
        break;
      case 'failed':
        sorted.sort((a, b) {
          final failedCompare = a.failedCount.compareTo(b.failedCount);
          if (failedCompare != 0) {
            return failedCompare;
          }
          return (a.latestTimestamp ?? '').compareTo(b.latestTimestamp ?? '');
        });
        break;
      default:
        sorted.sort(
          (a, b) =>
              (a.latestTimestamp ?? '').compareTo(b.latestTimestamp ?? ''),
        );
        break;
    }
    if (_tokenSortDescending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  Future<void> _showResult(GetTokenActionResult result) async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showLatestSnackBar(SnackBar(content: Text(result.message)));
  }

  static const _rangeItems = [
    DropdownMenuItem(value: '4h', child: Text('4 小时')),
    DropdownMenuItem(value: '8h', child: Text('8 小时')),
    DropdownMenuItem(value: '12h', child: Text('12 小时')),
    DropdownMenuItem(value: 'today', child: Text('今天')),
    DropdownMenuItem(value: '7d', child: Text('7 天')),
    DropdownMenuItem(value: 'custom', child: Text('自定义')),
  ];

  static const _credentialDisplayLimitValues = [0, 20, 50, 100, 200, 500];

  static const _credentialDisplayLimitItems = [
    DropdownMenuItem(value: 0, child: Text('全部')),
    DropdownMenuItem(value: 20, child: Text('20 条')),
    DropdownMenuItem(value: 50, child: Text('50 条')),
    DropdownMenuItem(value: 100, child: Text('100 条')),
    DropdownMenuItem(value: 200, child: Text('200 条')),
    DropdownMenuItem(value: 500, child: Text('500 条')),
  ];
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.state,
    required this.onRun,
    required this.onSaveConfig,
    required this.onSaveSecret,
  });

  final GetTokenToolState state;
  final VoidCallback? onRun;
  final VoidCallback onSaveConfig;
  final VoidCallback onSaveSecret;

  @override
  Widget build(BuildContext context) {
    final status = state.collection?.status ?? 'idle';
    final color = switch (status) {
      'running' => Colors.blue.shade50,
      'completed' => Colors.green.shade50,
      'failed' => Colors.red.shade50,
      _ => AppColors.surface,
    };
    final label = switch (status) {
      'running' => '采集中',
      'completed' => '已完成',
      'failed' => '失败',
      _ => '空闲',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.token_outlined, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Get Token',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(label, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  state.errorMessage ?? state.collection?.message ?? '等待开始',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: onSaveSecret,
                icon: const Icon(Icons.key_outlined),
                label: const Text('保存密钥'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveConfig,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存配置'),
              ),
              FilledButton.icon(
                onPressed: onRun,
                icon: state.collecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_outlined),
                label: Text(state.collecting ? '采集中...' : '开始采集'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.label,
    required this.processed,
    required this.total,
    required this.progressPercent,
  });

  final String label;
  final int processed;
  final int total;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${progressPercent.toStringAsFixed(2)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (progressPercent / 100).clamp(0, 1)),
        const SizedBox(height: 6),
        Text(
          '$processed / $total',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.summary});

  final GetTokenSummary summary;

  @override
  Widget build(BuildContext context) {
    final base = summary.successCount == 0 ? 1 : summary.successCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _Segment(
                color: Colors.redAccent,
                flex: summary.below10Count,
                base: base,
              ),
              _Segment(
                color: Colors.orangeAccent,
                flex: summary.between10And50Count,
                base: base,
              ),
              _Segment(
                color: Colors.amber,
                flex: summary.equal50Count,
                base: base,
              ),
              _Segment(
                color: Colors.green,
                flex: summary.above50Count,
                base: base,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('<10% ${summary.below10Count}'),
            Text('10%-50% ${summary.between10And50Count}'),
            Text('=50% ${summary.equal50Count}'),
            Text('>50% ${summary.above50Count}'),
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color, required this.flex, required this.base});

  final Color color;
  final int flex;
  final int base;

  @override
  Widget build(BuildContext context) {
    if (flex <= 0) {
      return const SizedBox.shrink();
    }
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ChangeList extends StatelessWidget {
  const _ChangeList({
    required this.title,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final String emptyMessage;
  final List<GetTokenCredentialChangeItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(emptyMessage, style: const TextStyle(color: AppColors.muted))
        else
          Column(
            children: [
              for (final item in items) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${item.email}${item.planType == null ? '' : ' · ${item.planType}'}',
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _QuotaDecreaseList extends StatelessWidget {
  const _QuotaDecreaseList({required this.changes});

  final GetTokenCredentialChanges? changes;

  @override
  Widget build(BuildContext context) {
    final items =
        changes?.quotaDecreases ?? const <GetTokenCredentialChangeItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('额度下降明细', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (changes?.hasPrevious == true &&
            changes?.quotaBaselineReady == false)
          const Text(
            '上次缓存没有额度基线，本次已补齐；再次查询后开始显示减少明细。',
            style: TextStyle(color: AppColors.muted),
          )
        else if (items.isEmpty)
          const Text('当前没有额度下降明细。', style: TextStyle(color: AppColors.muted))
        else
          Column(
            children: [
              for (final item in items) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${item.email} · ${_percentOrDash(item.previousRemainingPercent)} -> ${_percentOrDash(item.currentRemainingPercent)} · 下降 ${_percentOrDash(item.decrease)}',
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _RefreshDetailSection extends StatelessWidget {
  const _RefreshDetailSection({required this.title, required this.details});

  final String title;
  final List<GetTokenRefreshDetail> details;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(title),
      children: [
        if (details.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '当前分类没有账号。',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                for (final detail in details)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(detail.email),
                    subtitle: Text(
                      detail.refreshDate == null
                          ? '未知'
                          : '${detail.refreshDate}${detail.refreshDays == null ? '' : ' · ${detail.refreshDays!.toStringAsFixed(2)} 天后刷新'}',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UsageRowCard extends StatelessWidget {
  const _UsageRowCard({required this.row});

  final GetTokenUsageRow row;

  @override
  Widget build(BuildContext context) {
    final cacheRate = row.inputTokens == 0
        ? 0
        : row.cachedTokens / row.inputTokens * 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.source,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(_percentOrDash(row.currentUsage?.remainingPercent)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'token ${row.totalTokens} · 请求 ${row.requestCount} · 失败 ${row.failedCount}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            'input ${row.inputTokens} · output ${row.outputTokens} · reasoning ${row.reasoningTokens} · 缓存率 ${cacheRate.toStringAsFixed(2)}%',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            row.usageError ?? _formatUsageResetTime(row),
            style: TextStyle(
              color: row.usageError == null
                  ? AppColors.muted
                  : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SizedField extends StatelessWidget {
  const _SizedField({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

String? _textOrNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

int _intFrom(String value, {required int fallback}) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    return fallback;
  }
  return parsed;
}

int? _optionalIntFrom(String value) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

String _percentOrDash(double? value) {
  if (value == null) {
    return '-';
  }
  return '${value.toStringAsFixed(2)}%';
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '未知';
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}

String _formatCredentialResetTime(GetTokenCredentialRow row) {
  final normalized = _normalizedCredentialResetAt(row);
  return _formatDateTime(normalized);
}

String _formatUsageResetTime(GetTokenUsageRow row) {
  final normalized = _normalizedUsageResetAt(row);
  return _formatDateTime(normalized);
}

DateTime? _normalizedCredentialResetAt(GetTokenCredentialRow row) {
  final resetAt = row.resetAt;
  if (resetAt != null && !_isClearlyInvalidResetAt(resetAt)) {
    return resetAt;
  }
  final resetAfterSeconds = row.resetAfterSeconds;
  if (resetAfterSeconds == null || resetAfterSeconds < 0) {
    return null;
  }
  final base = row.updatedAt ?? DateTime.now().toUtc();
  return base.toUtc().add(Duration(seconds: resetAfterSeconds));
}

DateTime? _normalizedUsageResetAt(GetTokenUsageRow row) {
  final usage = row.currentUsage;
  if (usage == null) {
    return null;
  }
  final resetAt = usage.resetAt;
  if (resetAt != null && !_isClearlyInvalidResetAt(resetAt)) {
    return resetAt;
  }
  final resetAfterSeconds = usage.resetAfterSeconds;
  final quotaCachedAt = row.quotaCachedAt;
  if (resetAfterSeconds == null ||
      resetAfterSeconds < 0 ||
      quotaCachedAt == null) {
    return null;
  }
  final cachedAt = DateTime.fromMillisecondsSinceEpoch(
    (quotaCachedAt * 1000).round(),
    isUtc: true,
  );
  return cachedAt.add(Duration(seconds: resetAfterSeconds));
}

bool _isClearlyInvalidResetAt(DateTime value) {
  final now = DateTime.now().toUtc();
  return value.isBefore(DateTime.utc(2020)) ||
      value.toUtc().isAfter(now.add(const Duration(days: 365)));
}
