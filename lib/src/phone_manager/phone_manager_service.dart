import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PhoneManagerService {
  const PhoneManagerService();

  static const _windowsChannel = MethodChannel(
    'personal_toolbox/phone_manager',
  );
  static const _androidChannel = MethodChannel(
    'personal_toolbox/phone_companion',
  );

  Future<PhoneManagerSupport> checkSupport() async {
    if (Platform.isWindows) {
      final result = await _windowsChannel
          .invokeMapMethod<String, Object?>('checkSupport')
          .onError<MissingPluginException>((error, stackTrace) {
            return <String, Object?>{
              'available': false,
              'source': 'windowsProfile',
              'status': 'MissingPlugin',
              'message': _missingWindowsPluginMessage,
            };
          });
      return PhoneManagerSupport.fromMap(result);
    }
    if (Platform.isAndroid) {
      final result = await _androidChannel
          .invokeMapMethod<String, Object?>('companionStatus')
          .onError<MissingPluginException>((error, stackTrace) {
            return <String, Object?>{
              'available': false,
              'source': 'androidCompanion',
              'status': 'MissingPlugin',
              'message': _missingAndroidPluginMessage,
            };
          });
      return PhoneManagerSupport.fromMap(result);
    }
    return const PhoneManagerSupport(
      available: false,
      source: PhoneCapabilitySource.systemGuided,
      status: 'Unsupported',
      message: '手机管理当前仅支持 Windows 管理端和 Android 伴随端。',
      missingPermissions: [],
      runtimeWarnings: [],
    );
  }

  Future<PhoneCapabilityResult> requestCompanionPermissions() async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: '权限请求仅在 Android 伴随端可用。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('requestPermissions')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> startCompanionServer() async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: '伴随服务只能在 Android 设备上启动。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('startCompanionServer')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> stopCompanionServer() async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: '伴随服务只能在 Android 设备上停止。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('stopCompanionServer')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> selectFiles() async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: '文件选择需要在 Android 伴随端执行。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('selectFiles')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<List<PhoneDevice>> listDevices() async {
    if (!Platform.isWindows) {
      return const [];
    }
    final result = await _windowsChannel
        .invokeListMethod<Object?>('listDevices')
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingWindowsPluginMessage);
        });
    return [
      for (final item in result ?? const <Object?>[])
        if (item case final Map<Object?, Object?> map) PhoneDevice.fromMap(map),
    ];
  }

  Future<PhoneCapabilityResult> connectDevice(String deviceId) {
    return _invokeWindowsDeviceAction('connectDevice', deviceId);
  }

  Future<PhoneCapabilityResult> disconnectDevice(String deviceId) {
    return _invokeWindowsDeviceAction('disconnectDevice', deviceId);
  }

  Future<PhoneCapabilityResult> startAudioTransfer(String deviceId) {
    return _invokeWindowsDeviceAction('startAudioTransfer', deviceId);
  }

  Future<PhoneCapabilityResult> stopAudioTransfer(String deviceId) {
    return _invokeWindowsDeviceAction('stopAudioTransfer', deviceId);
  }

  Future<PhoneMediaSession> getMediaSession() async {
    if (!Platform.isWindows) {
      return PhoneMediaSession.unavailable('媒体会话仅在 Windows 管理端可用。');
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>('getMediaSession')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'windowsProfile',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneMediaSession.fromMap(result);
  }

  Future<PhoneCapabilityResult> sendMediaCommand(
    PhoneMediaCommand command, {
    Duration? position,
  }) async {
    if (!Platform.isWindows) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.windowsProfile,
        status: 'Unsupported',
        message: '媒体控制仅在 Windows 管理端可用。',
      );
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>('sendMediaCommand', <String, Object?>{
          'command': command.name,
          if (position != null) 'positionMs': position.inMilliseconds,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'windowsProfile',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneVolumeState> getVolumeState() async {
    if (!Platform.isWindows) {
      return PhoneVolumeState.unavailable('音量控制仅在 Windows 管理端可用。');
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>('getVolumeState')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'windowsProfile',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneVolumeState.fromMap(result);
  }

  Future<PhoneCapabilityResult> setVolume(double value) async {
    if (!Platform.isWindows) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.windowsProfile,
        status: 'Unsupported',
        message: '音量控制仅在 Windows 管理端可用。',
      );
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>('setVolume', <String, Object?>{
          'volume': value.clamp(0, 1),
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'windowsProfile',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> setMuted(bool muted) async {
    if (!Platform.isWindows) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.windowsProfile,
        status: 'Unsupported',
        message: '静音控制仅在 Windows 管理端可用。',
      );
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>('setMuted', <String, Object?>{
          'muted': muted,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'windowsProfile',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<List<PhoneContact>> listContacts() async {
    final result = await _invokeListData('listContacts');
    return [
      for (final item in result)
        if (item case final Map<Object?, Object?> map)
          PhoneContact.fromMap(map),
    ];
  }

  Future<List<PhoneMessage>> listMessages() async {
    final result = await _invokeListData('listMessages');
    return [
      for (final item in result)
        if (item case final Map<Object?, Object?> map)
          PhoneMessage.fromMap(map),
    ];
  }

  Future<List<PhoneCallLog>> listCallLogs() async {
    final result = await _invokeListData('listCallLogs');
    return [
      for (final item in result)
        if (item case final Map<Object?, Object?> map)
          PhoneCallLog.fromMap(map),
    ];
  }

  Future<List<PhoneFileItem>> listFiles() async {
    final result = await _invokeListData('listFiles');
    return [
      for (final item in result)
        if (item case final Map<Object?, Object?> map)
          PhoneFileItem.fromMap(map),
    ];
  }

  Future<List<PhoneDiagnostic>> getDiagnostics() async {
    final MethodChannel channel = Platform.isAndroid
        ? _androidChannel
        : _windowsChannel;
    final result = await channel
        .invokeListMethod<Object?>('getDiagnostics')
        .onError<MissingPluginException>((error, stackTrace) {
          return <Object?>[
            <String, Object?>{
              'area': Platform.isAndroid ? 'Android 伴随端' : 'Windows 管理端',
              'status': 'MissingPlugin',
              'message': Platform.isAndroid
                  ? _missingAndroidPluginMessage
                  : _missingWindowsPluginMessage,
              'severity': 'error',
            },
          ];
        });
    return [
      for (final item in result ?? const <Object?>[])
        if (item case final Map<Object?, Object?> map)
          PhoneDiagnostic.fromMap(map),
    ];
  }

  Future<PhoneCapabilityResult> openPanSettings() async {
    if (!Platform.isWindows) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.systemGuided,
        status: 'Unsupported',
        message: 'PAN 系统引导仅在 Windows 管理端可用。',
      );
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>('openPanSettings')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'systemGuided',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> registerHid() async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: 'HID 注册需要在 Android 伴随端执行。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('registerHid')
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> sendHidKey(String key) async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: 'HID 输入需要在 Android 伴随端执行。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('sendHidKey', <String, Object?>{
          'key': key,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> sendHidMouse({
    int dx = 0,
    int dy = 0,
    int wheel = 0,
    int buttons = 0,
  }) async {
    if (!Platform.isAndroid) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: 'HID 输入需要在 Android 伴随端执行。',
      );
    }
    final result = await _androidChannel
        .invokeMapMethod<String, Object?>('sendHidMouse', <String, Object?>{
          'dx': dx,
          'dy': dy,
          'wheel': wheel,
          'buttons': buttons,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingAndroidPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<PhoneCapabilityResult> receiveFile(PhoneFileItem file) async {
    if (!Platform.isWindows) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'Unsupported',
        message: '接收 Android 会话文件需要在 Windows 管理端执行。',
      );
    }
    final response = await _windowsCompanionRequest(<String, Object?>{
      'command': 'fileContent',
      'id': file.id,
    });
    final base64 = response['base64'] as String?;
    if (base64 == null) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.androidCompanion,
        status: 'EmptyFile',
        message: '伴随端没有返回可保存的文件内容。',
      );
    }
    final bytes = base64Decode(base64);
    final downloads = await getDownloadsDirectory();
    final fallbackDownloads = Directory(
      path.join(
        Platform.environment['USERPROFILE'] ?? Directory.current.path,
        'Downloads',
      ),
    );
    final targetDir = Directory(
      path.join(
        downloads?.path ?? fallbackDownloads.path,
        'personal_toolbox_phone_files',
      ),
    );
    await targetDir.create(recursive: true);
    final targetFile = await _uniqueFile(
      targetDir,
      _safeFileName(response['name'] as String? ?? file.name),
    );
    await targetFile.writeAsBytes(bytes, flush: true);
    return PhoneCapabilityResult(
      available: true,
      source: PhoneCapabilitySource.androidCompanion,
      status: 'Saved',
      message: '已接收并保存文件：${targetFile.path}',
    );
  }

  Future<PhoneCapabilityResult> _invokeWindowsDeviceAction(
    String method,
    String deviceId,
  ) async {
    if (!Platform.isWindows) {
      return const PhoneCapabilityResult(
        available: false,
        source: PhoneCapabilitySource.windowsProfile,
        status: 'Unsupported',
        message: '设备连接操作仅在 Windows 管理端可用。',
      );
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>(method, <String, Object?>{
          'deviceId': deviceId,
        })
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'windowsProfile',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    return PhoneCapabilityResult.fromMap(result);
  }

  Future<List<Object?>> _invokeListData(String method) async {
    if (Platform.isWindows) {
      return _invokeWindowsCompanionList(method);
    }
    final MethodChannel channel = Platform.isAndroid
        ? _androidChannel
        : _windowsChannel;
    final result = await channel
        .invokeListMethod<Object?>(method)
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(
            Platform.isAndroid
                ? _missingAndroidPluginMessage
                : _missingWindowsPluginMessage,
          );
        });
    return result ?? const <Object?>[];
  }

  Future<List<Object?>> _invokeWindowsCompanionList(String method) async {
    final command = switch (method) {
      'listContacts' => 'contacts',
      'listMessages' => 'messages',
      'listCallLogs' => 'callLogs',
      'listFiles' => 'files',
      _ => throw StateError('未知伴随端列表请求：$method'),
    };
    final response = await _windowsCompanionRequest(<String, Object?>{
      'command': command,
    });
    final items = response['items'];
    if (items is! List<Object?>) {
      return const <Object?>[];
    }
    return [
      for (final item in items)
        if (item is Map) Map<Object?, Object?>.from(item),
    ];
  }

  Future<Map<String, Object?>> _windowsCompanionRequest(
    Map<String, Object?> request,
  ) async {
    if (!Platform.isWindows) {
      throw StateError('Windows 伴随端请求只能在 Windows 管理端执行。');
    }
    final result = await _windowsChannel
        .invokeMapMethod<String, Object?>(
          'companionRequestRaw',
          <String, Object?>{'requestJson': jsonEncode(request)},
        )
        .onError<MissingPluginException>((error, stackTrace) {
          return <String, Object?>{
            'available': false,
            'source': 'androidCompanion',
            'status': 'MissingPlugin',
            'message': _missingWindowsPluginMessage,
          };
        });
    final status = PhoneCapabilityResult.fromMap(result);
    if (!status.available) {
      throw StateError(status.message);
    }
    final responseJson = result?['responseJson'] as String? ?? '';
    if (responseJson.isEmpty) {
      throw StateError('Android 伴随端返回了空响应。');
    }
    final decoded = jsonDecode(responseJson);
    if (decoded is! Map) {
      throw StateError('Android 伴随端响应格式不正确。');
    }
    final response = Map<String, Object?>.from(decoded);
    if (response['available'] == false) {
      throw StateError(response['message'] as String? ?? 'Android 伴随端拒绝了请求。');
    }
    return response;
  }
}

Future<File> _uniqueFile(Directory directory, String fileName) async {
  final extension = path.extension(fileName);
  final baseName = path.basenameWithoutExtension(fileName);
  var candidate = File(path.join(directory.path, '$baseName$extension'));
  var index = 1;
  while (await candidate.exists()) {
    candidate = File(path.join(directory.path, '$baseName ($index)$extension'));
    index += 1;
  }
  return candidate;
}

String _safeFileName(String value) {
  final trimmed = value.trim().isEmpty ? 'phone-file' : value.trim();
  return trimmed.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');
}

const phoneCompanionServiceUuid = '7b01f6f2-64d8-42e0-9b52-2f6cb11c7d34';

const _missingWindowsPluginMessage =
    'Windows 手机管理原生通道尚未加载。请完全关闭应用进程后重新运行或重新构建 Windows 版本；仅热重载不会加载新增 MethodChannel。';

const _missingAndroidPluginMessage =
    'Android 手机伴随原生通道尚未加载。请重新安装或重新运行 Android 版本。';

class PhoneManagerSupport {
  const PhoneManagerSupport({
    required this.available,
    required this.source,
    required this.status,
    required this.message,
    required this.missingPermissions,
    required this.runtimeWarnings,
  });

  factory PhoneManagerSupport.fromMap(Map<Object?, Object?>? map) {
    return PhoneManagerSupport(
      available: map?['available'] as bool? ?? false,
      source: parsePhoneCapabilitySource(map?['source'] as String?),
      status: map?['status'] as String? ?? 'Unknown',
      message: map?['message'] as String? ?? '手机管理状态未知。',
      missingPermissions: _stringList(map?['missingPermissions']),
      runtimeWarnings: _stringList(map?['runtimeWarnings']),
    );
  }

  final bool available;
  final PhoneCapabilitySource source;
  final String status;
  final String message;
  final List<String> missingPermissions;
  final List<String> runtimeWarnings;
}

class PhoneDevice {
  const PhoneDevice({
    required this.id,
    required this.name,
    required this.enabled,
    required this.state,
    required this.companionOnline,
    required this.capabilities,
    required this.lastError,
    required this.missingPermissions,
  });

  factory PhoneDevice.fromMap(Map<Object?, Object?> map) {
    return PhoneDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名设备',
      enabled: map['enabled'] as bool? ?? false,
      state: parsePhoneConnectionState(map['state'] as String?),
      companionOnline: map['companionOnline'] as bool? ?? false,
      capabilities: [
        for (final item
            in map['capabilities'] as List<Object?>? ?? const <Object?>[])
          if (item case final Map<Object?, Object?> capability)
            PhoneCapability.fromMap(capability),
      ],
      lastError: map['lastError'] as String?,
      missingPermissions: _stringList(map['missingPermissions']),
    );
  }

  final String id;
  final String name;
  final bool enabled;
  final PhoneConnectionState state;
  final bool companionOnline;
  final List<PhoneCapability> capabilities;
  final String? lastError;
  final List<String> missingPermissions;

  bool get audioOpened => state == PhoneConnectionState.audioOpened;
  bool get audioEnabled => state == PhoneConnectionState.audioEnabled;
}

class PhoneCapability {
  const PhoneCapability({
    required this.id,
    required this.label,
    required this.available,
    required this.source,
    required this.status,
    required this.message,
  });

  factory PhoneCapability.fromMap(Map<Object?, Object?> map) {
    return PhoneCapability(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      available: map['available'] as bool? ?? false,
      source: parsePhoneCapabilitySource(map['source'] as String?),
      status: map['status'] as String? ?? 'Unknown',
      message: map['message'] as String? ?? '',
    );
  }

  final String id;
  final String label;
  final bool available;
  final PhoneCapabilitySource source;
  final String status;
  final String message;
}

class PhoneCapabilityResult {
  const PhoneCapabilityResult({
    required this.available,
    required this.source,
    required this.status,
    required this.message,
    this.state,
  });

  factory PhoneCapabilityResult.fromMap(Map<Object?, Object?>? map) {
    return PhoneCapabilityResult(
      available: map?['available'] as bool? ?? false,
      source: parsePhoneCapabilitySource(map?['source'] as String?),
      status: map?['status'] as String? ?? 'Unknown',
      message: map?['message'] as String? ?? '操作没有返回详细信息。',
      state: parseNullablePhoneConnectionState(map?['state'] as String?),
    );
  }

  final bool available;
  final PhoneCapabilitySource source;
  final String status;
  final String message;
  final PhoneConnectionState? state;
}

class PhoneMediaSession {
  const PhoneMediaSession({
    required this.available,
    required this.source,
    required this.status,
    required this.message,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnailBase64,
    required this.playbackStatus,
    required this.position,
    required this.duration,
    required this.canPlay,
    required this.canPause,
    required this.canStop,
    required this.canNext,
    required this.canPrevious,
    required this.canSeek,
  });

  factory PhoneMediaSession.fromMap(Map<Object?, Object?>? map) {
    return PhoneMediaSession(
      available: map?['available'] as bool? ?? false,
      source: parsePhoneCapabilitySource(map?['source'] as String?),
      status: map?['status'] as String? ?? 'Unknown',
      message: map?['message'] as String? ?? '未读取到媒体会话。',
      title: map?['title'] as String? ?? '',
      artist: map?['artist'] as String? ?? '',
      album: map?['album'] as String? ?? '',
      thumbnailBase64: map?['thumbnailBase64'] as String?,
      playbackStatus: map?['playbackStatus'] as String? ?? 'Unknown',
      position: Duration(
        milliseconds: (map?['positionMs'] as num? ?? 0).round(),
      ),
      duration: Duration(
        milliseconds: (map?['durationMs'] as num? ?? 0).round(),
      ),
      canPlay: map?['canPlay'] as bool? ?? false,
      canPause: map?['canPause'] as bool? ?? false,
      canStop: map?['canStop'] as bool? ?? false,
      canNext: map?['canNext'] as bool? ?? false,
      canPrevious: map?['canPrevious'] as bool? ?? false,
      canSeek: map?['canSeek'] as bool? ?? false,
    );
  }

  factory PhoneMediaSession.unavailable(String message) {
    return PhoneMediaSession(
      available: false,
      source: PhoneCapabilitySource.windowsProfile,
      status: 'Unsupported',
      message: message,
      title: '',
      artist: '',
      album: '',
      thumbnailBase64: null,
      playbackStatus: 'Unknown',
      position: Duration.zero,
      duration: Duration.zero,
      canPlay: false,
      canPause: false,
      canStop: false,
      canNext: false,
      canPrevious: false,
      canSeek: false,
    );
  }

  final bool available;
  final PhoneCapabilitySource source;
  final String status;
  final String message;
  final String title;
  final String artist;
  final String album;
  final String? thumbnailBase64;
  final String playbackStatus;
  final Duration position;
  final Duration duration;
  final bool canPlay;
  final bool canPause;
  final bool canStop;
  final bool canNext;
  final bool canPrevious;
  final bool canSeek;
}

class PhoneVolumeState {
  const PhoneVolumeState({
    required this.available,
    required this.source,
    required this.status,
    required this.message,
    required this.volume,
    required this.muted,
    required this.endpointName,
  });

  factory PhoneVolumeState.fromMap(Map<Object?, Object?>? map) {
    return PhoneVolumeState(
      available: map?['available'] as bool? ?? false,
      source: parsePhoneCapabilitySource(map?['source'] as String?),
      status: map?['status'] as String? ?? 'Unknown',
      message: map?['message'] as String? ?? '未读取到音量状态。',
      volume: (map?['volume'] as num? ?? 0).clamp(0, 1).toDouble(),
      muted: map?['muted'] as bool? ?? false,
      endpointName: map?['endpointName'] as String? ?? '',
    );
  }

  factory PhoneVolumeState.unavailable(String message) {
    return PhoneVolumeState(
      available: false,
      source: PhoneCapabilitySource.windowsProfile,
      status: 'Unsupported',
      message: message,
      volume: 0,
      muted: false,
      endpointName: '',
    );
  }

  final bool available;
  final PhoneCapabilitySource source;
  final String status;
  final String message;
  final double volume;
  final bool muted;
  final String endpointName;
}

class PhoneContact {
  const PhoneContact({
    required this.id,
    required this.name,
    required this.phones,
    required this.emails,
    required this.source,
  });

  factory PhoneContact.fromMap(Map<Object?, Object?> map) {
    return PhoneContact(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名联系人',
      phones: _stringList(map['phones']),
      emails: _stringList(map['emails']),
      source: parsePhoneCapabilitySource(map['source'] as String?),
    );
  }

  final String id;
  final String name;
  final List<String> phones;
  final List<String> emails;
  final PhoneCapabilitySource source;
}

class PhoneMessage {
  const PhoneMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.source,
  });

  factory PhoneMessage.fromMap(Map<Object?, Object?> map) {
    return PhoneMessage(
      id: map['id'] as String? ?? '',
      address: map['address'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestampMs'] as num? ?? 0).round(),
      ),
      type: map['type'] as String? ?? 'unknown',
      source: parsePhoneCapabilitySource(map['source'] as String?),
    );
  }

  final String id;
  final String address;
  final String body;
  final DateTime timestamp;
  final String type;
  final PhoneCapabilitySource source;
}

class PhoneCallLog {
  const PhoneCallLog({
    required this.id,
    required this.name,
    required this.number,
    required this.timestamp,
    required this.duration,
    required this.type,
    required this.source,
  });

  factory PhoneCallLog.fromMap(Map<Object?, Object?> map) {
    return PhoneCallLog(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      number: map['number'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestampMs'] as num? ?? 0).round(),
      ),
      duration: Duration(
        seconds: (map['durationSeconds'] as num? ?? 0).round(),
      ),
      type: map['type'] as String? ?? 'unknown',
      source: parsePhoneCapabilitySource(map['source'] as String?),
    );
  }

  final String id;
  final String name;
  final String number;
  final DateTime timestamp;
  final Duration duration;
  final String type;
  final PhoneCapabilitySource source;
}

class PhoneFileItem {
  const PhoneFileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.source,
  });

  factory PhoneFileItem.fromMap(Map<Object?, Object?> map) {
    return PhoneFileItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名文件',
      size: (map['size'] as num? ?? 0).round(),
      mimeType: map['mimeType'] as String? ?? '',
      source: parsePhoneCapabilitySource(map['source'] as String?),
    );
  }

  final String id;
  final String name;
  final int size;
  final String mimeType;
  final PhoneCapabilitySource source;
}

class PhoneDiagnostic {
  const PhoneDiagnostic({
    required this.area,
    required this.status,
    required this.message,
    required this.severity,
  });

  factory PhoneDiagnostic.fromMap(Map<Object?, Object?> map) {
    return PhoneDiagnostic(
      area: map['area'] as String? ?? '诊断',
      status: map['status'] as String? ?? 'Unknown',
      message: map['message'] as String? ?? '',
      severity: map['severity'] as String? ?? 'info',
    );
  }

  final String area;
  final String status;
  final String message;
  final String severity;
}

enum PhoneConnectionState { disconnected, audioEnabled, audioOpened, unknown }

PhoneConnectionState parsePhoneConnectionState(String? value) {
  return parseNullablePhoneConnectionState(value) ??
      PhoneConnectionState.unknown;
}

PhoneConnectionState? parseNullablePhoneConnectionState(String? value) {
  return switch (value) {
    'Disconnected' || 'Closed' => PhoneConnectionState.disconnected,
    'AudioEnabled' || 'Enabled' => PhoneConnectionState.audioEnabled,
    'AudioOpened' || 'Opened' => PhoneConnectionState.audioOpened,
    null || '' => null,
    _ => PhoneConnectionState.unknown,
  };
}

enum PhoneCapabilitySource {
  windowsProfile,
  androidCompanion,
  systemGuided,
  unknown,
}

PhoneCapabilitySource parsePhoneCapabilitySource(String? value) {
  return switch (value) {
    'windowsProfile' ||
    'WindowsProfile' => PhoneCapabilitySource.windowsProfile,
    'androidCompanion' ||
    'AndroidCompanion' => PhoneCapabilitySource.androidCompanion,
    'systemGuided' || 'SystemGuided' => PhoneCapabilitySource.systemGuided,
    _ => PhoneCapabilitySource.unknown,
  };
}

enum PhoneMediaCommand {
  play,
  pause,
  togglePlayPause,
  stop,
  next,
  previous,
  seek,
}

List<String> _stringList(Object? value) {
  return [
    for (final item in value as List<Object?>? ?? const <Object?>[])
      if (item != null) item.toString(),
  ];
}
