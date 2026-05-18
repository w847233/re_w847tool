import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pointycastle/export.dart';

import 'alipay_ledger_models.dart';
import 'alipay_open_api_client.dart';

class AlipayLedgerService {
  AlipayLedgerService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Future<AlipayLedgerPreview> queryBills({
    required AlipayLedgerConfig config,
    required AlipayOAuthToken token,
    required AlipayLedgerQuery query,
  }) async {
    _validateQuery(query);
    final client = AlipayOpenApiClient(config: config, now: _now);
    final method = config.methodName.trim().isEmpty
        ? defaultAlipayLedgerMethod
        : config.methodName.trim();
    final response = await client.call(
      method,
      _buildBizContent(method, token, query),
      extraParams: <String, String>{'auth_token': token.accessToken.trim()},
    );
    return parsePreview(method: method, response: response);
  }

  AlipayLedgerPreview parsePreview({
    required String method,
    required Map<String, dynamic> response,
  }) {
    if (response['billListItems'] is List) {
      final rows = (response['billListItems'] as List)
          .whereType<Map>()
          .map((row) => _fromMobileBill(method, Map<String, dynamic>.from(row)))
          .toList();
      final statistic = response['statisticInfo'] is Map
          ? Map<String, dynamic>.from(response['statisticInfo'] as Map)
          : null;
      return AlipayLedgerPreview(
        rows: rows,
        incomeAmount: _amountFrom(statistic?['incomeAmount']),
        expenseAmount: _amountFrom(statistic?['expenditureAmount']),
      );
    }
    if (response['detail_list'] is List) {
      final rows = (response['detail_list'] as List)
          .whereType<Map>()
          .map((row) => _fromAccountLog(method, Map<String, dynamic>.from(row)))
          .toList();
      return AlipayLedgerPreview(rows: rows);
    }
    return const AlipayLedgerPreview(rows: <AlipayBillRow>[]);
  }

  Map<String, dynamic> _buildBizContent(
    String method,
    AlipayOAuthToken token,
    AlipayLedgerQuery query,
  ) {
    final start = _formatApiTime(query.startTime);
    final end = _formatApiTime(query.endTime);
    if (method == alipayAccountLogMethod) {
      final content = <String, dynamic>{
        'start_time': start,
        'end_time': end,
        'page_no': '1',
        'page_size': '2000',
      };
      if (token.openId.trim().isNotEmpty) {
        content['open_id'] = token.openId.trim();
      } else if (token.userId.trim().isNotEmpty) {
        content['bill_user_id'] = token.userId.trim();
      } else {
        throw const AlipayOpenApiException('缺少 openId 或 userId，请重新授权');
      }
      return content;
    }
    if (token.userId.trim().isEmpty) {
      throw const AlipayOpenApiException('缺少 userId，请重新授权');
    }
    return <String, dynamic>{
      'user_id': token.userId.trim(),
      'start_time': start,
      'end_time': end,
    };
  }
}

AlipayBillRow _fromMobileBill(String method, Map<String, dynamic> row) {
  final title = _firstText(row, const ['consumeTitle', 'title', 'memo']);
  final category = _firstText(row, const ['categoryName', 'category']);
  final status = _firstText(row, const ['bizStateDesc', 'fundState', 'status']);
  final amount = _amountFrom(
    _first(row, const ['consumeFee', 'amount', 'fee']),
  );
  final type = _directionFrom(row, amount: amount, fallbackExpense: true);
  final occurredAt = _dateFrom(_first(row, const ['gmtCreate', 'occurredAt']));
  return AlipayBillRow(
    sourceId: _sourceId(
      method,
      row,
      occurredAt,
      title,
      amount,
      status,
      category,
    ),
    type: type,
    amount: amount?.abs() ?? 0,
    title: title,
    category: category,
    status: status,
    occurredAt: occurredAt,
    raw: row,
  );
}

AlipayBillRow _fromAccountLog(String method, Map<String, dynamic> row) {
  final title = _firstText(row, const [
    'trans_memo',
    'biz_desc',
    'bill_source',
    'other_account',
  ]);
  final category = _firstText(row, const ['type', 'bill_source']);
  final status = _firstText(row, const ['direction', 'type']);
  final amount = _amountFrom(_first(row, const ['trans_amount', 'amount']));
  final type = _directionFrom(row, amount: amount);
  final occurredAt = _dateFrom(_first(row, const ['trans_dt', 'gmtCreate']));
  return AlipayBillRow(
    sourceId: _sourceId(
      method,
      row,
      occurredAt,
      title,
      amount,
      status,
      category,
    ),
    type: type,
    amount: amount?.abs() ?? 0,
    title: title,
    category: category,
    status: status,
    occurredAt: occurredAt,
    raw: row,
  );
}

void _validateQuery(AlipayLedgerQuery query) {
  if (!query.startTime.isBefore(query.endTime)) {
    throw const AlipayOpenApiException('开始时间必须早于结束时间');
  }
  final days = query.endTime.difference(query.startTime).inHours / 24;
  if (days > 31) {
    throw const AlipayOpenApiException('单次支付宝账单查询不能超过 31 天');
  }
}

String _formatApiTime(DateTime value) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(value.toLocal());
}

Object? _first(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && '$value'.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _firstText(Map<String, dynamic> row, List<String> keys) {
  return _first(row, keys)?.toString().trim() ?? '';
}

double? _amountFrom(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  final normalized = value
      .toString()
      .replaceAll(',', '')
      .replaceAll('¥', '')
      .replaceAll('￥', '')
      .trim();
  return double.tryParse(normalized);
}

String _directionFrom(
  Map<String, dynamic> row, {
  required double? amount,
  bool fallbackExpense = false,
}) {
  final text = [
    row['direction'],
    row['type'],
    row['fundState'],
    row['bizStateDesc'],
    row['categoryName'],
  ].whereType<Object>().map((value) => value.toString()).join(' ');
  if (text.contains('收入') || text.contains('入账') || text.contains('收款')) {
    return '收入';
  }
  if (text.contains('支出') ||
      text.contains('付款') ||
      text.contains('扣款') ||
      text.contains('支付') ||
      text.contains('消费')) {
    return '支出';
  }
  if (amount != null && amount < 0) {
    return '支出';
  }
  return fallbackExpense ? '支出' : '';
}

DateTime? _dateFrom(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    final milliseconds = value > 100000000000 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds).toUtc();
  }
  final source = value.toString().trim();
  if (source.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(source.replaceFirst(' ', 'T'));
  return parsed?.toUtc();
}

String _sourceId(
  String method,
  Map<String, dynamic> row,
  DateTime? occurredAt,
  String title,
  double? amount,
  String status,
  String category,
) {
  final explicit = _firstText(row, const [
    'account_log_id',
    'accountLogId',
    'alipay_order_no',
    'alipayOrderNo',
    'trade_no',
    'tradeNo',
    'orderNo',
    'id',
  ]);
  if (explicit.isNotEmpty) {
    return 'alipay:$method:$explicit';
  }
  final stable = [
    method,
    occurredAt?.toIso8601String() ?? '',
    title,
    amount?.toStringAsFixed(2) ?? '',
    status,
    category,
  ].join('|');
  final digest = SHA256Digest().process(
    Uint8List.fromList(utf8.encode(stable)),
  );
  return 'alipay:$method:${_hex(digest)}';
}

String _hex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
