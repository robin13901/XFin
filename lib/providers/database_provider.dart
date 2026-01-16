import 'package:flutter/cupertino.dart';

import '../database/app_database.dart';

class DatabaseProvider extends ChangeNotifier {
  static DatabaseProvider _instance = DatabaseProvider._internal();
  DatabaseProvider._internal();

  late AppDatabase _db;
  AppDatabase get db => _db;

  @visibleForTesting
  static set instance(DatabaseProvider provider) => _instance = provider;

  static DatabaseProvider get instance => _instance;

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