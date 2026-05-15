import 'dart:io';

import 'package:flutter/services.dart';

class SystemControlService {
  const SystemControlService();

  static const _channel = MethodChannel('personal_toolbox/system_control');

  bool get isSupported => Platform.isWindows;

  Future<void> turnOffDisplay() async {
    if (!Platform.isWindows) {
      throw UnsupportedError('系统控制当前只支持 Windows。');
    }
    await _channel
        .invokeMethod<void>('turnOffDisplay')
        .onError<MissingPluginException>((error, stackTrace) {
          throw StateError(_missingPluginMessage);
        });
  }
}

const _missingPluginMessage =
    'Windows 原生系统控制通道尚未加载。请完全关闭当前应用进程，然后重新运行或重新构建 Windows 版本；仅热重载不会加载新增的原生 MethodChannel。';
