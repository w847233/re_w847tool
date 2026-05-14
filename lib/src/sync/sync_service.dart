import 'dart:convert';

import '../data/app_database.dart';
import 'sync_crypto_service.dart';
import 'webdav_client.dart';

const remoteSyncPath = 'personal-toolbox/state.v1.enc.json';

class SyncService {
  SyncService({
    required AppDatabase database,
    SyncCryptoService cryptoService = const SyncCryptoService(),
    WebDavClient? webDavClient,
  }) : _database = database,
       _cryptoService = cryptoService,
       _webDavClient = webDavClient ?? WebDavClient();

  final AppDatabase _database;
  final SyncCryptoService _cryptoService;
  final WebDavClient _webDavClient;

  Future<void> uploadEncryptedSnapshot({
    required WebDavConfig config,
    required String passphrase,
  }) async {
    final snapshot = await _database.exportPlainSnapshot();
    final document = await _cryptoService.encryptJson(
      payload: snapshot,
      passphrase: passphrase,
      deviceId: snapshot['deviceId'] as String,
    );
    await _webDavClient.makeCollection(config, 'personal-toolbox/');
    await _webDavClient.writeText(
      config,
      remoteSyncPath,
      const JsonEncoder.withIndent('  ').convert(document.toJson()),
    );
  }

  Future<bool> downloadEncryptedSnapshot({
    required WebDavConfig config,
    required String passphrase,
  }) async {
    final body = await _webDavClient.readText(config, remoteSyncPath);
    if (body == null) {
      return false;
    }
    final document = EncryptedSyncDocument.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
    final snapshot = await _cryptoService.decryptJson(
      document: document,
      passphrase: passphrase,
    );
    await _database.importPlainSnapshot(snapshot);
    return true;
  }
}
