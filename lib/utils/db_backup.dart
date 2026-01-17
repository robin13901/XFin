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

  /// Performs only the pickFiles call and forwards the result for processing.
  static Future<void> importDatabaseFromPicker(BuildContext context,
      AppDatabase currentDb, AppLocalizations l10n) async {
    try {
      final dynamic res = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.any);
      await processPickedFilesResult(res, currentDb, l10n);
    } catch (_) {
      showToast2(l10n.importFailed);
    }
  }

  static Future<void> processPickedFilesResult(
      dynamic res, AppDatabase currentDb, AppLocalizations l10n) async {
    try {
      if (res == null || res.files.isEmpty) return;
      final picked = res.files.single;
      final bool isPath = picked.path != null;
      if (isPath ? !await File(picked.path!).exists() : picked.bytes == null) {
        showToast2(isPath ? l10n.selectedFileDoesNotExist : l10n.selectedFileCannotBeAccessed);
        return;
      }
      final File src = isPath ? File(picked.path!) : File(p.join((await getTemporaryDirectory()).path, _dbFileNameTemp));
      if (!isPath) await src.writeAsBytes(picked.bytes as List<int>);
      await replaceDbWithFile(currentDb, src, l10n);
    } catch (_) {
      showToast2(l10n.importFailed);
    }
  }

  static Future<void> replaceDbWithFile(
      AppDatabase oldDb, File source, AppLocalizations l10n) async {
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
