import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:csv/csv.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AlipayBillImportRequest {
  const AlipayBillImportRequest({
    required this.appId,
    required this.privateKeyPem,
    required this.billDate,
    this.appAuthToken = '',
    this.billType = 'trade',
    this.gatewayUrl = 'https://openapi.alipay.com/gateway.do',
  });

  final String appId;
  final String privateKeyPem;
  final DateTime billDate;
  final String appAuthToken;
  final String billType;
  final String gatewayUrl;
}

class AlipayBillImportResult {
  const AlipayBillImportResult({
    required this.records,
    required this.billDownloadUrl,
    required this.billFileCode,
    required this.parsedFileNames,
  });

  final List<AlipayBillRecord> records;
  final String billDownloadUrl;
  final String billFileCode;
  final List<String> parsedFileNames;
}

class AlipayBillRecord {
  const AlipayBillRecord({
    required this.sourceId,
    required this.amount,
    required this.occurredAt,
    required this.title,
    required this.tradeNo,
    required this.outTradeNo,
    required this.businessType,
    required this.isRefund,
  });

  final String sourceId;
  final double amount;
  final DateTime occurredAt;
  final String title;
  final String tradeNo;
  final String outTradeNo;
  final String businessType;
  final bool isRefund;

  String toLedgerNote() {
    final parts = [
      '支付宝账单',
      if (title.isNotEmpty) title,
      if (businessType.isNotEmpty) businessType,
      if (tradeNo.isNotEmpty) '交易号 $tradeNo',
      if (outTradeNo.isNotEmpty) '商户单号 $outTradeNo',
    ];
    return parts.join(' · ');
  }
}

class AlipayBillImportException implements Exception {
  const AlipayBillImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AlipayBillImportService {
  AlipayBillImportService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;

  void close() {
    _client.close();
  }

  Future<AlipayBillImportResult> fetchRecentTradeBill(
    AlipayBillImportRequest request,
  ) async {
    _validateRequest(request);
    final downloadInfo = await _queryBillDownloadUrl(request);
    if (downloadInfo.url.isEmpty) {
      return AlipayBillImportResult(
        records: const [],
        billDownloadUrl: '',
        billFileCode: downloadInfo.fileCode,
        parsedFileNames: const [],
      );
    }

    final response = await _client.get(Uri.parse(downloadInfo.url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AlipayBillImportException('账单文件下载失败：HTTP ${response.statusCode}');
    }

    final parsed = parseDownloadedBill(
      response.bodyBytes,
      billDate: _billDate(request.billDate),
    );
    return AlipayBillImportResult(
      records: parsed.records,
      billDownloadUrl: downloadInfo.url,
      billFileCode: downloadInfo.fileCode,
      parsedFileNames: parsed.fileNames,
    );
  }

  AlipayDownloadedBill parseDownloadedBill(
    Uint8List bytes, {
    required String billDate,
  }) {
    final texts = _decodeBillTexts(bytes);
    final records = <AlipayBillRecord>[];
    for (final text in texts) {
      records.addAll(_parseCsvBill(text, billDate: billDate));
    }
    return AlipayDownloadedBill(
      records: records,
      fileNames: [for (final text in texts) text.fileName],
    );
  }

  void _validateRequest(AlipayBillImportRequest request) {
    if (request.appId.trim().isEmpty) {
      throw const AlipayBillImportException('请先填写支付宝应用 App ID。');
    }
    if (request.privateKeyPem.trim().isEmpty) {
      throw const AlipayBillImportException('请先填写支付宝应用私钥 PEM。');
    }
    if (request.billType.trim().isEmpty) {
      throw const AlipayBillImportException('请先填写账单类型。');
    }
    final current = _now();
    final today = DateTime(current.year, current.month, current.day);
    final billDate = DateTime(
      request.billDate.year,
      request.billDate.month,
      request.billDate.day,
    );
    if (!billDate.isBefore(today)) {
      throw const AlipayBillImportException('支付宝交易日账单按 T+1 生成，只能导入今天之前的账单。');
    }
  }

  Future<_AlipayBillDownloadInfo> _queryBillDownloadUrl(
    AlipayBillImportRequest request,
  ) async {
    final bizContent = jsonEncode({
      'bill_type': request.billType.trim(),
      'bill_date': _billDate(request.billDate),
    });
    final params = <String, String>{
      'app_id': request.appId.trim(),
      'method': 'alipay.data.dataservice.bill.downloadurl.query',
      'format': 'JSON',
      'charset': 'utf-8',
      'sign_type': 'RSA2',
      'timestamp': _timestamp(_now()),
      'version': '1.0',
      'biz_content': bizContent,
    };
    final appAuthToken = request.appAuthToken.trim();
    if (appAuthToken.isNotEmpty) {
      params['app_auth_token'] = appAuthToken;
    }
    params['sign'] = _sign(params, request.privateKeyPem);

    final response = await _client.post(
      Uri.parse(request.gatewayUrl.trim()),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params,
      encoding: utf8,
    );
    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map<String, dynamic>) {
      throw const AlipayBillImportException('支付宝接口返回格式异常。');
    }
    final node =
        payload['alipay_data_dataservice_bill_downloadurl_query_response'];
    if (node is! Map<String, dynamic>) {
      throw AlipayBillImportException(
        _alipayErrorMessage(payload) ?? '支付宝接口返回中缺少账单下载信息。',
      );
    }
    if (node['code'] != '10000') {
      throw AlipayBillImportException(
        _alipayErrorMessage(node) ?? '支付宝接口调用失败：${node['code'] ?? '未知错误'}',
      );
    }
    return _AlipayBillDownloadInfo(
      url: node['bill_download_url'] as String? ?? '',
      fileCode: node['bill_file_code'] as String? ?? '',
    );
  }

  String _sign(Map<String, String> params, String privateKeyPem) {
    final sorted = SplayTreeMap<String, String>.from(params);
    final content = sorted.entries
        .where((entry) => entry.key != 'sign' && entry.value.isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    try {
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem.trim());
      final signature = CryptoUtils.rsaSign(
        privateKey,
        Uint8List.fromList(utf8.encode(content)),
      );
      return base64Encode(signature);
    } catch (error) {
      throw AlipayBillImportException('支付宝应用私钥解析或签名失败：$error');
    }
  }

  List<_BillText> _decodeBillTexts(Uint8List bytes) {
    if (_isZip(bytes)) {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      return [
        for (final file in archive.files)
          if (file.isFile && _isBillTextFile(file.name))
            _BillText(file.name, _decodeText(file.readBytes() ?? Uint8List(0))),
      ];
    }
    return [_BillText('downloaded_bill.csv', _decodeText(bytes))];
  }

  List<AlipayBillRecord> _parseCsvBill(
    _BillText bill, {
    required String billDate,
  }) {
    final rows = csv.decode(bill.content.replaceAll('\ufeff', ''));
    final headerIndex = rows.indexWhere(_looksLikeHeader);
    if (headerIndex < 0) {
      return const [];
    }

    final headers = [
      for (final cell in rows[headerIndex]) cell?.toString().trim() ?? '',
    ];
    final records = <AlipayBillRecord>[];
    for (var rowIndex = headerIndex + 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((cell) => (cell?.toString().trim() ?? '').isEmpty)) {
        continue;
      }
      final tradeNo = _cell(headers, row, const [
        '支付宝交易号',
        '支付宝账单号',
        '交易号',
        '账单号',
      ]);
      final outTradeNo = _cell(headers, row, const ['商户订单号', '商家订单号', '外部订单号']);
      final title = _cell(headers, row, const ['商品名称', '商品说明', '订单标题', '备注']);
      final businessType = _cell(headers, row, const ['业务类型', '账务类型', '收支类型']);
      final status = _cell(headers, row, const ['交易状态', '状态']);
      if (_isClosedOrFailed(status)) {
        continue;
      }
      final amount = _amount(headers, row);
      if (amount == null || amount == 0) {
        continue;
      }
      final occurredAt =
          _date(headers, row) ?? DateFormat('yyyy-MM-dd').parseStrict(billDate);
      final sourceKey = tradeNo.isNotEmpty
          ? tradeNo
          : outTradeNo.isNotEmpty
          ? outTradeNo
          : '$billDate-${bill.fileName}-$rowIndex';
      final normalizedAmount = amount.abs();
      records.add(
        AlipayBillRecord(
          sourceId: 'alipay:$sourceKey',
          amount: normalizedAmount,
          occurredAt: occurredAt,
          title: title,
          tradeNo: tradeNo,
          outTradeNo: outTradeNo,
          businessType: businessType,
          isRefund:
              amount < 0 || businessType.contains('退款') || title.contains('退款'),
        ),
      );
    }
    return records;
  }

  bool _looksLikeHeader(List<dynamic> row) {
    final cells = row.map((cell) => _normalizeHeader(cell?.toString() ?? ''));
    final text = cells.join('|');
    return (text.contains('支付宝交易号') ||
            text.contains('商户订单号') ||
            text.contains('支付宝账单号')) &&
        (text.contains('订单金额') ||
            text.contains('商家实收') ||
            text.contains('收入') ||
            text.contains('发生金额'));
  }

  String _cell(List<String> headers, List<dynamic> row, List<String> aliases) {
    final index = _findHeader(headers, aliases);
    if (index == null || index >= row.length) {
      return '';
    }
    return row[index]?.toString().trim() ?? '';
  }

  int? _findHeader(List<String> headers, List<String> aliases) {
    final normalizedAliases = aliases.map(_normalizeHeader).toList();
    for (var i = 0; i < headers.length; i++) {
      final header = _normalizeHeader(headers[i]);
      if (normalizedAliases.any(
        (alias) => header == alias || header.contains(alias),
      )) {
        return i;
      }
    }
    return null;
  }

  double? _amount(List<String> headers, List<dynamic> row) {
    const preferred = ['商家实收', '收入', '订单金额', '交易金额', '发生金额', '金额'];
    for (final alias in preferred) {
      final value = _cell(headers, row, [alias]);
      final amount = _parseMoney(value);
      if (amount != null && amount != 0) {
        return amount;
      }
    }
    return null;
  }

  DateTime? _date(List<String> headers, List<dynamic> row) {
    const preferred = ['完成时间', '交易成功时间', '入账时间', '账务时间', '创建时间', '交易时间'];
    for (final alias in preferred) {
      final value = _cell(headers, row, [alias]);
      final date = _parseDate(value);
      if (date != null) {
        return date;
      }
    }
    return null;
  }

  double? _parseMoney(String value) {
    var normalized = value
        .trim()
        .replaceAll(',', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '');
    if (normalized.isEmpty) {
      return null;
    }
    var negative = false;
    if (normalized.startsWith('(') && normalized.endsWith(')')) {
      negative = true;
      normalized = normalized.substring(1, normalized.length - 1);
    }
    final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final amount = double.tryParse(match.group(0)!);
    if (amount == null) {
      return null;
    }
    return negative ? -amount.abs() : amount;
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim().replaceAll('/', '-');
    if (normalized.isEmpty) {
      return null;
    }
    for (final pattern in const [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd',
    ]) {
      try {
        return DateFormat(pattern).parseStrict(normalized);
      } catch (_) {}
    }
    return DateTime.tryParse(normalized);
  }

  bool _isClosedOrFailed(String status) {
    return status.contains('关闭') ||
        status.contains('失败') ||
        status.toUpperCase().contains('CLOSED');
  }

  String _decodeText(Uint8List bytes) {
    if (bytes.isEmpty) {
      return '';
    }
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return gbk_bytes.decode(bytes);
    }
  }

  bool _isZip(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }

  bool _isBillTextFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.csv') || lower.endsWith('.txt');
  }

  String _normalizeHeader(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\s:：_\-（）()\[\]【】]'), '')
        .replaceAll('元', '');
  }

  String _billDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _timestamp(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  String? _alipayErrorMessage(Map<String, dynamic> node) {
    final details = [
      node['sub_msg'],
      node['msg'],
      node['message'],
      node['code'],
      node['sub_code'],
    ].whereType<String>().where((item) => item.trim().isNotEmpty).toList();
    if (details.isEmpty) {
      return null;
    }
    return '支付宝接口调用失败：${details.join(' / ')}';
  }
}

class AlipayDownloadedBill {
  const AlipayDownloadedBill({required this.records, required this.fileNames});

  final List<AlipayBillRecord> records;
  final List<String> fileNames;
}

class _AlipayBillDownloadInfo {
  const _AlipayBillDownloadInfo({required this.url, required this.fileCode});

  final String url;
  final String fileCode;
}

class _BillText {
  const _BillText(this.fileName, this.content);

  final String fileName;
  final String content;
}
