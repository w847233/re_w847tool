import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const exchangeCurrencies = <ExchangeCurrency>[
  ExchangeCurrency(code: 'CNY', name: '人民币'),
  ExchangeCurrency(code: 'USD', name: '美元'),
  ExchangeCurrency(code: 'EUR', name: '欧元'),
  ExchangeCurrency(code: 'JPY', name: '日元'),
  ExchangeCurrency(code: 'GBP', name: '英镑'),
  ExchangeCurrency(code: 'HKD', name: '港币'),
  ExchangeCurrency(code: 'AUD', name: '澳元'),
  ExchangeCurrency(code: 'CAD', name: '加元'),
  ExchangeCurrency(code: 'CHF', name: '瑞郎'),
  ExchangeCurrency(code: 'SGD', name: '新加坡元'),
  ExchangeCurrency(code: 'KRW', name: '韩元'),
  ExchangeCurrency(code: 'THB', name: '泰铢'),
];

const exchangeTimeRanges = <ExchangeTimeRange>[
  ExchangeTimeRange(
    id: '1min',
    label: '1分',
    strategy: ExchangeTimeRangeStrategy.minuteApi,
    inputPointCount: 60,
    displayPointCount: 60,
    alignmentTolerance: Duration(minutes: 10),
    minuteScale: 1,
  ),
  ExchangeTimeRange(
    id: 'day',
    label: '日K',
    strategy: ExchangeTimeRangeStrategy.dailyApi,
    inputPointCount: 90,
    displayPointCount: 90,
    alignmentTolerance: Duration(hours: 36),
  ),
  ExchangeTimeRange(
    id: 'week',
    label: '周K',
    strategy: ExchangeTimeRangeStrategy.dailyAggregate,
    inputPointCount: 370,
    displayPointCount: 52,
    alignmentTolerance: Duration(days: 8),
    calendarUnit: ExchangeCalendarAggregateUnit.week,
  ),
  ExchangeTimeRange(
    id: 'month',
    label: '月K',
    strategy: ExchangeTimeRangeStrategy.dailyAggregate,
    inputPointCount: 1860,
    displayPointCount: 60,
    alignmentTolerance: Duration(days: 40),
    calendarUnit: ExchangeCalendarAggregateUnit.month,
  ),
  ExchangeTimeRange(
    id: 'year',
    label: '年K',
    strategy: ExchangeTimeRangeStrategy.dailyAggregate,
    inputPointCount: 3653,
    displayPointCount: 10,
    alignmentTolerance: Duration(days: 400),
    calendarUnit: ExchangeCalendarAggregateUnit.year,
  ),
  ExchangeTimeRange(
    id: '5min',
    label: '5分',
    strategy: ExchangeTimeRangeStrategy.minuteApi,
    inputPointCount: 72,
    displayPointCount: 72,
    alignmentTolerance: Duration(minutes: 15),
    minuteScale: 5,
  ),
  ExchangeTimeRange(
    id: '15min',
    label: '15分',
    strategy: ExchangeTimeRangeStrategy.minuteApiWithFallbackAggregate,
    inputPointCount: 216,
    displayPointCount: 72,
    alignmentTolerance: Duration(minutes: 30),
    minuteScale: 15,
    fallbackMinuteScale: 5,
    aggregateMinutes: 15,
  ),
  ExchangeTimeRange(
    id: '30min',
    label: '30分',
    strategy: ExchangeTimeRangeStrategy.minuteApi,
    inputPointCount: 72,
    displayPointCount: 72,
    alignmentTolerance: Duration(minutes: 75),
    minuteScale: 30,
  ),
  ExchangeTimeRange(
    id: '60min',
    label: '60分',
    strategy: ExchangeTimeRangeStrategy.minuteApi,
    inputPointCount: 96,
    displayPointCount: 96,
    alignmentTolerance: Duration(hours: 3),
    minuteScale: 60,
  ),
  ExchangeTimeRange(
    id: '4h',
    label: '4H',
    strategy: ExchangeTimeRangeStrategy.minuteAggregate,
    inputPointCount: 240,
    displayPointCount: 60,
    alignmentTolerance: Duration(hours: 10),
    minuteScale: 60,
    aggregateMinutes: 240,
  ),
];

final sinaForexMarketServiceProvider = Provider<SinaForexMarketService>((ref) {
  final service = SinaForexMarketService();
  ref.onDispose(service.close);
  return service;
});

class ExchangeCurrency {
  const ExchangeCurrency({required this.code, required this.name});

  final String code;
  final String name;

  String get label => '$code $name';
}

ExchangeTimeRange exchangeTimeRangeById(String id) {
  return exchangeTimeRanges.firstWhere(
    (range) => range.id == id,
    orElse: () => exchangeTimeRanges.first,
  );
}

enum ExchangeTimeRangeStrategy {
  minuteApi,
  minuteApiWithFallbackAggregate,
  minuteAggregate,
  dailyApi,
  dailyAggregate,
}

enum ExchangeCalendarAggregateUnit { week, month, year }

class ExchangeTimeRange {
  const ExchangeTimeRange({
    required this.id,
    required this.label,
    required this.strategy,
    required this.inputPointCount,
    required this.displayPointCount,
    required this.alignmentTolerance,
    this.minuteScale,
    this.fallbackMinuteScale,
    this.aggregateMinutes,
    this.calendarUnit,
    this.maxDisplayPoints,
  });

  final String id;
  final String label;
  final ExchangeTimeRangeStrategy strategy;
  final int inputPointCount;
  final int displayPointCount;
  final Duration alignmentTolerance;
  final int? minuteScale;
  final int? fallbackMinuteScale;
  final int? aggregateMinutes;
  final ExchangeCalendarAggregateUnit? calendarUnit;
  final int? maxDisplayPoints;

  bool get usesIntradayLabel =>
      strategy == ExchangeTimeRangeStrategy.minuteApi ||
      strategy == ExchangeTimeRangeStrategy.minuteApiWithFallbackAggregate ||
      strategy == ExchangeTimeRangeStrategy.minuteAggregate;

  bool get showsCalendarRange =>
      strategy == ExchangeTimeRangeStrategy.dailyAggregate;
}

enum SinaQuoteDirection { usdPerBase, quotePerUsd }

class SinaForexSymbol {
  const SinaForexSymbol({
    required this.symbol,
    required this.baseCode,
    required this.quoteCode,
    required this.quoteDirection,
  });

  final String symbol;
  final String baseCode;
  final String quoteCode;
  final SinaQuoteDirection quoteDirection;
}

class ExchangeRatePoint {
  const ExchangeRatePoint({
    required this.time,
    required this.rate,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) : periodStart = periodStart ?? time,
       periodEnd = periodEnd ?? time;

  final DateTime time;
  final double rate;
  final DateTime periodStart;
  final DateTime periodEnd;

  ExchangeRatePoint copyWith({
    DateTime? time,
    double? rate,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return ExchangeRatePoint(
      time: time ?? this.time,
      rate: rate ?? this.rate,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }
}

class ExchangeRateSeries {
  const ExchangeRateSeries({
    required this.fromCode,
    required this.toCode,
    required this.points,
    required this.latestRate,
    required this.source,
  });

  final String fromCode;
  final String toCode;
  final List<ExchangeRatePoint> points;
  final double latestRate;
  final String source;

  ExchangeRateChange get change {
    if (points.isEmpty) {
      return ExchangeRateChange.empty(latestRate);
    }
    return ExchangeRateChange.fromRates(points.first.rate, points.last.rate);
  }
}

class ExchangeRateChange {
  const ExchangeRateChange({
    required this.startRate,
    required this.endRate,
    required this.absoluteChange,
    required this.percentChange,
  });

  factory ExchangeRateChange.fromRates(double startRate, double endRate) {
    final absolute = endRate - startRate;
    final percent = startRate == 0 ? 0.0 : absolute / startRate * 100;
    return ExchangeRateChange(
      startRate: startRate,
      endRate: endRate,
      absoluteChange: absolute,
      percentChange: percent,
    );
  }

  factory ExchangeRateChange.empty(double latestRate) {
    return ExchangeRateChange(
      startRate: latestRate,
      endRate: latestRate,
      absoluteChange: 0,
      percentChange: 0,
    );
  }

  final double startRate;
  final double endRate;
  final double absoluteChange;
  final double percentChange;

  bool get isUp => percentChange >= 0;
}

class SinaForexMarketException implements Exception {
  const SinaForexMarketException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SinaForexMarketService {
  SinaForexMarketService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const sourceName = '新浪财经外汇';
  static const _headers = {
    'Referer': 'https://finance.sina.com.cn',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };

  static const _symbols = <String, SinaForexSymbol>{
    'CNY': SinaForexSymbol(
      symbol: 'fx_susdcny',
      baseCode: 'USD',
      quoteCode: 'CNY',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'EUR': SinaForexSymbol(
      symbol: 'fx_seurusd',
      baseCode: 'EUR',
      quoteCode: 'USD',
      quoteDirection: SinaQuoteDirection.usdPerBase,
    ),
    'GBP': SinaForexSymbol(
      symbol: 'fx_sgbpusd',
      baseCode: 'GBP',
      quoteCode: 'USD',
      quoteDirection: SinaQuoteDirection.usdPerBase,
    ),
    'AUD': SinaForexSymbol(
      symbol: 'fx_saudusd',
      baseCode: 'AUD',
      quoteCode: 'USD',
      quoteDirection: SinaQuoteDirection.usdPerBase,
    ),
    'CAD': SinaForexSymbol(
      symbol: 'fx_susdcad',
      baseCode: 'USD',
      quoteCode: 'CAD',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'CHF': SinaForexSymbol(
      symbol: 'fx_susdchf',
      baseCode: 'USD',
      quoteCode: 'CHF',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'HKD': SinaForexSymbol(
      symbol: 'fx_susdhkd',
      baseCode: 'USD',
      quoteCode: 'HKD',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'JPY': SinaForexSymbol(
      symbol: 'fx_susdjpy',
      baseCode: 'USD',
      quoteCode: 'JPY',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'SGD': SinaForexSymbol(
      symbol: 'fx_susdsgd',
      baseCode: 'USD',
      quoteCode: 'SGD',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'KRW': SinaForexSymbol(
      symbol: 'fx_susdkrw',
      baseCode: 'USD',
      quoteCode: 'KRW',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
    'THB': SinaForexSymbol(
      symbol: 'fx_susdthb',
      baseCode: 'USD',
      quoteCode: 'THB',
      quoteDirection: SinaQuoteDirection.quotePerUsd,
    ),
  };

  Future<Map<String, double>> fetchLatestUsdLegs(
    Set<String> currencyCodes,
  ) async {
    final requested = currencyCodes.where((code) => code != 'USD').toSet();
    if (requested.isEmpty) {
      return const {'USD': 1};
    }
    final symbols = requested.map(_symbolForCode).toList();
    final uri = Uri.https('hq.sinajs.cn', '/', {
      'list': symbols.map((symbol) => symbol.symbol).join(','),
    });
    final response = await _get(uri);
    final text = _decodeResponse(response.bodyBytes);
    final latest = <String, double>{'USD': 1};
    for (final symbol in symbols) {
      latest[_currencyForSymbol(symbol)] = _usdPerUnit(
        symbol,
        _parseLatestQuote(text, symbol.symbol),
      );
    }
    return latest;
  }

  Future<ExchangeRateSeries> fetchSeries({
    required String fromCode,
    required String toCode,
    required ExchangeTimeRange range,
  }) async {
    if (fromCode == toCode) {
      return ExchangeRateSeries(
        fromCode: fromCode,
        toCode: toCode,
        points: [ExchangeRatePoint(time: DateTime.now(), rate: 1)],
        latestRate: 1,
        source: sourceName,
      );
    }

    final points = await _fetchPairPoints(fromCode, toCode, range);
    if (points.isEmpty) {
      throw const SinaForexMarketException('该货币对暂时无法获取行情。');
    }
    final sampled = _samplePoints(points, range.maxDisplayPoints);
    return ExchangeRateSeries(
      fromCode: fromCode,
      toCode: toCode,
      points: sampled,
      latestRate: sampled.last.rate,
      source: sourceName,
    );
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw SinaForexMarketException('新浪行情请求失败：HTTP ${response.statusCode}');
      }
      return response;
    } on SinaForexMarketException {
      rethrow;
    } catch (error) {
      throw SinaForexMarketException('新浪行情请求失败：$error');
    }
  }

  Future<List<ExchangeRatePoint>> _fetchPairPoints(
    String fromCode,
    String toCode,
    ExchangeTimeRange range,
  ) async {
    if (fromCode == 'USD') {
      final toLeg = await _fetchUsdLegSeries(toCode, range);
      return toLeg
          .map(
            (point) => ExchangeRatePoint(
              time: point.time,
              rate: 1 / point.rate,
              periodStart: point.periodStart,
              periodEnd: point.periodEnd,
            ),
          )
          .toList();
    }
    if (toCode == 'USD') {
      return _fetchUsdLegSeries(fromCode, range);
    }

    final fromLeg = await _fetchUsdLegSeries(fromCode, range);
    final toLeg = await _fetchUsdLegSeries(toCode, range);
    return _combineLegs(fromLeg, toLeg, range);
  }

  Future<List<ExchangeRatePoint>> _fetchUsdLegSeries(
    String currencyCode,
    ExchangeTimeRange range,
  ) async {
    final symbol = _symbolForCode(currencyCode);
    final raw = await _loadRawQuoteSeries(symbol, range);
    final converted = raw
        .map((point) => point.copyWith(rate: _usdPerUnit(symbol, point.rate)))
        .where((point) => point.rate > 0 && point.rate.isFinite)
        .toList();
    if (converted.isEmpty) {
      throw SinaForexMarketException('$currencyCode 暂无可用行情。');
    }
    return _trimRecent(converted, range.displayPointCount);
  }

  Future<List<ExchangeRatePoint>> _loadRawQuoteSeries(
    SinaForexSymbol symbol,
    ExchangeTimeRange range,
  ) async {
    switch (range.strategy) {
      case ExchangeTimeRangeStrategy.minuteApi:
        return _trimRecent(
          await _fetchRawMinuteKLine(
            symbol,
            scale: range.minuteScale!,
            datalen: range.inputPointCount,
          ),
          range.displayPointCount,
        );
      case ExchangeTimeRangeStrategy.minuteApiWithFallbackAggregate:
        final direct = await _fetchRawMinuteKLine(
          symbol,
          scale: range.minuteScale!,
          datalen: range.displayPointCount,
        );
        if (direct.isNotEmpty) {
          return _trimRecent(direct, range.displayPointCount);
        }
        final fallback = await _fetchRawMinuteKLine(
          symbol,
          scale: range.fallbackMinuteScale!,
          datalen: range.inputPointCount,
        );
        return _trimRecent(
          _aggregateMinutePoints(fallback, range.aggregateMinutes!),
          range.displayPointCount,
        );
      case ExchangeTimeRangeStrategy.minuteAggregate:
        final raw = await _fetchRawMinuteKLine(
          symbol,
          scale: range.minuteScale!,
          datalen: range.inputPointCount,
        );
        return _trimRecent(
          _aggregateMinutePoints(raw, range.aggregateMinutes!),
          range.displayPointCount,
        );
      case ExchangeTimeRangeStrategy.dailyApi:
        return _trimRecent(
          await _fetchDailyKLine(symbol),
          range.displayPointCount,
        );
      case ExchangeTimeRangeStrategy.dailyAggregate:
        final raw = _trimRecent(
          await _fetchDailyKLine(symbol),
          range.inputPointCount,
        );
        return _trimRecent(
          _aggregateCalendarPoints(raw, range.calendarUnit!),
          range.displayPointCount,
        );
    }
  }

  Future<List<ExchangeRatePoint>> _fetchRawMinuteKLine(
    SinaForexSymbol symbol, {
    required int scale,
    required int datalen,
  }) async {
    final varName = 'var_${symbol.symbol}_$scale';
    final uri = Uri.https(
      'vip.stock.finance.sina.com.cn',
      '/forex/api/jsonp.php/$varName=/NewForexService.getMinKline',
      {
        'symbol': symbol.symbol,
        'scale': scale.toString(),
        'datalen': max(datalen + 20, 120).toString(),
      },
    );
    final response = await _get(uri);
    final source = _decodeResponse(response.bodyBytes);
    if (_isEmptyMinutePayload(source)) {
      return const <ExchangeRatePoint>[];
    }
    return parseMinuteKLine(source);
  }

  Future<List<ExchangeRatePoint>> _fetchDailyKLine(
    SinaForexSymbol symbol,
  ) async {
    final varName = 'var_${symbol.symbol}_day';
    final uri = Uri.https(
      'vip.stock.finance.sina.com.cn',
      '/forex/api/jsonp.php/$varName=/NewForexService.getDayKLine',
      {'symbol': symbol.symbol},
    );
    final response = await _get(uri);
    return parseDailyKLine(_decodeResponse(response.bodyBytes));
  }

  SinaForexSymbol _symbolForCode(String code) {
    final symbol = _symbols[code];
    if (symbol == null) {
      throw SinaForexMarketException('暂不支持 $code 货币行情。');
    }
    return symbol;
  }

  String _currencyForSymbol(SinaForexSymbol symbol) {
    return symbol.quoteDirection == SinaQuoteDirection.usdPerBase
        ? symbol.baseCode
        : symbol.quoteCode;
  }

  double _usdPerUnit(SinaForexSymbol symbol, double quote) {
    if (quote <= 0 || !quote.isFinite) {
      throw SinaForexMarketException('${symbol.symbol} 行情价格无效。');
    }
    return symbol.quoteDirection == SinaQuoteDirection.usdPerBase
        ? quote
        : 1 / quote;
  }

  double _parseLatestQuote(String source, String symbol) {
    final match = RegExp('var\\s+hq_str_$symbol="([^"]*)"').firstMatch(source);
    if (match == null) {
      throw SinaForexMarketException('$symbol 实时行情格式异常。');
    }
    final fields = match.group(1)!.split(',');
    if (fields.length < 2) {
      throw SinaForexMarketException('$symbol 实时行情字段缺失。');
    }
    final quote = double.tryParse(fields[1]);
    if (quote == null) {
      throw SinaForexMarketException('$symbol 实时价格不是数字。');
    }
    return quote;
  }

  List<ExchangeRatePoint> _combineLegs(
    List<ExchangeRatePoint> fromLeg,
    List<ExchangeRatePoint> toLeg,
    ExchangeTimeRange range,
  ) {
    final combined = <ExchangeRatePoint>[];
    var toIndex = 0;
    for (final from in fromLeg) {
      while (toIndex + 1 < toLeg.length &&
          !toLeg[toIndex + 1].time.isAfter(from.time)) {
        toIndex++;
      }
      final to = toLeg[toIndex];
      if (from.time.difference(to.time).abs() <= range.alignmentTolerance) {
        final time = from.time.isAfter(to.time) ? from.time : to.time;
        final periodStart = from.periodStart.isAfter(to.periodStart)
            ? from.periodStart
            : to.periodStart;
        final periodEnd = from.periodEnd.isBefore(to.periodEnd)
            ? from.periodEnd
            : to.periodEnd;
        combined.add(
          ExchangeRatePoint(
            time: time,
            rate: from.rate / to.rate,
            periodStart: periodStart,
            periodEnd: periodEnd.isBefore(periodStart) ? time : periodEnd,
          ),
        );
      }
    }
    return combined;
  }

  List<ExchangeRatePoint> _aggregateMinutePoints(
    List<ExchangeRatePoint> points,
    int bucketMinutes,
  ) {
    if (points.isEmpty) {
      return const <ExchangeRatePoint>[];
    }
    final bucketMs = Duration(minutes: bucketMinutes).inMilliseconds;
    final grouped = <int, List<ExchangeRatePoint>>{};
    for (final point in points) {
      final bucket = point.time.millisecondsSinceEpoch ~/ bucketMs;
      grouped.putIfAbsent(bucket, () => <ExchangeRatePoint>[]).add(point);
    }
    final buckets = grouped.keys.toList()..sort();
    return [
      for (final bucket in buckets) _buildAggregatePoint(grouped[bucket]!),
    ];
  }

  List<ExchangeRatePoint> _aggregateCalendarPoints(
    List<ExchangeRatePoint> points,
    ExchangeCalendarAggregateUnit unit,
  ) {
    if (points.isEmpty) {
      return const <ExchangeRatePoint>[];
    }
    final aggregated = <ExchangeRatePoint>[];
    var currentBucket = '';
    var buffer = <ExchangeRatePoint>[];
    for (final point in points) {
      final bucket = _calendarBucketId(point.time, unit);
      if (currentBucket.isNotEmpty && bucket != currentBucket) {
        aggregated.add(_buildAggregatePoint(buffer));
        buffer = <ExchangeRatePoint>[];
      }
      currentBucket = bucket;
      buffer.add(point);
    }
    if (buffer.isNotEmpty) {
      aggregated.add(_buildAggregatePoint(buffer));
    }
    return aggregated;
  }

  ExchangeRatePoint _buildAggregatePoint(List<ExchangeRatePoint> points) {
    final first = points.first;
    final last = points.last;
    return ExchangeRatePoint(
      time: last.time,
      rate: last.rate,
      periodStart: first.periodStart,
      periodEnd: last.periodEnd,
    );
  }

  String _calendarBucketId(DateTime time, ExchangeCalendarAggregateUnit unit) {
    switch (unit) {
      case ExchangeCalendarAggregateUnit.week:
        final start = time.subtract(Duration(days: time.weekday - 1));
        return '${start.year}-${start.month}-${start.day}';
      case ExchangeCalendarAggregateUnit.month:
        return '${time.year}-${time.month}';
      case ExchangeCalendarAggregateUnit.year:
        return '${time.year}';
    }
  }

  List<ExchangeRatePoint> _trimRecent(
    List<ExchangeRatePoint> points,
    int count,
  ) {
    if (points.length <= count) {
      return points;
    }
    return points.sublist(points.length - count);
  }

  List<ExchangeRatePoint> _samplePoints(
    List<ExchangeRatePoint> points,
    int? maxCount,
  ) {
    if (maxCount == null || points.length <= maxCount) {
      return points;
    }
    final sampled = <ExchangeRatePoint>[];
    final step = (points.length - 1) / (maxCount - 1);
    for (var i = 0; i < maxCount; i++) {
      sampled.add(points[(i * step).round()]);
    }
    return sampled;
  }
}

List<ExchangeRatePoint> parseMinuteKLine(String source) {
  final jsonText = _extractJsonArray(source);
  final decoded = jsonDecode(jsonText);
  if (decoded is! List) {
    throw const SinaForexMarketException('分钟 K 线响应不是数组。');
  }
  final points = decoded.map((item) {
    if (item is! Map) {
      throw const SinaForexMarketException('分钟 K 线条目格式异常。');
    }
    final time = DateTime.tryParse(item['d']?.toString() ?? '');
    final close = double.tryParse(item['c']?.toString() ?? '');
    if (time == null || close == null) {
      throw const SinaForexMarketException('分钟 K 线字段缺失或格式异常。');
    }
    return ExchangeRatePoint(time: time, rate: close);
  }).toList();
  if (points.isEmpty) {
    throw const SinaForexMarketException('分钟 K 线为空。');
  }
  return points;
}

List<ExchangeRatePoint> parseDailyKLine(String source) {
  final payload = _extractQuotedPayload(source);
  final points = <ExchangeRatePoint>[];
  for (final row in payload.split('|')) {
    final fields = row.trim().split(',');
    if (fields.length < 5 || fields.first.isEmpty) {
      continue;
    }
    final time = DateTime.tryParse(fields[0]);
    final close = double.tryParse(fields[4]);
    if (time != null && close != null && close > 0) {
      points.add(ExchangeRatePoint(time: time, rate: close));
    }
  }
  if (points.isEmpty) {
    throw const SinaForexMarketException('日 K 线为空。');
  }
  return points;
}

String _decodeResponse(List<int> bytes) {
  return utf8.decode(bytes, allowMalformed: true);
}

bool _isEmptyMinutePayload(String source) {
  return source.contains('"msg":"data is empty"') ||
      source.contains('"msg": "data is empty"');
}

String _extractJsonArray(String source) {
  final start = source.indexOf('([');
  final end = source.lastIndexOf('])');
  if (start == -1 || end == -1 || end <= start) {
    throw const SinaForexMarketException('K 线 JSONP 包裹格式异常。');
  }
  return source.substring(start + 1, end + 1);
}

String _extractQuotedPayload(String source) {
  final start = source.indexOf('("');
  final end = source.lastIndexOf('")');
  if (start == -1 || end == -1 || end <= start) {
    throw const SinaForexMarketException('日 K 线 JSONP 包裹格式异常。');
  }
  return source.substring(start + 2, end);
}
