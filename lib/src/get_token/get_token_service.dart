import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'get_token_models.dart';
import 'get_token_repository.dart';

const _defaultBaseUrl = 'http://8.211.131.13:8317/v0/management';
const _defaultManagementKey = 'EUrd@qq1';
const _usageEventsBaseUrl = 'http://8.211.131.13:8080/api/v1/usage/events';

final getTokenControllerProvider = Provider<GetTokenController>((ref) {
  final controller = GetTokenController(
    repository: ref.watch(getTokenRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  controller.start();
  return controller;
});

final getTokenToolStateProvider = StreamProvider<GetTokenToolState>((ref) {
  return ref.watch(getTokenControllerProvider).stream;
});

class GetTokenController {
  GetTokenController({
    required GetTokenRepository repository,
    GetTokenService? service,
  }) : _repository = repository,
       _service = service ?? GetTokenService();

  final GetTokenRepository _repository;
  final GetTokenService _service;
  final StreamController<GetTokenToolState> _stateController =
      StreamController<GetTokenToolState>.broadcast();

  GetTokenToolState _state = GetTokenToolState.initial;
  bool _disposed = false;
  bool _started = false;

  Stream<GetTokenToolState> get stream => _stateController.stream;

  void dispose() {
    _disposed = true;
    _service.dispose();
    _stateController.close();
  }

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _emit(_state);
    await reload();
  }

  Future<void> reload() async {
    try {
      final results = await Future.wait<dynamic>([
        _repository.loadConfig(),
        _repository.loadSecretConfig(),
        _repository.loadCollectionSnapshot(),
        _repository.loadCredentialRows(),
        _repository.loadUsageSnapshot(),
      ]);
      _state = _state.copyWith(
        loading: false,
        config: results[0] as GetTokenConfig,
        secret: results[1] as GetTokenSecretConfig,
        collection: results[2] as GetTokenCollectionSnapshot?,
        credentials: results[3] as List<GetTokenCredentialRow>,
        usageSnapshot: results[4] as GetTokenUsageSnapshot?,
        running: false,
        collecting: false,
        queryingTokenUsage: false,
        clearErrorMessage: true,
      );
      _emit(_state);
    } catch (error) {
      _emit(
        _state.copyWith(
          loading: false,
          errorMessage: '加载 get_token 数据失败：$error',
        ),
      );
    }
  }

  Future<GetTokenActionResult> saveConfig(GetTokenConfig config) async {
    try {
      await _repository.saveConfig(config);
      _emit(_state.copyWith(config: config, clearErrorMessage: true));
      return const GetTokenActionResult(success: true, message: '配置已保存');
    } catch (error) {
      return GetTokenActionResult(success: false, message: '配置保存失败：$error');
    }
  }

  Future<GetTokenActionResult> saveSecretConfig(
    GetTokenSecretConfig config,
  ) async {
    try {
      await _repository.saveSecretConfig(config);
      _emit(_state.copyWith(secret: config, clearErrorMessage: true));
      return const GetTokenActionResult(success: true, message: '管理密钥已保存到本机');
    } catch (error) {
      return GetTokenActionResult(success: false, message: '管理密钥保存失败：$error');
    }
  }

  Future<GetTokenActionResult> runCollection() async {
    final previousRows = await _repository.loadCredentialRows();
    final runtimeCreatedAt = DateTime.now().toUtc();
    _emit(
      _state.copyWith(
        collecting: true,
        running: true,
        clearErrorMessage: true,
        collection: GetTokenCollectionSnapshot(
          status: 'running',
          message: '正在拉取凭证列表',
          processed: 0,
          total: 0,
          progressPercent: 0,
          createdAt: runtimeCreatedAt,
          updatedAt: runtimeCreatedAt,
        ),
      ),
    );
    try {
      final result = await _service.collectCredentials(
        config: _state.config,
        secret: _state.secret,
        previousRows: previousRows,
        onProgress: (progress) {
          final snapshot = GetTokenCollectionSnapshot(
            status: 'running',
            message: progress.message,
            processed: progress.processed,
            total: progress.total,
            progressPercent: progress.progressPercent,
            createdAt: runtimeCreatedAt,
            updatedAt: DateTime.now().toUtc(),
          );
          _emit(
            _state.copyWith(
              collecting: true,
              running: true,
              collection: snapshot,
              credentials: progress.credentials,
            ),
          );
        },
      );
      await _repository.saveCollectionSnapshot(
        snapshot: result.snapshot,
        credentials: result.credentials,
      );
      _emit(
        _state.copyWith(
          collecting: false,
          running: false,
          collection: result.snapshot,
          credentials: result.credentials,
          clearErrorMessage: true,
        ),
      );
      return const GetTokenActionResult(success: true, message: '采集完成');
    } catch (error) {
      _emit(
        _state.copyWith(
          collecting: false,
          running: false,
          errorMessage: '$error',
        ),
      );
      return GetTokenActionResult(success: false, message: '$error');
    }
  }

  Future<GetTokenActionResult> queryTokenUsage({
    GetTokenUsageQuery? query,
  }) async {
    final currentQuery =
        query ??
        GetTokenUsageQuery(
          apiRange: _state.config.apiRange,
          apiStart: _state.config.apiStart,
          apiEnd: _state.config.apiEnd,
          cacheRange: _state.config.cacheRange,
          cacheStart: _state.config.cacheStart,
          cacheEnd: _state.config.cacheEnd,
          pageSize: _state.config.pageSize,
          refreshQuota: _state.config.refreshQuota,
          quotaCacheTtlSeconds: _state.config.quotaCacheTtlSeconds,
        );
    _emit(_state.copyWith(queryingTokenUsage: true, clearErrorMessage: true));
    try {
      final previousUsageSnapshot = await _repository.loadUsageSnapshot();
      final credentialRows = await _repository.loadCredentialRows();
      final existingEvents = await _repository.loadUsageEvents();
      final result = await _service.collectTokenUsage(
        config: _state.config,
        secret: _state.secret,
        query: currentQuery,
        existingEvents: existingEvents,
        previousRows: previousUsageSnapshot?.rows ?? const <GetTokenUsageRow>[],
        currentCredentialRows: credentialRows,
      );
      await _repository.mergeUsageEvents(result.events);
      await _repository.saveUsageSnapshot(result.snapshot);
      _emit(
        _state.copyWith(
          queryingTokenUsage: false,
          usageSnapshot: result.snapshot,
          credentials: credentialRows,
          clearErrorMessage: true,
        ),
      );
      return const GetTokenActionResult(
        success: true,
        message: 'Token 使用统计已更新',
      );
    } catch (error) {
      _emit(_state.copyWith(queryingTokenUsage: false, errorMessage: '$error'));
      return GetTokenActionResult(success: false, message: '$error');
    }
  }

  Future<GetTokenActionResult> clearTokenUsageCache() async {
    try {
      await _repository.clearUsageCache();
      _emit(_state.copyWith(clearUsageSnapshot: true, clearErrorMessage: true));
      return const GetTokenActionResult(
        success: true,
        message: 'Token 使用缓存已清除',
      );
    } catch (error) {
      return GetTokenActionResult(
        success: false,
        message: 'Token 使用缓存清除失败：$error',
      );
    }
  }

  Future<GetTokenActionResult> refreshCredentialQuota(String authIndex) async {
    if (authIndex.trim().isEmpty) {
      return const GetTokenActionResult(
        success: false,
        message: '缺少 auth_index',
      );
    }
    final previousRows = await _repository.loadCredentialRows();
    final existingSnapshot = await _repository.loadCollectionSnapshot();
    if (existingSnapshot == null) {
      return const GetTokenActionResult(
        success: false,
        message: '当前没有可刷新的采集结果',
      );
    }
    _emit(
      _state.copyWith(refreshingAuthIndex: authIndex, clearErrorMessage: true),
    );
    try {
      final result = await _service.refreshCredentialQuota(
        config: _state.config,
        secret: _state.secret,
        authIndex: authIndex,
        previousRows: previousRows,
        previousSnapshot: existingSnapshot,
      );
      await _repository.saveCollectionSnapshot(
        snapshot: result.snapshot,
        credentials: result.credentials,
      );
      var usageSnapshot = await _repository.loadUsageSnapshot();
      if (usageSnapshot != null) {
        usageSnapshot = _service.patchUsageSnapshotWithCredentialRefresh(
          usageSnapshot: usageSnapshot,
          refreshedCredentials: result.credentials,
          targetAuthIndex: authIndex,
        );
        await _repository.saveUsageSnapshot(usageSnapshot);
      }
      _emit(
        _state.copyWith(
          refreshingAuthIndex: authIndex,
          credentials: result.credentials,
          collection: result.snapshot,
          usageSnapshot: usageSnapshot,
          clearRefreshingAuthIndex: true,
          clearErrorMessage: true,
        ),
      );
      return const GetTokenActionResult(success: true, message: '单个凭证额度已刷新');
    } catch (error) {
      _emit(
        _state.copyWith(clearRefreshingAuthIndex: true, errorMessage: '$error'),
      );
      return GetTokenActionResult(success: false, message: '$error');
    }
  }

  void _emit(GetTokenToolState next) {
    _state = next;
    if (_disposed || _stateController.isClosed) {
      return;
    }
    _stateController.add(next);
  }
}

class GetTokenService {
  GetTokenService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() {
    _client.close();
  }

  Future<GetTokenCollectionResult> collectCredentials({
    required GetTokenConfig config,
    required GetTokenSecretConfig secret,
    required List<GetTokenCredentialRow> previousRows,
    void Function(GetTokenCollectionProgress progress)? onProgress,
  }) async {
    final resolved = _ResolvedConfig.from(config: config, secret: secret);
    final authFiles = await _fetchAuthFiles(resolved);
    final limitedFiles = resolved.limit == null
        ? authFiles
        : authFiles.take(resolved.limit!).toList();
    final previousByKey = {
      for (final row in previousRows) row.id: _credentialInfoFromRow(row),
    };
    final currentCredentials = _credentialMap(limitedFiles);
    final total = limitedFiles.length;
    if (total == 0) {
      final summary = const GetTokenSummary();
      final changes = _compareWithPrevious(
        previous: previousByKey,
        current: currentCredentials,
      );
      final refreshStats = const GetTokenRefreshStats();
      final now = DateTime.now().toUtc();
      return GetTokenCollectionResult(
        snapshot: GetTokenCollectionSnapshot(
          status: 'completed',
          message: '未获取到任何凭证',
          processed: 0,
          total: 0,
          progressPercent: 100,
          createdAt: now,
          updatedAt: now,
          completedAt: now,
          summary: summary,
          credentialChanges: changes,
          refreshStats: refreshStats,
        ),
        credentials: const <GetTokenCredentialRow>[],
      );
    }

    final successes = <Map<String, dynamic>>[];
    final failures = <Map<String, dynamic>>[];
    final credentials = <GetTokenCredentialRow>[];
    var processed = 0;
    final createdAt = DateTime.now().toUtc();
    for (var i = 0; i < limitedFiles.length; i += resolved.batchSize) {
      final batch = limitedFiles.skip(i).take(resolved.batchSize).toList();
      final results = await Future.wait(
        batch.map((item) async {
          try {
            return _UsageFetchResult(
              success: await _fetchSingleUsage(item, resolved),
            );
          } catch (error) {
            return _UsageFetchResult(error: _formatError(error), source: item);
          }
        }),
      );
      for (final result in results) {
        processed += 1;
        if (result.success != null) {
          successes.add(result.success!);
        } else if (result.source != null) {
          failures.add({
            'email': _emailLabel(result.source!),
            'auth_index': result.source!['auth_index'],
            'error': result.error ?? '未知错误',
            'name': result.source!['name'],
          });
        }
        final transientRows = _buildCredentialRows(
          credentialsMap: _enrichCredentialsWithUsage(
            currentCredentials,
            successes,
            failures,
          ),
        );
        credentials
          ..clear()
          ..addAll(transientRows);
        onProgress?.call(
          GetTokenCollectionProgress(
            message: '已完成 $processed/$total',
            processed: processed,
            total: total,
            progressPercent: total == 0 ? 0 : (processed / total) * 100,
            credentials: transientRows,
          ),
        );
      }
    }

    final summary = _classifyResults(successes, failures, total);
    final refreshStats = _buildRefreshStats(successes, failures);
    final enriched = _enrichCredentialsWithUsage(
      currentCredentials,
      successes,
      failures,
    );
    final changes = _compareWithPrevious(
      previous: previousByKey,
      current: enriched,
    );
    final rows = _buildCredentialRows(credentialsMap: enriched);
    final completedAt = DateTime.now().toUtc();
    return GetTokenCollectionResult(
      snapshot: GetTokenCollectionSnapshot(
        status: 'completed',
        message: '采集完成',
        processed: total,
        total: total,
        progressPercent: 100,
        createdAt: createdAt,
        updatedAt: completedAt,
        completedAt: completedAt,
        summary: summary,
        credentialChanges: changes,
        refreshStats: refreshStats,
      ),
      credentials: rows,
    );
  }

  Future<GetTokenUsageCollectionResult> collectTokenUsage({
    required GetTokenConfig config,
    required GetTokenSecretConfig secret,
    required GetTokenUsageQuery query,
    required List<GetTokenUsageEvent> existingEvents,
    required List<GetTokenUsageRow> previousRows,
    required List<GetTokenCredentialRow> currentCredentialRows,
  }) async {
    final resolved = _ResolvedConfig.from(config: config, secret: secret);
    _validateRange(
      query.apiRange,
      query.apiStart,
      query.apiEnd,
      label: 'api_range',
    );
    _validateRange(
      query.cacheRange,
      query.cacheStart,
      query.cacheEnd,
      label: 'cache_range',
    );
    if (!const {20, 50, 100, 500, 1000}.contains(query.pageSize)) {
      throw GetTokenServiceException('page_size 只能是 20、50、100、500、1000');
    }

    final upstream = await _fetchUsageEvents(
      rangeValue: query.apiRange,
      pageSize: query.pageSize,
      timeout: resolved.timeout,
      start: query.apiStart,
      end: query.apiEnd,
    );
    final upstreamEvents = _listOfMaps(
      upstream['events'],
    ).map(GetTokenUsageEvent.fromJson).toList();
    final mergedEvents = _mergeUsageEvents(existingEvents, upstreamEvents);
    final displayEvents = mergedEvents.events.where((event) {
      return _eventMatchesRange(
        event,
        query.cacheRange,
        start: query.cacheStart,
        end: query.cacheEnd,
      );
    }).toList();
    final aggregate = _aggregateUsageEvents(displayEvents);
    final changedAuthIndices = <String>{
      for (final row in aggregate.rows)
        if (_rowChanged(row, previousRows)) row.authIndex,
    };
    final enrichedRows = await _attachCurrentQuota(
      rows: aggregate.rows,
      resolved: resolved,
      currentCredentialRows: currentCredentialRows,
      previousRows: previousRows,
      refreshQuota: query.refreshQuota,
      changedAuthIndices: changedAuthIndices,
      quotaCacheTtlSeconds: query.quotaCacheTtlSeconds,
    );
    final now = DateTime.now().toUtc();
    return GetTokenUsageCollectionResult(
      events: upstreamEvents,
      snapshot: GetTokenUsageSnapshot(
        updatedAt: now,
        params: query,
        eventTableCount: mergedEvents.events.length,
        addedEventCount: mergedEvents.addedCount,
        summary: aggregate.summary,
        rows: enrichedRows,
        upstream: GetTokenUpstreamInfo.fromJson(upstream),
      ),
    );
  }

  Future<GetTokenCollectionResult> refreshCredentialQuota({
    required GetTokenConfig config,
    required GetTokenSecretConfig secret,
    required String authIndex,
    required List<GetTokenCredentialRow> previousRows,
    required GetTokenCollectionSnapshot previousSnapshot,
  }) async {
    final resolved = _ResolvedConfig.from(config: config, secret: secret);
    final authFiles = await _fetchAuthFiles(resolved);
    final target = {
      for (final item in authFiles) (item['auth_index'] ?? '').toString(): item,
    }[authIndex];
    if (target == null) {
      throw GetTokenServiceException('未找到凭证：$authIndex');
    }
    final usage = await _fetchSingleUsage(target, resolved);
    final currentMap = {
      for (final row in previousRows) row.id: _credentialInfoFromRow(row),
    };
    final key = _credentialKey(target);
    currentMap[key] = {
      ...currentMap[key] ?? _credentialInfo(target),
      'remaining_percent': usage['remaining_percent'],
      'used_percent': usage['used_percent'],
      'last_query_status': 'success',
      'last_error': null,
      'limit_reached': usage['limit_reached'],
      'reset_at': usage['reset_at'],
      'reset_after_seconds': usage['reset_after_seconds'],
      'limit_window_seconds': usage['limit_window_seconds'],
      'raw': usage['raw'],
    };

    final rows = _buildCredentialRows(credentialsMap: currentMap);
    final successes = rows
        .where((row) => !row.isFailure)
        .map(_rowToUsageMap)
        .toList();
    final failures = rows.where((row) => row.isFailure).map((row) {
      return {
        'email': row.email,
        'auth_index': row.authIndex,
        'error': row.error,
      };
    }).toList();
    final summary = _classifyResults(successes, failures, rows.length);
    final refreshStats = _buildRefreshStats(successes, failures);
    final snapshot = GetTokenCollectionSnapshot(
      status: 'completed',
      message: '已刷新单个凭证额度',
      processed: previousSnapshot.total,
      total: previousSnapshot.total,
      progressPercent: 100,
      createdAt: previousSnapshot.createdAt,
      updatedAt: DateTime.now().toUtc(),
      completedAt: DateTime.now().toUtc(),
      summary: summary,
      credentialChanges: previousSnapshot.credentialChanges,
      refreshStats: refreshStats,
    );
    return GetTokenCollectionResult(snapshot: snapshot, credentials: rows);
  }

  GetTokenUsageSnapshot patchUsageSnapshotWithCredentialRefresh({
    required GetTokenUsageSnapshot usageSnapshot,
    required List<GetTokenCredentialRow> refreshedCredentials,
    required String targetAuthIndex,
  }) {
    final byAuth = {
      for (final row in refreshedCredentials)
        if (row.authIndex != null && row.authIndex!.isNotEmpty)
          row.authIndex!: row,
    };
    final nowSeconds =
        DateTime.now().toUtc().millisecondsSinceEpoch.toDouble() / 1000;
    final rows = usageSnapshot.rows.map((row) {
      if (row.authIndex != targetAuthIndex) {
        return row;
      }
      final credential = byAuth[targetAuthIndex];
      if (credential == null || credential.isFailure) {
        return row;
      }
      return GetTokenUsageRow(
        authIndex: row.authIndex,
        source: row.source,
        sourceType: row.sourceType,
        requestCount: row.requestCount,
        failedCount: row.failedCount,
        inputTokens: row.inputTokens,
        outputTokens: row.outputTokens,
        reasoningTokens: row.reasoningTokens,
        cachedTokens: row.cachedTokens,
        totalTokens: row.totalTokens,
        latestTimestamp: row.latestTimestamp,
        models: row.models,
        currentUsage: GetTokenCurrentUsage(
          remainingPercent: credential.remainingPercent,
          usedPercent: credential.usedPercent,
          planType: credential.planType,
          limitReached: credential.limitReached,
          resetAt: credential.resetAt,
          resetAfterSeconds: credential.resetAfterSeconds,
          limitWindowSeconds: credential.limitWindowSeconds,
        ),
        quotaCachedAt: nowSeconds,
        usageError: null,
      );
    }).toList();
    return GetTokenUsageSnapshot(
      updatedAt: usageSnapshot.updatedAt,
      params: usageSnapshot.params,
      eventTableCount: usageSnapshot.eventTableCount,
      addedEventCount: usageSnapshot.addedEventCount,
      summary: usageSnapshot.summary,
      rows: rows,
      upstream: usageSnapshot.upstream,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAuthFiles(
    _ResolvedConfig config,
  ) async {
    final payload = await _requestJson(
      Uri.parse('${config.baseUrl}/auth-files'),
      headers: _buildCommonHeaders(config),
      timeoutSeconds: config.timeout,
    );
    final files = payload['files'];
    if (files is! List) {
      throw const GetTokenServiceException('auth-files 返回结构异常，缺少 files 列表');
    }
    return files
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _fetchSingleUsage(
    Map<String, dynamic> item,
    _ResolvedConfig config,
  ) async {
    final authIndex = item['auth_index'];
    final accountId = _map(item['id_token'])['chatgpt_account_id'];
    if (authIndex == null || authIndex.toString().trim().isEmpty) {
      throw const GetTokenServiceException('缺少 auth_index');
    }
    if (accountId == null || accountId.toString().trim().isEmpty) {
      throw const GetTokenServiceException('缺少 chatgpt_account_id');
    }
    final payload = {
      'authIndex': authIndex,
      'method': 'GET',
      'url': 'https://chatgpt.com/backend-api/wham/usage',
      'header': {
        'Authorization': 'Bearer \$TOKEN\$',
        'Content-Type': 'application/json',
        'User-Agent':
            'codex_cli_rs/0.76.0 (Debian 13.0.0; x86_64) WindowsTerminal',
        'Chatgpt-Account-Id': accountId,
      },
    };
    final data = await _requestJson(
      Uri.parse('${config.baseUrl}/api-call'),
      method: 'POST',
      headers: _buildCommonHeaders(config),
      body: payload,
      timeoutSeconds: config.timeout,
    );
    if ((data['status_code'] as num?)?.toInt() != 200) {
      throw GetTokenServiceException(
        '远端返回 status_code=${data['status_code'] ?? 'unknown'}',
      );
    }
    final usage = _parseUsageBody(data['body']);
    final primaryWindow = _map(_map(usage['rate_limit'])['primary_window']);
    final usedPercent = primaryWindow['used_percent'];
    if (usedPercent == null) {
      throw const GetTokenServiceException('usage 中缺少 used_percent');
    }
    final used = (usedPercent as num).toDouble();
    return {
      'email': _emailLabel(item),
      'auth_index': authIndex.toString(),
      'account_id': accountId.toString(),
      'plan_type': usage['plan_type']?.toString(),
      'used_percent': used,
      'remaining_percent': (100 - used).clamp(0, 100).toDouble(),
      'reset_at': primaryWindow['reset_at']?.toString(),
      'reset_after_seconds': (primaryWindow['reset_after_seconds'] as num?)
          ?.toInt(),
      'limit_window_seconds': (primaryWindow['limit_window_seconds'] as num?)
          ?.toInt(),
      'limit_reached': _map(usage['rate_limit'])['limit_reached'] as bool?,
      'name': item['name']?.toString(),
      'raw': usage,
    };
  }

  Future<Map<String, dynamic>> _fetchUsageEvents({
    required String rangeValue,
    required int pageSize,
    required int timeout,
    String? start,
    String? end,
  }) async {
    final uri = Uri.parse(_usageEventsBaseUrl).replace(
      queryParameters: {
        'range': rangeValue,
        'page': '1',
        'page_size': '$pageSize',
        if (rangeValue == 'custom') 'start': start ?? '',
        if (rangeValue == 'custom') 'end': end ?? '',
      },
    );
    return _requestJson(
      uri,
      headers: const {
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
        'Sec-GPC': '1',
        'Referer': 'http://8.211.131.13:8080/',
      },
      timeoutSeconds: timeout,
    );
  }

  Future<Map<String, dynamic>> _requestJson(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    int timeoutSeconds = 30,
  }) async {
    late http.Response response;
    final mergedHeaders = <String, String>{...?headers};
    if (body != null) {
      mergedHeaders['Content-Type'] = 'application/json';
    }
    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: mergedHeaders, body: jsonEncode(body))
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        default:
          response = await _client
              .get(uri, headers: mergedHeaders)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
      }
    } on TimeoutException {
      throw GetTokenServiceException('请求超时：${uri.toString()}');
    } catch (error) {
      throw GetTokenServiceException('网络错误：$error');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GetTokenServiceException(
        'HTTP ${response.statusCode}: ${response.body.isEmpty ? response.reasonPhrase ?? 'unknown' : response.body}',
      );
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      throw GetTokenServiceException('接口返回 JSON 解析失败：$error');
    }
    throw const GetTokenServiceException('接口返回格式异常');
  }

  Map<String, String> _buildCommonHeaders(_ResolvedConfig config) {
    return {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
      'Authorization': 'Bearer ${config.managementKey}',
      'Sec-GPC': '1',
      'Referer': 'http://8.211.131.13:8317/management.html',
    };
  }

  Map<String, dynamic> _parseUsageBody(Object? body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    if (body is String) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw const GetTokenServiceException('usage body 不是对象');
  }

  Map<String, Map<String, dynamic>> _credentialMap(
    List<Map<String, dynamic>> authFiles,
  ) {
    return {
      for (final item in authFiles) _credentialKey(item): _credentialInfo(item),
    };
  }

  Map<String, dynamic> _credentialInfo(Map<String, dynamic> item) {
    final idToken = _map(item['id_token']);
    return {
      'key': _credentialKey(item),
      'email': _emailLabel(item),
      'auth_index': item['auth_index']?.toString(),
      'account_id': idToken['chatgpt_account_id']?.toString(),
      'plan_type': idToken['plan_type']?.toString(),
      'name': item['name']?.toString(),
    };
  }

  Map<String, dynamic> _credentialInfoFromRow(GetTokenCredentialRow row) {
    return {
      'key': row.id,
      'email': row.email,
      'auth_index': row.authIndex,
      'account_id': row.accountId,
      'plan_type': row.planType,
      'name': row.name,
      'remaining_percent': row.remainingPercent,
      'used_percent': row.usedPercent,
      'last_query_status': row.status,
      'last_error': row.error,
      'limit_reached': row.limitReached,
      'reset_at': row.resetAt?.toUtc().toIso8601String(),
      'reset_after_seconds': row.resetAfterSeconds,
      'limit_window_seconds': row.limitWindowSeconds,
      'raw': row.raw,
      'last_success_preserved': row.lastSuccessPreserved,
    };
  }

  String _credentialKey(Map<String, dynamic> item) {
    return (item['auth_index'] ??
            item['id'] ??
            item['email'] ??
            item['account'] ??
            item['name'] ??
            'unknown')
        .toString();
  }

  String _emailLabel(Map<String, dynamic> item) {
    return (item['email'] ?? item['account'] ?? item['name'] ?? 'unknown')
        .toString();
  }

  GetTokenSummary _classifyResults(
    List<Map<String, dynamic>> successes,
    List<Map<String, dynamic>> failures,
    int totalCredentials,
  ) {
    final remainingValues = successes
        .map((item) => (item['remaining_percent'] as num?)?.toDouble() ?? 0)
        .toList();
    final below50 = remainingValues.where((value) => value < 50).length;
    final below10 = remainingValues.where((value) => value < 10).length;
    final between10And50 = remainingValues
        .where((value) => value >= 10 && value < 50)
        .length;
    final above50 = remainingValues.where((value) => value > 50).length;
    final equal50 = remainingValues.where((value) => value == 50).length;
    final remainingSum = remainingValues.fold<double>(
      0,
      (sum, item) => sum + item,
    );
    final average = remainingValues.isEmpty
        ? 0
        : remainingSum / remainingValues.length;
    return GetTokenSummary(
      totalCredentials: totalCredentials,
      successCount: successes.length,
      failureCount: failures.length,
      totalRemainingPercent: double.parse(average.toStringAsFixed(2)),
      totalRemainingSum: double.parse(remainingSum.toStringAsFixed(2)),
      below50Count: below50,
      below10Count: below10,
      between10And50Count: between10And50,
      above50Count: above50,
      equal50Count: equal50,
    );
  }

  GetTokenRefreshStats _buildRefreshStats(
    List<Map<String, dynamic>> successes,
    List<Map<String, dynamic>> failures,
  ) {
    final now = DateTime.now().toUtc();
    final unrefreshed = <GetTokenRefreshDetail>[];
    final refreshIn1Day = <GetTokenRefreshDetail>[];
    final refreshIn3Day = <GetTokenRefreshDetail>[];
    final refreshIn5Day = <GetTokenRefreshDetail>[];
    final failedOrUnknown = <GetTokenRefreshDetail>[];

    for (final item in successes) {
      final email =
          (item['email'] ?? item['account'] ?? item['name'] ?? 'unknown')
              .toString();
      final resetAt = _parseResetAt(item['reset_at']);
      if (resetAt == null) {
        failedOrUnknown.add(GetTokenRefreshDetail(email: email));
        continue;
      }
      final delta = resetAt.difference(now);
      final refreshDays = delta.inMilliseconds <= 0
          ? 0
          : delta.inMilliseconds / Duration.millisecondsPerDay;
      final detail = GetTokenRefreshDetail(
        email: email,
        refreshDate: resetAt.toLocal().toIso8601String().split('T').first,
        refreshDays: double.parse(refreshDays.toStringAsFixed(2)),
      );
      if (delta <= const Duration(days: 1)) {
        refreshIn1Day.add(detail);
      } else if (delta <= const Duration(days: 3)) {
        refreshIn3Day.add(detail);
      } else if (delta <= const Duration(days: 5)) {
        refreshIn5Day.add(detail);
      } else {
        unrefreshed.add(detail);
      }
    }
    for (final item in failures) {
      failedOrUnknown.add(
        GetTokenRefreshDetail(
          email: (item['email'] ?? item['account'] ?? item['name'] ?? 'unknown')
              .toString(),
        ),
      );
    }
    return GetTokenRefreshStats(
      unrefreshedCount: unrefreshed.length,
      refreshIn1DayCount: refreshIn1Day.length,
      refreshIn3DayCount: refreshIn3Day.length,
      refreshIn5DayCount: refreshIn5Day.length,
      failedOrUnknownCount: failedOrUnknown.length,
      totalCount:
          unrefreshed.length +
          refreshIn1Day.length +
          refreshIn3Day.length +
          refreshIn5Day.length +
          failedOrUnknown.length,
      unrefreshed: unrefreshed,
      refreshIn1Day: refreshIn1Day,
      refreshIn3Day: refreshIn3Day,
      refreshIn5Day: refreshIn5Day,
      failedOrUnknown: failedOrUnknown,
    );
  }

  DateTime? _parseResetAt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final timestamp = num.tryParse(text);
    if (timestamp != null) {
      return _dateTimeFromEpochTimestamp(timestamp);
    }
    return DateTime.tryParse(text)?.toUtc();
  }

  DateTime _dateTimeFromEpochTimestamp(num value) {
    final absolute = value.abs();
    if (absolute < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value.toDouble() * 1000).round(),
        isUtc: true,
      );
    }
    if (absolute < 100000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value.round(), isUtc: true);
    }
    return DateTime.fromMicrosecondsSinceEpoch(value.round(), isUtc: true);
  }

  Map<String, Map<String, dynamic>> _enrichCredentialsWithUsage(
    Map<String, Map<String, dynamic>> credentials,
    List<Map<String, dynamic>> successes,
    List<Map<String, dynamic>> failures,
  ) {
    final enriched = {
      for (final entry in credentials.entries) entry.key: {...entry.value},
    };
    for (final item in successes) {
      final key =
          (item['auth_index'] ??
                  item['email'] ??
                  item['account_id'] ??
                  'unknown')
              .toString();
      final current = enriched[key];
      if (current == null) {
        continue;
      }
      current.addAll({
        'remaining_percent': item['remaining_percent'],
        'used_percent': item['used_percent'],
        'last_query_status': 'success',
        'last_error': null,
        'limit_reached': item['limit_reached'],
        'reset_at': item['reset_at'],
        'reset_after_seconds': item['reset_after_seconds'],
        'limit_window_seconds': item['limit_window_seconds'],
        'raw': item['raw'],
      });
    }
    for (final item in failures) {
      final key = (item['auth_index'] ?? item['email'] ?? 'unknown').toString();
      final current = enriched[key];
      if (current == null) {
        continue;
      }
      current.addAll({
        'last_query_status': 'failed',
        'last_error': item['error'],
      });
    }
    return enriched;
  }

  GetTokenCredentialChanges _compareWithPrevious({
    required Map<String, Map<String, dynamic>> previous,
    required Map<String, Map<String, dynamic>> current,
  }) {
    if (previous.isEmpty) {
      return GetTokenCredentialChanges(
        hasPrevious: false,
        previousCount: 0,
        currentCount: current.length,
        quotaBaselineReady: false,
        quotaBaselineCount: 0,
      );
    }
    final previousKeys = previous.keys.toSet();
    final currentKeys = current.keys.toSet();
    final sharedKeys = previousKeys.intersection(currentKeys);
    final addedKeys = (currentKeys.difference(previousKeys).toList()
      ..sort(
        (a, b) => (current[a]!['email'] ?? a).toString().compareTo(
          (current[b]!['email'] ?? b).toString(),
        ),
      ));
    final removedKeys = (previousKeys.difference(currentKeys).toList()
      ..sort(
        (a, b) => (previous[a]!['email'] ?? a).toString().compareTo(
          (previous[b]!['email'] ?? b).toString(),
        ),
      ));
    final quotaBaselineCount = previous.values
        .where((item) => item['remaining_percent'] != null)
        .length;
    final quotaDecreases = _buildQuotaDecreases(
      previous: previous,
      current: current,
      sharedKeys: sharedKeys,
    );
    return GetTokenCredentialChanges(
      hasPrevious: true,
      previousCount: previous.length,
      currentCount: current.length,
      addedCount: addedKeys.length,
      removedCount: removedKeys.length,
      netChange: current.length - previous.length,
      quotaDecreaseCount: quotaDecreases.length,
      totalQuotaDecrease: double.parse(
        quotaDecreases
            .fold<double>(0, (sum, item) => sum + (item.decrease ?? 0))
            .toStringAsFixed(2),
      ),
      quotaBaselineReady: quotaBaselineCount > 0,
      quotaBaselineCount: quotaBaselineCount,
      added: addedKeys.map((key) => _changeItemFromMap(current[key]!)).toList(),
      removed: removedKeys
          .map((key) => _changeItemFromMap(previous[key]!))
          .toList(),
      quotaDecreases: quotaDecreases,
    );
  }

  List<GetTokenCredentialChangeItem> _buildQuotaDecreases({
    required Map<String, Map<String, dynamic>> previous,
    required Map<String, Map<String, dynamic>> current,
    required Set<String> sharedKeys,
  }) {
    final result = <GetTokenCredentialChangeItem>[];
    for (final key in sharedKeys) {
      final previousRemaining = (previous[key]!['remaining_percent'] as num?)
          ?.toDouble();
      final currentRemaining = (current[key]!['remaining_percent'] as num?)
          ?.toDouble();
      if (previousRemaining == null || currentRemaining == null) {
        continue;
      }
      final decrease = previousRemaining - currentRemaining;
      if (decrease <= 0) {
        continue;
      }
      result.add(
        GetTokenCredentialChangeItem(
          key: key,
          email:
              (current[key]!['email'] ?? previous[key]!['email'] ?? 'unknown')
                  .toString(),
          authIndex:
              (current[key]!['auth_index'] ?? previous[key]!['auth_index'])
                  ?.toString(),
          previousRemainingPercent: double.parse(
            previousRemaining.toStringAsFixed(2),
          ),
          currentRemainingPercent: double.parse(
            currentRemaining.toStringAsFixed(2),
          ),
          decrease: double.parse(decrease.toStringAsFixed(2)),
        ),
      );
    }
    result.sort((a, b) => (b.decrease ?? 0).compareTo(a.decrease ?? 0));
    return result;
  }

  GetTokenCredentialChangeItem _changeItemFromMap(Map<String, dynamic> item) {
    return GetTokenCredentialChangeItem(
      key: (item['key'] ?? '').toString(),
      email: (item['email'] ?? 'unknown').toString(),
      authIndex: item['auth_index']?.toString(),
      accountId: item['account_id']?.toString(),
      planType: item['plan_type']?.toString(),
      name: item['name']?.toString(),
    );
  }

  List<GetTokenCredentialRow> _buildCredentialRows({
    required Map<String, Map<String, dynamic>> credentialsMap,
  }) {
    final rows = credentialsMap.entries.map((entry) {
      final item = entry.value;
      return GetTokenCredentialRow(
        id: entry.key,
        email: (item['email'] ?? 'unknown').toString(),
        status: (item['last_query_status'] ?? 'failed').toString(),
        authIndex: item['auth_index']?.toString(),
        accountId: item['account_id']?.toString(),
        planType: item['plan_type']?.toString(),
        name: item['name']?.toString(),
        usedPercent: (item['used_percent'] as num?)?.toDouble(),
        remainingPercent: (item['remaining_percent'] as num?)?.toDouble(),
        limitReached: item['limit_reached'] as bool?,
        error: item['last_error']?.toString(),
        resetAt: _parseResetAt(item['reset_at']),
        resetAfterSeconds: (item['reset_after_seconds'] as num?)?.toInt(),
        limitWindowSeconds: (item['limit_window_seconds'] as num?)?.toInt(),
        raw: _mapOrNull(item['raw']),
        lastSuccessPreserved: item['last_success_preserved'] as bool? ?? false,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList();
    rows.sort((a, b) {
      if (a.isFailure != b.isFailure) {
        return a.isFailure ? 1 : -1;
      }
      final left = a.remainingPercent ?? 101;
      final right = b.remainingPercent ?? 101;
      final byRemaining = left.compareTo(right);
      if (byRemaining != 0) {
        return byRemaining;
      }
      return a.email.compareTo(b.email);
    });
    return rows;
  }

  Map<String, dynamic> _rowToUsageMap(GetTokenCredentialRow row) {
    return {
      'email': row.email,
      'auth_index': row.authIndex,
      'account_id': row.accountId,
      'plan_type': row.planType,
      'used_percent': row.usedPercent,
      'remaining_percent': row.remainingPercent,
      'limit_reached': row.limitReached,
      'reset_at': row.resetAt?.toUtc().toIso8601String(),
      'reset_after_seconds': row.resetAfterSeconds,
      'limit_window_seconds': row.limitWindowSeconds,
      'raw': row.raw,
    };
  }

  _UsageAggregate _aggregateUsageEvents(List<GetTokenUsageEvent> events) {
    final grouped = <String, _UsageAccumulator>{};
    for (final event in events) {
      final authIndex = event.authIndex;
      final current = grouped.putIfAbsent(
        authIndex,
        () => _UsageAccumulator(
          authIndex: authIndex,
          source: event.source,
          sourceType: event.sourceType,
        ),
      );
      current.requestCount += 1;
      if (event.failed) {
        current.failedCount += 1;
      }
      current.inputTokens += event.inputTokens;
      current.outputTokens += event.outputTokens;
      current.reasoningTokens += event.reasoningTokens;
      current.cachedTokens += event.cachedTokens;
      current.totalTokens += event.totalTokens;
      if (current.latestTimestamp == null ||
          event.timestamp.toUtc().toIso8601String().compareTo(
                current.latestTimestamp!,
              ) >
              0) {
        current.latestTimestamp = event.timestamp.toUtc().toIso8601String();
      }
      if (event.model != null && event.model!.isNotEmpty) {
        current.models.add(event.model!);
      }
    }
    final rows = grouped.values.map((item) => item.toRow()).toList()
      ..sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    return _UsageAggregate(
      rows: rows,
      summary: GetTokenUsageSummary(
        credentialCount: rows.length,
        eventCount: events.length,
        failedEventCount: events.where((event) => event.failed).length,
        totalTokens: rows.fold<int>(0, (sum, row) => sum + row.totalTokens),
        inputTokens: rows.fold<int>(0, (sum, row) => sum + row.inputTokens),
        outputTokens: rows.fold<int>(0, (sum, row) => sum + row.outputTokens),
        reasoningTokens: rows.fold<int>(
          0,
          (sum, row) => sum + row.reasoningTokens,
        ),
        cachedTokens: rows.fold<int>(0, (sum, row) => sum + row.cachedTokens),
      ),
    );
  }

  bool _eventMatchesRange(
    GetTokenUsageEvent event,
    String rangeValue, {
    String? start,
    String? end,
  }) {
    final time = event.timestamp.toUtc();
    final now = DateTime.now().toUtc();
    if (rangeValue.endsWith('h')) {
      final hours = int.tryParse(
        rangeValue.substring(0, rangeValue.length - 1),
      );
      if (hours == null) {
        return false;
      }
      return !time.isBefore(now.subtract(Duration(hours: hours)));
    }
    if (rangeValue == 'today') {
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      return !time.isBefore(todayStart);
    }
    if (rangeValue == '7d') {
      return !time.isBefore(now.subtract(const Duration(days: 7)));
    }
    if (rangeValue == 'custom') {
      final startDate = DateTime.tryParse(start ?? '');
      final endDate = DateTime.tryParse(end ?? '');
      if (startDate == null || endDate == null) {
        return false;
      }
      final startUtc = DateTime.utc(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endUtc = DateTime.utc(endDate.year, endDate.month, endDate.day + 1);
      return !time.isBefore(startUtc) && time.isBefore(endUtc);
    }
    return false;
  }

  void _validateRange(
    String rangeValue,
    String? start,
    String? end, {
    required String label,
  }) {
    if (!const {
      '4h',
      '8h',
      '12h',
      'today',
      '7d',
      'custom',
    }.contains(rangeValue)) {
      throw GetTokenServiceException('$label 只能是 4h、8h、12h、today、7d、custom');
    }
    if (rangeValue == 'custom' &&
        ((start ?? '').trim().isEmpty || (end ?? '').trim().isEmpty)) {
      throw GetTokenServiceException(
        '$label=custom 时必须提供 start 和 end，格式为 YYYY-MM-DD',
      );
    }
  }

  bool _rowChanged(GetTokenUsageRow row, List<GetTokenUsageRow> previousRows) {
    GetTokenUsageRow? previous;
    for (final item in previousRows) {
      if (item.authIndex == row.authIndex) {
        previous = item;
        break;
      }
    }
    if (previous == null) {
      return true;
    }
    return previous.totalTokens != row.totalTokens;
  }

  Future<List<GetTokenUsageRow>> _attachCurrentQuota({
    required List<GetTokenUsageRow> rows,
    required _ResolvedConfig resolved,
    required List<GetTokenCredentialRow> currentCredentialRows,
    required List<GetTokenUsageRow> previousRows,
    required bool refreshQuota,
    required Set<String> changedAuthIndices,
    required int quotaCacheTtlSeconds,
  }) async {
    if (rows.isEmpty) {
      return const <GetTokenUsageRow>[];
    }
    final previousByAuth = {for (final row in previousRows) row.authIndex: row};
    final credentialByAuth = {
      for (final row in currentCredentialRows)
        if (row.authIndex != null && row.authIndex!.isNotEmpty)
          row.authIndex!: row,
    };
    final nowSeconds =
        DateTime.now().toUtc().millisecondsSinceEpoch.toDouble() / 1000;
    final seeded = rows.map((row) {
      final previous = previousByAuth[row.authIndex];
      final credential = credentialByAuth[row.authIndex];
      final cachedAt = previous?.quotaCachedAt;
      final currentUsage =
          _normalizeUsageResetAt(previous?.currentUsage, cachedAt) ??
          (credential == null || credential.isFailure
              ? null
              : GetTokenCurrentUsage(
                  remainingPercent: credential.remainingPercent,
                  usedPercent: credential.usedPercent,
                  planType: credential.planType,
                  limitReached: credential.limitReached,
                  resetAt: credential.resetAt,
                  resetAfterSeconds: credential.resetAfterSeconds,
                  limitWindowSeconds: credential.limitWindowSeconds,
                ));
      return GetTokenUsageRow(
        authIndex: row.authIndex,
        source: row.source,
        sourceType: row.sourceType,
        requestCount: row.requestCount,
        failedCount: row.failedCount,
        inputTokens: row.inputTokens,
        outputTokens: row.outputTokens,
        reasoningTokens: row.reasoningTokens,
        cachedTokens: row.cachedTokens,
        totalTokens: row.totalTokens,
        latestTimestamp: row.latestTimestamp,
        models: row.models,
        currentUsage: currentUsage,
        quotaCachedAt: cachedAt,
        usageError: previous?.usageError,
      );
    }).toList();

    final targets = <GetTokenUsageRow>[];
    if (refreshQuota) {
      for (final row in seeded) {
        final cachedAt = row.quotaCachedAt ?? 0;
        final stale =
            row.currentUsage == null ||
            nowSeconds - cachedAt >= quotaCacheTtlSeconds;
        if (stale &&
            (changedAuthIndices.contains(row.authIndex) ||
                row.currentUsage == null)) {
          targets.add(row);
        }
      }
    }
    if (targets.isEmpty) {
      return seeded;
    }
    final authFiles = await _fetchAuthFiles(resolved);
    final byAuth = {
      for (final item in authFiles) (item['auth_index'] ?? '').toString(): item,
    };
    final refreshed = await Future.wait(
      targets.map((row) async {
        final source = byAuth[row.authIndex];
        if (source == null) {
          return _QuotaRefreshResult(authIndex: row.authIndex, error: '未找到凭证');
        }
        try {
          final usage = await _fetchSingleUsage(source, resolved);
          return _QuotaRefreshResult(authIndex: row.authIndex, usage: usage);
        } catch (error) {
          return _QuotaRefreshResult(
            authIndex: row.authIndex,
            error: _formatError(error),
          );
        }
      }),
    );
    final refreshedByAuth = {
      for (final item in refreshed) item.authIndex: item,
    };
    return seeded.map((row) {
      final update = refreshedByAuth[row.authIndex];
      if (update == null) {
        return row;
      }
      if (update.usage != null) {
        return GetTokenUsageRow(
          authIndex: row.authIndex,
          source: row.source,
          sourceType: row.sourceType,
          requestCount: row.requestCount,
          failedCount: row.failedCount,
          inputTokens: row.inputTokens,
          outputTokens: row.outputTokens,
          reasoningTokens: row.reasoningTokens,
          cachedTokens: row.cachedTokens,
          totalTokens: row.totalTokens,
          latestTimestamp: row.latestTimestamp,
          models: row.models,
          currentUsage: GetTokenCurrentUsage(
            remainingPercent: (update.usage!['remaining_percent'] as num?)
                ?.toDouble(),
            usedPercent: (update.usage!['used_percent'] as num?)?.toDouble(),
            planType: update.usage!['plan_type']?.toString(),
            limitReached: update.usage!['limit_reached'] as bool?,
            resetAt: _parseResetAt(update.usage!['reset_at']),
            resetAfterSeconds: (update.usage!['reset_after_seconds'] as num?)
                ?.toInt(),
            limitWindowSeconds: (update.usage!['limit_window_seconds'] as num?)
                ?.toInt(),
          ),
          quotaCachedAt: nowSeconds,
          usageError: null,
        );
      }
      return GetTokenUsageRow(
        authIndex: row.authIndex,
        source: row.source,
        sourceType: row.sourceType,
        requestCount: row.requestCount,
        failedCount: row.failedCount,
        inputTokens: row.inputTokens,
        outputTokens: row.outputTokens,
        reasoningTokens: row.reasoningTokens,
        cachedTokens: row.cachedTokens,
        totalTokens: row.totalTokens,
        latestTimestamp: row.latestTimestamp,
        models: row.models,
        currentUsage: row.currentUsage,
        quotaCachedAt: row.quotaCachedAt,
        usageError: update.error,
      );
    }).toList();
  }

  GetTokenCurrentUsage? _normalizeUsageResetAt(
    GetTokenCurrentUsage? usage,
    double? quotaCachedAt,
  ) {
    if (usage == null) {
      return null;
    }
    final resetAt = usage.resetAt;
    if (resetAt != null && !_isClearlyInvalidResetAt(resetAt)) {
      return usage;
    }
    final resetAfterSeconds = usage.resetAfterSeconds;
    if (resetAfterSeconds == null ||
        resetAfterSeconds < 0 ||
        quotaCachedAt == null) {
      return usage;
    }
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(
      (quotaCachedAt * 1000).round(),
      isUtc: true,
    );
    return GetTokenCurrentUsage(
      remainingPercent: usage.remainingPercent,
      usedPercent: usage.usedPercent,
      planType: usage.planType,
      limitReached: usage.limitReached,
      resetAt: cachedAt.add(Duration(seconds: resetAfterSeconds)),
      resetAfterSeconds: usage.resetAfterSeconds,
      limitWindowSeconds: usage.limitWindowSeconds,
    );
  }

  bool _isClearlyInvalidResetAt(DateTime value) {
    final now = DateTime.now().toUtc();
    return value.isBefore(DateTime.utc(2020)) ||
        value.toUtc().isAfter(now.add(const Duration(days: 365)));
  }

  String _formatError(Object error) {
    if (error is GetTokenServiceException) {
      return error.message;
    }
    return error.toString();
  }

  _MergedUsageEvents _mergeUsageEvents(
    List<GetTokenUsageEvent> existingEvents,
    List<GetTokenUsageEvent> upstreamEvents,
  ) {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 90));
    final eventById = <String, GetTokenUsageEvent>{
      for (final event in existingEvents)
        if (!event.timestamp.isBefore(cutoff)) event.id: event,
    };
    var addedCount = 0;
    for (final event in upstreamEvents) {
      if (event.timestamp.isBefore(cutoff)) {
        continue;
      }
      if (eventById.containsKey(event.id)) {
        continue;
      }
      eventById[event.id] = event;
      addedCount += 1;
    }
    final events = eventById.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _MergedUsageEvents(events: events, addedCount: addedCount);
  }
}

class GetTokenServiceException implements Exception {
  const GetTokenServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ResolvedConfig {
  const _ResolvedConfig({
    required this.baseUrl,
    required this.managementKey,
    required this.batchSize,
    required this.timeout,
    required this.limit,
  });

  final String baseUrl;
  final String managementKey;
  final int batchSize;
  final int timeout;
  final int? limit;

  factory _ResolvedConfig.from({
    required GetTokenConfig config,
    required GetTokenSecretConfig secret,
  }) {
    return _ResolvedConfig(
      baseUrl:
          (config.baseUrl.trim().isEmpty ? _defaultBaseUrl : config.baseUrl)
              .replaceFirst(RegExp(r'/+$'), ''),
      managementKey: secret.managementKey.trim().isEmpty
          ? _defaultManagementKey
          : secret.managementKey.trim(),
      batchSize: config.batchSize <= 0 ? 30 : config.batchSize,
      timeout: config.timeout <= 0 ? 30 : config.timeout,
      limit: config.limit != null && config.limit! > 0 ? config.limit : null,
    );
  }
}

class GetTokenCollectionProgress {
  const GetTokenCollectionProgress({
    required this.message,
    required this.processed,
    required this.total,
    required this.progressPercent,
    required this.credentials,
  });

  final String message;
  final int processed;
  final int total;
  final double progressPercent;
  final List<GetTokenCredentialRow> credentials;
}

class GetTokenCollectionResult {
  const GetTokenCollectionResult({
    required this.snapshot,
    required this.credentials,
  });

  final GetTokenCollectionSnapshot snapshot;
  final List<GetTokenCredentialRow> credentials;
}

class GetTokenUsageCollectionResult {
  const GetTokenUsageCollectionResult({
    required this.events,
    required this.snapshot,
  });

  final List<GetTokenUsageEvent> events;
  final GetTokenUsageSnapshot snapshot;
}

class _UsageFetchResult {
  const _UsageFetchResult({this.success, this.error, this.source});

  final Map<String, dynamic>? success;
  final String? error;
  final Map<String, dynamic>? source;
}

class _QuotaRefreshResult {
  const _QuotaRefreshResult({required this.authIndex, this.usage, this.error});

  final String authIndex;
  final Map<String, dynamic>? usage;
  final String? error;
}

class _UsageAccumulator {
  _UsageAccumulator({
    required this.authIndex,
    required this.source,
    this.sourceType,
  });

  final String authIndex;
  final String source;
  final String? sourceType;
  int requestCount = 0;
  int failedCount = 0;
  int inputTokens = 0;
  int outputTokens = 0;
  int reasoningTokens = 0;
  int cachedTokens = 0;
  int totalTokens = 0;
  String? latestTimestamp;
  final Set<String> models = <String>{};

  GetTokenUsageRow toRow() {
    return GetTokenUsageRow(
      authIndex: authIndex,
      source: source,
      sourceType: sourceType,
      requestCount: requestCount,
      failedCount: failedCount,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      reasoningTokens: reasoningTokens,
      cachedTokens: cachedTokens,
      totalTokens: totalTokens,
      latestTimestamp: latestTimestamp,
      models: models.toList()..sort(),
    );
  }
}

class _UsageAggregate {
  const _UsageAggregate({required this.rows, required this.summary});

  final List<GetTokenUsageRow> rows;
  final GetTokenUsageSummary summary;
}

class _MergedUsageEvents {
  const _MergedUsageEvents({required this.events, required this.addedCount});

  final List<GetTokenUsageEvent> events;
  final int addedCount;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const <Map<String, dynamic>>[];
}
