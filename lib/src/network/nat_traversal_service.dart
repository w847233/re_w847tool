import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stun/stun.dart' as stun;

import 'native_tcp_port_mapper.dart';
import 'nat_traversal_models.dart';
import 'nat_traversal_repository.dart';

final natTraversalServiceProvider = Provider<NatTraversalService>((ref) {
  final service = NatTraversalService();
  ref.onDispose(service.dispose);
  return service;
});

final natTraversalStartupProvider = Provider<void>((ref) {
  unawaited(_bootstrapNatTraversal(ref));
  return;
});

Future<void> _bootstrapNatTraversal(Ref ref) async {
  try {
    final repository = ref.read(natTraversalRepositoryProvider);
    final service = ref.read(natTraversalServiceProvider);
    final rules = await repository.loadRules();
    final config = await repository.loadConfig();
    await service.registerSavedRules(rules);
    await service.startEnabledRules(rules, config);
  } catch (error, stackTrace) {
    // 启动阶段的自动打洞失败不阻塞主界面，保留到手动启动时再提示。
    stderr.writeln('NAT 启动阶段自动打洞失败：$error');
    stderr.writeln(stackTrace);
  }
}

class NatTraversalService {
  final _activeTunnels = <String, _ActiveTunnel>{};
  final _snapshots = <String, NatTunnelSnapshot>{};
  final _snapshotController =
      StreamController<Map<String, NatTunnelSnapshot>>.broadcast();

  Stream<Map<String, NatTunnelSnapshot>> get snapshots =>
      _snapshotController.stream;

  Map<String, NatTunnelSnapshot> get currentSnapshots =>
      Map.unmodifiable(_snapshots);

  Future<NatDetectionSummary> detectNat(NatTraversalConfig config) async {
    final endpoint = _parseServer(config.stunServer, 19302);
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final detector = stun.NATDetector(
        primaryServer: endpoint.host,
        primaryPort: endpoint.port,
        socket: socket,
        timeout: const Duration(seconds: 5),
      );
      final result = await detector.detectNATType();
      return _summarizeDetection(result);
    } finally {
      socket.close();
    }
  }

  Future<void> registerSavedRules(List<NatTunnelRule> rules) async {
    for (final rule in rules) {
      _snapshots.putIfAbsent(rule.id, () => NatTunnelSnapshot.saved(rule));
    }
    _emitSnapshots();
  }

  Future<void> startEnabledRules(
    List<NatTunnelRule> rules,
    NatTraversalConfig config,
  ) async {
    for (final rule in rules.where((rule) => rule.enabled)) {
      await startTunnel(rule, config);
    }
  }

  Future<NatTunnelSnapshot> startTunnel(
    NatTunnelRule rule,
    NatTraversalConfig config,
  ) async {
    await stopTunnel(rule.id);
    final starting = NatTunnelSnapshot(
      ruleId: rule.id,
      protocol: rule.protocol,
      status: NatTunnelStatus.starting,
      message: '正在建立 ${rule.protocol.label} 打洞转发...',
    );
    _setSnapshot(starting);

    try {
      final tunnel = switch (rule.protocol) {
        NatTunnelProtocol.udp => _UdpNatTunnel(
          rule: rule,
          config: config,
          onChanged: _setSnapshot,
        ),
        NatTunnelProtocol.tcp => _NativeTcpForwardTunnel(
          rule: rule,
          config: config,
          onChanged: _setSnapshot,
        ),
      };
      _activeTunnels[rule.id] = tunnel;
      final snapshot = await tunnel.start();
      _setSnapshot(snapshot);
      return snapshot;
    } catch (error) {
      _activeTunnels.remove(rule.id);
      final failed = starting.copyWith(
        status: NatTunnelStatus.failed,
        message: '启动失败：$error',
      );
      _setSnapshot(failed);
      return failed;
    }
  }

  Future<void> stopTunnel(String ruleId) async {
    final tunnel = _activeTunnels.remove(ruleId);
    await tunnel?.stop();
    final snapshot = _snapshots[ruleId];
    if (snapshot != null &&
        snapshot.status != NatTunnelStatus.saved &&
        snapshot.status != NatTunnelStatus.failed) {
      _setSnapshot(
        snapshot.copyWith(status: NatTunnelStatus.stopped, message: '已停止'),
      );
    }
  }

  Future<void> removeTunnel(String ruleId) async {
    await stopTunnel(ruleId);
    _snapshots.remove(ruleId);
    _emitSnapshots();
  }

  Future<NatConnectivityCheck> tcpPing(String host, int port) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      stopwatch.stop();
      return NatConnectivityCheck(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: 'TCPing 成功，耗时 ${stopwatch.elapsedMilliseconds} ms',
      );
    } catch (error) {
      stopwatch.stop();
      return NatConnectivityCheck(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: 'TCPing 未返回：$error',
      );
    }
  }

  Future<NatConnectivityCheck> tcpPingTunnel(String ruleId) async {
    final snapshot = _snapshots[ruleId];
    if (snapshot?.publicIp == null || snapshot?.publicPort == null) {
      return const NatConnectivityCheck(
        success: false,
        message: '该转发没有可用于 TCPing 的公网 TCP 端点',
      );
    }
    final check = await tcpPing(snapshot!.publicIp!, snapshot.publicPort!);
    _setSnapshot(snapshot.copyWith(tcpCheck: check));
    return check;
  }

  Future<List<NatLocalAddress>> listLocalAddresses() async {
    final addresses = <String, NatLocalAddress>{
      '127.0.0.1': const NatLocalAddress(
        address: '127.0.0.1',
        label: '127.0.0.1 · 本机回环',
      ),
      '0.0.0.0': const NatLocalAddress(
        address: '0.0.0.0',
        label: '0.0.0.0 · 本机所有 IPv4',
      ),
    };

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final adapter in interfaces) {
        for (final address in adapter.addresses) {
          addresses.putIfAbsent(
            address.address,
            () => NatLocalAddress(
              address: address.address,
              label: '${address.address} · ${adapter.name}',
            ),
          );
        }
      }
    } catch (_) {}

    return addresses.values.toList();
  }

  Future<List<NatPortCandidate>> listOpenPorts() async {
    final ports = await Isolate.run<List<Map<String, Object?>>>(
      _listOpenPortDataOnWorker,
    );
    return ports.map(_portCandidateFromData).toList(growable: false);
  }

  void _setSnapshot(NatTunnelSnapshot snapshot) {
    _snapshots[snapshot.ruleId] = snapshot;
    _emitSnapshots();
  }

  void _emitSnapshots() {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(Map.unmodifiable(_snapshots));
    }
  }

  Future<void> dispose() async {
    for (final tunnel in _activeTunnels.values.toList()) {
      await tunnel.stop();
    }
    _activeTunnels.clear();
    await _snapshotController.close();
  }
}

List<Map<String, Object?>> _listOpenPortDataOnWorker() {
  if (Platform.isWindows) {
    return _listWindowsOpenPortData();
  }
  return _listPosixOpenPortData();
}

List<Map<String, Object?>> _listWindowsOpenPortData() {
  final processNames = _loadWindowsProcessNameData();
  final results = <Map<String, Object?>>[];
  for (final protocol in NatTunnelProtocol.values) {
    final process = Process.runSync('netstat', ['-ano', '-p', protocol.name]);
    if (process.exitCode != 0) {
      continue;
    }
    final lines = '${process.stdout}'.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.toUpperCase().startsWith(protocol.name.toUpperCase())) {
        continue;
      }
      final parts = trimmed.split(RegExp(r'\s+'));
      if (protocol == NatTunnelProtocol.tcp) {
        if (parts.length < 5 || parts[3].toUpperCase() != 'LISTENING') {
          continue;
        }
        final port = _parseEndpointPort(parts[1]);
        final pid = int.tryParse(parts[4]);
        if (port == null) {
          continue;
        }
        results.add(
          _portCandidateData(
            protocol: protocol,
            localAddress: _parseEndpointAddress(parts[1]),
            localPort: port,
            processId: pid,
            processName: pid == null ? null : processNames[pid],
          ),
        );
      } else {
        if (parts.length < 3) {
          continue;
        }
        final port = _parseEndpointPort(parts[1]);
        final pid = int.tryParse(parts.last);
        if (port == null) {
          continue;
        }
        results.add(
          _portCandidateData(
            protocol: protocol,
            localAddress: _parseEndpointAddress(parts[1]),
            localPort: port,
            processId: pid,
            processName: pid == null ? null : processNames[pid],
          ),
        );
      }
    }
  }
  return _dedupePortData(results);
}

List<Map<String, Object?>> _listPosixOpenPortData() {
  try {
    final process = Process.runSync('lsof', ['-nP', '-iTCP', '-iUDP']);
    if (process.exitCode != 0) {
      return const <Map<String, Object?>>[];
    }
    final results = <Map<String, Object?>>[];
    for (final line in '${process.stdout}'.split(RegExp(r'\r?\n')).skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.contains('LISTEN')) {
        continue;
      }
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 9) {
        continue;
      }
      final endpoint = parts[8];
      final protocol = endpoint.toUpperCase().contains('UDP')
          ? NatTunnelProtocol.udp
          : NatTunnelProtocol.tcp;
      final port = _parseEndpointPort(endpoint);
      if (port == null) {
        continue;
      }
      results.add(
        _portCandidateData(
          protocol: protocol,
          localAddress: _parseEndpointAddress(endpoint),
          localPort: port,
          processId: int.tryParse(parts[1]),
          processName: parts[0],
        ),
      );
    }
    return _dedupePortData(results);
  } catch (_) {
    return const <Map<String, Object?>>[];
  }
}

Map<int, String> _loadWindowsProcessNameData() {
  try {
    final result = Process.runSync('tasklist', ['/fo', 'csv', '/nh']);
    if (result.exitCode != 0) {
      return const <int, String>{};
    }
    final names = <int, String>{};
    for (final line in '${result.stdout}'.split(RegExp(r'\r?\n'))) {
      final columns = _parseCsvLine(line);
      if (columns.length < 2) {
        continue;
      }
      final pid = int.tryParse(columns[1]);
      if (pid != null) {
        names[pid] = columns[0];
      }
    }
    return names;
  } catch (_) {
    return const <int, String>{};
  }
}

Map<String, Object?> _portCandidateData({
  required NatTunnelProtocol protocol,
  required String localAddress,
  required int localPort,
  int? processId,
  String? processName,
}) {
  return <String, Object?>{
    'protocol': protocol.name,
    'localAddress': localAddress,
    'localPort': localPort,
    'processId': processId,
    'processName': processName,
  };
}

NatPortCandidate _portCandidateFromData(Map<String, Object?> data) {
  final protocolName = data['protocol'] as String?;
  final protocol = NatTunnelProtocol.values.firstWhere(
    (value) => value.name == protocolName,
    orElse: () => NatTunnelProtocol.tcp,
  );
  return NatPortCandidate(
    protocol: protocol,
    localAddress: data['localAddress'] as String? ?? '0.0.0.0',
    localPort: data['localPort'] as int? ?? 0,
    processId: data['processId'] as int?,
    processName: data['processName'] as String?,
  );
}

List<Map<String, Object?>> _dedupePortData(List<Map<String, Object?>> ports) {
  final byKey = <String, Map<String, Object?>>{};
  for (final port in ports) {
    byKey.putIfAbsent(
      '${port['protocol']}:${port['localAddress']}:${port['localPort']}:${port['processId']}',
      () => port,
    );
  }
  final values = byKey.values.toList();
  values.sort((left, right) {
    final protocolCompare = _protocolSortIndex(
      left['protocol'] as String?,
    ).compareTo(_protocolSortIndex(right['protocol'] as String?));
    if (protocolCompare != 0) {
      return protocolCompare;
    }
    return (left['localPort'] as int? ?? 0).compareTo(
      right['localPort'] as int? ?? 0,
    );
  });
  return values;
}

int _protocolSortIndex(String? protocolName) {
  final index = NatTunnelProtocol.values.indexWhere(
    (value) => value.name == protocolName,
  );
  return index < 0 ? NatTunnelProtocol.values.length : index;
}

abstract class _ActiveTunnel {
  Future<NatTunnelSnapshot> start();

  Future<void> stop();
}

class _UdpNatTunnel implements _ActiveTunnel {
  _UdpNatTunnel({
    required this.rule,
    required this.config,
    required this.onChanged,
  });

  final NatTunnelRule rule;
  final NatTraversalConfig config;
  final ValueChangedSnapshot onChanged;

  RawDatagramSocket? _publicSocket;
  RawDatagramSocket? _localSocket;
  StreamSubscription<RawSocketEvent>? _publicSubscription;
  StreamSubscription<RawSocketEvent>? _localSubscription;
  Timer? _keepAliveTimer;
  InternetAddress? _lastRemoteAddress;
  int? _lastRemotePort;
  int _bytesFromRemote = 0;
  int _bytesToRemote = 0;
  NatTunnelSnapshot? _snapshot;

  @override
  Future<NatTunnelSnapshot> start() async {
    final stunEndpoint = _parseServer(config.stunServer, 19302);
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.readEventsEnabled = true;
    _publicSocket = socket;
    final publicEvents = socket.asBroadcastStream();
    final publicEndpoint = await _performStunBinding(
      socket: socket,
      events: publicEvents,
      stunEndpoint: stunEndpoint,
      timeout: const Duration(seconds: 5),
    );

    _localSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _localSubscription = _localSocket!.listen(_handleLocalEvent);
    _publicSubscription = publicEvents.listen(_handlePublicEvent);
    _startKeepAlive(stunEndpoint);

    final remoteText = rule.hasRemotePeer
        ? '，已向 ${rule.remoteHost}:${rule.remotePort} 发送保活包'
        : '，等待远端先完成对端打洞或来自 Full Cone NAT 的入站包';
    _snapshot = NatTunnelSnapshot(
      ruleId: rule.id,
      protocol: rule.protocol,
      status: NatTunnelStatus.active,
      publicIp: publicEndpoint.ip,
      publicPort: publicEndpoint.port,
      localBindPort: socket.port,
      message:
          'UDP 映射已建立：${publicEndpoint.ip}:${publicEndpoint.port} -> ${rule.targetAddress}:${rule.targetPort}$remoteText',
    );
    return _snapshot!;
  }

  void _handlePublicEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final socket = _publicSocket;
    final localSocket = _localSocket;
    if (socket == null || localSocket == null) {
      return;
    }
    while (true) {
      final datagram = socket.receive();
      if (datagram == null) {
        break;
      }
      if (_looksLikeStun(datagram.data)) {
        continue;
      }
      _lastRemoteAddress = datagram.address;
      _lastRemotePort = datagram.port;
      final targetAddress = InternetAddress.tryParse(
        _resolveTargetAddress(rule.targetAddress),
      );
      if (targetAddress == null) {
        _markFailed('本地目标地址无效：${rule.targetAddress}');
        return;
      }
      localSocket.send(datagram.data, targetAddress, rule.targetPort);
      _bytesFromRemote += datagram.data.length;
      _updateSnapshot(
        lastRemoteEndpoint: '${datagram.address.address}:${datagram.port}',
      );
    }
  }

  void _handleLocalEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final publicSocket = _publicSocket;
    final localSocket = _localSocket;
    final remoteAddress = _lastRemoteAddress;
    final remotePort = _lastRemotePort;
    if (publicSocket == null ||
        localSocket == null ||
        remoteAddress == null ||
        remotePort == null) {
      return;
    }
    while (true) {
      final datagram = localSocket.receive();
      if (datagram == null) {
        break;
      }
      publicSocket.send(datagram.data, remoteAddress, remotePort);
      _bytesToRemote += datagram.data.length;
      _updateSnapshot();
    }
  }

  void _startKeepAlive(_ServerEndpoint stunEndpoint) {
    final socket = _publicSocket;
    if (socket == null) {
      return;
    }
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        final stunAddresses = await InternetAddress.lookup(
          stunEndpoint.host,
          type: InternetAddressType.IPv4,
        );
        if (stunAddresses.isNotEmpty) {
          socket.send(
            _buildStunBindingRequest(_randomTransactionId()),
            stunAddresses.first,
            stunEndpoint.port,
          );
        }
        if (rule.hasRemotePeer) {
          final remoteAddresses = await InternetAddress.lookup(
            rule.remoteHost,
            type: InternetAddressType.IPv4,
          );
          if (remoteAddresses.isNotEmpty) {
            socket.send([0], remoteAddresses.first, rule.remotePort!);
          }
        }
      } catch (_) {}
    });
  }

  void _updateSnapshot({String? lastRemoteEndpoint}) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    _snapshot = snapshot.copyWith(
      bytesFromRemote: _bytesFromRemote,
      bytesToRemote: _bytesToRemote,
      lastRemoteEndpoint: lastRemoteEndpoint,
    );
    onChanged(_snapshot!);
  }

  void _markFailed(String message) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    _snapshot = snapshot.copyWith(
      status: NatTunnelStatus.failed,
      message: message,
    );
    onChanged(_snapshot!);
  }

  @override
  Future<void> stop() async {
    _keepAliveTimer?.cancel();
    await _publicSubscription?.cancel();
    await _localSubscription?.cancel();
    _publicSocket?.close();
    _localSocket?.close();
  }
}

class _NativeTcpForwardTunnel implements _ActiveTunnel {
  _NativeTcpForwardTunnel({
    required this.rule,
    required this.config,
    required this.onChanged,
  });

  final NatTunnelRule rule;
  final NatTraversalConfig config;
  final ValueChangedSnapshot onChanged;

  final NativeTcpPortMapper _mapper = NativeTcpPortMapper();
  NatTunnelSnapshot? _snapshot;

  @override
  Future<NatTunnelSnapshot> start() async {
    final tcpStunEndpoint = _parseServer(
      config.tcpStunServer,
      3478,
      fallback: NatTraversalConfig.defaultTcpStunServer,
    );
    final httpEndpoint = _parseServer(
      config.tcpKeepAliveServer,
      80,
      fallback: NatTraversalConfig.defaultTcpKeepAliveServer,
    );
    final targetAddress = _resolveTargetAddress(rule.targetAddress);

    _snapshot = NatTunnelSnapshot(
      ruleId: rule.id,
      protocol: rule.protocol,
      status: NatTunnelStatus.starting,
      message:
          '正在建立内置 TCP full-cone 映射：$targetAddress:${rule.targetPort}，TCP STUN ${tcpStunEndpoint.host}:${tcpStunEndpoint.port}',
    );
    onChanged(_snapshot!);

    try {
      final result = await _mapper.startForward(
        ruleId: rule.id,
        stunHost: tcpStunEndpoint.host,
        stunPort: tcpStunEndpoint.port,
        httpHost: httpEndpoint.host,
        httpPort: httpEndpoint.port,
        targetHost: targetAddress,
        targetPort: rule.targetPort,
        keepAliveSeconds: 30,
      );
      _snapshot = NatTunnelSnapshot(
        ruleId: rule.id,
        protocol: rule.protocol,
        status: NatTunnelStatus.active,
        publicIp: result.publicIp,
        publicPort: result.publicPort,
        localBindPort: result.localBindPort,
        message:
            'TCP 映射已建立：${result.publicIp}:${result.publicPort} -> $targetAddress:${rule.targetPort}。内置转发器正在监听本机 ${result.localBindPort} 端口。',
      );
      return _snapshot!;
    } on MissingPluginException {
      return NatTunnelSnapshot(
        ruleId: rule.id,
        protocol: rule.protocol,
        status: NatTunnelStatus.warning,
        message: '当前运行环境没有加载原生 TCP 映射模块。请在 Windows 或 Android 应用中使用该功能。',
      );
    } on PlatformException catch (error) {
      return NatTunnelSnapshot(
        ruleId: rule.id,
        protocol: rule.protocol,
        status: NatTunnelStatus.warning,
        message: _describeTcpMappingError(
          error.message ?? error.code,
          tcpStunEndpoint,
          httpEndpoint,
        ),
      );
    } catch (error) {
      return NatTunnelSnapshot(
        ruleId: rule.id,
        protocol: rule.protocol,
        status: NatTunnelStatus.failed,
        message: '内置 TCP 映射启动失败：$error',
      );
    }
  }

  @override
  Future<void> stop() async {
    await _mapper.stopForward(rule.id);
    final snapshot = _snapshot;
    if (snapshot != null) {
      _snapshot = snapshot.copyWith(
        status: NatTunnelStatus.stopped,
        message: '内置 TCP 映射已停止。',
      );
      onChanged(_snapshot!);
    }
  }
}

String _describeTcpMappingError(
  String rawMessage,
  _ServerEndpoint tcpStunEndpoint,
  _ServerEndpoint httpEndpoint,
) {
  final tcpStun = '${tcpStunEndpoint.host}:${tcpStunEndpoint.port}';
  final http = '${httpEndpoint.host}:${httpEndpoint.port}';
  if (rawMessage.startsWith('connect_tcp_stun_failed') ||
      rawMessage.startsWith('tcp_stun_response')) {
    return '内置 TCP 映射启动失败：无法通过 TCP 连接或读取 TCP STUN 服务器 $tcpStun。'
        'UDP NAT 检测成功不代表同一个 STUN 地址支持 TCP；请在设置中把 TCP STUN 服务器改为支持 TCP STUN 的地址，例如 ${NatTraversalConfig.defaultTcpStunServer} 或 stun.antisip.com:3478。'
        '原始错误：$rawMessage';
  }
  if (rawMessage.startsWith('connect_http_keepalive_failed')) {
    return '内置 TCP 映射启动失败：无法连接 TCP HTTP 保活服务器 $http。请在设置中换一个可 TCP 访问的 HTTP 地址。原始错误：$rawMessage';
  }
  if (rawMessage.startsWith('reuse_local_tcp_port_for_stun_failed') ||
      rawMessage.startsWith('bind_tcp_forward_listener_failed')) {
    return '内置 TCP 映射启动失败：系统没有允许同一本地 TCP 端口复用。请确认当前平台、防火墙和安全软件允许端口复用。原始错误：$rawMessage';
  }
  return '内置 TCP 映射启动失败：$rawMessage';
}

typedef ValueChangedSnapshot = void Function(NatTunnelSnapshot snapshot);

class _ServerEndpoint {
  const _ServerEndpoint({required this.host, required this.port});

  final String host;
  final int port;
}

class _PublicEndpoint {
  const _PublicEndpoint({required this.ip, required this.port});

  final String ip;
  final int port;
}

NatDetectionSummary _summarizeDetection(stun.NATDetectionResult result) {
  final level = switch (result.natType) {
    stun.NATType.openInternet ||
    stun.NATType.fullCone ||
    stun.NATType.restrictedCone ||
    stun.NATType.portRestrictedCone => NatSupportLevel.supported,
    stun.NATType.symmetric ||
    stun.NATType.symmetricFirewall => NatSupportLevel.limited,
    stun.NATType.udpBlocked => NatSupportLevel.unsupported,
  };
  final message = switch (level) {
    NatSupportLevel.supported => '当前 NAT 支持或较适合 UDP 打洞，可添加 UDP 转发规则。',
    NatSupportLevel.limited => '当前 NAT 较严格，UDP 打洞可能只对少量对端成功，建议配置 TURN 中继兜底。',
    NatSupportLevel.unsupported => '当前网络看起来阻断 UDP，STUN/UDP 打洞不可用。',
    NatSupportLevel.unknown => '未能确认 NAT 行为。',
  };
  final alternate = result.alternateIp == null || result.alternatePort == null
      ? null
      : '${result.alternateIp}:${result.alternatePort}';
  return NatDetectionSummary(
    checkedAt: DateTime.now(),
    natType: result.natType.displayName,
    filteringBehavior: result.filteringBehavior.displayName,
    mappingBehavior: result.mappingBehavior.displayName,
    publicIp: result.publicIp,
    publicPort: result.publicPort,
    alternateServer: alternate,
    rfc5780Supported: result.rfc5780Supported,
    supportLevel: level,
    message: message,
  );
}

Future<_PublicEndpoint> _performStunBinding({
  required RawDatagramSocket socket,
  required Stream<RawSocketEvent> events,
  required _ServerEndpoint stunEndpoint,
  required Duration timeout,
}) async {
  final transactionId = _randomTransactionId();
  final request = _buildStunBindingRequest(transactionId);
  final addresses = await InternetAddress.lookup(
    stunEndpoint.host,
    type: InternetAddressType.IPv4,
  );
  if (addresses.isEmpty) {
    throw StateError('无法解析 STUN 服务器：${stunEndpoint.host}');
  }

  final completer = Completer<_PublicEndpoint>();
  late final StreamSubscription<RawSocketEvent> subscription;
  subscription = events.listen((event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    while (true) {
      final datagram = socket.receive();
      if (datagram == null) {
        break;
      }
      final endpoint = _parseStunBindingResponse(datagram.data, transactionId);
      if (endpoint != null && !completer.isCompleted) {
        completer.complete(endpoint);
        subscription.cancel();
        break;
      }
    }
  });

  socket.send(request, addresses.first, stunEndpoint.port);
  try {
    return await completer.future.timeout(timeout);
  } on TimeoutException {
    await subscription.cancel();
    throw TimeoutException('STUN 映射请求超时，请检查服务器地址或当前网络 UDP 出口。');
  }
}

Uint8List _randomTransactionId() {
  final random = Random.secure();
  return Uint8List.fromList(List<int>.generate(12, (_) => random.nextInt(256)));
}

Uint8List _buildStunBindingRequest(Uint8List transactionId) {
  final bytes = Uint8List(20);
  final view = ByteData.sublistView(bytes);
  view.setUint16(0, 0x0001);
  view.setUint16(2, 0);
  view.setUint32(4, 0x2112A442);
  bytes.setRange(8, 20, transactionId);
  return bytes;
}

_PublicEndpoint? _parseStunBindingResponse(
  Uint8List data,
  Uint8List transactionId,
) {
  if (data.length < 20) {
    return null;
  }
  final view = ByteData.sublistView(data);
  if (view.getUint16(0) != 0x0101 || view.getUint32(4) != 0x2112A442) {
    return null;
  }
  for (var index = 0; index < transactionId.length; index++) {
    if (data[8 + index] != transactionId[index]) {
      return null;
    }
  }

  final messageLength = view.getUint16(2);
  var offset = 20;
  final end = min(data.length, 20 + messageLength);
  while (offset + 4 <= end) {
    final type = view.getUint16(offset);
    final length = view.getUint16(offset + 2);
    final valueOffset = offset + 4;
    if (valueOffset + length > data.length) {
      return null;
    }
    if (type == 0x0020 || type == 0x0001) {
      final endpoint = _parseMappedAddress(
        data,
        valueOffset,
        length,
        xor: type == 0x0020,
        transactionId: transactionId,
      );
      if (endpoint != null) {
        return endpoint;
      }
    }
    offset = valueOffset + ((length + 3) & ~3);
  }
  return null;
}

_PublicEndpoint? _parseMappedAddress(
  Uint8List data,
  int offset,
  int length, {
  required bool xor,
  required Uint8List transactionId,
}) {
  if (length < 8 || offset + length > data.length) {
    return null;
  }
  final view = ByteData.sublistView(data);
  final family = data[offset + 1];
  var port = view.getUint16(offset + 2);
  if (xor) {
    port = port ^ 0x2112;
  }

  if (family == 0x01) {
    final raw = data.sublist(offset + 4, offset + 8);
    if (xor) {
      final cookie = ByteData(4)..setUint32(0, 0x2112A442);
      for (var index = 0; index < raw.length; index++) {
        raw[index] = raw[index] ^ cookie.getUint8(index);
      }
    }
    return _PublicEndpoint(
      ip: InternetAddress.fromRawAddress(raw).address,
      port: port,
    );
  }

  if (family == 0x02 && length >= 20) {
    final raw = data.sublist(offset + 4, offset + 20);
    if (xor) {
      final mask = Uint8List(16);
      final cookie = ByteData(4)..setUint32(0, 0x2112A442);
      for (var index = 0; index < 4; index++) {
        mask[index] = cookie.getUint8(index);
      }
      mask.setRange(4, 16, transactionId);
      for (var index = 0; index < raw.length; index++) {
        raw[index] = raw[index] ^ mask[index];
      }
    }
    return _PublicEndpoint(
      ip: InternetAddress.fromRawAddress(raw).address,
      port: port,
    );
  }
  return null;
}

bool _looksLikeStun(Uint8List data) {
  if (data.length < 20) {
    return false;
  }
  final view = ByteData.sublistView(data);
  return view.getUint32(4) == 0x2112A442;
}

_ServerEndpoint _parseServer(
  String value,
  int defaultPort, {
  String? fallback,
}) {
  var source = value.trim();
  if (source.isEmpty) {
    source = fallback ?? NatTraversalConfig.defaultStunServer;
  }
  if (source.contains('://')) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.host.isNotEmpty) {
      return _ServerEndpoint(
        host: uri.host,
        port: uri.hasPort ? uri.port : defaultPort,
      );
    }
  }
  source = source
      .replaceFirst(RegExp(r'^(stun|turn|turns):', caseSensitive: false), '')
      .split('?')
      .first;
  if (source.startsWith('[')) {
    final end = source.indexOf(']');
    if (end > 0) {
      final host = source.substring(1, end);
      final rest = source.substring(end + 1);
      final port = rest.startsWith(':')
          ? int.tryParse(rest.substring(1)) ?? defaultPort
          : defaultPort;
      return _ServerEndpoint(host: host, port: port);
    }
  }
  final colonCount = ':'.allMatches(source).length;
  if (colonCount == 1) {
    final parts = source.split(':');
    return _ServerEndpoint(
      host: parts.first,
      port: int.tryParse(parts.last) ?? defaultPort,
    );
  }
  return _ServerEndpoint(host: source, port: defaultPort);
}

String _parseEndpointAddress(String endpoint) {
  final normalized = endpoint.replaceAll('[', '').replaceAll(']', '');
  final index = normalized.lastIndexOf(':');
  if (index <= 0) {
    return '0.0.0.0';
  }
  final address = normalized.substring(0, index);
  if (address == '*' || address.isEmpty) {
    return '0.0.0.0';
  }
  return address;
}

String _resolveTargetAddress(String address) {
  final normalized = address.trim();
  if (normalized.isEmpty || normalized == '0.0.0.0' || normalized == '::') {
    return '127.0.0.1';
  }
  return normalized;
}

int? _parseEndpointPort(String endpoint) {
  final cleaned = endpoint.replaceAll('[', '').replaceAll(']', '');
  final match = RegExp(r':(\d+)(?:\D|$)').firstMatch(cleaned);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  final lastColon = cleaned.lastIndexOf(':');
  if (lastColon >= 0 && lastColon + 1 < cleaned.length) {
    return int.tryParse(cleaned.substring(lastColon + 1));
  }
  return null;
}

List<String> _parseCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') {
      if (quoted && index + 1 < line.length && line[index + 1] == '"') {
        buffer.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  if (buffer.isNotEmpty || line.endsWith(',')) {
    result.add(buffer.toString());
  }
  return result;
}
