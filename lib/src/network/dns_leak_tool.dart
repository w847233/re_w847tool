import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'dns_tool_service.dart';

class DnsLeakTool extends StatefulWidget {
  const DnsLeakTool({super.key});

  @override
  State<DnsLeakTool> createState() => _DnsLeakToolState();
}

class _DnsLeakToolState extends State<DnsLeakTool> {
  final DnsToolService _service = DnsToolService();
  DnsLeakReport? _report;
  List<DnsBenchmarkResult> _benchmarkResults = const [];
  List<DnsAdapter> _adapters = const [];
  DnsOptimizeMode _optimizeMode = DnsOptimizeMode.latency;
  String _selectedCandidateId = dnsCandidates.first.id;
  String? _selectedAdapterName;
  bool _checkingLeak = false;
  bool _benchmarking = false;
  bool _loadingAdapters = false;
  bool _settingDns = false;
  bool _domesticOnly = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadAdapters();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DnsResponsiveGrid(
      left: Column(
        children: [
          AppPanel(
            title: 'DNS 泄露检测',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '通过公网出口 IP 与当前系统 DNS 解析出口做对照，帮助判断 VPN、代理或自定义 DNS 是否存在疑似泄露。',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _checkingLeak ? null : _runLeakCheck,
                  icon: _checkingLeak
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.security_outlined),
                  label: Text(_checkingLeak ? '检测中...' : '开始检测'),
                ),
                if (_report != null) ...[
                  const SizedBox(height: 18),
                  _LeakReportCard(report: _report!),
                ],
              ],
            ),
          ),
          if (_lastError != null) ...[
            const SizedBox(height: 12),
            _InlineNotice(message: _lastError!, isError: true),
          ],
        ],
      ),
      right: Column(
        children: [
          AppPanel(
            title: '全球 DNS 优选',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<DnsOptimizeMode>(
                  selected: {_optimizeMode},
                  segments: const [
                    ButtonSegment(
                      value: DnsOptimizeMode.latency,
                      icon: Icon(Icons.speed_outlined),
                      label: Text('延迟优选'),
                    ),
                    ButtonSegment(
                      value: DnsOptimizeMode.accuracy,
                      icon: Icon(Icons.fact_check_outlined),
                      label: Text('解析准确性优选'),
                    ),
                  ],
                  onSelectionChanged: (value) {
                    setState(() => _optimizeMode = value.first);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _optimizeMode == DnsOptimizeMode.latency
                      ? '按 DoH 查询平均耗时排序，适合追求打开网页响应速度。点击优选后会测试下方列表中的全部域名。'
                      : '按多个域名解析结果与多数候选的一致性排序，适合排查污染或异常解析。点击优选后会测试下方列表中的全部域名。',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('只优选国内 DNS 与国内域名'),
                  subtitle: Text(
                    _domesticOnly
                        ? '将只测试国内域名，并只比较中国大陆友好的 DNS 服务。'
                        : '将测试国内与全球域名，并比较全部可测试 DNS 服务。',
                  ),
                  value: _domesticOnly,
                  onChanged: _benchmarking
                      ? null
                      : (value) {
                          setState(() {
                            _domesticOnly = value;
                            _benchmarkResults = const [];
                          });
                        },
                ),
                const SizedBox(height: 8),
                _BenchmarkDomainList(domains: _activeBenchmarkDomains),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _benchmarking ? null : _runBenchmark,
                      icon: _benchmarking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.travel_explore_outlined),
                      label: Text(_benchmarking ? '优选中...' : '开始优选'),
                    ),
                    Text(
                      '本次将测试 ${_activeBenchmarkDomains.length} 个域名',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                if (_benchmarkResults.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  for (final result in _sortedBenchmarkResults) ...[
                    _DnsResultTile(
                      result: result,
                      selected: result.candidate.id == _selectedCandidateId,
                      onSelect: () => setState(
                        () => _selectedCandidateId = result.candidate.id,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            title: '设置系统 DNS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!Platform.isWindows)
                  const _InlineNotice(
                    message: '当前只支持在 Windows 上直接写入系统 DNS，其它平台请按页面结果手动设置。',
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAdapterName,
                    decoration: const InputDecoration(labelText: '活动网卡'),
                    items: [
                      for (final adapter in _adapters)
                        DropdownMenuItem(
                          value: adapter.name,
                          child: Text(
                            adapter.description.isEmpty
                                ? adapter.name
                                : '${adapter.name} · ${adapter.description}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _settingDns || _adapters.isEmpty
                        ? null
                        : (value) =>
                              setState(() => _selectedAdapterName = value),
                  ),
                  if (_loadingAdapters) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ],
                  if (!_loadingAdapters && _adapters.isEmpty) ...[
                    const SizedBox(height: 10),
                    const _InlineNotice(message: '未发现活动硬件网卡，请检查网络连接后刷新。'),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCandidateId,
                    decoration: const InputDecoration(labelText: 'DNS 服务'),
                    items: [
                      for (final candidate in dnsCandidates)
                        DropdownMenuItem(
                          value: candidate.id,
                          child: Text(
                            '${candidate.name} · ${candidate.ipv4Servers.join(' / ')}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _settingDns
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedCandidateId = value);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _settingDns ? null : _applySelectedDns,
                        icon: _settingDns
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.dns_outlined),
                        label: Text(_settingDns ? '设置中...' : '设置 DNS'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _settingDns ? null : _resetDns,
                        icon: const Icon(Icons.restore_outlined),
                        label: const Text('恢复自动获取'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loadingAdapters ? null : _loadAdapters,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新网卡'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '写入系统 DNS 通常需要管理员权限；设置前请确认当前网络允许手动 DNS，公共 Wi-Fi 登录页可能受影响。',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DnsBenchmarkResult> get _sortedBenchmarkResults {
    final results = [..._benchmarkResults];
    results.sort((left, right) {
      if (_optimizeMode == DnsOptimizeMode.accuracy) {
        final accuracyCompare = right.accuracyScore.compareTo(
          left.accuracyScore,
        );
        if (accuracyCompare != 0) {
          return accuracyCompare;
        }
      }
      final leftLatency = left.averageLatencyMs ?? double.infinity;
      final rightLatency = right.averageLatencyMs ?? double.infinity;
      final latencyCompare = leftLatency.compareTo(rightLatency);
      if (latencyCompare != 0) {
        return latencyCompare;
      }
      return right.successCount.compareTo(left.successCount);
    });
    return results;
  }

  DnsCandidate get _selectedCandidate {
    return dnsCandidates.firstWhere(
      (candidate) => candidate.id == _selectedCandidateId,
      orElse: () => dnsCandidates.first,
    );
  }

  List<DnsBenchmarkDomain> get _activeBenchmarkDomains {
    if (!_domesticOnly) {
      return dnsBenchmarkDomains;
    }
    return dnsBenchmarkDomains.where((domain) => domain.isDomestic).toList();
  }

  Future<void> _loadAdapters() async {
    setState(() {
      _loadingAdapters = true;
      _lastError = null;
    });
    try {
      final adapters = await _service.listAdapters();
      if (!mounted) {
        return;
      }
      setState(() {
        _adapters = adapters;
        _selectedAdapterName ??= adapters.firstOrNull?.name;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '读取活动网卡失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAdapters = false);
      }
    }
  }

  Future<void> _runLeakCheck() async {
    setState(() {
      _checkingLeak = true;
      _lastError = null;
    });
    try {
      final report = await _service.detectLeak();
      if (mounted) {
        setState(() => _report = report);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = 'DNS 泄露检测失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _checkingLeak = false);
      }
    }
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _benchmarking = true;
      _lastError = null;
    });
    try {
      final results = await _service.benchmark(domesticOnly: _domesticOnly);
      if (!mounted) {
        return;
      }
      setState(() {
        _benchmarkResults = results;
        final best = _sortedBenchmarkResults
            .where((result) => result.successCount > 0)
            .firstOrNull;
        if (best != null) {
          _selectedCandidateId = best.candidate.id;
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = 'DNS 优选失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _benchmarking = false);
      }
    }
  }

  Future<void> _applySelectedDns() async {
    final adapterName = _selectedAdapterName;
    if (adapterName == null) {
      _showMessage('请先选择要设置的活动网卡。');
      return;
    }
    setState(() {
      _settingDns = true;
      _lastError = null;
    });
    try {
      await _service.setDnsServers(
        adapterName: adapterName,
        servers: _selectedCandidate.ipv4Servers,
      );
      if (mounted) {
        _showMessage('已将 $adapterName 设置为 ${_selectedCandidate.name}');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '设置 DNS 失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _settingDns = false);
      }
    }
  }

  Future<void> _resetDns() async {
    final adapterName = _selectedAdapterName;
    if (adapterName == null) {
      _showMessage('请先选择要恢复的活动网卡。');
      return;
    }
    setState(() {
      _settingDns = true;
      _lastError = null;
    });
    try {
      await _service.resetDnsServers(adapterName: adapterName);
      if (mounted) {
        _showMessage('已将 $adapterName 恢复为自动获取 DNS');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '恢复自动 DNS 失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _settingDns = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showLatestSnackMessage(message);
  }
}

class _LeakReportCard extends StatelessWidget {
  const _LeakReportCard({required this.report});

  final DnsLeakReport report;

  @override
  Widget build(BuildContext context) {
    final riskText = switch (report.risk) {
      DnsLeakRisk.low => '风险较低',
      DnsLeakRisk.medium => '疑似泄露',
      DnsLeakRisk.unknown => '无法判断',
    };
    final riskColor = switch (report.risk) {
      DnsLeakRisk.low => AppColors.good,
      DnsLeakRisk.medium => AppColors.bad,
      DnsLeakRisk.unknown => AppColors.muted,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: riskColor),
                const SizedBox(width: 8),
                Text(
                  riskText,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: riskColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              label: '公网出口',
              value: _formatGeo(report.publicIp, report.publicGeo),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              label: 'DNS 出口',
              value: _formatGeo(report.resolverIp, report.resolverGeo),
            ),
            const SizedBox(height: 12),
            const Text(
              '提示：DNS 泄露判断依赖当前网络、VPN 路由和递归解析器行为；如果正在使用 VPN，DNS 出口与 VPN 出口国家不一致时更需要关注。',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGeo(String? ip, IpGeo? geo) {
    if (ip == null) {
      return '未检测到';
    }
    if (geo == null) {
      return '$ip · 地理信息未知';
    }
    return '$ip · ${geo.location} · ${geo.network}';
  }
}

class _DnsResultTile extends StatelessWidget {
  const _DnsResultTile({
    required this.result,
    required this.selected,
    required this.onSelect,
  });

  final DnsBenchmarkResult result;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final latencyText = result.averageLatencyMs == null
        ? '不可用'
        : '${result.averageLatencyMs!.round()} ms';
    final accuracyText = '${(result.accuracyScore * 100).round()}%';

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.bg,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.candidate.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${result.candidate.region} · ${result.candidate.ipv4Servers.join(' / ')}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(label: '平均延迟', value: latencyText),
                  _MetricPill(label: '解析一致性', value: accuracyText),
                  _MetricPill(
                    label: '成功样本',
                    value: '${result.successCount}/${result.sampleCount}',
                  ),
                ],
              ),
              if (result.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  result.error!,
                  style: const TextStyle(color: AppColors.bad, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text('$label：$value', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _BenchmarkDomainList extends StatelessWidget {
  const _BenchmarkDomainList({required this.domains});

  final List<DnsBenchmarkDomain> domains;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt_outlined, size: 18),
                const SizedBox(width: 8),
                Text('将优选测试的域名', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final domain in domains)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${domain.label} · ${domain.domain}'),
                    avatar: Icon(
                      domain.isDomestic
                          ? Icons.flag_outlined
                          : Icons.public_outlined,
                      size: 16,
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

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
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? AppColors.bad.withValues(alpha: 0.08) : AppColors.bg,
        border: Border.all(color: isError ? AppColors.bad : AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              size: 18,
              color: isError ? AppColors.bad : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? AppColors.bad : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DnsResponsiveGrid extends StatelessWidget {
  const _DnsResponsiveGrid({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 390, child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
