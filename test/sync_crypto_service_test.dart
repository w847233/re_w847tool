import 'package:flutter_test/flutter_test.dart';
import 'package:personal_toolbox/src/sync/sync_crypto_service.dart';

void main() {
  test('同步快照可以加密并用同一密码解密', () async {
    const service = SyncCryptoService();
    final payload = {
      'schemaVersion': 1,
      'deviceId': 'device-a',
      'settings': [
        {'key': 'preferredFontWeight', 'value': '700'},
      ],
    };

    final encrypted = await service.encryptJson(
      payload: payload,
      passphrase: 'secret-passphrase',
      deviceId: 'device-a',
    );
    final decrypted = await service.decryptJson(
      document: encrypted,
      passphrase: 'secret-passphrase',
    );

    expect(encrypted.payload, isNot(contains('preferredFontWeight')));
    expect(decrypted['settings'], payload['settings']);
  });
}
