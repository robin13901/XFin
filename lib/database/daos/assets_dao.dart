import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_dao.g.dart';

@DriftAccessor(tables: [Assets])
class AssetsDao extends DatabaseAccessor<AppDatabase> with _$AssetsDaoMixin {
  AssetsDao(super.db);

  Future<void> validate(Asset asset) async {
    // name and tickerSymbol are checked by unique constraint in the table definition.
    // type is checked by the type converter.
  }

  Future<int> addAsset(AssetsCompanion entry) => into(assets).insert(entry);

  Future<Asset> getAsset(int id) => (select(assets)..where((a) => a.id.equals(id))).getSingle();
}
