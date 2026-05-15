import 'dart:convert';

class GetTokenConfig {
  const GetTokenConfig({
    this.baseUrl = '',
    this.batchSize = 30,
    this.timeout = 30,
    this.limit,
    this.apiRange = '4h',
    this.cacheRange = '4h',
    this.apiStart,
    this.apiEnd,
    this.cacheStart,
    this.cacheEnd,
    this.pageSize = 500,
    this.tokenIntervalSeconds = 10,
    this.quotaCacheTtlSeconds = 60,
    this.refreshQuota = false,
    this.tokenSortMode = 'latest',
    this.tokenSortDescending = true,
    this.credentialSortMode = 'remaining',
    this.credentialSortDescending = false,
    this.credentialDisplayLimit = 0,
    this.tokenPollingEnabled = false,
  });

  final String baseUrl;
  final int batchSize;
  final int timeout;
  final int? limit;
  final String apiRange;
  final String cacheRange;
  final String? apiStart;
  final String? apiEnd;
  final String? cacheStart;
  final String? cacheEnd;
  final int pageSize;
  final int tokenIntervalSeconds;
  final int quotaCacheTtlSeconds;
  final bool refreshQuota;
  final String tokenSortMode;
  final bool tokenSortDescending;
  final String credentialSortMode;
  final bool credentialSortDescending;
  final int credentialDisplayLimit;
  final bool tokenPollingEnabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'baseUrl': baseUrl.trim(),
    'batchSize': batchSize,
    'timeout': timeout,
    'limit': limit,
    'apiRange': apiRange,
    'cacheRange': cacheRange,
    'apiStart': apiStart,
    'apiEnd': apiEnd,
    'cacheStart': cacheStart,
    'cacheEnd': cacheEnd,
    'pageSize': pageSize,
    'tokenIntervalSeconds': tokenIntervalSeconds,
    'quotaCacheTtlSeconds': quotaCacheTtlSeconds,
    'refreshQuota': refreshQuota,
    'tokenSortMode': tokenSortMode,
    'tokenSortDescending': tokenSortDescending,
    'credentialSortMode': credentialSortMode,
    'credentialSortDescending': credentialSortDescending,
    'credentialDisplayLimit': credentialDisplayLimit,
    'tokenPollingEnabled': tokenPollingEnabled,
  };

  GetTokenConfig copyWith({
    String? baseUrl,
    int? batchSize,
    int? timeout,
    int? limit,
    bool clearLimit = false,
    String? apiRange,
    String? cacheRange,
    String? apiStart,
    String? apiEnd,
    String? cacheStart,
    String? cacheEnd,
    bool clearApiStart = false,
    bool clearApiEnd = false,
    bool clearCacheStart = false,
    bool clearCacheEnd = false,
    int? pageSize,
    int? tokenIntervalSeconds,
    int? quotaCacheTtlSeconds,
    bool? refreshQuota,
    String? tokenSortMode,
    bool? tokenSortDescending,
    String? credentialSortMode,
    bool? credentialSortDescending,
    int? credentialDisplayLimit,
    bool? tokenPollingEnabled,
  }) {
    return GetTokenConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      batchSize: batchSize ?? this.batchSize,
      timeout: timeout ?? this.timeout,
      limit: clearLimit ? null : (limit ?? this.limit),
      apiRange: apiRange ?? this.apiRange,
      cacheRange: cacheRange ?? this.cacheRange,
      apiStart: clearApiStart ? null : (apiStart ?? this.apiStart),
      apiEnd: clearApiEnd ? null : (apiEnd ?? this.apiEnd),
      cacheStart: clearCacheStart ? null : (cacheStart ?? this.cacheStart),
      cacheEnd: clearCacheEnd ? null : (cacheEnd ?? this.cacheEnd),
      pageSize: pageSize ?? this.pageSize,
      tokenIntervalSeconds: tokenIntervalSeconds ?? this.tokenIntervalSeconds,
      quotaCacheTtlSeconds: quotaCacheTtlSeconds ?? this.quotaCacheTtlSeconds,
      refreshQuota: refreshQuota ?? this.refreshQuota,
      tokenSortMode: tokenSortMode ?? this.tokenSortMode,
      tokenSortDescending: tokenSortDescending ?? this.tokenSortDescending,
      credentialSortMode: credentialSortMode ?? this.credentialSortMode,
      credentialSortDescending:
          credentialSortDescending ?? this.credentialSortDescending,
      credentialDisplayLimit:
          credentialDisplayLimit ?? this.credentialDisplayLimit,
      tokenPollingEnabled: tokenPollingEnabled ?? this.tokenPollingEnabled,
    );
  }

  factory GetTokenConfig.fromJson(Map<String, dynamic> json) {
    return GetTokenConfig(
      baseUrl: (json['baseUrl'] as String? ?? '').trim(),
      batchSize: json['batchSize'] as int? ?? 30,
      timeout: json['timeout'] as int? ?? 30,
      limit: json['limit'] as int?,
      apiRange: json['apiRange'] as String? ?? '4h',
      cacheRange: json['cacheRange'] as String? ?? '4h',
      apiStart: json['apiStart'] as String?,
      apiEnd: json['apiEnd'] as String?,
      cacheStart: json['cacheStart'] as String?,
      cacheEnd: json['cacheEnd'] as String?,
      pageSize: json['pageSize'] as int? ?? 500,
      tokenIntervalSeconds: json['tokenIntervalSeconds'] as int? ?? 10,
      quotaCacheTtlSeconds: json['quotaCacheTtlSeconds'] as int? ?? 60,
      refreshQuota: json['refreshQuota'] as bool? ?? false,
      tokenSortMode: json['tokenSortMode'] as String? ?? 'latest',
      tokenSortDescending: json['tokenSortDescending'] as bool? ?? true,
      credentialSortMode: json['credentialSortMode'] as String? ?? 'remaining',
      credentialSortDescending:
          json['credentialSortDescending'] as bool? ?? false,
      credentialDisplayLimit: json['credentialDisplayLimit'] as int? ?? 0,
      tokenPollingEnabled: json['tokenPollingEnabled'] as bool? ?? false,
    );
  }
}

class GetTokenSecretConfig {
  const GetTokenSecretConfig({this.managementKey = ''});

  final String managementKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'managementKey': managementKey,
  };

  factory GetTokenSecretConfig.fromJson(Map<String, dynamic> json) {
    return GetTokenSecretConfig(
      managementKey: json['managementKey'] as String? ?? '',
    );
  }
}

class GetTokenSummary {
  const GetTokenSummary({
    this.totalCredentials = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.totalRemainingPercent = 0,
    this.totalRemainingSum = 0,
    this.below50Count = 0,
    this.below10Count = 0,
    this.between10And50Count = 0,
    this.above50Count = 0,
    this.equal50Count = 0,
  });

  final int totalCredentials;
  final int successCount;
  final int failureCount;
  final double totalRemainingPercent;
  final double totalRemainingSum;
  final int below50Count;
  final int below10Count;
  final int between10And50Count;
  final int above50Count;
  final int equal50Count;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total_credentials': totalCredentials,
    'success_count': successCount,
    'failure_count': failureCount,
    'total_remaining_percent': totalRemainingPercent,
    'total_remaining_sum': totalRemainingSum,
    'below_50_count': below50Count,
    'below_10_count': below10Count,
    'between_10_and_50_count': between10And50Count,
    'above_50_count': above50Count,
    'equal_50_count': equal50Count,
  };

  factory GetTokenSummary.fromJson(Map<String, dynamic> json) {
    return GetTokenSummary(
      totalCredentials: json['total_credentials'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      failureCount: json['failure_count'] as int? ?? 0,
      totalRemainingPercent: (json['total_remaining_percent'] as num? ?? 0)
          .toDouble(),
      totalRemainingSum: (json['total_remaining_sum'] as num? ?? 0).toDouble(),
      below50Count: json['below_50_count'] as int? ?? 0,
      below10Count: json['below_10_count'] as int? ?? 0,
      between10And50Count: json['between_10_and_50_count'] as int? ?? 0,
      above50Count: json['above_50_count'] as int? ?? 0,
      equal50Count: json['equal_50_count'] as int? ?? 0,
    );
  }
}

class GetTokenCredentialChangeItem {
  const GetTokenCredentialChangeItem({
    required this.key,
    required this.email,
    this.authIndex,
    this.accountId,
    this.planType,
    this.name,
    this.previousRemainingPercent,
    this.currentRemainingPercent,
    this.decrease,
  });

  final String key;
  final String email;
  final String? authIndex;
  final String? accountId;
  final String? planType;
  final String? name;
  final double? previousRemainingPercent;
  final double? currentRemainingPercent;
  final double? decrease;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'email': email,
    'auth_index': authIndex,
    'account_id': accountId,
    'plan_type': planType,
    'name': name,
    'previous_remaining_percent': previousRemainingPercent,
    'current_remaining_percent': currentRemainingPercent,
    'decrease': decrease,
  };

  factory GetTokenCredentialChangeItem.fromJson(Map<String, dynamic> json) {
    return GetTokenCredentialChangeItem(
      key: json['key'] as String? ?? '',
      email: json['email'] as String? ?? 'unknown',
      authIndex: json['auth_index'] as String?,
      accountId: json['account_id'] as String?,
      planType: json['plan_type'] as String?,
      name: json['name'] as String?,
      previousRemainingPercent: (json['previous_remaining_percent'] as num?)
          ?.toDouble(),
      currentRemainingPercent: (json['current_remaining_percent'] as num?)
          ?.toDouble(),
      decrease: (json['decrease'] as num?)?.toDouble(),
    );
  }
}

class GetTokenCredentialChanges {
  const GetTokenCredentialChanges({
    this.hasPrevious = false,
    this.previousCount = 0,
    this.currentCount = 0,
    this.addedCount = 0,
    this.removedCount = 0,
    this.netChange = 0,
    this.quotaDecreaseCount = 0,
    this.totalQuotaDecrease = 0,
    this.quotaBaselineReady = false,
    this.quotaBaselineCount = 0,
    this.added = const <GetTokenCredentialChangeItem>[],
    this.removed = const <GetTokenCredentialChangeItem>[],
    this.quotaDecreases = const <GetTokenCredentialChangeItem>[],
  });

  final bool hasPrevious;
  final int previousCount;
  final int currentCount;
  final int addedCount;
  final int removedCount;
  final int netChange;
  final int quotaDecreaseCount;
  final double totalQuotaDecrease;
  final bool quotaBaselineReady;
  final int quotaBaselineCount;
  final List<GetTokenCredentialChangeItem> added;
  final List<GetTokenCredentialChangeItem> removed;
  final List<GetTokenCredentialChangeItem> quotaDecreases;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'has_previous': hasPrevious,
    'previous_count': previousCount,
    'current_count': currentCount,
    'added_count': addedCount,
    'removed_count': removedCount,
    'net_change': netChange,
    'quota_decrease_count': quotaDecreaseCount,
    'total_quota_decrease': totalQuotaDecrease,
    'quota_baseline_ready': quotaBaselineReady,
    'quota_baseline_count': quotaBaselineCount,
    'added': added.map((item) => item.toJson()).toList(),
    'removed': removed.map((item) => item.toJson()).toList(),
    'quota_decreases': quotaDecreases.map((item) => item.toJson()).toList(),
  };

  factory GetTokenCredentialChanges.fromJson(Map<String, dynamic> json) {
    return GetTokenCredentialChanges(
      hasPrevious: json['has_previous'] as bool? ?? false,
      previousCount: json['previous_count'] as int? ?? 0,
      currentCount: json['current_count'] as int? ?? 0,
      addedCount: json['added_count'] as int? ?? 0,
      removedCount: json['removed_count'] as int? ?? 0,
      netChange: json['net_change'] as int? ?? 0,
      quotaDecreaseCount: json['quota_decrease_count'] as int? ?? 0,
      totalQuotaDecrease: (json['total_quota_decrease'] as num? ?? 0)
          .toDouble(),
      quotaBaselineReady: json['quota_baseline_ready'] as bool? ?? false,
      quotaBaselineCount: json['quota_baseline_count'] as int? ?? 0,
      added: _list(
        json['added'],
      ).map(GetTokenCredentialChangeItem.fromJson).toList(),
      removed: _list(
        json['removed'],
      ).map(GetTokenCredentialChangeItem.fromJson).toList(),
      quotaDecreases: _list(
        json['quota_decreases'],
      ).map(GetTokenCredentialChangeItem.fromJson).toList(),
    );
  }
}

class GetTokenRefreshDetail {
  const GetTokenRefreshDetail({
    required this.email,
    this.refreshDate,
    this.refreshDays,
  });

  final String email;
  final String? refreshDate;
  final double? refreshDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'refresh_date': refreshDate,
    'refresh_days': refreshDays,
  };

  factory GetTokenRefreshDetail.fromJson(Map<String, dynamic> json) {
    return GetTokenRefreshDetail(
      email: json['email'] as String? ?? 'unknown',
      refreshDate: json['refresh_date'] as String?,
      refreshDays: (json['refresh_days'] as num?)?.toDouble(),
    );
  }
}

class GetTokenRefreshStats {
  const GetTokenRefreshStats({
    this.unrefreshedCount = 0,
    this.refreshIn1DayCount = 0,
    this.refreshIn3DayCount = 0,
    this.refreshIn5DayCount = 0,
    this.failedOrUnknownCount = 0,
    this.totalCount = 0,
    this.unrefreshed = const <GetTokenRefreshDetail>[],
    this.refreshIn1Day = const <GetTokenRefreshDetail>[],
    this.refreshIn3Day = const <GetTokenRefreshDetail>[],
    this.refreshIn5Day = const <GetTokenRefreshDetail>[],
    this.failedOrUnknown = const <GetTokenRefreshDetail>[],
  });

  final int unrefreshedCount;
  final int refreshIn1DayCount;
  final int refreshIn3DayCount;
  final int refreshIn5DayCount;
  final int failedOrUnknownCount;
  final int totalCount;
  final List<GetTokenRefreshDetail> unrefreshed;
  final List<GetTokenRefreshDetail> refreshIn1Day;
  final List<GetTokenRefreshDetail> refreshIn3Day;
  final List<GetTokenRefreshDetail> refreshIn5Day;
  final List<GetTokenRefreshDetail> failedOrUnknown;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'unrefreshed_count': unrefreshedCount,
    'refresh_in_1_day_count': refreshIn1DayCount,
    'refresh_in_3_day_count': refreshIn3DayCount,
    'refresh_in_5_day_count': refreshIn5DayCount,
    'failed_or_unknown_count': failedOrUnknownCount,
    'total_count': totalCount,
    'details': {
      'unrefreshed': unrefreshed.map((item) => item.toJson()).toList(),
      'refresh_in_1_day': refreshIn1Day.map((item) => item.toJson()).toList(),
      'refresh_in_3_day': refreshIn3Day.map((item) => item.toJson()).toList(),
      'refresh_in_5_day': refreshIn5Day.map((item) => item.toJson()).toList(),
      'failed_or_unknown': failedOrUnknown
          .map((item) => item.toJson())
          .toList(),
    },
  };

  factory GetTokenRefreshStats.fromJson(Map<String, dynamic> json) {
    final details = _map(json['details']);
    return GetTokenRefreshStats(
      unrefreshedCount: json['unrefreshed_count'] as int? ?? 0,
      refreshIn1DayCount: json['refresh_in_1_day_count'] as int? ?? 0,
      refreshIn3DayCount: json['refresh_in_3_day_count'] as int? ?? 0,
      refreshIn5DayCount: json['refresh_in_5_day_count'] as int? ?? 0,
      failedOrUnknownCount: json['failed_or_unknown_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      unrefreshed: _list(
        details['unrefreshed'],
      ).map(GetTokenRefreshDetail.fromJson).toList(),
      refreshIn1Day: _list(
        details['refresh_in_1_day'],
      ).map(GetTokenRefreshDetail.fromJson).toList(),
      refreshIn3Day: _list(
        details['refresh_in_3_day'],
      ).map(GetTokenRefreshDetail.fromJson).toList(),
      refreshIn5Day: _list(
        details['refresh_in_5_day'],
      ).map(GetTokenRefreshDetail.fromJson).toList(),
      failedOrUnknown: _list(
        details['failed_or_unknown'],
      ).map(GetTokenRefreshDetail.fromJson).toList(),
    );
  }
}

class GetTokenCredentialRow {
  const GetTokenCredentialRow({
    required this.id,
    required this.email,
    required this.status,
    this.authIndex,
    this.accountId,
    this.planType,
    this.name,
    this.usedPercent,
    this.remainingPercent,
    this.limitReached,
    this.error,
    this.resetAt,
    this.resetAfterSeconds,
    this.limitWindowSeconds,
    this.raw,
    this.lastSuccessPreserved = false,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String status;
  final String? authIndex;
  final String? accountId;
  final String? planType;
  final String? name;
  final double? usedPercent;
  final double? remainingPercent;
  final bool? limitReached;
  final String? error;
  final DateTime? resetAt;
  final int? resetAfterSeconds;
  final int? limitWindowSeconds;
  final Map<String, dynamic>? raw;
  final bool lastSuccessPreserved;
  final DateTime? updatedAt;

  bool get isFailure => status == 'failed';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'status': status,
    'auth_index': authIndex,
    'account_id': accountId,
    'plan_type': planType,
    'name': name,
    'used_percent': usedPercent,
    'remaining_percent': remainingPercent,
    'limit_reached': limitReached,
    'error': error,
    'reset_at': resetAt?.toUtc().toIso8601String(),
    'reset_after_seconds': resetAfterSeconds,
    'limit_window_seconds': limitWindowSeconds,
    'raw': raw,
    'last_success_preserved': lastSuccessPreserved,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  factory GetTokenCredentialRow.fromJson(Map<String, dynamic> json) {
    return GetTokenCredentialRow(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'failed',
      authIndex: json['auth_index'] as String?,
      accountId: json['account_id'] as String?,
      planType: json['plan_type'] as String?,
      name: json['name'] as String?,
      usedPercent: (json['used_percent'] as num?)?.toDouble(),
      remainingPercent: (json['remaining_percent'] as num?)?.toDouble(),
      limitReached: json['limit_reached'] as bool?,
      error: json['error'] as String?,
      resetAt: _date(json['reset_at']),
      resetAfterSeconds: json['reset_after_seconds'] as int?,
      limitWindowSeconds: json['limit_window_seconds'] as int?,
      raw: json['raw'] is Map
          ? Map<String, dynamic>.from(json['raw'] as Map)
          : null,
      lastSuccessPreserved: json['last_success_preserved'] as bool? ?? false,
      updatedAt: _date(json['updated_at']),
    );
  }
}

class GetTokenCurrentUsage {
  const GetTokenCurrentUsage({
    this.remainingPercent,
    this.usedPercent,
    this.planType,
    this.limitReached,
    this.resetAt,
    this.resetAfterSeconds,
    this.limitWindowSeconds,
  });

  final double? remainingPercent;
  final double? usedPercent;
  final String? planType;
  final bool? limitReached;
  final DateTime? resetAt;
  final int? resetAfterSeconds;
  final int? limitWindowSeconds;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'remaining_percent': remainingPercent,
    'used_percent': usedPercent,
    'plan_type': planType,
    'limit_reached': limitReached,
    'reset_at': resetAt?.toUtc().toIso8601String(),
    'reset_after_seconds': resetAfterSeconds,
    'limit_window_seconds': limitWindowSeconds,
  };

  factory GetTokenCurrentUsage.fromJson(Map<String, dynamic> json) {
    return GetTokenCurrentUsage(
      remainingPercent: (json['remaining_percent'] as num?)?.toDouble(),
      usedPercent: (json['used_percent'] as num?)?.toDouble(),
      planType: json['plan_type'] as String?,
      limitReached: json['limit_reached'] as bool?,
      resetAt: _date(json['reset_at']),
      resetAfterSeconds: json['reset_after_seconds'] as int?,
      limitWindowSeconds: json['limit_window_seconds'] as int?,
    );
  }
}

class GetTokenUsageQuery {
  const GetTokenUsageQuery({
    this.apiRange = '4h',
    this.apiStart,
    this.apiEnd,
    this.cacheRange = '4h',
    this.cacheStart,
    this.cacheEnd,
    this.pageSize = 500,
    this.refreshQuota = false,
    this.quotaCacheTtlSeconds = 60,
  });

  final String apiRange;
  final String? apiStart;
  final String? apiEnd;
  final String cacheRange;
  final String? cacheStart;
  final String? cacheEnd;
  final int pageSize;
  final bool refreshQuota;
  final int quotaCacheTtlSeconds;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'api_range': apiRange,
    'api_start': apiStart,
    'api_end': apiEnd,
    'cache_range': cacheRange,
    'cache_start': cacheStart,
    'cache_end': cacheEnd,
    'page_size': pageSize,
    'refresh_quota': refreshQuota,
    'quota_cache_ttl_seconds': quotaCacheTtlSeconds,
  };

  factory GetTokenUsageQuery.fromJson(Map<String, dynamic> json) {
    return GetTokenUsageQuery(
      apiRange: json['api_range'] as String? ?? '4h',
      apiStart: json['api_start'] as String?,
      apiEnd: json['api_end'] as String?,
      cacheRange: json['cache_range'] as String? ?? '4h',
      cacheStart: json['cache_start'] as String?,
      cacheEnd: json['cache_end'] as String?,
      pageSize: json['page_size'] as int? ?? 500,
      refreshQuota: json['refresh_quota'] as bool? ?? false,
      quotaCacheTtlSeconds: json['quota_cache_ttl_seconds'] as int? ?? 60,
    );
  }
}

class GetTokenUsageEvent {
  const GetTokenUsageEvent({
    required this.id,
    required this.authIndex,
    required this.source,
    required this.timestamp,
    this.sourceType,
    this.failed = false,
    this.model,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.reasoningTokens = 0,
    this.cachedTokens = 0,
    this.totalTokens = 0,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String authIndex;
  final String source;
  final String? sourceType;
  final bool failed;
  final String? model;
  final DateTime timestamp;
  final int inputTokens;
  final int outputTokens;
  final int reasoningTokens;
  final int cachedTokens;
  final int totalTokens;
  final Map<String, dynamic> raw;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'auth_index': authIndex,
    'source': source,
    'source_type': sourceType,
    'failed': failed,
    'model': model,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'tokens': {
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'reasoning_tokens': reasoningTokens,
      'cached_tokens': cachedTokens,
      'total_tokens': totalTokens,
    },
    'raw': raw,
  };

  factory GetTokenUsageEvent.fromJson(Map<String, dynamic> json) {
    final tokens = _map(json['tokens']);
    return GetTokenUsageEvent(
      id: (json['id'] ?? '').toString(),
      authIndex:
          (json['auth_index'] ??
                  json['source_key'] ??
                  json['source'] ??
                  'unknown')
              .toString(),
      source: (json['source'] ?? 'unknown').toString(),
      sourceType: json['source_type'] as String?,
      failed: json['failed'] as bool? ?? false,
      model: json['model'] as String?,
      timestamp: _date(json['timestamp']) ?? DateTime.now().toUtc(),
      inputTokens: (tokens['input_tokens'] as num? ?? 0).toInt(),
      outputTokens: (tokens['output_tokens'] as num? ?? 0).toInt(),
      reasoningTokens: (tokens['reasoning_tokens'] as num? ?? 0).toInt(),
      cachedTokens: (tokens['cached_tokens'] as num? ?? 0).toInt(),
      totalTokens: (tokens['total_tokens'] as num? ?? 0).toInt(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class GetTokenUsageSummary {
  const GetTokenUsageSummary({
    this.credentialCount = 0,
    this.eventCount = 0,
    this.failedEventCount = 0,
    this.totalTokens = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.reasoningTokens = 0,
    this.cachedTokens = 0,
  });

  final int credentialCount;
  final int eventCount;
  final int failedEventCount;
  final int totalTokens;
  final int inputTokens;
  final int outputTokens;
  final int reasoningTokens;
  final int cachedTokens;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'credential_count': credentialCount,
    'event_count': eventCount,
    'failed_event_count': failedEventCount,
    'total_tokens': totalTokens,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'reasoning_tokens': reasoningTokens,
    'cached_tokens': cachedTokens,
  };

  factory GetTokenUsageSummary.fromJson(Map<String, dynamic> json) {
    return GetTokenUsageSummary(
      credentialCount: json['credential_count'] as int? ?? 0,
      eventCount: json['event_count'] as int? ?? 0,
      failedEventCount: json['failed_event_count'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
      reasoningTokens: json['reasoning_tokens'] as int? ?? 0,
      cachedTokens: json['cached_tokens'] as int? ?? 0,
    );
  }
}

class GetTokenUsageRow {
  const GetTokenUsageRow({
    required this.authIndex,
    required this.source,
    this.sourceType,
    this.requestCount = 0,
    this.failedCount = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.reasoningTokens = 0,
    this.cachedTokens = 0,
    this.totalTokens = 0,
    this.latestTimestamp,
    this.models = const <String>[],
    this.currentUsage,
    this.quotaCachedAt,
    this.usageError,
  });

  final String authIndex;
  final String source;
  final String? sourceType;
  final int requestCount;
  final int failedCount;
  final int inputTokens;
  final int outputTokens;
  final int reasoningTokens;
  final int cachedTokens;
  final int totalTokens;
  final String? latestTimestamp;
  final List<String> models;
  final GetTokenCurrentUsage? currentUsage;
  final double? quotaCachedAt;
  final String? usageError;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'auth_index': authIndex,
    'source': source,
    'source_type': sourceType,
    'request_count': requestCount,
    'failed_count': failedCount,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'reasoning_tokens': reasoningTokens,
    'cached_tokens': cachedTokens,
    'total_tokens': totalTokens,
    'latest_timestamp': latestTimestamp,
    'models': models,
    'current_usage': currentUsage?.toJson(),
    'quota_cached_at': quotaCachedAt,
    'usage_error': usageError,
  };

  factory GetTokenUsageRow.fromJson(Map<String, dynamic> json) {
    final currentUsage = _mapOrNull(json['current_usage']);
    return GetTokenUsageRow(
      authIndex: json['auth_index'] as String? ?? 'unknown',
      source: json['source'] as String? ?? 'unknown',
      sourceType: json['source_type'] as String?,
      requestCount: json['request_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
      reasoningTokens: json['reasoning_tokens'] as int? ?? 0,
      cachedTokens: json['cached_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      latestTimestamp: json['latest_timestamp'] as String?,
      models: (json['models'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      currentUsage: currentUsage == null
          ? null
          : GetTokenCurrentUsage.fromJson(currentUsage),
      quotaCachedAt: (json['quota_cached_at'] as num?)?.toDouble(),
      usageError: json['usage_error'] as String?,
    );
  }
}

class GetTokenUpstreamInfo {
  const GetTokenUpstreamInfo({
    this.models = const <String>[],
    this.sources = const <String>[],
    this.totalCount,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  final List<String> models;
  final List<String> sources;
  final int? totalCount;
  final int? page;
  final int? pageSize;
  final int? totalPages;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'models': models,
    'sources': sources,
    'total_count': totalCount,
    'page': page,
    'page_size': pageSize,
    'total_pages': totalPages,
  };

  factory GetTokenUpstreamInfo.fromJson(Map<String, dynamic> json) {
    return GetTokenUpstreamInfo(
      models: (json['models'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      sources: (json['sources'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['page_size'] as num?)?.toInt(),
      totalPages: (json['total_pages'] as num?)?.toInt(),
    );
  }
}

class GetTokenUsageSnapshot {
  const GetTokenUsageSnapshot({
    required this.updatedAt,
    required this.params,
    required this.eventTableCount,
    required this.addedEventCount,
    required this.summary,
    required this.rows,
    required this.upstream,
  });

  final DateTime updatedAt;
  final GetTokenUsageQuery params;
  final int eventTableCount;
  final int addedEventCount;
  final GetTokenUsageSummary summary;
  final List<GetTokenUsageRow> rows;
  final GetTokenUpstreamInfo upstream;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'params': params.toJson(),
    'event_table_count': eventTableCount,
    'added_event_count': addedEventCount,
    'summary': summary.toJson(),
    'rows': rows.map((item) => item.toJson()).toList(),
    'upstream': upstream.toJson(),
  };

  factory GetTokenUsageSnapshot.fromJson(Map<String, dynamic> json) {
    return GetTokenUsageSnapshot(
      updatedAt: _date(json['updated_at']) ?? DateTime.now().toUtc(),
      params: GetTokenUsageQuery.fromJson(_map(json['params'])),
      eventTableCount: json['event_table_count'] as int? ?? 0,
      addedEventCount: json['added_event_count'] as int? ?? 0,
      summary: GetTokenUsageSummary.fromJson(_map(json['summary'])),
      rows: _list(json['rows']).map(GetTokenUsageRow.fromJson).toList(),
      upstream: GetTokenUpstreamInfo.fromJson(_map(json['upstream'])),
    );
  }
}

class GetTokenCollectionSnapshot {
  const GetTokenCollectionSnapshot({
    required this.status,
    required this.message,
    required this.processed,
    required this.total,
    required this.progressPercent,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.summary,
    this.credentialChanges,
    this.refreshStats,
  });

  final String status;
  final String message;
  final int processed;
  final int total;
  final double progressPercent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final GetTokenSummary? summary;
  final GetTokenCredentialChanges? credentialChanges;
  final GetTokenRefreshStats? refreshStats;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status,
    'message': message,
    'processed': processed,
    'total': total,
    'progress_percent': progressPercent,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'summary': summary?.toJson(),
    'credential_changes': credentialChanges?.toJson(),
    'refresh_stats': refreshStats?.toJson(),
  };
}

class GetTokenToolState {
  const GetTokenToolState({
    this.loading = true,
    this.config = const GetTokenConfig(),
    this.secret = const GetTokenSecretConfig(),
    this.collection,
    this.credentials = const <GetTokenCredentialRow>[],
    this.usageSnapshot,
    this.running = false,
    this.collecting = false,
    this.queryingTokenUsage = false,
    this.refreshingAuthIndex,
    this.errorMessage,
  });

  final bool loading;
  final GetTokenConfig config;
  final GetTokenSecretConfig secret;
  final GetTokenCollectionSnapshot? collection;
  final List<GetTokenCredentialRow> credentials;
  final GetTokenUsageSnapshot? usageSnapshot;
  final bool running;
  final bool collecting;
  final bool queryingTokenUsage;
  final String? refreshingAuthIndex;
  final String? errorMessage;

  List<GetTokenCredentialRow> get failures =>
      credentials.where((item) => item.isFailure).toList();

  GetTokenToolState copyWith({
    bool? loading,
    GetTokenConfig? config,
    GetTokenSecretConfig? secret,
    GetTokenCollectionSnapshot? collection,
    bool clearCollection = false,
    List<GetTokenCredentialRow>? credentials,
    GetTokenUsageSnapshot? usageSnapshot,
    bool clearUsageSnapshot = false,
    bool? running,
    bool? collecting,
    bool? queryingTokenUsage,
    String? refreshingAuthIndex,
    bool clearRefreshingAuthIndex = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return GetTokenToolState(
      loading: loading ?? this.loading,
      config: config ?? this.config,
      secret: secret ?? this.secret,
      collection: clearCollection ? null : (collection ?? this.collection),
      credentials: credentials ?? this.credentials,
      usageSnapshot: clearUsageSnapshot
          ? null
          : (usageSnapshot ?? this.usageSnapshot),
      running: running ?? this.running,
      collecting: collecting ?? this.collecting,
      queryingTokenUsage: queryingTokenUsage ?? this.queryingTokenUsage,
      refreshingAuthIndex: clearRefreshingAuthIndex
          ? null
          : (refreshingAuthIndex ?? this.refreshingAuthIndex),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  static const initial = GetTokenToolState();
}

class GetTokenActionResult {
  const GetTokenActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

DateTime? _date(Object? value) {
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
  return DateTime.tryParse(text)?.toUtc();
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

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const <Map<String, dynamic>>[];
}

String encodeJson(Object? value) {
  return jsonEncode(value);
}
