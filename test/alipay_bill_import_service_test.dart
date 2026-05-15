import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:personal_toolbox/src/ledger/alipay_bill_import_service.dart';

void main() {
  test('支付宝 GBK ZIP 交易账单可以解析为导入记录', () {
    final csvText = [
      '# 支付宝交易账单明细',
      '支付宝交易号,商户订单号,业务类型,商品名称,完成时间,商家实收（元）,交易状态',
      '202605140001,ORDER-1,交易,咖啡,2026-05-14 09:30:00,12.34,交易成功',
      '202605140002,ORDER-2,退款,订单退款,2026-05-14 10:00:00,-2.00,交易成功',
      '',
    ].join('\n');
    final csvBytes = Uint8List.fromList(gbk_bytes.encode(csvText));
    final archive = Archive()
      ..addFile(ArchiveFile('trade.csv', csvBytes.length, csvBytes));
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final service = AlipayBillImportService();
    addTearDown(service.close);

    final bill = service.parseDownloadedBill(zipBytes, billDate: '2026-05-14');

    expect(bill.fileNames, ['trade.csv']);
    expect(bill.records, hasLength(2));
    expect(bill.records.first.sourceId, 'alipay:202605140001');
    expect(bill.records.first.amount, 12.34);
    expect(bill.records.first.title, '咖啡');
    expect(bill.records.first.isRefund, isFalse);
    expect(bill.records.last.amount, 2.0);
    expect(bill.records.last.isRefund, isTrue);
  });
}
