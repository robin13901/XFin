import 'package:flutter/cupertino.dart';

import '../database/app_database.dart';

class DatabaseProvider extends ChangeNotifier {
  static final DatabaseProvider instance = DatabaseProvider._internal();
  DatabaseProvider._internal();

  late AppDatabase _db;
  AppDatabase get db => _db;

  void initialize(AppDatabase db) {
    _db = db;
    notifyListeners();
  }

  Future<void> replaceDatabase(AppDatabase newDb) async {
    await _db.close();
    _db = newDb;
    notifyListeners();
  }
}