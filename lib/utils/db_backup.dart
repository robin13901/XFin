import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import '../database/app_database.dart';
import '../database/connection/native.dart' as connection;
import '../providers/database_provider.dart';

class DbBackup {
  static const _dbFileName = 'db.sqlite';
  static const _dbFileNameTemp = 'xfin-db.sqlite';

  static Future<File> _localDbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _dbFileName));
  }

  static Future<void> exportAndShareDatabase(
      BuildContext context, AppLocalizations l10n) async {
    try {
      final dbFile = await _localDbFile();
      if (!await dbFile.exists()) return;
      final bytes = await dbFile.readAsBytes();
      final name = '${dateTimeToString(DateTime.now())}-xfin-db-backup.sqlite';
      await FlutterFileSaver().writeFileAsBytes(fileName: name, bytes: bytes);
      showToast2(l10n.fileSavedSuccessfully);
    } catch (_) {
      showToast2(l10n.exportFailed);
    }
  }

  static Future<void> importDatabaseFromPicker(BuildContext context,
      AppDatabase currentDb, AppLocalizations l10n) async {
    try {
      final res = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.any);
      if (res == null || res.files.isEmpty) return;

      final picked = res.files.single;
      File src;
      if (picked.path != null) {
        src = File(picked.path!);
        if (!await src.exists()) {
          showToast2(l10n.selectedFileDoesNotExist);
          return;
        }
      } else {
        final bytes = picked.bytes;
        if (bytes == null) {
          showToast2(l10n.selectedFileCannotBeAccessed);
          return;
        }
        final tmp = await getTemporaryDirectory();
        src = File(p.join(tmp.path, _dbFileNameTemp));
        await src.writeAsBytes(bytes);
      }

      await _replaceDbWithFile(currentDb, src, l10n);
    } catch (e) {
      showToast2(l10n.importFailed);
      return;
    }
  }

  static Future<void> _replaceDbWithFile(AppDatabase oldDb, File source, AppLocalizations l10n) async {
    final appDbFile = await _localDbFile();
    await oldDb.close();

    final tmpDir = await getTemporaryDirectory();
    final tmp = File(p.join(tmpDir.path, _dbFileNameTemp));
    if (await tmp.exists()) await tmp.delete();
    await source.copy(tmp.path);

    try {
      if (await appDbFile.exists()) await appDbFile.delete();
      await tmp.rename(appDbFile.path);
    } catch (_) {
      await tmp.copy(appDbFile.path);
      if (await tmp.exists()) await tmp.delete();
    }

    showToast2(l10n.databaseReplacedSuccessfully);
    try {
      final newDb = AppDatabase(connection.connect());
      await DatabaseProvider.instance.replaceDatabase(newDb);
      return;
    } catch (e) {
      showToast2(l10n.databaseReplacedButReopenFailed);
      return;
    }
  }
}
