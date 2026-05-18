import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:personal_toolbox/src/exchange_rate/sina_forex_market_service.dart';
import 'package:personal_toolbox/src/tools/tool_registry.dart';

void main() {
  test('工具注册表包含金融分类和汇率换算工具', () {
    expect(
      toolCategories.where((category) => category.id == 'finance').single.name,
      '金融',
    );
    final tool = toolDefinitions
        .where((definition) => definition.id == 'exchangeRate')
        .single;
    expect(tool.categoryId, 'finance');
    expect(tool.route, '/tools/exchangeRate');
    expect(tool.syncEnabled, isFalse);
  });

  test('解析新浪分钟 K 线 JSONP', () {
    final points = parseMinuteKLine(
      '/*<script>location.href=\'//sina.com\';</script>*/\n'
      'var_fx_susdcny_5=([{"d":"2026-05-16 00:25:00","o":"6.8130",'
      '"h":"6.8132","l":"6.8130","c":"6.8132"}])',
    );

    expect(points, hasLength(1));
    expect(points.single.time, DateTime(2026, 5, 16, 0, 25));
    expect(points.single.rate, 6.8132);
  });

  test('解析新浪日 K 字符串', () {
    final points = parseDailyKLine(
      '/*<script>location.href=\'//sina.com\';</script>*/\n'
      'var_fx_susdcny_day=("2026-05-14,6.80,6.79,6.82,6.81,|'
      '2026-05-15,6.81,6.80,6.83,6.82")',
    );

    expect(points, hasLength(2));
    expect(points.first.time, DateTime(2026, 5, 14));
    expect(points.last.rate, 6.82);
  });

  test('时间范围标签顺序符合行情视图', () {
    expect(exchangeTimeRanges.map((range) => range.label).toList(), [
      '1分',
      '日K',
      '周K',
      '月K',
      '年K',
      '5分',
      '15分',
      '30分',
      '60分',
      '4H',
    ]);
  });

  test('实时行情提取 USD 桥接价格', () async {
    final service = SinaForexMarketService(
      client: _FakeClient((request) async {
        expect(request.url.host, 'hq.sinajs.cn');
        return '''
var hq_str_fx_susdcny="02:31:02,6.8000,6.8100,6.8100,211,6.7900,6.8200,6.7800,6.8100,在岸人民币,0,0,0,新浪,0,0,,2026-05-16";
var hq_str_fx_seurusd="05:00:00,1.1600,1.1620,1.1600,57,1.1670,1.1673,1.1616,1.1625,欧元兑美元即期汇率,0,0,0,,0,0,,2026-05-16";
''';
      }),
    );

    final legs = await service.fetchLatestUsdLegs({'USD', 'CNY', 'EUR'});

    expect(legs['USD'], 1);
    expect(legs['CNY'], closeTo(1 / 6.8, 0.000001));
    expect(legs['EUR'], 1.16);
  });

  test('通过 USD 桥接合成非美元货币对序列', () async {
    final service = SinaForexMarketService(
      client: _FakeClient((request) async {
        final symbol = request.url.queryParameters['symbol'];
        if (symbol == 'fx_susdcny') {
          return _minutePayload('fx_susdcny', ['7.0000', '7.1000']);
        }
        if (symbol == 'fx_susdjpy') {
          return _minutePayload('fx_susdjpy', ['140.0000', '142.0000']);
        }
        fail('unexpected request: ${request.url}');
      }),
    );

    final series = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'JPY',
      range: exchangeTimeRanges.first,
    );

    expect(series.points, hasLength(2));
    expect(series.points.first.rate, closeTo(20, 0.000001));
    expect(series.points.last.rate, closeTo(20, 0.000001));
  });

  test('美元目标货币直接沿用真实货币腿的时间序列', () async {
    final service = SinaForexMarketService(
      client: _FakeClient((request) async {
        expect(request.url.queryParameters['symbol'], 'fx_susdcny');
        return _minutePayload('fx_susdcny', ['7.0000', '7.1000']);
      }),
    );

    final series = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'USD',
      range: exchangeTimeRanges.first,
    );

    expect(series.points, hasLength(2));
    expect(series.points.first.rate, closeTo(1 / 7, 0.000001));
    expect(series.points.last.rate, closeTo(1 / 7.1, 0.000001));
  });

  test('15 分钟在直连接口为空时会退回到 5 分钟聚合', () async {
    final service = SinaForexMarketService(
      client: _FakeClient((request) async {
        final scale = request.url.queryParameters['scale'];
        if (scale == '15') {
          return 'var_fx_susdcny_15=({"msg":"data is empty"})';
        }
        return 'var_fx_susdcny_5=([{"d":"2026-05-16 00:00:00","o":"7.0","h":"7.0","l":"7.0","c":"7.0"},{"d":"2026-05-16 00:05:00","o":"7.1","h":"7.1","l":"7.1","c":"7.1"},{"d":"2026-05-16 00:10:00","o":"7.2","h":"7.2","l":"7.2","c":"7.2"},{"d":"2026-05-16 00:15:00","o":"7.3","h":"7.3","l":"7.3","c":"7.3"},{"d":"2026-05-16 00:20:00","o":"7.4","h":"7.4","l":"7.4","c":"7.4"},{"d":"2026-05-16 00:25:00","o":"7.5","h":"7.5","l":"7.5","c":"7.5"}])';
      }),
    );

    final series = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'USD',
      range: exchangeTimeRangeById('15min'),
    );

    expect(series.points, hasLength(2));
    expect(series.points.first.rate, closeTo(1 / 7.2, 0.000001));
    expect(series.points.first.periodStart, DateTime(2026, 5, 16, 0, 0));
    expect(series.points.first.periodEnd, DateTime(2026, 5, 16, 0, 10));
    expect(series.points.last.rate, closeTo(1 / 7.5, 0.000001));
    expect(series.points.last.periodStart, DateTime(2026, 5, 16, 0, 15));
    expect(series.points.last.periodEnd, DateTime(2026, 5, 16, 0, 25));
  });

  test('4H 会由 60 分钟线聚合并保留区间', () async {
    final service = SinaForexMarketService(
      client: _FakeClient((request) async {
        expect(request.url.queryParameters['scale'], '60');
        return 'var_fx_susdcny_60=([{"d":"2026-05-16 00:00:00","o":"7.0","h":"7.0","l":"7.0","c":"7.0"},{"d":"2026-05-16 01:00:00","o":"7.1","h":"7.1","l":"7.1","c":"7.1"},{"d":"2026-05-16 02:00:00","o":"7.2","h":"7.2","l":"7.2","c":"7.2"},{"d":"2026-05-16 03:00:00","o":"7.3","h":"7.3","l":"7.3","c":"7.3"},{"d":"2026-05-16 04:00:00","o":"7.4","h":"7.4","l":"7.4","c":"7.4"},{"d":"2026-05-16 05:00:00","o":"7.5","h":"7.5","l":"7.5","c":"7.5"},{"d":"2026-05-16 06:00:00","o":"7.6","h":"7.6","l":"7.6","c":"7.6"},{"d":"2026-05-16 07:00:00","o":"7.7","h":"7.7","l":"7.7","c":"7.7"}])';
      }),
    );

    final series = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'USD',
      range: exchangeTimeRangeById('4h'),
    );

    expect(series.points, hasLength(2));
    expect(series.points.first.periodStart, DateTime(2026, 5, 16, 0, 0));
    expect(series.points.first.periodEnd, DateTime(2026, 5, 16, 3, 0));
    expect(series.points.last.periodStart, DateTime(2026, 5, 16, 4, 0));
    expect(series.points.last.periodEnd, DateTime(2026, 5, 16, 7, 0));
  });

  test('周K、月K、年K 会按日线聚合并保留区间', () async {
    final service = SinaForexMarketService(
      client: _FakeClient((request) async {
        expect(request.url.path, contains('getDayKLine'));
        return 'var_fx_susdcny_day=("2025-12-31,7.0,7.0,7.0,7.0,|2026-01-02,7.1,7.1,7.1,7.1,|2026-03-30,7.2,7.2,7.2,7.2,|2026-03-31,7.3,7.3,7.3,7.3,|2026-04-06,7.4,7.4,7.4,7.4,|2026-04-30,7.5,7.5,7.5,7.5")';
      }),
    );

    final weekly = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'USD',
      range: exchangeTimeRangeById('week'),
    );
    final monthly = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'USD',
      range: exchangeTimeRangeById('month'),
    );
    final yearly = await service.fetchSeries(
      fromCode: 'CNY',
      toCode: 'USD',
      range: exchangeTimeRangeById('year'),
    );

    expect(weekly.points.first.periodStart, DateTime(2025, 12, 31));
    expect(weekly.points.first.periodEnd, DateTime(2026, 1, 2));
    expect(monthly.points.last.periodStart, DateTime(2026, 4, 6));
    expect(monthly.points.last.periodEnd, DateTime(2026, 4, 30));
    expect(yearly.points.first.periodStart, DateTime(2025, 12, 31));
    expect(yearly.points.first.periodEnd, DateTime(2025, 12, 31));
    expect(yearly.points.last.periodStart, DateTime(2026, 1, 2));
    expect(yearly.points.last.periodEnd, DateTime(2026, 4, 30));
  });

  test('空分钟 K 线会抛出中文错误', () {
    expect(
      () => parseMinuteKLine('var_fx_susdcny_5=([])'),
      throwsA(isA<SinaForexMarketException>()),
    );
  });
}

String _minutePayload(String symbol, List<String> closes) {
  final rows = <String>[];
  for (var i = 0; i < closes.length; i++) {
    rows.add(
      '{"d":"2026-05-16 0${i + 1}:00:00","o":"${closes[i]}",'
      '"h":"${closes[i]}","l":"${closes[i]}","c":"${closes[i]}"}',
    );
  }
  return 'var_${symbol}_5=([${rows.join(',')}])';
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final FutureOr<String> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/javascript; charset=utf-8'},
    );
  }
}
