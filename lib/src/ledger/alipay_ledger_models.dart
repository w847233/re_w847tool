import 'dart:convert';

const alipayLedgerConfigKey = 'localOnly.alipayLedgerConfig';
const alipayOAuthTokenKey = 'localOnly.alipayOAuthToken';
const defaultAlipayLedgerMethod = 'alipay.user.mobilebill.list.query';
const alipayAccountLogMethod = 'alipay.data.bill.accountlog.query';
const alipayOAuthTokenMethod = 'alipay.system.oauth.token';
const alipayOAuthRedirectUri = 'http://127.0.0.1:39187/alipay/oauth/callback';

class AlipayLedgerConfig {
  const AlipayLedgerConfig({
    this.appId = '',
    this.privateKeyPem = '',
    this.alipayPublicKeyPem = '',
    this.methodName = defaultAlipayLedgerMethod,
  });

  final String appId;
  final String privateKeyPem;
  final String alipayPublicKeyPem;
  final String methodName;

  bool get isConfigured =>
      appId.trim().isNotEmpty &&
      privateKeyPem.trim().isNotEmpty &&
      alipayPublicKeyPem.trim().isNotEmpty &&
      methodName.trim().isNotEmpty;

  AlipayLedgerConfig copyWith({
    String? appId,
    String? privateKeyPem,
    String? alipayPublicKeyPem,
    String? methodName,
  }) {
    return AlipayLedgerConfig(
      appId: appId ?? this.appId,
      privateKeyPem: privateKeyPem ?? this.privateKeyPem,
      alipayPublicKeyPem: alipayPublicKeyPem ?? this.alipayPublicKeyPem,
      methodName: methodName ?? this.methodName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'appId': appId.trim(),
      'privateKeyPem': privateKeyPem.trim(),
      'alipayPublicKeyPem': alipayPublicKeyPem.trim(),
      'methodName': methodName.trim().isEmpty
          ? defaultAlipayLedgerMethod
          : methodName.trim(),
    };
  }

  factory AlipayLedgerConfig.fromJson(Map<String, dynamic> json) {
    return AlipayLedgerConfig(
      appId: (json['appId'] as String? ?? '').trim(),
      privateKeyPem: (json['privateKeyPem'] as String? ?? '').trim(),
      alipayPublicKeyPem: (json['alipayPublicKeyPem'] as String? ?? '').trim(),
      methodName: (json['methodName'] as String? ?? defaultAlipayLedgerMethod)
          .trim(),
    );
  }

  static AlipayLedgerConfig parse(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const AlipayLedgerConfig();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return AlipayLedgerConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return AlipayLedgerConfig.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const AlipayLedgerConfig();
  }
}

class AlipayOAuthToken {
  const AlipayOAuthToken({
    this.userId = '',
    this.openId = '',
    this.accessToken = '',
    this.refreshToken = '',
    this.expiresAt,
  });

  final String userId;
  final String openId;
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  bool get isAuthorized =>
      (userId.trim().isNotEmpty || openId.trim().isNotEmpty) &&
      accessToken.trim().isNotEmpty;

  bool get isExpired {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().toUtc().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    );
  }

  AlipayOAuthToken copyWith({
    String? userId,
    String? openId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AlipayOAuthToken(
      userId: userId ?? this.userId,
      openId: openId ?? this.openId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId.trim(),
      'openId': openId.trim(),
      'accessToken': accessToken.trim(),
      'refreshToken': refreshToken.trim(),
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
    };
  }

  factory AlipayOAuthToken.fromJson(Map<String, dynamic> json) {
    return AlipayOAuthToken(
      userId: (json['userId'] as String? ?? '').trim(),
      openId: (json['openId'] as String? ?? '').trim(),
      accessToken: (json['accessToken'] as String? ?? '').trim(),
      refreshToken: (json['refreshToken'] as String? ?? '').trim(),
      expiresAt: _parseDate(json['expiresAt']),
    );
  }

  static AlipayOAuthToken parse(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const AlipayOAuthToken();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return AlipayOAuthToken.fromJson(decoded);
      }
      if (decoded is Map) {
        return AlipayOAuthToken.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const AlipayOAuthToken();
  }
}

class AlipayLedgerQuery {
  const AlipayLedgerQuery({required this.startTime, required this.endTime});

  final DateTime startTime;
  final DateTime endTime;
}

class AlipayBillRow {
  const AlipayBillRow({
    required this.sourceId,
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    required this.status,
    required this.occurredAt,
    required this.raw,
  });

  final String sourceId;
  final String type;
  final double amount;
  final String title;
  final String category;
  final String status;
  final DateTime? occurredAt;
  final Map<String, dynamic> raw;

  bool get isImportable =>
      sourceId.trim().isNotEmpty &&
      (type == '支出' || type == '收入') &&
      amount > 0 &&
      occurredAt != null;

  String get note {
    final parts = <String>[
      '支付宝',
      if (category.trim().isNotEmpty) category.trim(),
      if (title.trim().isNotEmpty) title.trim(),
      if (status.trim().isNotEmpty) status.trim(),
    ];
    return parts.join('｜');
  }
}

class AlipayLedgerPreview {
  const AlipayLedgerPreview({
    required this.rows,
    this.incomeAmount,
    this.expenseAmount,
  });

  final List<AlipayBillRow> rows;
  final double? incomeAmount;
  final double? expenseAmount;
}

class AlipayLedgerImportResult {
  const AlipayLedgerImportResult({
    required this.added,
    required this.duplicates,
    required this.ignored,
  });

  final int added;
  final int duplicates;
  final int ignored;

  String get message => '导入完成：新增 $added 条，跳过重复 $duplicates 条，忽略无效 $ignored 条';
}

DateTime? _parseDate(Object? source) {
  if (source is! String || source.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(source.trim())?.toUtc();
}
