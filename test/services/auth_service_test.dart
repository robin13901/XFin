import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xfin/services/auth_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class FakeAuthenticationOptions extends Fake implements AuthenticationOptions {}

String _sha256(String input) =>
    sha256.convert(utf8.encode(input)).toString();

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockLocalAuth;
  late AuthService sut;

  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    sut = AuthService.withDependencies(
      storage: mockStorage,
      localAuth: mockLocalAuth,
    );
  });

  group('isPasswordSet', () {
    test('returns false when no hash stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      expect(await sut.isPasswordSet, isFalse);
    });

    test('returns true when hash is stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'somehash');
      expect(await sut.isPasswordSet, isTrue);
    });

    test('returns false when stored value is empty string', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => '');
      expect(await sut.isPasswordSet, isFalse);
    });
  });

  group('setPassword', () {
    test('writes SHA-256 hash to secure storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await sut.setPassword('mySecret');

      verify(() => mockStorage.write(
            key: 'xfin_password_hash',
            value: _sha256('mySecret'),
          )).called(1);
    });
  });

  group('verifyPassword', () {
    test('returns true for matching password', () async {
      final hash = _sha256('correct');
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => hash);

      expect(await sut.verifyPassword('correct'), isTrue);
    });

    test('returns false for wrong password', () async {
      final hash = _sha256('correct');
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => hash);

      expect(await sut.verifyPassword('wrong'), isFalse);
    });

    test('returns false when no hash stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      expect(await sut.verifyPassword('anything'), isFalse);
    });
  });

  group('removePassword', () {
    test('deletes both hash and biometrics keys', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await sut.removePassword();

      verify(() => mockStorage.delete(key: 'xfin_password_hash')).called(1);
      verify(() => mockStorage.delete(key: 'xfin_biometrics_enabled'))
          .called(1);
    });
  });

  group('isBiometricsEnabled', () {
    test('returns true when stored value is "true"', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'true');
      expect(await sut.isBiometricsEnabled, isTrue);
    });

    test('returns false when stored value is "false"', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'false');
      expect(await sut.isBiometricsEnabled, isFalse);
    });

    test('returns false when nothing stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      expect(await sut.isBiometricsEnabled, isFalse);
    });
  });

  group('setBiometricsEnabled', () {
    test('writes "true" for enabled', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await sut.setBiometricsEnabled(true);

      verify(() => mockStorage.write(
            key: 'xfin_biometrics_enabled',
            value: 'true',
          )).called(1);
    });

    test('writes "false" for disabled', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await sut.setBiometricsEnabled(false);

      verify(() => mockStorage.write(
            key: 'xfin_biometrics_enabled',
            value: 'false',
          )).called(1);
    });
  });

  group('canCheckBiometrics', () {
    test('returns true when canCheckBiometrics is true', () async {
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) => Future.value(true));
      when(() => mockLocalAuth.isDeviceSupported())
          .thenAnswer((_) => Future.value(false));

      expect(await sut.canCheckBiometrics, isTrue);
    });

    test('returns true when isDeviceSupported is true', () async {
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) => Future.value(false));
      when(() => mockLocalAuth.isDeviceSupported())
          .thenAnswer((_) => Future.value(true));

      expect(await sut.canCheckBiometrics, isTrue);
    });

    test('returns false when both are false', () async {
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) => Future.value(false));
      when(() => mockLocalAuth.isDeviceSupported())
          .thenAnswer((_) => Future.value(false));

      expect(await sut.canCheckBiometrics, isFalse);
    });

    test('returns false on exception', () async {
      when(() => mockLocalAuth.canCheckBiometrics).thenThrow(Exception('err'));

      expect(await sut.canCheckBiometrics, isFalse);
    });
  });

  group('authenticateWithBiometrics', () {
    test('returns true on successful authentication', () async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);

      expect(await sut.authenticateWithBiometrics('reason'), isTrue);
    });

    test('returns false when authentication fails', () async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => false);

      expect(await sut.authenticateWithBiometrics('reason'), isFalse);
    });

    test('returns false on exception', () async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenThrow(Exception('platform error'));

      expect(await sut.authenticateWithBiometrics('reason'), isFalse);
    });
  });
}
