import 'dart:io';

import 'package:flutter/services.dart';

class BluetoothAudioService {
  const BluetoothAudioService();

  static const _channel = MethodChannel('personal_toolbox/bluetooth_audio');

  Future<BluetoothAudioSupport> checkSupport() async {
    if (!Platform.isWindows) {
      return const BluetoothAudioSupport(
        supported: false,
        message: '蓝牙音频转接当前只支持 Windows 10 2004 及以上版本。',
      );
    }
    final result = await _channel
        .invokeMapMethod<String, Object?>('checkSupport')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'supported': false,
            'message': _missingPluginMessage,
          };
        });
    if (result == null) {
      throw StateError('蓝牙音频支持检测没有返回结果。');
    }
    return BluetoothAudioSupport.fromMap(result);
  }

  Future<List<BluetoothAudioDevice>> listDevices() async {
    if (!Platform.isWindows) {
      return const [];
    }
    final result = await _channel
        .invokeListMethod<Object?>('listDevices')
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingPluginMessage);
        });
    return [
      for (final item in result ?? const <Object?>[])
        if (item case final Map<Object?, Object?> map)
          BluetoothAudioDevice.fromMap(map),
    ];
  }

  Future<BluetoothAudioConnectionResult> enableConnection(
    String deviceId,
  ) async {
    return _invokeConnection('enableConnection', deviceId);
  }

  Future<BluetoothAudioConnectionResult> openConnection(String deviceId) async {
    return _invokeConnection('openConnection', deviceId);
  }

  Future<BluetoothAudioConnectionResult> closeConnection(
    String deviceId,
  ) async {
    return _invokeConnection('closeConnection', deviceId);
  }

  Future<void> releaseConnection(String deviceId) async {
    if (!Platform.isWindows) {
      return;
    }
    await _channel
        .invokeMethod<void>('releaseConnection', <String, Object?>{
          'deviceId': deviceId,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingPluginMessage);
        });
  }

  Future<void> releaseAllConnections() async {
    if (!Platform.isWindows) {
      return;
    }
    await _channel
        .invokeMethod<void>('releaseAllConnections')
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingPluginMessage);
        });
  }

  Future<List<WindowsPlaybackDevice>> listPlaybackDevices() async {
    if (!Platform.isWindows) {
      return const [];
    }
    final result = await _channel
        .invokeListMethod<Object?>('listPlaybackDevices')
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingPluginMessage);
        });
    return [
      for (final item in result ?? const <Object?>[])
        if (item case final Map<Object?, Object?> map)
          WindowsPlaybackDevice.fromMap(map),
    ];
  }

  Future<WindowsPlaybackDeviceResult> setPlaybackDevice(String deviceId) async {
    if (!Platform.isWindows) {
      return const WindowsPlaybackDeviceResult(
        success: false,
        status: 'Unsupported',
        message: '蓝牙音频转接当前只支持 Windows。',
      );
    }
    final result = await _channel
        .invokeMapMethod<String, Object?>(
          'setPlaybackDevice',
          <String, Object?>{'playbackDeviceId': deviceId},
        )
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'success': false,
            'status': 'MissingPlugin',
            'message': _missingPluginMessage,
          };
        });
    if (result == null) {
      throw StateError('Windows 播放设备切换没有返回结果。');
    }
    return WindowsPlaybackDeviceResult.fromMap(result);
  }

  Future<double> getPlaybackLevel({String? playbackDeviceId}) async {
    if (!Platform.isWindows) {
      return 0;
    }
    final result = await _channel
        .invokeMapMethod<String, Object?>('getPlaybackLevel', <String, Object?>{
          'playbackDeviceId': playbackDeviceId,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingPluginMessage);
        });
    final level = result?['level'];
    if (level is num) {
      return level.clamp(0, 1).toDouble();
    }
    return 0;
  }

  Future<BluetoothAudioConnectionResult> _invokeConnection(
    String method,
    String deviceId,
  ) async {
    if (!Platform.isWindows) {
      return const BluetoothAudioConnectionResult(
        success: false,
        status: 'Unsupported',
        state: BluetoothAudioConnectionState.closed,
        message: '蓝牙音频转接当前只支持 Windows。',
      );
    }
    final result = await _channel
        .invokeMapMethod<String, Object?>(method, <String, Object?>{
          'deviceId': deviceId,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'success': false,
            'status': 'MissingPlugin',
            'state': 'Closed',
            'message': _missingPluginMessage,
          };
        });
    if (result == null) {
      throw StateError('蓝牙音频连接操作没有返回结果。');
    }
    return BluetoothAudioConnectionResult.fromMap(result, method: method);
  }
}

const _missingPluginMessage =
    'Windows 原生蓝牙音频通道尚未加载。请完全关闭当前应用进程，然后重新运行或重新构建 Windows 版本；仅热重载不会加载新增的原生 MethodChannel。';

class BluetoothAudioSupport {
  const BluetoothAudioSupport({required this.supported, required this.message});

  factory BluetoothAudioSupport.fromMap(Map<Object?, Object?> map) {
    final supported = map['supported'] as bool? ?? false;
    final nativeMessage = map['message'] as String? ?? '';
    return BluetoothAudioSupport(
      supported: supported,
      message: supported
          ? '当前系统支持蓝牙 A2DP 接收，可将已配对手机音频转接到 Windows 默认播放设备。'
          : '当前系统不支持蓝牙音频接收。$nativeMessage',
    );
  }

  final bool supported;
  final String message;
}

class BluetoothAudioDevice {
  const BluetoothAudioDevice({
    required this.id,
    required this.name,
    required this.isEnabled,
    required this.state,
  });

  factory BluetoothAudioDevice.fromMap(Map<Object?, Object?> map) {
    return BluetoothAudioDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名设备',
      isEnabled: map['isEnabled'] as bool? ?? false,
      state: parseBluetoothAudioConnectionState(map['state'] as String?),
    );
  }

  final String id;
  final String name;
  final bool isEnabled;
  final BluetoothAudioConnectionState state;
}

class WindowsPlaybackDevice {
  const WindowsPlaybackDevice({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  factory WindowsPlaybackDevice.fromMap(Map<Object?, Object?> map) {
    return WindowsPlaybackDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名播放设备',
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final bool isDefault;
}

class WindowsPlaybackDeviceResult {
  const WindowsPlaybackDeviceResult({
    required this.success,
    required this.status,
    required this.message,
  });

  factory WindowsPlaybackDeviceResult.fromMap(Map<Object?, Object?> map) {
    final success = map['success'] as bool? ?? false;
    final status = map['status'] as String? ?? 'Unknown';
    final fallback = success
        ? '已切换 Windows 默认播放设备，蓝牙音频会跟随该输出。'
        : '切换 Windows 播放设备失败，系统返回状态：$status。';
    return WindowsPlaybackDeviceResult(
      success: success,
      status: status,
      message: fallback,
    );
  }

  final bool success;
  final String status;
  final String message;
}

class BluetoothAudioConnectionResult {
  const BluetoothAudioConnectionResult({
    required this.success,
    required this.status,
    required this.state,
    required this.message,
  });

  factory BluetoothAudioConnectionResult.fromMap(
    Map<Object?, Object?> map, {
    String? method,
  }) {
    final success = map['success'] as bool? ?? false;
    final status = map['status'] as String? ?? 'Unknown';
    final state = parseBluetoothAudioConnectionState(map['state'] as String?);
    final nativeMessage = map['message'] as String? ?? '';
    return BluetoothAudioConnectionResult(
      success: success,
      status: status,
      state: state,
      message: _localizedConnectionMessage(
        method: method,
        success: success,
        status: status,
        nativeMessage: nativeMessage,
      ),
    );
  }

  final bool success;
  final String status;
  final BluetoothAudioConnectionState state;
  final String message;
}

String _localizedConnectionMessage({
  required String? method,
  required bool success,
  required String status,
  required String nativeMessage,
}) {
  if (!success) {
    final reason = status == 'Unavailable'
        ? '该设备没有可用的蓝牙音频接收连接。'
        : '系统返回状态：$status。';
    return nativeMessage.isEmpty ? reason : '$reason $nativeMessage';
  }
  return switch (method) {
    'enableConnection' => '已启用蓝牙音频接收，请在手机上选择这台电脑作为音频输出。',
    'openConnection' => '蓝牙音频连接已打开，手机音频应通过 Windows 默认播放设备输出。',
    'closeConnection' => '已关闭蓝牙音频播放，接收授权仍保留。',
    _ => '蓝牙音频连接操作已完成。',
  };
}

enum BluetoothAudioConnectionState { closed, opened, enabled, unknown }

BluetoothAudioConnectionState parseBluetoothAudioConnectionState(
  String? value,
) {
  return switch (value) {
    'Closed' => BluetoothAudioConnectionState.closed,
    'Opened' => BluetoothAudioConnectionState.opened,
    'Enabled' => BluetoothAudioConnectionState.enabled,
    _ => BluetoothAudioConnectionState.unknown,
  };
}
