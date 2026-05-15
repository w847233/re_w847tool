import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'nat_traversal_models.dart';
import 'nat_traversal_repository.dart';
import 'nat_traversal_service.dart';

class NatTraversalTool extends ConsumerStatefulWidget {
  const NatTraversalTool({super.key, NatTraversalService? service})
    : _service = service;

  final NatTraversalService? _service;

  @override
  ConsumerState<NatTraversalTool> createState() => _NatTraversalToolState();
}

class _NatTraversalToolState extends ConsumerState<NatTraversalTool> {
  final _labelController = TextEditingController();
  final _targetPortController = TextEditingController();
  final _remoteHostController = TextEditingController();
  final _remotePortController = TextEditingController();

  late final NatTraversalService _service;
  StreamSubscription<Map<String, NatTunnelSnapshot>>? _snapshotSubscription;
  Timer? _deferredPortRefreshTimer;
  NatTraversalConfig _config = const NatTraversalConfig();
  List<NatTunnelRule> _rules = const [];
  List<NatPortCandidate> _ports = const [];
  List<NatLocalAddress> _addresses = _defaultLocalAddresses;
  Map<String, NatTunnelSnapshot> _snapshots = const {};
  Set<String> _startingRuleIds = const {};
  NatTunnelProtocol _protocol = NatTunnelProtocol.udp;
  String _targetAddress = '127.0.0.1';
  NatDetectionSummary? _detection;
  bool _loading = true;
  bool _detecting = false;
  bool _refreshingPorts = false;
  bool _savingRule = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? ref.read(natTraversalServiceProvider);
    _snapshotSubscription = _service.snapshots.listen((snapshots) {
      if (mounted) {
        setState(() => _snapshots = snapshots);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialState());
  }

  @override
  void dispose() {
    _deferredPortRefreshTimer?.cancel();
    _snapshotSubscription?.cancel();
    _labelController.dispose();
    _targetPortController.dispose();
    _remoteHostController.dispose();
    _remotePortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NatResponsiveGrid(
      left: Column(
        children: [
          _DetectionPanel(
            detection: _detection,
            detecting: _detecting,
            config: _config,
            onDetect: _detectNat,
          ),
          const SizedBox(height: 16),
          _RuleFormPanel(
            protocol: _protocol,
            targetAddress: _targetAddress,
            addresses: _addresses,
            ports: _ports,
            loadingPorts: _refreshingPorts,
            labelController: _labelController,
            targetPortController: _targetPortController,
            remoteHostController: _remoteHostController,
            remotePortController: _remotePortController,
            saving: _savingRule,
            canAttemptUdp: _detection?.canAttemptUdpHolePunch ?? true,
            onProtocolChanged: (value) => setState(() => _protocol = value),
            onAddressChanged: (value) => setState(() => _targetAddress = value),
            onPortSelected: _applyPortCandidate,
            onRefreshPorts: () => _refreshPorts(),
            onSaveOnly: () => _saveRule(startAfterSave: false),
            onSaveAndStart: () => _saveRule(startAfterSave: true),
          ),
        ],
      ),
      right: Column(
        children: [
          if (_lastError != null) ...[
            _InlineNotice(message: _lastError!, isError: true),
            const SizedBox(height: 16),
          ],
          _TunnelListPanel(
            loading: _loading,
            rules: _rules,
            snapshots: _snapshots,
            startingRuleIds: _startingRuleIds,
            detection: _detection,
            onStart: (rule) => _startRule(rule, notify: true),
            onStop: (rule) => _service.stopTunnel(rule.id),
            onDelete: _deleteRule,
            onTcpPing: _tcpPingRule,
            onToggleAutoStart: _toggleRuleAutoStart,
          ),
          const SizedBox(height: 16),
          const _UdpTestingPanel(),
        ],
      ),
    );
  }

  Future<void> _loadInitialState() async {
    final repository = ref.read(natTraversalRepositoryProvider);
    try {
      final configFuture = repository.loadConfig();
      final rulesFuture = repository.loadRules();
      final config = await configFuture;
      final rules = await rulesFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _rules = rules;
        _targetAddress = _addresses.firstOrNull?.address ?? '127.0.0.1';
        _loading = false;
      });
      await _service.registerSavedRules(rules);
      unawaited(_loadLocalAddresses());
      _schedulePortRefresh();
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _lastError = '读取 NAT 穿透配置失败：$error';
        });
      }
    }
  }

  Future<void> _loadLocalAddresses() async {
    try {
      final addresses = await _service.listLocalAddresses();
      if (!mounted) {
        return;
      }
      setState(() {
        _addresses = addresses.isEmpty ? _defaultLocalAddresses : addresses;
        if (!_addresses.any((item) => item.address == _targetAddress)) {
          _targetAddress = _addresses.firstOrNull?.address ?? '127.0.0.1';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '读取本机网络地址失败：$error');
      }
    }
  }

  void _schedulePortRefresh() {
    _deferredPortRefreshTimer?.cancel();
    _deferredPortRefreshTimer = Timer(const Duration(milliseconds: 350), () {
      _deferredPortRefreshTimer = null;
      if (mounted) {
        unawaited(_refreshPorts());
      }
    });
  }

  Future<void> _detectNat() async {
    setState(() {
      _detecting = true;
      _lastError = null;
    });
    try {
      final config = await ref
          .read(natTraversalRepositoryProvider)
          .loadConfig();
      final detection = await _service.detectNat(config);
      if (mounted) {
        setState(() {
          _config = config;
          _detection = detection;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = 'NAT 检测失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _detecting = false);
      }
    }
  }

  Future<void> _refreshPorts() async {
    if (_refreshingPorts) {
      return;
    }
    setState(() => _refreshingPorts = true);
    try {
      final ports = await _service.listOpenPorts();
      if (mounted) {
        setState(() => _ports = ports);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '刷新本机端口失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingPorts = false);
      }
    }
  }

  void _applyPortCandidate(NatPortCandidate candidate) {
    setState(() {
      _protocol = candidate.protocol;
      _targetPortController.text = candidate.localPort.toString();
      if (candidate.localAddress != '0.0.0.0' &&
          candidate.localAddress != '::') {
        _targetAddress = candidate.localAddress;
      }
      if (_labelController.text.trim().isEmpty) {
        _labelController.text =
            '${candidate.protocol.label} ${candidate.processName ?? '本机服务'}';
      }
    });
  }

  Future<void> _saveRule({required bool startAfterSave}) async {
    final port = int.tryParse(_targetPortController.text.trim());
    if (port == null || port <= 0 || port > 65535) {
      _showMessage('请输入 1-65535 范围内的本地端口。');
      return;
    }
    final remotePortText = _remotePortController.text.trim();
    final remotePort = remotePortText.isEmpty
        ? null
        : int.tryParse(remotePortText);
    if (remotePortText.isNotEmpty &&
        (remotePort == null || remotePort <= 0 || remotePort > 65535)) {
      _showMessage('远端端口需要是 1-65535 范围内的数字。');
      return;
    }
    setState(() {
      _savingRule = true;
      _lastError = null;
    });
    try {
      final repository = ref.read(natTraversalRepositoryProvider);
      final rule = await repository.addRule(
        protocol: _protocol,
        targetAddress: _targetAddress,
        targetPort: port,
        label: _labelController.text,
        remoteHost: _remoteHostController.text,
        remotePort: remotePort,
      );
      final rules = await repository.loadRules();
      if (!mounted) {
        return;
      }
      setState(() {
        _rules = rules;
        _labelController.clear();
        _targetPortController.clear();
        _remoteHostController.clear();
        _remotePortController.clear();
      });
      await _service.registerSavedRules(rules);
      if (startAfterSave) {
        await _startRule(rule, notify: true);
      } else {
        _showMessage('打洞规则已保存');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '保存打洞规则失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _savingRule = false);
      }
    }
  }

  Future<void> _startRule(NatTunnelRule rule, {bool notify = false}) async {
    if (_startingRuleIds.contains(rule.id)) {
      return;
    }
    setState(() {
      _lastError = null;
      _startingRuleIds = {..._startingRuleIds, rule.id};
      _snapshots = {
        ..._snapshots,
        rule.id: (_snapshots[rule.id] ?? NatTunnelSnapshot.saved(rule))
            .copyWith(
              status: NatTunnelStatus.starting,
              message: '正在建立 ${rule.protocol.label} 打洞转发...',
            ),
      };
    });
    try {
      final config = await ref
          .read(natTraversalRepositoryProvider)
          .loadConfig();
      if (mounted) {
        setState(() => _config = config);
      }
      final snapshot = await _service.startTunnel(rule, config);
      if (!mounted) {
        return;
      }
      setState(() => _snapshots = _service.currentSnapshots);
      if (notify) {
        _showMessage(snapshot.message);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = '启动打洞规则失败：$error';
      setState(() => _lastError = message);
      if (notify) {
        _showMessage(message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _startingRuleIds = {
            for (final id in _startingRuleIds)
              if (id != rule.id) id,
          };
        });
      }
    }
  }

  Future<void> _deleteRule(NatTunnelRule rule) async {
    final repository = ref.read(natTraversalRepositoryProvider);
    await repository.removeRule(rule.id);
    await _service.removeTunnel(rule.id);
    final rules = await repository.loadRules();
    if (mounted) {
      setState(() => _rules = rules);
    }
  }

  Future<void> _toggleRuleAutoStart(NatTunnelRule rule) async {
    final repository = ref.read(natTraversalRepositoryProvider);
    try {
      await repository.updateRule(rule.copyWith(enabled: !rule.enabled));
      final rules = await repository.loadRules();
      if (!mounted) {
        return;
      }
      setState(() => _rules = rules);
      await _service.registerSavedRules(rules);
      _showMessage(rule.enabled ? '已关闭启动后自动打洞' : '已开启启动后自动打洞');
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '更新自动打洞设置失败：$error');
      }
    }
  }

  Future<void> _tcpPingRule(NatTunnelRule rule) async {
    final check = await _service.tcpPingTunnel(rule.id);
    if (mounted) {
      _showMessage(check.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showLatestSnackMessage(message);
  }
}

const List<NatLocalAddress> _defaultLocalAddresses = [
  NatLocalAddress(address: '127.0.0.1', label: '127.0.0.1 · 本机回环'),
  NatLocalAddress(address: '0.0.0.0', label: '0.0.0.0 · 本机所有 IPv4'),
];

class _DetectionPanel extends StatelessWidget {
  const _DetectionPanel({
    required this.detection,
    required this.detecting,
    required this.config,
    required this.onDetect,
  });

  final NatDetectionSummary? detection;
  final bool detecting;
  final NatTraversalConfig config;
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'NAT 类型检测',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前配置了 ${config.stunServers.length} 个 STUN 服务器。检测会并行测试列表，分别选出 UDP NAT 检测和 TCP STUN 探测延迟最低的可用服务器。',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: detecting ? null : onDetect,
            icon: detecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar_outlined),
            label: Text(detecting ? '检测中...' : '检测当前 NAT'),
          ),
          if (detection != null) ...[
            const SizedBox(height: 16),
            _DetectionResultCard(detection: detection!),
          ],
        ],
      ),
    );
  }
}

class _DetectionResultCard extends StatelessWidget {
  const _DetectionResultCard({required this.detection});

  final NatDetectionSummary detection;

  @override
  Widget build(BuildContext context) {
    final color = switch (detection.supportLevel) {
      NatSupportLevel.supported => AppColors.good,
      NatSupportLevel.limited => AppColors.accent,
      NatSupportLevel.unsupported => AppColors.bad,
      NatSupportLevel.unknown => AppColors.muted,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.hub_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detection.natType,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(label: '已选 UDP STUN', value: detection.udpSelectionLabel),
          _InfoLine(label: '公网映射', value: detection.publicEndpoint),
          _InfoLine(label: '过滤行为', value: detection.filteringBehavior),
          _InfoLine(label: '映射行为', value: detection.mappingBehavior),
          _InfoLine(label: '已选 TCP STUN', value: detection.tcpSelectionLabel),
          _InfoLine(
            label: 'TCP STUN',
            value: detection.tcpStunReachable ? '可达' : '不可达',
          ),
          _InfoLine(label: 'TCP 公网端点', value: detection.tcpPublicEndpoint),
          _InfoLine(
            label: 'RFC 5780',
            value: detection.rfc5780Supported ? '支持' : '未发现完整支持',
          ),
          if (detection.alternateServer != null)
            _InfoLine(label: '备用测试端', value: detection.alternateServer!),
          const SizedBox(height: 8),
          Text(
            detection.message,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            detection.tcpStunMessage,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RuleFormPanel extends StatelessWidget {
  const _RuleFormPanel({
    required this.protocol,
    required this.targetAddress,
    required this.addresses,
    required this.ports,
    required this.loadingPorts,
    required this.labelController,
    required this.targetPortController,
    required this.remoteHostController,
    required this.remotePortController,
    required this.saving,
    required this.canAttemptUdp,
    required this.onProtocolChanged,
    required this.onAddressChanged,
    required this.onPortSelected,
    required this.onRefreshPorts,
    required this.onSaveOnly,
    required this.onSaveAndStart,
  });

  final NatTunnelProtocol protocol;
  final String targetAddress;
  final List<NatLocalAddress> addresses;
  final List<NatPortCandidate> ports;
  final bool loadingPorts;
  final TextEditingController labelController;
  final TextEditingController targetPortController;
  final TextEditingController remoteHostController;
  final TextEditingController remotePortController;
  final bool saving;
  final bool canAttemptUdp;
  final ValueChanged<NatTunnelProtocol> onProtocolChanged;
  final ValueChanged<String> onAddressChanged;
  final ValueChanged<NatPortCandidate> onPortSelected;
  final VoidCallback onRefreshPorts;
  final VoidCallback onSaveOnly;
  final VoidCallback onSaveAndStart;

  @override
  Widget build(BuildContext context) {
    final protocolPorts = ports
        .where((candidate) => candidate.protocol == protocol)
        .toList();
    final canSave =
        !saving && (protocol != NatTunnelProtocol.udp || canAttemptUdp);
    return AppPanel(
      title: '添加打洞转发',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<NatTunnelProtocol>(
            segments: const [
              ButtonSegment(
                value: NatTunnelProtocol.tcp,
                label: Text('TCP'),
                icon: Icon(Icons.cable_outlined),
              ),
              ButtonSegment(
                value: NatTunnelProtocol.udp,
                label: Text('UDP'),
                icon: Icon(Icons.swap_calls_outlined),
              ),
            ],
            selected: {protocol},
            onSelectionChanged: (values) => onProtocolChanged(values.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: labelController,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: addresses.any((item) => item.address == targetAddress)
                ? targetAddress
                : null,
            decoration: const InputDecoration(labelText: '本地网络地址'),
            items: [
              for (final address in addresses)
                DropdownMenuItem(
                  value: address.address,
                  child: Text(address.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onAddressChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NatPortCandidate>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: '进程开放端口'),
            items: [
              for (final candidate in protocolPorts.take(80))
                DropdownMenuItem(
                  value: candidate,
                  child: Text(candidate.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onPortSelected(value);
              }
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: loadingPorts ? null : onRefreshPorts,
              icon: loadingPorts
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(loadingPorts ? '刷新中' : '刷新端口'),
            ),
          ),
          TextField(
            controller: targetPortController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '本地端口'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: remoteHostController,
            decoration: const InputDecoration(labelText: '远端公网地址（可选）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: remotePortController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '远端端口（可选）'),
          ),
          const SizedBox(height: 12),
          _InlineNotice(
            message: protocol == NatTunnelProtocol.udp
                ? 'UDP 会创建本机公网映射端口，并把收到的数据转发到所选本地地址和端口。受限 NAT 需要填写远端地址做预打洞。'
                : 'TCP 使用内置 full-cone NAT 映射：同端口 HTTP 保活、TCP STUN 获取公网端点，并监听映射端口转发到本地服务。',
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: canSave ? onSaveOnly : null,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? '保存中...' : '保存'),
                ),
                FilledButton.icon(
                  onPressed: canSave ? onSaveAndStart : null,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(saving ? '保存中...' : '保存并启动'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TunnelListPanel extends StatelessWidget {
  const _TunnelListPanel({
    required this.loading,
    required this.rules,
    required this.snapshots,
    required this.startingRuleIds,
    required this.detection,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
    required this.onTcpPing,
    required this.onToggleAutoStart,
  });

  final bool loading;
  final List<NatTunnelRule> rules;
  final Map<String, NatTunnelSnapshot> snapshots;
  final Set<String> startingRuleIds;
  final NatDetectionSummary? detection;
  final ValueChanged<NatTunnelRule> onStart;
  final ValueChanged<NatTunnelRule> onStop;
  final ValueChanged<NatTunnelRule> onDelete;
  final ValueChanged<NatTunnelRule> onTcpPing;
  final ValueChanged<NatTunnelRule> onToggleAutoStart;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '打洞列表',
      trailing: _SupportPill(detection: detection),
      child: loading
          ? const LinearProgressIndicator()
          : rules.isEmpty
          ? const EmptyState(
              icon: Icons.route_outlined,
              title: '还没有转发规则',
              message: '先检测 NAT，再添加要暴露的本地网络和端口。',
            )
          : Column(
              children: [
                for (final rule in rules) ...[
                  _TunnelRuleTile(
                    rule: rule,
                    snapshot:
                        snapshots[rule.id] ?? NatTunnelSnapshot.saved(rule),
                    startingRequested: startingRuleIds.contains(rule.id),
                    onStart: () => onStart(rule),
                    onStop: () => onStop(rule),
                    onDelete: () => onDelete(rule),
                    onTcpPing: () => onTcpPing(rule),
                    onToggleAutoStart: () => onToggleAutoStart(rule),
                  ),
                  if (rule != rules.last) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _TunnelRuleTile extends StatelessWidget {
  const _TunnelRuleTile({
    required this.rule,
    required this.snapshot,
    required this.startingRequested,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
    required this.onTcpPing,
    required this.onToggleAutoStart,
  });

  final NatTunnelRule rule;
  final NatTunnelSnapshot snapshot;
  final bool startingRequested;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDelete;
  final VoidCallback onTcpPing;
  final VoidCallback onToggleAutoStart;

  @override
  Widget build(BuildContext context) {
    final active = snapshot.status == NatTunnelStatus.active;
    final starting =
        snapshot.status == NatTunnelStatus.starting || startingRequested;
    final statusColor = switch (snapshot.status) {
      NatTunnelStatus.active => AppColors.good,
      NatTunnelStatus.warning => AppColors.accent,
      NatTunnelStatus.failed => AppColors.bad,
      NatTunnelStatus.starting => AppColors.accent,
      NatTunnelStatus.saved || NatTunnelStatus.stopped => AppColors.muted,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.alt_route_outlined, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rule.protocol.label} ${rule.targetAddress}:${rule.targetPort}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              _TinyPill(text: _statusText(snapshot.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _MiniMetric(
                label: '公网端点',
                value: snapshot.publicEndpoint,
                copyValue: snapshot.publicIp == null
                    ? null
                    : snapshot.publicEndpoint,
              ),
              _MiniMetric(
                label: '本地绑定',
                value: snapshot.localBindPort == null
                    ? '未绑定'
                    : '0.0.0.0:${snapshot.localBindPort}',
                copyValue: snapshot.localBindPort == null
                    ? null
                    : '0.0.0.0:${snapshot.localBindPort}',
              ),
              _MiniMetric(label: '入站字节', value: '${snapshot.bytesFromRemote}'),
              _MiniMetric(label: '出站字节', value: '${snapshot.bytesToRemote}'),
              if (snapshot.lastRemoteEndpoint != null)
                _MiniMetric(label: '最近远端', value: snapshot.lastRemoteEndpoint!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            snapshot.message,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          if (snapshot.tcpCheck != null) ...[
            const SizedBox(height: 6),
            Text(
              snapshot.tcpCheck!.message,
              style: TextStyle(
                color: snapshot.tcpCheck!.success
                    ? AppColors.good
                    : AppColors.bad,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onToggleAutoStart,
                icon: Icon(rule.enabled ? Icons.toggle_on : Icons.toggle_off),
                label: Text(rule.enabled ? '自动打洞：开' : '自动打洞：关'),
              ),
              OutlinedButton.icon(
                onPressed: starting ? null : onStart,
                icon: starting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(starting ? '启动中...' : (active ? '重启' : '启动')),
              ),
              OutlinedButton.icon(
                onPressed: active || starting ? onStop : null,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.publicIp == null ? null : onTcpPing,
                icon: const Icon(Icons.network_ping_outlined),
                label: const Text('TCPing'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText(NatTunnelStatus status) {
    return switch (status) {
      NatTunnelStatus.saved => '已保存',
      NatTunnelStatus.starting => '启动中',
      NatTunnelStatus.active => '运行中',
      NatTunnelStatus.warning => '受限',
      NatTunnelStatus.failed => '失败',
      NatTunnelStatus.stopped => '已停止',
    };
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({required this.detection});

  final NatDetectionSummary? detection;

  @override
  Widget build(BuildContext context) {
    final level = detection?.supportLevel;
    final text = switch (level) {
      NatSupportLevel.supported => '可尝试 UDP',
      NatSupportLevel.limited => '严格 NAT',
      NatSupportLevel.unsupported => 'UDP 不可用',
      NatSupportLevel.unknown => '未知',
      null => '未检测',
    };
    final color = switch (level) {
      NatSupportLevel.supported => AppColors.good,
      NatSupportLevel.limited => AppColors.accent,
      NatSupportLevel.unsupported => AppColors.bad,
      NatSupportLevel.unknown || null => AppColors.muted,
    };
    return _TinyPill(text: text, color: color);
  }
}

class _UdpTestingPanel extends StatelessWidget {
  const _UdpTestingPanel();

  @override
  Widget build(BuildContext context) {
    return const AppPanel(
      title: '连通性测试',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '流程完成后可以对公网端点执行 TCPing；若端点来自 UDP 映射，TCPing 失败是正常结果，因为 UDP 没有 TCP 握手。',
            style: TextStyle(color: AppColors.muted),
          ),
          SizedBox(height: 10),
          _InlineNotice(
            message:
                'UDP 建议用对端或 VPS 自测：ncat/nc -u 监听与发送、nping --udp、iperf3 -u，或抓包确认是否收到双向 UDP 包。没有可靠的单端 UDP ping 可证明公网可达。',
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, this.copyValue});

  final String label;
  final String value;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final copyText = copyValue;
    final valueWidget = copyText == null
        ? Text(value, overflow: TextOverflow.ellipsis)
        : Tooltip(
            message: '点击复制',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: copyText));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showLatestSnackMessage('已复制$label：$copyText');
                },
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accent,
                  ),
                ),
              ),
            ),
          );
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          valueWidget,
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: isError ? AppColors.bad : AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
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
    );
  }
}

class _NatResponsiveGrid extends StatelessWidget {
  const _NatResponsiveGrid({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1040) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 420, child: left),
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
