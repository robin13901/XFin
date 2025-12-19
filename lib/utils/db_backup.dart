import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xfin/utils/format.dart';
import '../database/app_database.dart';

class DbBackup {
  static const _dbFileName = 'db.sqlite';

  /// Returns the File object pointing at the app DB file (application documents).
  static Future<File> _localDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, _dbFileName));
  }

  /// Copy the DB file to a temporary location and open the native share sheet.
  ///
  /// Shows simple SnackBar feedback on success/failure.
  static Future<void> exportAndShareDatabase(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final dbFile = await _localDbFile();
      if (!await dbFile.exists()) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Database file not found')),
        );
        return;
      }

      final fileBytes = await dbFile.readAsBytes();
      final backupName = '${dateTimeToString(DateTime.now())}-xfin-db-backup.sqlite';

      try {
        // This will open the native "Save as" dialog on Android & iOS
        await FlutterFileSaver().writeFileAsBytes(
          fileName: backupName,
          bytes: fileBytes,
        );

        messenger?.showSnackBar(
          const SnackBar(
              content: Text('Save dialog opened / file saved successfully')),
        );
      } catch (e) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  /// Let the user pick a file (via platform picker), then safely replace the app DB file.
  ///
  /// - [currentDb] : your currently-open AppDatabase instance. This function will call
  ///   `await currentDb.close()` to release file handles before replacing the file.
  /// - [recreateDb] : optional async callback returning a new AppDatabase instance after import.
  ///    Use this to re-create/re-provide your DB so the app continues to work without restart.
  ///
  /// Returns the newly created AppDatabase if [recreateDb] is provided and succeeds,
  /// or `null` if not provided (or on failure).
  static Future<AppDatabase?> importDatabaseFromPicker(
      BuildContext context,
      AppDatabase currentDb, {
        Future<AppDatabase> Function()? recreateDb,
      }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      // Pick a single file
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return null;
      }

      final pickedPath = result.files.single.path;
      if (pickedPath == null) {
        // On some platforms the path might be null (e.g., picking from cloud); attempt to use bytes
        final pickedBytes = result.files.single.bytes;
        if (pickedBytes == null) {
          messenger?.showSnackBar(
            const SnackBar(content: Text('Selected file cannot be accessed')),
          );
          return null;
        }

        // Write bytes to a temp file
        final tmp = await getTemporaryDirectory();
        final tmpFile = File(p.join(tmp.path,
            'imported-db-${DateTime.now().millisecondsSinceEpoch}.sqlite'));
        await tmpFile.writeAsBytes(pickedBytes);
        return await _replaceDbWithFile(
            messenger, currentDb, tmpFile, recreateDb);
      } else {
        final sourceFile = File(pickedPath);
        if (!await sourceFile.exists()) {
          messenger?.showSnackBar(
            const SnackBar(content: Text('Selected file does not exist')),
          );
          return null;
        }

        return await _replaceDbWithFile(
            messenger, currentDb, sourceFile, recreateDb);
      }
    } catch (e, st) {
      debugPrint('Import DB error: $e\n$st');
      messenger?.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
      return null;
    }
  }

  /// Internal helper that closes current DB, copies sourceFile over the app DB file,
  /// and optionally calls recreateDb to return a new AppDatabase instance.
  static Future<AppDatabase?> _replaceDbWithFile(
      ScaffoldMessengerState? messenger,
      AppDatabase currentDb,
      File sourceFile,
      Future<AppDatabase> Function()? recreateDb,
      ) async {

    try {
      final appDbFile = await _localDbFile();

      // Close the running DB to release file handles. If you have many subscribers
      // to the Provider or other parts of the app using the DB concurrently,
      // ensure you handle the app state accordingly (e.g. disable UI while importing).
      await currentDb.close();

      // Copy (overwrite) to app DB location.
      // We copy to a temp file first to reduce chance of corrupt partial write,
      // then rename/move to final destination when supported.
      final tmpDir = await getTemporaryDirectory();
      final tempDest = File(p.join(tmpDir.path,
          'db_import_tmp_${DateTime.now().millisecondsSinceEpoch}.sqlite'));

      if (await tempDest.exists()) {
        await tempDest.delete();
      }

      await sourceFile.copy(tempDest.path);

      // Try an atomic replace via rename, but fallback to copy if rename fails.
      try {
        // On some platforms (Android) rename across filesystems may fail; handle it.
        if (await appDbFile.exists()) {
          // Remove original first to avoid rename collision on some platforms.
          await appDbFile.delete();
        }
        await tempDest.rename(appDbFile.path);
      } catch (e) {
        // Fallback: copy contents and delete temp
        await tempDest.copy(appDbFile.path);
        if (await tempDest.exists()) {
          await tempDest.delete();
        }
      }

      messenger?.showSnackBar(
        const SnackBar(content: Text('Database replaced successfully')),
      );

      // If the caller provided a recreateDb callback, call it now and return the new instance.
      if (recreateDb != null) {
        try {
          final newDb = await recreateDb();
          // Caller is responsible for re-providing the newDb in Provider or otherwise wiring it up.
          messenger?.showSnackBar(
            const SnackBar(content: Text('Database re-opened successfully')),
          );
          return newDb;
        } catch (e) {
          messenger?.showSnackBar(
            SnackBar(content: Text('Database replaced but reopen failed: $e')),
          );
          return null;
        }
      } else {
        // No recreate callback provided. It's a common pattern to restart the app or
        // re-create the Provider-provided AppDatabase instance elsewhere.
        messenger?.showSnackBar(
          const SnackBar(
              content: Text(
                  'Database replaced. Restart app or re-create the DB instance.')),
        );
        return null;
      }
    } catch (e, st) {
      debugPrint('Replace DB file failed: $e\n$st');
      messenger?.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
      return null;
    }
  }
}
