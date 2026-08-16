import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static const _keyPasswordHash = 'xfin_password_hash';
  static const _keyBiometricsEnabled = 'xfin_biometrics_enabled';

  static final AuthService _instance = AuthService._internal(
    const FlutterSecureStorage(),
    LocalAuthentication(),
  );
  static AuthService get instance => _instance;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  AuthService._internal(this._storage, this._localAuth);

  /// For testing only — inject custom storage and localAuth.
  factory AuthService.withDependencies({
    required FlutterSecureStorage storage,
    required LocalAuthentication localAuth,
  }) =>
      AuthService._internal(storage, localAuth);

  /// Exposed for test assertions — computes the hash that setPassword stores.
  String hashForTest(String password) => _hash(password);

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<bool> get isPasswordSet async {
    final hash = await _storage.read(key: _keyPasswordHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPassword(String password) async {
    await _storage.write(key: _keyPasswordHash, value: _hash(password));
  }

  Future<bool> verifyPassword(String password) async {
    final stored = await _storage.read(key: _keyPasswordHash);
    if (stored == null) return false;
    return stored == _hash(password);
  }

  Future<void> removePassword() async {
    await _storage.delete(key: _keyPasswordHash);
    await _storage.delete(key: _keyBiometricsEnabled);
  }

  Future<bool> get isBiometricsEnabled async {
    final val = await _storage.read(key: _keyBiometricsEnabled);
    return val == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
        key: _keyBiometricsEnabled, value: enabled ? 'true' : 'false');
  }

  Future<bool> get canCheckBiometrics async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
