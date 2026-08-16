import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/lock_screen.dart';
import 'package:xfin/services/auth_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class FakeAuthenticationOptions extends Fake implements AuthenticationOptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeProvider.instance.loadTheme();

    mockStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();

    // Default: no values stored, biometrics not available
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockLocalAuth.canCheckBiometrics)
        .thenAnswer((_) => Future.value(false));
    when(() => mockLocalAuth.isDeviceSupported())
        .thenAnswer((_) => Future.value(false));
  });

  Widget buildLockScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ThemeProvider.instance),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/lock',
        routes: {
          '/lock': (_) => LockScreen(
                authService: AuthService.withDependencies(
                  storage: mockStorage,
                  localAuth: mockLocalAuth,
                ),
              ),
          '/main': (_) => const Scaffold(body: Text('main')),
        },
      ),
    );
  }

  group('LockScreen rendering', () {
    testWidgets('shows lock icon, password field and unlock button',
        (tester) async {
      await tester.pumpWidget(buildLockScreen());
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('biometric button not shown when biometrics disabled',
        (tester) async {
      // biometrics_enabled not set → default null → disabled
      await tester.pumpWidget(buildLockScreen());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });

    testWidgets('biometric button shown when biometrics enabled and available',
        (tester) async {
      when(() => mockStorage.read(key: 'xfin_biometrics_enabled'))
          .thenAnswer((_) async => 'true');
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) => Future.value(true));
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => false); // don't auto-unlock

      await tester.pumpWidget(buildLockScreen());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });
  });

  group('Password verification', () {
    testWidgets('shows error message on wrong password', (tester) async {
      final svc = AuthService.withDependencies(
          storage: mockStorage, localAuth: mockLocalAuth);
      final correctHash = svc.hashForTest('correct');
      when(() => mockStorage.read(key: 'xfin_password_hash'))
          .thenAnswer((_) async => correctHash);

      await tester.pumpWidget(buildLockScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.lockWrongPassword), findsOneWidget);
    });

    testWidgets('navigates to /main on correct password', (tester) async {
      final svc = AuthService.withDependencies(
          storage: mockStorage, localAuth: mockLocalAuth);
      final correctHash = svc.hashForTest('secret');
      when(() => mockStorage.read(key: 'xfin_password_hash'))
          .thenAnswer((_) async => correctHash);

      await tester.pumpWidget(buildLockScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'secret');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('main'), findsOneWidget);
    });
  });

  group('Biometric authentication', () {
    setUp(() {
      when(() => mockStorage.read(key: 'xfin_biometrics_enabled'))
          .thenAnswer((_) async => 'true');
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) => Future.value(true));
    });

    testWidgets('navigates to /main after successful biometric auth',
        (tester) async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(buildLockScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('stays on lock screen when biometric auth fails',
        (tester) async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => false);

      await tester.pumpWidget(buildLockScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('main'), findsNothing);
    });
  });

  group('Visibility toggle', () {
    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
    });

    testWidgets('tapping eye icon toggles visibility', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isFalse);
    });
  });
}
