import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the session token and the registered push device live between
/// launches. The real store is the platform keychain/keystore; tests use
/// [MemoryTokenStore].
abstract class TokenStore {
  Future<String?> readToken();
  Future<void> writeToken(String? token);

  /// Id of the push device this install registered (for unregistering on
  /// sign-out).
  Future<String?> readPushDevice();
  Future<void> writePushDevice(String? id);
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _token = 'session_token';
  static const _device = 'push_device_id';

  // Not synced to iCloud / other devices, readable after the first unlock so
  // a push can open the app in the background.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<void> _write(String key, String? value) =>
      value == null ? _storage.delete(key: key) : _storage.write(key: key, value: value);

  @override
  Future<String?> readToken() => _storage.read(key: _token);

  @override
  Future<void> writeToken(String? token) => _write(_token, token);

  @override
  Future<String?> readPushDevice() => _storage.read(key: _device);

  @override
  Future<void> writePushDevice(String? id) => _write(_device, id);
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({this.token, this.pushDevice});

  String? token;
  String? pushDevice;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String? token) async => this.token = token;

  @override
  Future<String?> readPushDevice() async => pushDevice;

  @override
  Future<void> writePushDevice(String? id) async => pushDevice = id;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => const SecureTokenStore());

/// Reads the stored session before the first frame. A broken keystore (or
/// a test without the plugin) means "signed out", never a crash.
Future<String?> restoreSession(TokenStore store) async {
  try {
    return await store.readToken();
  } catch (e) {
    debugPrint('session restore failed: $e');
    return null;
  }
}
