import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/daos/assets_dao.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/database/daos/trades_dao.dart';
import 'package:xfin/database/daos/transfers_dao.dart';
import 'package:drift/native.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase database;
  late AccountsDao accountsDao;
  late BookingsDao bookingsDao;
  late TransfersDao transfersDao;
  late AssetsDao assetsDao;
  late TradesDao tradesDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    accountsDao = database.accountsDao;
    bookingsDao = database.bookingsDao;
    transfersDao = database.transfersDao;
    assetsDao = database.assetsDao;
    tradesDao = database.tradesDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('AccountsDao Tests', () {
    test('addAccount and getAccount', () async {
      final account = AccountsCompanion.insert(name: 'Test Account', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final id = await accountsDao.addAccount(account);
      final result = await accountsDao.getAccount(id);

      expect(result.id, id);
      expect(result.name, 'Test Account');
      expect(result.balance, 1000.0);
      expect(result.isArchived, false);
    });

    test('deleteAccount', () async {
      final account = AccountsCompanion.insert(name: 'Test Account', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final id = await accountsDao.addAccount(account);

      await accountsDao.deleteAccount(id);
      
      expect(() async => await accountsDao.getAccount(id), throwsA(isA<StateError>()));
    });

    test('setArchived', () async {
      final account = AccountsCompanion.insert(name: 'Test Account', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final id = await accountsDao.addAccount(account);

      await accountsDao.setArchived(id, true);
      var result = await accountsDao.getAccount(id);
      expect(result.isArchived, true);

      await accountsDao.setArchived(id, false);
      result = await accountsDao.getAccount(id);
      expect(result.isArchived, false);
    });

    test('updateBalance', () async {
      final account = AccountsCompanion.insert(name: 'Test Account', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final id = await accountsDao.addAccount(account);

      await accountsDao.updateBalance(id, 500.0);
      var result = await accountsDao.getAccount(id);
      expect(result.balance, 1500.0);

      await accountsDao.updateBalance(id, -250.0);
      result = await accountsDao.getAccount(id);
      expect(result.balance, 1250.0);
    });

    test('watchAllAccounts and watchArchivedAccounts', () async {
      final account1 = AccountsCompanion.insert(name: 'Active Account', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash, isArchived: const Value(false));
      final account2 = AccountsCompanion.insert(name: 'Archived Account', balance: 2000.0, initialBalance: 2000.0, type: AccountTypes.cash, isArchived: const Value(true));
      await accountsDao.addAccount(account1);
      await accountsDao.addAccount(account2);

      final activeAccountsStream = accountsDao.watchAllAccounts();
      final archivedAccountsStream = accountsDao.watchArchivedAccounts();

      expect(
          activeAccountsStream,
          emits(isA<List<Account>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.name, 'name', 'Active Account')));
      expect(
          archivedAccountsStream,
          emits(isA<List<Account>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.name, 'name', 'Archived Account')));
    });

    test('hasBookings', () async {
      final account = AccountsCompanion.insert(name: 'Test Account', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final accountId = await accountsDao.addAccount(account);
      
      final booking = BookingsCompanion.insert(date: 20240101, amount: 100.0, category: 'Test', accountId: accountId, isGenerated: false);
      await bookingsDao.createBookingAndUpdateAccount(booking);

      expect(await accountsDao.hasBookings(accountId), isTrue);

      final insertedBooking = await bookingsDao.getBooking(1);

      await bookingsDao.deleteBookingAndUpdateAccount(insertedBooking.id);

      expect(await accountsDao.hasBookings(accountId), isFalse);
    });

    test('hasTransfers', () async {
      final account1 = AccountsCompanion.insert(name: 'Account 1', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final account2 = AccountsCompanion.insert(name: 'Account 2', balance: 1000.0, initialBalance: 1000.0, type: AccountTypes.cash);
      final accountId1 = await accountsDao.addAccount(account1);
      final accountId2 = await accountsDao.addAccount(account2);

      final transfer = TransfersCompanion.insert(date: 20240101, amount: 100.0, sendingAccountId: accountId1, receivingAccountId: accountId2, isGenerated: false);
      final transferId = await transfersDao.createTransferAndUpdateAccounts(transfer);

      expect(await accountsDao.hasTransfers(accountId1), isTrue);
      expect(await accountsDao.hasTransfers(accountId2), isTrue);

      await transfersDao.deleteTransferAndUpdateAccounts(transferId);

      expect(await accountsDao.hasTransfers(accountId1), isFalse);
      expect(await accountsDao.hasTransfers(accountId2), isFalse);
    });

    test('hasTrades', () async {
      final clearingAccount = AccountsCompanion.insert(name: 'Clearing Account', balance: 10000.0, initialBalance: 10000.0, type: AccountTypes.cash);
      final portfolioAccount = AccountsCompanion.insert(name: 'Portfolio Account', balance: 0.0, initialBalance: 0.0, type: AccountTypes.portfolio);
      final clearingAccountId = await accountsDao.addAccount(clearingAccount);
      final portfolioAccountId = await accountsDao.addAccount(portfolioAccount);

      final asset = AssetsCompanion.insert(name: 'Test Asset', type: AssetTypes.stock, tickerSymbol: 'TEST');
      final assetId = await assetsDao.addAsset(asset);

      await database.assetsOnAccountsDao.updateAssetsOnAccount(AssetsOnAccountsCompanion(accountId: Value(portfolioAccountId), assetId: Value(assetId), value: const Value(0), sharesOwned: const Value(0), netCostBasis: const Value(0), brokerCostBasis: const Value(0), buyFeeTotal: const Value(0)));

      final trade = TradesCompanion.insert(date: 20240101, assetId: assetId, type: TradeTypes.buy, movedValue: 1000.0, shares: 10.0, pricePerShare: 100.0, profitAndLoss: 0.0, tradingFee: -1.0, clearingAccountId: clearingAccountId, portfolioAccountId: portfolioAccountId);
      final tradeId = await tradesDao.createTradeAndUpdateAccounts(trade);

      expect(await accountsDao.hasTrades(clearingAccountId), isTrue);
      expect(await accountsDao.hasTrades(portfolioAccountId), isTrue);

      await tradesDao.deleteTradeAndUpdateAccounts(tradeId);

      expect(await accountsDao.hasTrades(clearingAccountId), isFalse);
      expect(await accountsDao.hasTrades(portfolioAccountId), isFalse);
    });
  });
}
