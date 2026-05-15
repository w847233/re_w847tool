enum NatTunnelProtocol {
  udp('UDP'),
  tcp('TCP');

  const NatTunnelProtocol(this.label);

  final String label;

  static NatTunnelProtocol fromName(String? value) {
    return values.firstWhere(
      (protocol) => protocol.name == value,
      orElse: () => udp,
    );
  }
}

enum NatSupportLevel { supported, limited, unsupported, unknown }

enum NatTunnelStatus { saved, starting, active, warning, failed, stopped }

class NatTraversalConfig {
  const NatTraversalConfig({
    this.stunServer = defaultStunServer,
    this.tcpStunServer = defaultTcpStunServer,
    this.turnServer = '',
    this.turnUsername = '',
    this.turnPassword = '',
    this.tcpKeepAliveServer = defaultTcpKeepAliveServer,
  });

  static const defaultStunServer = 'stun.l.google.com:19302';
  static const defaultTcpStunServer = 'stun.nextcloud.com:443';
  static const defaultTcpKeepAliveServer = 'example.com:80';

  final String stunServer;
  final String tcpStunServer;
  final String turnServer;
  final String turnUsername;
  final String turnPassword;
  final String tcpKeepAliveServer;

  bool get hasTurnServer => turnServer.trim().isNotEmpty;

  NatTraversalConfig copyWith({
    String? stunServer,
    String? tcpStunServer,
    String? turnServer,
    String? turnUsername,
    String? turnPassword,
    String? tcpKeepAliveServer,
  }) {
    return NatTraversalConfig(
      stunServer: stunServer ?? this.stunServer,
      tcpStunServer: tcpStunServer ?? this.tcpStunServer,
      turnServer: turnServer ?? this.turnServer,
      turnUsername: turnUsername ?? this.turnUsername,
      turnPassword: turnPassword ?? this.turnPassword,
      tcpKeepAliveServer: tcpKeepAliveServer ?? this.tcpKeepAliveServer,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stunServer': stunServer,
      'tcpStunServer': tcpStunServer,
      'turnServer': turnServer,
      'turnUsername': turnUsername,
      'turnPassword': turnPassword,
      'tcpKeepAliveServer': tcpKeepAliveServer,
    };
  }

  factory NatTraversalConfig.fromJson(Map<String, dynamic> json) {
    return NatTraversalConfig(
      stunServer: (json['stunServer'] as String?)?.trim().isNotEmpty == true
          ? (json['stunServer'] as String).trim()
          : defaultStunServer,
      tcpStunServer:
          (json['tcpStunServer'] as String?)?.trim().isNotEmpty == true
          ? (json['tcpStunServer'] as String).trim()
          : defaultTcpStunServer,
      turnServer: (json['turnServer'] as String? ?? '').trim(),
      turnUsername: (json['turnUsername'] as String? ?? '').trim(),
      turnPassword: json['turnPassword'] as String? ?? '',
      tcpKeepAliveServer:
          (json['tcpKeepAliveServer'] as String?)?.trim().isNotEmpty == true
          ? (json['tcpKeepAliveServer'] as String).trim()
          : defaultTcpKeepAliveServer,
    );
  }
}

class NatTunnelRule {
  const NatTunnelRule({
    required this.id,
    required this.protocol,
    required this.targetAddress,
    required this.targetPort,
    required this.createdAt,
    required this.updatedAt,
    this.label = '',
    this.remoteHost = '',
    this.remotePort,
    this.enabled = false,
  });

  final String id;
  final NatTunnelProtocol protocol;
  final String targetAddress;
  final int targetPort;
  final String label;
  final String remoteHost;
  final int? remotePort;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return '${protocol.label} $targetAddress:$targetPort';
  }

  bool get hasRemotePeer {
    return remoteHost.trim().isNotEmpty && remotePort != null;
  }

  NatTunnelRule copyWith({
    String? id,
    NatTunnelProtocol? protocol,
    String? targetAddress,
    int? targetPort,
    String? label,
    String? remoteHost,
    int? remotePort,
    bool? clearRemotePort,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NatTunnelRule(
      id: id ?? this.id,
      protocol: protocol ?? this.protocol,
      targetAddress: targetAddress ?? this.targetAddress,
      targetPort: targetPort ?? this.targetPort,
      label: label ?? this.label,
      remoteHost: remoteHost ?? this.remoteHost,
      remotePort: clearRemotePort == true
          ? null
          : (remotePort ?? this.remotePort),
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'protocol': protocol.name,
      'targetAddress': targetAddress,
      'targetPort': targetPort,
      'label': label,
      'remoteHost': remoteHost,
      'remotePort': remotePort,
      'enabled': enabled,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory NatTunnelRule.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return NatTunnelRule(
      id: json['id'] as String? ?? '',
      protocol: NatTunnelProtocol.fromName(json['protocol'] as String?),
      targetAddress: json['targetAddress'] as String? ?? '127.0.0.1',
      targetPort: _port(json['targetPort']) ?? 0,
      label: json['label'] as String? ?? '',
      remoteHost: json['remoteHost'] as String? ?? '',
      remotePort: _port(json['remotePort']),
      enabled: json['enabled'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? now,
      updatedAt: _date(json['updatedAt']) ?? now,
    );
  }
}

class NatDetectionSummary {
  const NatDetectionSummary({
    required this.checkedAt,
    required this.natType,
    required this.filteringBehavior,
    required this.mappingBehavior,
    required this.rfc5780Supported,
    required this.supportLevel,
    required this.message,
    this.publicIp,
    this.publicPort,
    this.alternateServer,
  });

  final DateTime checkedAt;
  final String natType;
  final String filteringBehavior;
  final String mappingBehavior;
  final String? publicIp;
  final int? publicPort;
  final String? alternateServer;
  final bool rfc5780Supported;
  final NatSupportLevel supportLevel;
  final String message;

  bool get canAttemptUdpHolePunch {
    return supportLevel == NatSupportLevel.supported ||
        supportLevel == NatSupportLevel.limited;
  }

  String get publicEndpoint {
    final ip = publicIp;
    final port = publicPort;
    if (ip == null || port == null) {
      return '未发现';
    }
    return '$ip:$port';
  }
}

class NatPortCandidate {
  const NatPortCandidate({
    required this.protocol,
    required this.localAddress,
    required this.localPort,
    this.processId,
    this.processName,
  });

  final NatTunnelProtocol protocol;
  final String localAddress;
  final int localPort;
  final int? processId;
  final String? processName;

  String get label {
    final process = [
      if (processName != null && processName!.isNotEmpty) processName,
      if (processId != null) 'PID $processId',
    ].join(' · ');
    final suffix = process.isEmpty ? '' : ' · $process';
    return '${protocol.label} $localAddress:$localPort$suffix';
  }
}

class NatLocalAddress {
  const NatLocalAddress({required this.address, required this.label});

  final String address;
  final String label;
}

class NatConnectivityCheck {
  const NatConnectivityCheck({
    required this.success,
    required this.message,
    this.latencyMs,
  });

  final bool success;
  final String message;
  final int? latencyMs;
}

class NatTunnelSnapshot {
  const NatTunnelSnapshot({
    required this.ruleId,
    required this.protocol,
    required this.status,
    required this.message,
    this.publicIp,
    this.publicPort,
    this.localBindPort,
    this.bytesFromRemote = 0,
    this.bytesToRemote = 0,
    this.lastRemoteEndpoint,
    this.tcpCheck,
  });

  final String ruleId;
  final NatTunnelProtocol protocol;
  final NatTunnelStatus status;
  final String message;
  final String? publicIp;
  final int? publicPort;
  final int? localBindPort;
  final int bytesFromRemote;
  final int bytesToRemote;
  final String? lastRemoteEndpoint;
  final NatConnectivityCheck? tcpCheck;

  String get publicEndpoint {
    final ip = publicIp;
    final port = publicPort;
    if (ip == null || port == null) {
      return '未分配';
    }
    return '$ip:$port';
  }

  NatTunnelSnapshot copyWith({
    NatTunnelStatus? status,
    String? message,
    String? publicIp,
    int? publicPort,
    int? localBindPort,
    int? bytesFromRemote,
    int? bytesToRemote,
    String? lastRemoteEndpoint,
    NatConnectivityCheck? tcpCheck,
  }) {
    return NatTunnelSnapshot(
      ruleId: ruleId,
      protocol: protocol,
      status: status ?? this.status,
      message: message ?? this.message,
      publicIp: publicIp ?? this.publicIp,
      publicPort: publicPort ?? this.publicPort,
      localBindPort: localBindPort ?? this.localBindPort,
      bytesFromRemote: bytesFromRemote ?? this.bytesFromRemote,
      bytesToRemote: bytesToRemote ?? this.bytesToRemote,
      lastRemoteEndpoint: lastRemoteEndpoint ?? this.lastRemoteEndpoint,
      tcpCheck: tcpCheck ?? this.tcpCheck,
    );
  }

  static NatTunnelSnapshot saved(NatTunnelRule rule) {
    return NatTunnelSnapshot(
      ruleId: rule.id,
      protocol: rule.protocol,
      status: NatTunnelStatus.saved,
      message: '已保存，尚未启动',
    );
  }
}

int? _port(Object? value) {
  if (value is int && value > 0 && value <= 65535) {
    return value;
  }
  if (value is num && value > 0 && value <= 65535) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0 && parsed <= 65535) {
      return parsed;
    }
  }
  return null;
}

DateTime? _date(Object? value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
