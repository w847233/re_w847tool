import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class EncryptedSyncDocument {
  const EncryptedSyncDocument({
    required this.schemaVersion,
    required this.updatedAt,
    required this.deviceId,
    required this.cipher,
    required this.kdf,
    required this.iterations,
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.payload,
  });

  final int schemaVersion;
  final DateTime updatedAt;
  final String deviceId;
  final String cipher;
  final String kdf;
  final int iterations;
  final String salt;
  final String nonce;
  final String mac;
  final String payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deviceId': deviceId,
    'cipher': cipher,
    'kdf': kdf,
    'iterations': iterations,
    'salt': salt,
    'nonce': nonce,
    'mac': mac,
    'payload': payload,
  };

  factory EncryptedSyncDocument.fromJson(Map<String, dynamic> json) {
    return EncryptedSyncDocument(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      deviceId: json['deviceId'] as String? ?? 'remote',
      cipher: json['cipher'] as String? ?? 'AES-256-GCM',
      kdf: json['kdf'] as String? ?? 'PBKDF2-HMAC-SHA256',
      iterations: json['iterations'] as int? ?? SyncCryptoService.iterations,
      salt: json['salt'] as String,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
      payload: json['payload'] as String,
    );
  }
}

class SyncCryptoService {
  static const iterations = 150000;

  const SyncCryptoService();

  Future<EncryptedSyncDocument> encryptJson({
    required Map<String, dynamic> payload,
    required String passphrase,
    required String deviceId,
  }) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveKey(passphrase, salt, iterations);
    final algorithm = AesGcm.with256bits();
    final encodedPayload = utf8.encode(jsonEncode(payload));
    final box = await algorithm.encrypt(
      encodedPayload,
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedSyncDocument(
      schemaVersion: payload['schemaVersion'] as int? ?? 1,
      updatedAt: DateTime.now().toUtc(),
      deviceId: deviceId,
      cipher: 'AES-256-GCM',
      kdf: 'PBKDF2-HMAC-SHA256',
      iterations: iterations,
      salt: base64Encode(salt),
      nonce: base64Encode(box.nonce),
      mac: base64Encode(box.mac.bytes),
      payload: base64Encode(box.cipherText),
    );
  }

  Future<Map<String, dynamic>> decryptJson({
    required EncryptedSyncDocument document,
    required String passphrase,
  }) async {
    final secretKey = await _deriveKey(
      passphrase,
      base64Decode(document.salt),
      document.iterations,
    );
    final box = SecretBox(
      base64Decode(document.payload),
      nonce: base64Decode(document.nonce),
      mac: Mac(base64Decode(document.mac)),
    );
    final bytes = await AesGcm.with256bits().decrypt(box, secretKey: secretKey);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt,
    int iterationCount,
  ) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterationCount,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
