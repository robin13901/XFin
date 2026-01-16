import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:drift/native.dart';
import 'package:xfin/l10n/app_localizations.dart';

import 'package:xfin/utils/db_backup.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/providers/database_provider.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeContext fakeContext;
  late _FakeL10n l10n;

  late Directory tempDir;

  const filePickerChannel = MethodChannel('plugins.flutter.io/file_picker');
  const fileSaverChannel = MethodChannel('flutter_file_saver');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const flutterToastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  setUp(() async {
    fakeContext = _FakeContext();
    l10n = _FakeL10n();
    tempDir = await Directory.systemTemp.createTemp('db_backup_test');

    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Intercept FlutterToast calls
    messenger.setMockMethodCallHandler(flutterToastChannel, (call) async {
      return null; // pretend toast succeeded
    });

    // path_provider fake
    messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') return tempDir.path;
      if (call.method == 'getTemporaryDirectory') return tempDir.path;
      return null;
    });

    // file_saver fake
    messenger.setMockMethodCallHandler(fileSaverChannel, (call) async {
      return true;
    });

    // file_picker fake default: user cancels
    messenger.setMockMethodCallHandler(filePickerChannel, (call) async {
      return null;
    });
  });

  tearDown(() async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(flutterToastChannel, null);
    messenger.setMockMethodCallHandler(filePickerChannel, null);
    messenger.setMockMethodCallHandler(fileSaverChannel, null);
    messenger.setMockMethodCallHandler(pathProviderChannel, null);

    await tempDir.delete(recursive: true);
  });

  group('DbBackup.exportAndShareDatabase', () {
    test('returns silently if db file does not exist', () async {
      final dbFile = File(p.join(tempDir.path, 'db.sqlite'));
      if (await dbFile.exists()) await dbFile.delete();

      await DbBackup.exportAndShareDatabase(fakeContext, l10n);
      // nothing to assert; test passes if no exception
    });

    test('exports database successfully', () async {
      final dbFile = File(p.join(tempDir.path, 'db.sqlite'));
      await dbFile.writeAsBytes(Uint8List.fromList([1, 2, 3]));

      await DbBackup.exportAndShareDatabase(fakeContext, l10n);
    });
  });

  group('DbBackup.importDatabaseFromPicker', () {
    test('user cancels picker → no-op', () async {
      final db = AppDatabase(NativeDatabase.memory());
      DatabaseProvider.instance.initialize(db);

      await DbBackup.importDatabaseFromPicker(fakeContext, db, l10n);
    });

    test('picked file path does not exist', () async {
      final db = AppDatabase(NativeDatabase.memory());
      DatabaseProvider.instance.initialize(db);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(filePickerChannel, (call) async {
        if (call.method == 'pickFiles') {
          return {
            'files': [
              {'path': p.join(tempDir.path, 'missing.sqlite')}
            ]
          };
        }
        return null;
      });

      await DbBackup.importDatabaseFromPicker(fakeContext, db, l10n);
    });

    test('successful import via bytes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      DatabaseProvider.instance.initialize(db);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(filePickerChannel, (call) async {
        if (call.method == 'pickFiles') {
          return {
            'files': [
              {'bytes': Uint8List.fromList([1, 2, 3])}
            ]
          };
        }
        return null;
      });

      await DbBackup.importDatabaseFromPicker(fakeContext, db, l10n);
    });
  });
}


/* -------------------------------------------------------------------------- */
/*                                    FAKES                                   */
/* -------------------------------------------------------------------------- */

class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeL10n implements AppLocalizations {
  final List<String> messages = [];

  @override
  String get fileSavedSuccessfully => _log('fileSavedSuccessfully');
  @override
  String get exportFailed => _log('exportFailed');
  @override
  String get importFailed => _log('importFailed');
  @override
  String get selectedFileDoesNotExist => _log('selectedFileDoesNotExist');
  @override
  String get selectedFileCannotBeAccessed => _log('selectedFileCannotBeAccessed');
  @override
  String get databaseReplacedSuccessfully => _log('databaseReplacedSuccessfully');
  @override
  String get databaseReplacedButReopenFailed => _log('databaseReplacedButReopenFailed');

  String _log(String s) {
    messages.add(s);
    return s;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
