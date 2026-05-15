import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import 'get_token_models.dart';

const getTokenConfigKey = 'getTokenConfig';
const getTokenSecretConfigKey = '${localOnlySettingPrefix}getTokenSecretConfig';
const _latestCollectionStateId = 'latest';
const _latestUsageStateId = 'latest';

final getTokenRepositoryProvider = Provider<GetTokenRepository>((ref) {
  return GetTokenRepository(ref.watch(appDatabaseProvider));
});

class GetTokenRepository {
  const GetTokenRepository(this._database);

  final AppDatabase _database;

  Stream<GetTokenConfig> watchConfig() {
    return _database.watchSettingValue(getTokenConfigKey).map(parseConfig);
  }

  Future<GetTokenConfig> loadConfig() async {
    return parseConfig(await _database.getSettingValue(getTokenConfigKey));
  }

  Future<void> saveConfig(GetTokenConfig config) {
    return _database.setSettingValue(
      getTokenConfigKey,
      jsonEncode(config.toJson()),
    );
  }

  Future<GetTokenSecretConfig> loadSecretConfig() async {
    return parseSecretConfig(
      await _database.getSettingValue(getTokenSecretConfigKey),
    );
  }

  Future<void> saveSecretConfig(GetTokenSecretConfig config) {
    return _database.setSettingValue(
      getTokenSecretConfigKey,
      jsonEncode(config.toJson()),
    );
  }

  Future<List<GetTokenCredentialRow>> loadCredentialRows() async {
    final rows = await _database.loadGetTokenCredentialSnapshots();
    return rows.map(_credentialFromRecord).toList();
  }

  Future<GetTokenCollectionSnapshot?> loadCollectionSnapshot() async {
    final row = await _database.loadGetTokenCollectionStateRecord();
    return row == null ? null : _collectionFromRecord(row);
  }

  Future<void> saveCollectionSnapshot({
    required GetTokenCollectionSnapshot snapshot,
    required List<GetTokenCredentialRow> credentials,
  }) async {
    final deviceId = await _database.ensureDeviceId();
    await _database.replaceGetTokenCredentialSnapshots(
      credentials
          .map((row) => _credentialToRecord(row, deviceId: deviceId))
          .toList(),
    );
    await _database.saveGetTokenCollectionStateRecord(
      GetTokenCollectionStateRecord(
        id: _latestCollectionStateId,
        status: snapshot.status,
        message: snapshot.message,
        processed: snapshot.processed,
        total: snapshot.total,
        progressPercent: snapshot.progressPercent,
        summaryJson: snapshot.summary == null
            ? null
            : jsonEncode(snapshot.summary!.toJson()),
        credentialChangesJson: snapshot.credentialChanges == null
            ? null
            : jsonEncode(snapshot.credentialChanges!.toJson()),
        refreshStatsJson: snapshot.refreshStats == null
            ? null
            : jsonEncode(snapshot.refreshStats!.toJson()),
        createdAt: snapshot.createdAt,
        updatedAt: snapshot.updatedAt,
        completedAt: snapshot.completedAt,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> replaceCredentialRows(
    List<GetTokenCredentialRow> credentials,
  ) async {
    final deviceId = await _database.ensureDeviceId();
    await _database.replaceGetTokenCredentialSnapshots(
      credentials
          .map((row) => _credentialToRecord(row, deviceId: deviceId))
          .toList(),
    );
  }

  Future<GetTokenUsageSnapshot?> loadUsageSnapshot() async {
    final row = await _database.loadGetTokenUsageQueryStateRecord();
    return row == null ? null : _usageSnapshotFromRecord(row);
  }

  Future<void> saveUsageSnapshot(GetTokenUsageSnapshot snapshot) async {
    final deviceId = await _database.ensureDeviceId();
    await _database.saveGetTokenUsageQueryStateRecord(
      GetTokenUsageQueryStateRecord(
        id: _latestUsageStateId,
        paramsJson: jsonEncode(snapshot.params.toJson()),
        summaryJson: jsonEncode(snapshot.summary.toJson()),
        upstreamJson: jsonEncode(snapshot.upstream.toJson()),
        rowsJson: jsonEncode(snapshot.rows.map((row) => row.toJson()).toList()),
        eventTableCount: snapshot.eventTableCount,
        addedEventCount: snapshot.addedEventCount,
        updatedAt: snapshot.updatedAt,
        deviceId: deviceId,
      ),
    );
  }

  Future<List<GetTokenUsageEvent>> loadUsageEvents() async {
    final rows = await _database.loadGetTokenUsageEvents();
    return rows.map(_usageEventFromRecord).toList();
  }

  Future<void> mergeUsageEvents(List<GetTokenUsageEvent> events) async {
    final deviceId = await _database.ensureDeviceId();
    await _database.mergeGetTokenUsageEvents(
      events
          .map((row) => _usageEventToRecord(row, deviceId: deviceId))
          .toList(),
    );
  }

  Future<void> clearUsageCache() {
    return _database.clearGetTokenUsageCache();
  }

  GetTokenConfig parseConfig(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const GetTokenConfig();
    }
    try {
      return GetTokenConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(source) as Map),
      );
    } catch (_) {
      return const GetTokenConfig();
    }
  }

  GetTokenSecretConfig parseSecretConfig(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const GetTokenSecretConfig();
    }
    try {
      return GetTokenSecretConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(source) as Map),
      );
    } catch (_) {
      return const GetTokenSecretConfig();
    }
  }

  GetTokenCredentialSnapshotRecord _credentialToRecord(
    GetTokenCredentialRow row, {
    required String deviceId,
  }) {
    return GetTokenCredentialSnapshotRecord(
      id: row.id,
      email: row.email,
      authIndex: row.authIndex,
      accountId: row.accountId,
      planType: row.planType,
      credentialName: row.name,
      status: row.status,
      usedPercent: row.usedPercent,
      remainingPercent: row.remainingPercent,
      limitReached: row.limitReached,
      error: row.error,
      resetAt: row.resetAt,
      resetAfterSeconds: row.resetAfterSeconds,
      limitWindowSeconds: row.limitWindowSeconds,
      rawJson: row.raw == null ? null : jsonEncode(row.raw),
      lastSuccessPreserved: row.lastSuccessPreserved,
      updatedAt: row.updatedAt ?? DateTime.now().toUtc(),
      deviceId: deviceId,
    );
  }

  GetTokenCredentialRow _credentialFromRecord(
    GetTokenCredentialSnapshotRecord row,
  ) {
    return GetTokenCredentialRow(
      id: row.id,
      email: row.email,
      status: row.status,
      authIndex: row.authIndex,
      accountId: row.accountId,
      planType: row.planType,
      name: row.credentialName,
      usedPercent: row.usedPercent,
      remainingPercent: row.remainingPercent,
      limitReached: row.limitReached,
      error: row.error,
      resetAt: row.resetAt,
      resetAfterSeconds: row.resetAfterSeconds,
      limitWindowSeconds: row.limitWindowSeconds,
      raw: _decodeMap(row.rawJson),
      lastSuccessPreserved: row.lastSuccessPreserved,
      updatedAt: row.updatedAt,
    );
  }

  GetTokenCollectionSnapshot _collectionFromRecord(
    GetTokenCollectionStateRecord row,
  ) {
    return GetTokenCollectionSnapshot(
      status: row.status,
      message: row.message,
      processed: row.processed,
      total: row.total,
      progressPercent: row.progressPercent,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt,
      summary: row.summaryJson == null
          ? null
          : GetTokenSummary.fromJson(_decodeMap(row.summaryJson)),
      credentialChanges: row.credentialChangesJson == null
          ? null
          : GetTokenCredentialChanges.fromJson(
              _decodeMap(row.credentialChangesJson),
            ),
      refreshStats: row.refreshStatsJson == null
          ? null
          : GetTokenRefreshStats.fromJson(_decodeMap(row.refreshStatsJson)),
    );
  }

  GetTokenUsageSnapshot _usageSnapshotFromRecord(
    GetTokenUsageQueryStateRecord row,
  ) {
    final rows = _decodeList(
      row.rowsJson,
    ).map(GetTokenUsageRow.fromJson).toList();
    return GetTokenUsageSnapshot(
      updatedAt: row.updatedAt,
      params: GetTokenUsageQuery.fromJson(_decodeMap(row.paramsJson)),
      eventTableCount: row.eventTableCount,
      addedEventCount: row.addedEventCount,
      summary: GetTokenUsageSummary.fromJson(_decodeMap(row.summaryJson)),
      rows: rows,
      upstream: GetTokenUpstreamInfo.fromJson(_decodeMap(row.upstreamJson)),
    );
  }

  GetTokenUsageEventRecord _usageEventToRecord(
    GetTokenUsageEvent event, {
    required String deviceId,
  }) {
    return GetTokenUsageEventRecord(
      id: event.id,
      authIndex: event.authIndex,
      source: event.source,
      sourceType: event.sourceType,
      failed: event.failed,
      model: event.model,
      timestamp: event.timestamp,
      inputTokens: event.inputTokens,
      outputTokens: event.outputTokens,
      reasoningTokens: event.reasoningTokens,
      cachedTokens: event.cachedTokens,
      totalTokens: event.totalTokens,
      rawJson: jsonEncode(event.raw),
      updatedAt: DateTime.now().toUtc(),
      deviceId: deviceId,
    );
  }

  GetTokenUsageEvent _usageEventFromRecord(GetTokenUsageEventRecord row) {
    return GetTokenUsageEvent(
      id: row.id,
      authIndex: row.authIndex,
      source: row.source,
      sourceType: row.sourceType,
      failed: row.failed,
      model: row.model,
      timestamp: row.timestamp,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      reasoningTokens: row.reasoningTokens,
      cachedTokens: row.cachedTokens,
      totalTokens: row.totalTokens,
      raw: _decodeMap(row.rawJson),
    );
  }
}

Map<String, dynamic> _decodeMap(String? source) {
  if (source == null || source.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  try {
    return Map<String, dynamic>.from(jsonDecode(source) as Map);
  } catch (_) {
    return const <String, dynamic>{};
  }
}

List<Map<String, dynamic>> _decodeList(String? source) {
  if (source == null || source.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  try {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}
