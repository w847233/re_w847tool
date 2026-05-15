import 'package:flutter/services.dart';

class NativeTcpPortMapper {
  static const _channel = MethodChannel('personal_toolbox/nat_traversal');

  Future<NativeTcpMappingResult> startForward({
    required String ruleId,
    required String stunHost,
    required int stunPort,
    required String httpHost,
    required int httpPort,
    required String targetHost,
    required int targetPort,
    int keepAliveSeconds = 30,
  }) async {
    final result = await _channel
        .invokeMapMethod<String, Object?>('startTcpForward', <String, Object?>{
          'ruleId': ruleId,
          'stunHost': stunHost,
          'stunPort': stunPort,
          'httpHost': httpHost,
          'httpPort': httpPort,
          'targetHost': targetHost,
          'targetPort': targetPort,
          'keepAliveSeconds': keepAliveSeconds,
        });
    if (result == null) {
      throw StateError('原生 TCP 映射没有返回结果。');
    }
    return NativeTcpMappingResult(
      publicIp: result['publicIp'] as String? ?? '',
      publicPort: result['publicPort'] as int? ?? 0,
      localBindPort: result['localBindPort'] as int? ?? 0,
    );
  }

  Future<void> stopForward(String ruleId) async {
    await _channel.invokeMethod<void>('stopTcpForward', <String, Object?>{
      'ruleId': ruleId,
    });
  }
}

class NativeTcpMappingResult {
  const NativeTcpMappingResult({
    required this.publicIp,
    required this.publicPort,
    required this.localBindPort,
  });

  final String publicIp;
  final int publicPort;
  final int localBindPort;
}
