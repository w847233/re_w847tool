import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'steam_status_models.dart';
import 'steam_status_repository.dart';

final steamStatusControllerProvider = Provider<SteamStatusController>((ref) {
  final controller = SteamStatusController(
    repository: ref.watch(steamStatusRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  controller.start();
  return controller;
});

final steamToolStateProvider = StreamProvider<SteamToolState>((ref) {
  return ref.watch(steamStatusControllerProvider).stream;
});

class SteamStatusController {
  SteamStatusController({required SteamStatusRepository repository})
    : _repository = repository;

  static const _backendAssetPrefix = 'assets/steam_status_backend/';
  static const _backendAssets = <String>[
    'assets/steam_status_backend/app.py',
    'assets/steam_status_backend/web_server.py',
    'assets/steam_status_backend/steam_bot.py',
    'assets/steam_status_backend/requirements.txt',
    'assets/steam_status_backend/templates/index.html',
    'assets/steam_status_backend/static/style.css',
  ];

  final SteamStatusRepository _repository;
  final http.Client _httpClient = http.Client();
  final StreamController<SteamToolState> _stateController =
      StreamController<SteamToolState>.broadcast();
  StringBuffer _stderrBuffer = StringBuffer();
  StringBuffer _stdoutBuffer = StringBuffer();

  SteamToolState _state = SteamToolState.initial;
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  StreamSubscription<String>? _eventSubscription;
  Timer? _pollTimer;
  Timer? _eventReconnectTimer;
  bool _disposed = false;
  bool _started = false;
  bool _processExited = false;

  Stream<SteamToolState> get stream => _stateController.stream;

  void start() {
    if (_started) {
      _emit(_state);
      return;
    }
    _started = true;
    _emit(_state);
    unawaited(_bootstrap());
  }

  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    _eventReconnectTimer?.cancel();
    await _eventSubscription?.cancel();
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _httpClient.close();
    await _stopBackendProcess();
    await _stateController.close();
  }

  Future<SteamActionResult> restartBackend() async {
    if (_disposed) {
      return const SteamActionResult(success: false, message: 'Steam 控制器已释放');
    }
    await _stopBackendProcess();
    _stderrBuffer = StringBuffer();
    _stdoutBuffer = StringBuffer();
    _processExited = false;
    _updateState(
      _state.copyWith(
        backendPhase: SteamBackendPhase.starting,
        backendMessage: '正在重启 Steam 侧车服务...',
        remoteState: SteamRemoteState.empty,
        clearBackendError: true,
        clearAuthPrompt: true,
        waitingForMobileApproval: false,
        loginInProgress: false,
        clearLoginMessage: true,
      ),
    );
    unawaited(_bootstrap());
    return const SteamActionResult(success: true, message: '正在重启 Steam 侧车服务');
  }

  Future<void> _stopBackendProcess() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _eventReconnectTimer?.cancel();
    _eventReconnectTimer = null;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    await _stderrSubscription?.cancel();
    _stderrSubscription = null;
    final process = _process;
    _process = null;
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
  }

  Future<SteamActionResult> loginWithPassword(
    String username,
    String password,
  ) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return const SteamActionResult(success: false, message: '用户名和密码不能为空');
    }
    _beginLogin('正在向 Steam 提交登录请求...');
    return _postAction(
      '/api/login',
      body: {'username': normalizedUsername, 'password': password},
      successMessage: '正在登录 Steam，请等待后续状态...',
      clearPrompt: true,
      keepLoginInProgress: true,
    );
  }

  Future<SteamActionResult> loginWithSavedAccount(String username) async {
    if (username.trim().isEmpty) {
      return const SteamActionResult(success: false, message: '缺少账号信息');
    }
    _beginLogin('正在使用已保存凭证连接 Steam...');
    return _postAction(
      '/api/login_session',
      body: {'username': username.trim()},
      successMessage: '正在使用已保存凭证登录，请等待后续状态...',
      clearPrompt: true,
      keepLoginInProgress: true,
    );
  }

  Future<SteamActionResult> saveCurrentCredentials() async {
    return _postAction(
      '/api/save_credentials',
      body: const <String, dynamic>{},
      successMessage: '当前登录凭证已保存到本机',
      onSuccess: () async {
        await _refreshSavedAccounts();
        _updateState(
          _state.copyWith(
            shouldPromptSaveCredentials: false,
            clearBackendError: true,
          ),
        );
      },
    );
  }

  Future<SteamActionResult> deleteSavedAccount(String username) async {
    final result = await _deleteAction(
      '/api/saved_account',
      body: {'username': username},
      successMessage: '已删除保存的账号凭证',
      onSuccess: _refreshSavedAccounts,
    );
    return result;
  }

  Future<SteamActionResult> submitGuardCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      return const SteamActionResult(success: false, message: '验证码不能为空');
    }
    return _postAction(
      '/api/guard_code',
      body: {'code': normalizedCode},
      successMessage: '验证码已提交，请等待 Steam 响应',
      onSuccess: () async {
        _updateState(
          _state.copyWith(
            loginInProgress: true,
            loginMessage: '验证码已提交，正在等待 Steam 授权...',
            clearBackendError: true,
          ),
        );
      },
    );
  }

  Future<SteamActionResult> logout() async {
    return _postAction(
      '/api/logout',
      body: const <String, dynamic>{},
      successMessage: '已登出当前账号',
      onSuccess: () async {
        await _refreshRemoteState();
        await _refreshSavedAccounts();
        _endLogin(clearMessage: true);
      },
    );
  }

  Future<SteamActionResult> setStatus({
    required String text,
    int? appId,
    required bool noisy,
    String? richText,
    Map<String, String>? richPresenceValues,
  }) async {
    final normalizedText = text.trim();
    final normalizedRichText = _normalizeOptional(richText);
    if (normalizedText.isEmpty) {
      return const SteamActionResult(success: false, message: '请输入状态文字');
    }
    if (normalizedRichText != null && !normalizedRichText.startsWith('#')) {
      return const SteamActionResult(
        success: false,
        message: 'Rich Presence Token 必须以 # 开头',
      );
    }
    final result = await _postAction(
      '/api/status',
      body: {
        'text': normalizedText,
        'app_id': appId,
        'noisy': noisy,
        'rich_text': normalizedRichText,
        'rich_presence_values': richPresenceValues,
      },
      successMessage: normalizedRichText == null
          ? '状态已提交'
          : '状态与 Rich Presence 已提交',
      onSuccess: () async {
        await _repository.addHistory(
          text: normalizedText,
          appId: appId,
          richText: normalizedRichText,
        );
        await _refreshRemoteState();
      },
    );
    return result;
  }

  Future<SteamActionResult> clearStatus() async {
    return _deleteAction(
      '/api/status',
      body: const <String, dynamic>{},
      successMessage: '状态已清除',
      onSuccess: _refreshRemoteState,
    );
  }

  Future<SteamActionResult> setPersonaState(int state) async {
    return _postAction(
      '/api/persona_state',
      body: {'state': state},
      successMessage: '副状态已更新',
      onSuccess: _refreshRemoteState,
    );
  }

  Future<SteamActionResult> setPersonaStateFlags(int flags) async {
    return _postAction(
      '/api/persona_state_flags',
      body: {'flags': flags},
      successMessage: '特殊标记已更新',
      onSuccess: _refreshRemoteState,
    );
  }

  Future<List<SteamRichPresenceToken>> fetchRichPresenceTokens(
    int appId,
  ) async {
    final response = await _httpClient.get(
      _uri('/api/rich_presence_tokens', {'app_id': '$appId'}),
    );
    final payload = _decodeJson(response.body);
    if (response.statusCode != 200 || payload['success'] != true) {
      throw StateError((payload['error'] as String?) ?? '获取 Token 失败');
    }
    final tokens = payload['tokens'];
    if (tokens is! List) {
      return const <SteamRichPresenceToken>[];
    }
    return tokens
        .whereType<Map>()
        .map(
          (item) => SteamRichPresenceToken(
            token: item['token'] as String? ?? '',
            display: item['display'] as String? ?? '',
            placeholders:
                (item['placeholders'] as List?)?.whereType<String>().toList() ??
                const <String>[],
          ),
        )
        .where((item) => item.token.isNotEmpty)
        .toList();
  }

  Future<SteamActionResult> setCMAutoPreference(bool enabled) async {
    return _postAction(
      '/api/cm_preference',
      body: {'enabled': enabled},
      successMessage: enabled ? '已开启登录前自动优选' : '已关闭登录前自动优选',
      onSuccess: _refreshCMPreference,
    );
  }

  Future<SteamActionResult> testCMServers() async {
    if (!_state.backendReady) {
      const message = 'Steam 侧车服务尚未就绪';
      _updateState(_state.copyWith(backendError: message));
      return const SteamActionResult(success: false, message: message);
    }
    try {
      final response = await _httpClient.post(
        _uri('/api/cm_test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'max_count': _state.cmPreference.maxCount,
          'timeout_seconds': _state.cmPreference.timeoutSeconds,
        }),
      );
      final payload = _decodeJson(response.body);
      final preference = _parseCMPreference(payload['cm_preference']);
      _updateState(
        _state.copyWith(
          cmPreference: preference,
          backendError: response.statusCode >= 400
              ? (payload['error'] as String? ?? 'Steam CM 测速失败')
              : null,
          clearBackendError: response.statusCode < 400,
        ),
      );
      if (response.statusCode >= 400 || payload['success'] != true) {
        return SteamActionResult(
          success: false,
          message: payload['error'] as String? ?? 'Steam CM 测速失败',
        );
      }
      final best = preference.bestServer;
      final message = best == null
          ? '测速完成，但没有找到可用 CM 节点'
          : '已优选 ${best.endpoint}（${best.latencyMs?.toStringAsFixed(1)} ms）';
      return SteamActionResult(success: true, message: message);
    } catch (error) {
      final message = 'Steam CM 测速失败：$error';
      _updateState(_state.copyWith(backendError: message));
      return SteamActionResult(success: false, message: message);
    }
  }

  Future<SteamActionResult> resolveSteamDomains() async {
    if (!_state.backendReady) {
      const message = 'Steam 侧车服务尚未就绪';
      _updateState(_state.copyWith(backendError: message));
      return const SteamActionResult(success: false, message: message);
    }
    try {
      final response = await _httpClient.post(
        _uri('/api/domain_resolve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(const <String, dynamic>{}),
      );
      final payload = _decodeJson(response.body);
      final preferences = _parseDomainPreferences(payload['domain_preference']);
      _updateState(
        _state.copyWith(
          domainPreferences: preferences,
          backendError: response.statusCode >= 400
              ? (payload['error'] as String? ?? 'Steam 域名解析失败')
              : null,
          clearBackendError: response.statusCode < 400,
        ),
      );
      if (response.statusCode >= 400 || payload['success'] != true) {
        return SteamActionResult(
          success: false,
          message: payload['error'] as String? ?? 'Steam 域名解析失败',
        );
      }
      return SteamActionResult(
        success: true,
        message: '已解析 ${preferences.length} 个 Steam 流程域名',
      );
    } catch (error) {
      final message = 'Steam 域名解析失败：$error';
      _updateState(_state.copyWith(backendError: message));
      return SteamActionResult(success: false, message: message);
    }
  }

  Future<SteamActionResult> setSteamDomainEnabled(
    String domain,
    bool enabled,
  ) async {
    return _postAction(
      '/api/domain_preference',
      body: {'domain': domain, 'enabled': enabled},
      successMessage: enabled ? '已启用 $domain 的 DNS 优选' : '已停用 $domain 的 DNS 优选',
      onSuccess: _refreshDomainPreference,
    );
  }

  Future<SteamActionResult> setSteamDomainIpSelected({
    required String domain,
    required String ip,
    required bool selected,
  }) async {
    SteamDomainPreference? current;
    for (final item in _state.domainPreferences) {
      if (item.domain == domain) {
        current = item;
        break;
      }
    }
    if (current == null) {
      return SteamActionResult(success: false, message: '未找到域名 $domain');
    }
    final selectedIps = current.selectedIps.toList();
    if (selected) {
      if (!selectedIps.contains(ip)) {
        selectedIps.add(ip);
      }
    } else {
      selectedIps.remove(ip);
    }
    return _postAction(
      '/api/domain_preference',
      body: {'domain': domain, 'selected_ips': selectedIps},
      successMessage: selected ? '已选择 $ip' : '已取消选择 $ip',
      onSuccess: _refreshDomainPreference,
    );
  }

  Future<void> _bootstrap() async {
    _updateState(
      _state.copyWith(
        backendPhase: SteamBackendPhase.starting,
        backendMessage: '正在释放内置 Steam 后端脚本...',
        clearBackendError: true,
      ),
    );
    try {
      final backendDir = await _prepareBackendDirectory();
      final port = await _findAvailablePort();
      _updateState(_state.copyWith(backendMessage: '正在查找本机 Python 3 解释器...'));
      final basePythonCommand = await _resolvePythonCommand();
      final pythonCommand = await _ensureBackendRuntime(
        basePythonCommand,
        backendDir,
      );

      final process = await Process.start(
        pythonCommand.executable,
        [...pythonCommand.arguments, 'app.py'],
        workingDirectory: backendDir.path,
        environment: {
          ...Platform.environment,
          'PYTHONUTF8': '1',
          'STATUSHACK_HOST': '127.0.0.1',
          'STATUSHACK_PORT': '$port',
        },
        runInShell: false,
      );

      _process = process;
      _processExited = false;
      process.exitCode.then((exitCode) {
        _processExited = true;
        _handleBackendProcessExit(exitCode);
      });
      _stdoutSubscription = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_stdoutBuffer.writeln);
      _stderrSubscription = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_stderrBuffer.writeln);

      _updateState(_state.copyWith(port: port));
      await _waitUntilReady();
      await _refreshAll();
      _updateState(
        _state.copyWith(
          backendPhase: SteamBackendPhase.ready,
          clearBackendError: true,
          clearBackendMessage: true,
        ),
      );
      _connectEventStream();
      _startPolling();
    } catch (error) {
      final detail = error is StateError ? error.message : '$error';
      _updateState(
        _state.copyWith(
          backendPhase: SteamBackendPhase.error,
          backendError: detail,
          remoteState: SteamRemoteState.empty,
        ),
      );
    }
  }

  Future<void> _waitUntilReady() async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (_disposed) {
        throw StateError('服务已停止');
      }
      if (_processExited) {
        final stderr = _stderrBuffer.toString().trim();
        final stdout = _stdoutBuffer.toString().trim();
        final output = stderr.isNotEmpty ? stderr : stdout;
        throw StateError(output.isEmpty ? 'Steam 侧车服务启动失败' : output);
      }
      try {
        final response = await _httpClient
            .get(_uri('/api/state'))
            .timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          return;
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('Steam 侧车服务启动超时，请确认本机 Python 与依赖已就绪');
  }

  Future<Directory> _prepareBackendDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final backendDir = Directory(
      p.join(supportDir.path, 'steam_status_backend'),
    );
    await backendDir.create(recursive: true);
    for (final asset in _backendAssets) {
      final relativePath = asset.replaceFirst(_backendAssetPrefix, '');
      final file = File(p.join(backendDir.path, relativePath));
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return backendDir;
  }

  Future<int> _findAvailablePort() async {
    for (var port = 38500; port < 38540; port++) {
      try {
        final socket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          port,
        );
        await socket.close();
        return port;
      } catch (_) {}
    }
    throw StateError('没有找到可用的本地端口用于启动 Steam 侧车服务');
  }

  Future<_PythonCommand> _resolvePythonCommand() async {
    const candidates = <_PythonCommand>[
      _PythonCommand('py', <String>['-3']),
      _PythonCommand('python', <String>[]),
      _PythonCommand('python3', <String>[]),
    ];
    for (final candidate in candidates) {
      try {
        final result = await Process.run(candidate.executable, [
          ...candidate.arguments,
          '--version',
        ]);
        if (result.exitCode == 0) {
          return candidate;
        }
      } catch (_) {}
    }
    throw StateError('未找到可用的 Python 3 解释器');
  }

  Future<_PythonCommand> _ensureBackendRuntime(
    _PythonCommand basePythonCommand,
    Directory backendDir,
  ) async {
    final venvDir = Directory(p.join(backendDir.path, '.venv'));
    final runtimePythonPath = Platform.isWindows
        ? p.join(venvDir.path, 'Scripts', 'python.exe')
        : p.join(venvDir.path, 'bin', 'python');
    final runtimePython = File(runtimePythonPath);

    if (!await runtimePython.exists()) {
      _updateState(
        _state.copyWith(backendMessage: '正在创建 Steam 后端专用 Python 虚拟环境...'),
      );
      final result =
          await Process.run(basePythonCommand.executable, [
            ...basePythonCommand.arguments,
            '-m',
            'venv',
            venvDir.path,
          ], workingDirectory: backendDir.path).timeout(
            const Duration(minutes: 2),
            onTimeout: () => throw StateError('创建 Python 虚拟环境超时'),
          );
      if (result.exitCode != 0) {
        throw StateError('创建 Python 虚拟环境失败\n${_processOutput(result)}');
      }
    }

    final runtimeCommand = _PythonCommand(runtimePythonPath, const <String>[]);
    if (await _backendDependenciesReady(runtimeCommand, backendDir)) {
      return runtimeCommand;
    }

    _updateState(
      _state.copyWith(backendMessage: '正在安装 Steam 后端依赖，首次启动可能需要一点时间...'),
    );
    final installResult =
        await Process.run(
          runtimeCommand.executable,
          [
            ...runtimeCommand.arguments,
            '-m',
            'pip',
            'install',
            '-r',
            p.join(backendDir.path, 'requirements.txt'),
          ],
          workingDirectory: backendDir.path,
          environment: _pythonEnvironment(),
        ).timeout(
          const Duration(minutes: 5),
          onTimeout: () => throw StateError('安装 Steam 后端依赖超时'),
        );
    if (installResult.exitCode != 0) {
      throw StateError('安装 Steam 后端依赖失败\n${_processOutput(installResult)}');
    }

    if (!await _backendDependenciesReady(runtimeCommand, backendDir)) {
      throw StateError('Steam 后端依赖安装完成后仍无法导入，请检查 Python 环境');
    }
    return runtimeCommand;
  }

  Future<bool> _backendDependenciesReady(
    _PythonCommand pythonCommand,
    Directory backendDir,
  ) async {
    try {
      final result = await Process.run(
        pythonCommand.executable,
        [
          ...pythonCommand.arguments,
          '-c',
          'import flask, gevent, requests, steam, vdf',
        ],
        workingDirectory: backendDir.path,
        environment: _pythonEnvironment(),
      ).timeout(const Duration(seconds: 20));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_refreshAll());
    });
  }

  void _connectEventStream() {
    _eventReconnectTimer?.cancel();
    unawaited(_openEventStream());
  }

  Future<void> _openEventStream() async {
    if (_disposed || !_state.backendReady) {
      return;
    }
    try {
      final request = http.Request('GET', _uri('/api/events'));
      final response = await _httpClient.send(request);
      if (response.statusCode != 200) {
        throw StateError('事件流连接失败：HTTP ${response.statusCode}');
      }
      await _eventSubscription?.cancel();
      _eventSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleEventLine,
            onDone: _scheduleEventReconnect,
            onError: (_) => _scheduleEventReconnect(),
            cancelOnError: true,
          );
    } catch (_) {
      _scheduleEventReconnect();
    }
  }

  void _scheduleEventReconnect() {
    if (_disposed || !_state.backendReady) {
      return;
    }
    _eventReconnectTimer?.cancel();
    _eventReconnectTimer = Timer(
      const Duration(seconds: 3),
      _connectEventStream,
    );
  }

  void _handleEventLine(String line) {
    try {
      if (!line.startsWith('data:')) {
        return;
      }
      final payload = line.substring(5).trim();
      if (payload.isEmpty) {
        return;
      }
      final data = _decodeJson(payload);
      final eventType = data['type'] as String? ?? '';
      final body = data['data'];
      final eventData = body is Map
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{};
      _handleServerEvent(eventType, eventData);
    } catch (error) {
      _updateState(
        _state.copyWith(
          backendError: '解析 Steam 侧车事件失败：$error',
          loginInProgress: false,
        ),
      );
    }
  }

  void _handleServerEvent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'logged_on':
        _updateState(
          _state.copyWith(
            clearAuthPrompt: true,
            waitingForMobileApproval: false,
            shouldPromptSaveCredentials:
                data['need_save_prompt'] as bool? ?? false,
            clearBackendError: true,
            loginInProgress: false,
            loginMessage: 'Steam 登录成功',
          ),
        );
        unawaited(_refreshAll());
        break;
      case 'login_started':
      case 'login_waiting':
      case 'cm_connecting':
        _updateState(
          _state.copyWith(
            loginInProgress: true,
            loginMessage: data['message'] as String? ?? '正在登录 Steam...',
            clearBackendError: true,
          ),
        );
        break;
      case 'cm_testing':
        _updateState(
          _state.copyWith(
            loginMessage: data['message'] as String? ?? '正在测速 Steam CM 节点...',
            clearBackendError: true,
          ),
        );
        break;
      case 'cm_preference_updated':
        _updateState(
          _state.copyWith(
            cmPreference: _parseCMPreference(data),
            clearBackendError: true,
          ),
        );
        break;
      case 'domain_resolving':
        _updateState(
          _state.copyWith(
            loginMessage: data['message'] as String? ?? '正在解析 Steam 域名...',
            clearBackendError: true,
          ),
        );
        break;
      case 'domain_preference_updated':
        _updateState(
          _state.copyWith(
            domainPreferences: _parseDomainPreferences(data),
            clearBackendError: true,
          ),
        );
        break;
      case 'auth_code_required':
        final isTwoFactor = data['is_two_factor'] as bool? ?? false;
        final mismatch = data['mismatch'] as bool? ?? false;
        _updateState(
          _state.copyWith(
            authPrompt: SteamAuthPrompt(
              title: isTwoFactor ? 'Steam 手机令牌验证' : 'Steam Guard 邮件验证',
              subtitle: mismatch
                  ? '验证码错误，请重新输入'
                  : (data['prompt'] as String? ?? '请输入验证码'),
              isTwoFactor: isTwoFactor,
            ),
            waitingForMobileApproval: false,
            clearBackendError: true,
            loginInProgress: true,
            loginMessage: '需要完成 Steam Guard 验证',
          ),
        );
        break;
      case 'waiting_for_mobile_approval':
        _updateState(
          _state.copyWith(
            clearAuthPrompt: true,
            waitingForMobileApproval: true,
            clearBackendError: true,
            loginInProgress: true,
            loginMessage: '正在等待 Steam 手机 App 批准...',
          ),
        );
        break;
      case 'status_updated':
      case 'status_cleared':
      case 'persona_state_updated':
      case 'persona_state_flags_updated':
        _updateState(_state.copyWith(clearBackendError: true));
        unawaited(_refreshRemoteState());
        break;
      case 'disconnected':
        _updateState(
          _state.copyWith(
            remoteState: _state.remoteState.copyWith(loggedIn: false),
            backendError: '与 Steam 的连接已断开',
            loginInProgress: false,
          ),
        );
        unawaited(_refreshRemoteState());
        break;
      case 'error':
        _updateState(
          _state.copyWith(
            backendError: data['message'] as String? ?? 'Steam 操作失败',
            clearAuthPrompt: true,
            waitingForMobileApproval: false,
            loginInProgress: false,
            clearLoginMessage: true,
          ),
        );
        unawaited(_refreshRemoteState());
        break;
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshRemoteState(),
      _refreshSavedAccounts(),
      _refreshCMPreference(),
      _refreshDomainPreference(),
    ]);
  }

  Future<void> _refreshRemoteState() async {
    if (_state.port == null) {
      return;
    }
    try {
      final response = await _httpClient.get(_uri('/api/state'));
      if (response.statusCode != 200) {
        return;
      }
      final payload = _decodeJson(response.body);
      final remoteState = SteamRemoteState(
        loggedIn: payload['logged_in'] as bool? ?? false,
        username: _normalizeOptional(payload['username'] as String?),
        currentStatus: _normalizeOptional(payload['current_status'] as String?),
        currentAppId: payload['current_app_id'] as int?,
        currentRichText: _normalizeOptional(
          payload['current_rich_text'] as String?,
        ),
        personaState: payload['current_persona_state'] as int? ?? 1,
        personaStateName:
            payload['current_persona_state_name'] as String? ?? 'Online',
        personaStateFlags: payload['current_persona_state_flags'] as int? ?? 0,
      );
      _updateState(
        _state.copyWith(
          remoteState: remoteState,
          cmPreference: _parseCMPreference(payload['cm_preference']),
          domainPreferences: _parseDomainPreferences(
            payload['domain_preference'],
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _refreshCMPreference() async {
    if (_state.port == null) {
      return;
    }
    try {
      final response = await _httpClient.get(_uri('/api/cm_preference'));
      if (response.statusCode != 200) {
        return;
      }
      final payload = _decodeJson(response.body);
      _updateState(
        _state.copyWith(
          cmPreference: _parseCMPreference(payload['cm_preference']),
        ),
      );
    } catch (_) {}
  }

  Future<void> _refreshDomainPreference() async {
    if (_state.port == null) {
      return;
    }
    try {
      final response = await _httpClient.get(_uri('/api/domain_preference'));
      if (response.statusCode != 200) {
        return;
      }
      final payload = _decodeJson(response.body);
      _updateState(
        _state.copyWith(
          domainPreferences: _parseDomainPreferences(
            payload['domain_preference'],
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _refreshSavedAccounts() async {
    if (_state.port == null) {
      return;
    }
    try {
      final response = await _httpClient.get(_uri('/api/saved_accounts'));
      if (response.statusCode != 200) {
        return;
      }
      final payload = _decodeJson(response.body);
      final accountsRaw = payload['accounts'];
      if (accountsRaw is! List) {
        return;
      }
      final accounts = accountsRaw
          .whereType<Map>()
          .map(
            (item) => SteamAccount(username: item['username'] as String? ?? ''),
          )
          .where((item) => item.username.isNotEmpty)
          .toList();
      _updateState(_state.copyWith(savedAccounts: accounts));
    } catch (_) {}
  }

  Future<SteamActionResult> _postAction(
    String path, {
    required Map<String, dynamic> body,
    required String successMessage,
    Future<void> Function()? onSuccess,
    bool clearPrompt = false,
    bool keepLoginInProgress = false,
  }) async {
    return _sendJsonAction(
      () => _httpClient.post(
        _uri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
      successMessage: successMessage,
      onSuccess: onSuccess,
      clearPrompt: clearPrompt,
      keepLoginInProgress: keepLoginInProgress,
    );
  }

  Future<SteamActionResult> _deleteAction(
    String path, {
    required Map<String, dynamic> body,
    required String successMessage,
    Future<void> Function()? onSuccess,
  }) async {
    return _sendJsonAction(
      () => _httpClient.delete(
        _uri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
      successMessage: successMessage,
      onSuccess: onSuccess,
    );
  }

  Future<SteamActionResult> _sendJsonAction(
    Future<http.Response> Function() request, {
    required String successMessage,
    Future<void> Function()? onSuccess,
    bool clearPrompt = false,
    bool keepLoginInProgress = false,
  }) async {
    if (!_state.backendReady) {
      const message = 'Steam 侧车服务尚未就绪';
      _updateState(
        _state.copyWith(
          backendError: message,
          loginInProgress: false,
          clearLoginMessage: true,
        ),
      );
      return const SteamActionResult(success: false, message: message);
    }
    try {
      final response = await request();
      final payload = _decodeJson(response.body);
      final success = payload['success'] as bool? ?? false;
      if (!success || response.statusCode >= 400) {
        final message = payload['error'] as String? ?? '请求失败';
        _updateState(
          _state.copyWith(backendError: message, loginInProgress: false),
        );
        return SteamActionResult(success: false, message: message);
      }
      if (clearPrompt) {
        _updateState(
          _state.copyWith(
            clearAuthPrompt: true,
            waitingForMobileApproval: false,
            clearBackendError: true,
            loginInProgress: keepLoginInProgress
                ? true
                : _state.loginInProgress,
            loginMessage: keepLoginInProgress
                ? (payload['message'] as String? ?? successMessage)
                : _state.loginMessage,
          ),
        );
      } else {
        _updateState(_state.copyWith(clearBackendError: true));
      }
      if (onSuccess != null) {
        await onSuccess();
      }
      return SteamActionResult(success: true, message: successMessage);
    } catch (error) {
      final message = '请求失败：$error';
      _updateState(
        _state.copyWith(backendError: message, loginInProgress: false),
      );
      return SteamActionResult(success: false, message: message);
    }
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: _state.port ?? 5000,
      path: path,
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _pythonEnvironment() {
    return {...Platform.environment, 'PYTHONUTF8': '1'};
  }

  String _processOutput(ProcessResult result) {
    final stdoutText = '${result.stdout}'.trim();
    final stderrText = '${result.stderr}'.trim();
    final parts = <String>[
      if (stdoutText.isNotEmpty) stdoutText,
      if (stderrText.isNotEmpty) stderrText,
    ];
    final output = parts.join('\n').trim();
    if (output.length > 4000) {
      return '${output.substring(0, 4000)}\n...（输出已截断）';
    }
    return output.isEmpty ? '进程退出码：${result.exitCode}' : output;
  }

  Map<String, dynamic> _decodeJson(String source) {
    if (source.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  SteamCMPreference _parseCMPreference(Object? source) {
    if (source is! Map) {
      return _state.cmPreference;
    }
    final map = Map<String, dynamic>.from(source);
    final serversRaw = map['servers'];
    final servers = serversRaw is List
        ? serversRaw
              .whereType<Map>()
              .map((item) {
                final server = Map<String, dynamic>.from(item);
                final latency = server['latency_ms'];
                return SteamCMServer(
                  endpoint: server['endpoint'] as String? ?? '',
                  host: server['host'] as String? ?? '',
                  port: server['port'] as int? ?? 0,
                  success: server['success'] as bool? ?? false,
                  latencyMs: latency is num ? latency.toDouble() : null,
                  error: _normalizeOptional(server['error'] as String?),
                );
              })
              .where((server) => server.endpoint.isNotEmpty)
              .toList()
        : _state.cmPreference.servers;
    final lastAppliedRaw = map['last_applied'];
    final checkedAtRaw = map['last_checked_at'];
    return SteamCMPreference(
      enabled: map['enabled'] as bool? ?? _state.cmPreference.enabled,
      servers: servers,
      lastCheckedAt: checkedAtRaw is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (checkedAtRaw * 1000).round(),
              isUtc: false,
            )
          : null,
      lastError: _normalizeOptional(map['last_error'] as String?),
      lastApplied: lastAppliedRaw is List
          ? lastAppliedRaw.whereType<String>().toList()
          : _state.cmPreference.lastApplied,
      maxCount: map['max_count'] as int? ?? _state.cmPreference.maxCount,
      timeoutSeconds: map['timeout_seconds'] is num
          ? (map['timeout_seconds'] as num).toDouble()
          : _state.cmPreference.timeoutSeconds,
    );
  }

  List<SteamDomainPreference> _parseDomainPreferences(Object? source) {
    if (source is! Map) {
      return _state.domainPreferences;
    }
    final map = Map<String, dynamic>.from(source);
    final domainsRaw = map['domains'];
    if (domainsRaw is! List) {
      return _state.domainPreferences;
    }
    return domainsRaw
        .whereType<Map>()
        .map((item) {
          final domain = Map<String, dynamic>.from(item);
          final ipsRaw = domain['ips'];
          final selectedIpsRaw = domain['selected_ips'];
          final resolvedAtRaw = domain['last_resolved_at'];
          final ips = ipsRaw is List
              ? ipsRaw
                    .whereType<Map>()
                    .map((ipItem) {
                      final ip = Map<String, dynamic>.from(ipItem);
                      final latency = ip['latency_ms'];
                      return SteamDomainIp(
                        address: ip['address'] as String? ?? '',
                        success: ip['success'] as bool? ?? false,
                        selected: ip['selected'] as bool? ?? false,
                        latencyMs: latency is num ? latency.toDouble() : null,
                        location: _normalizeOptional(ip['location'] as String?),
                        error: _normalizeOptional(ip['error'] as String?),
                      );
                    })
                    .where((ip) => ip.address.isNotEmpty)
                    .toList()
              : const <SteamDomainIp>[];
          return SteamDomainPreference(
            domain: domain['domain'] as String? ?? '',
            label: domain['label'] as String? ?? '',
            description: domain['description'] as String? ?? '',
            enabled: domain['enabled'] as bool? ?? true,
            ips: ips,
            lastResolvedAt: resolvedAtRaw is num
                ? DateTime.fromMillisecondsSinceEpoch(
                    (resolvedAtRaw * 1000).round(),
                    isUtc: false,
                  )
                : null,
            lastError: _normalizeOptional(domain['last_error'] as String?),
            port: domain['port'] as int? ?? 443,
            selectedIps: selectedIpsRaw is List
                ? selectedIpsRaw.whereType<String>().toList()
                : const <String>[],
          );
        })
        .where((domain) => domain.domain.isNotEmpty)
        .toList();
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _beginLogin(String message) {
    _updateState(
      _state.copyWith(
        loginInProgress: true,
        loginMessage: message,
        clearAuthPrompt: true,
        waitingForMobileApproval: false,
        clearBackendError: true,
      ),
    );
  }

  void _endLogin({bool clearMessage = false}) {
    _updateState(
      _state.copyWith(loginInProgress: false, clearLoginMessage: clearMessage),
    );
  }

  void _handleBackendProcessExit(int exitCode) {
    if (_disposed || _process == null) {
      return;
    }
    _pollTimer?.cancel();
    _eventReconnectTimer?.cancel();
    final stderr = _stderrBuffer.toString().trim();
    final stdout = _stdoutBuffer.toString().trim();
    final output = stderr.isNotEmpty ? stderr : stdout;
    final message = output.isEmpty
        ? 'Steam 侧车服务已退出，退出码：$exitCode'
        : 'Steam 侧车服务已退出，退出码：$exitCode\n$output';
    _updateState(
      _state.copyWith(
        backendPhase: SteamBackendPhase.error,
        backendError: message,
        loginInProgress: false,
        clearLoginMessage: true,
      ),
    );
  }

  void _updateState(SteamToolState next) {
    _state = next;
    _emit(next);
  }

  void _emit(SteamToolState value) {
    if (_disposed || _stateController.isClosed) {
      return;
    }
    _stateController.add(value);
  }
}

class _PythonCommand {
  const _PythonCommand(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}
