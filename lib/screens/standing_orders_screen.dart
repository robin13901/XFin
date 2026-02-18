import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../database/daos/periodic_bookings_dao.dart';
import '../database/daos/periodic_transfers_dao.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/liquid_glass_widgets.dart';
import '../widgets/periodic_booking_form.dart';
import '../widgets/periodic_transfer_form.dart';

class StandingOrdersScreen extends StatefulWidget {
  const StandingOrdersScreen({super.key});

  static void showPeriodicBookingForm(BuildContext context, PeriodicBooking? periodicBooking, {List<Asset>? preloadedAssets, List<Account>? preloadedAccounts}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PeriodicBookingForm(periodicBooking: periodicBooking, preloadedAssets: preloadedAssets, preloadedAccounts: preloadedAccounts),
    );
  }

  static void showPeriodicTransferForm(BuildContext context, PeriodicTransfer? periodicTransfer, {List<Asset>? preloadedAssets, List<Account>? preloadedAccounts}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PeriodicTransferForm(periodicTransfer: periodicTransfer, preloadedAssets: preloadedAssets, preloadedAccounts: preloadedAccounts),
    );
  }

  @override
  State<StandingOrdersScreen> createState() => _StandingOrdersScreenState();
}

class _StandingOrdersScreenState extends State<StandingOrdersScreen> {
  List<Asset> assets = [];
  List<Account> accounts = [];
  int _selectedIndex = 0;
  late AppLocalizations l10n;
  final GlobalKey _navBarKey = GlobalKey();
  final ValueNotifier<bool> _navBarVisible = ValueNotifier<bool>(true);

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    final db = context.read<DatabaseProvider>().db;
    loadAssetsAndAccounts(db);

    _widgetOptions = <Widget>[
      _buildPeriodicBookingList(db),
      _buildPeriodicTransferList(db),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  Future<void> loadAssetsAndAccounts(AppDatabase db) async {
    final allAssets = await db.assetsDao.getAllAssets();
    final allAccounts = await db.accountsDao.getAllAccounts();
    setState(() {
      assets = allAssets;
      accounts = allAccounts;
    });
  }

  Widget _buildPeriodicBookingList(AppDatabase db) {
    return StreamBuilder<List<PeriodicBookingWithAccountAndAsset>>(
      stream: db.periodicBookingsDao.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          showErrorDialog(context, snapshot.error.toString());
        }
        final periodicBookings = snapshot.data ?? [];
        if (periodicBookings.isEmpty) {
          return Center(child: Text(l10n.noPeriodicBookingsYet));
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            bottom: 92,
          ),
          itemCount: periodicBookings.length,
          itemBuilder: (context, index) {
            final item = periodicBookings[index];
            final periodicBooking = item.periodicBooking;
            final asset = item.asset;
            final account = item.account;
            final valueColor = periodicBooking.value < 0 ? Colors.red : Colors.green;
            final dateText = dateFormat.format(intToDateTime(periodicBooking.nextExecutionDate)!);

            return ListTile(
              title: Text(periodicBooking.category),
              subtitle: Text(account.name),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (periodicBooking.assetId == 1)
                    Text(
                      formatCurrency(periodicBooking.value),
                      style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${periodicBooking.shares} ${asset.currencySymbol ?? asset.tickerSymbol} ≈ ', style: const TextStyle(color: Colors.grey)),
                          TextSpan(text: formatCurrency(periodicBooking.value), style: TextStyle(color: valueColor)),
                        ],
                      ),
                    ),
                  Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              onTap: () => StandingOrdersScreen.showPeriodicBookingForm(context, periodicBooking, preloadedAssets: assets, preloadedAccounts: accounts),
              onLongPress: () => showDeleteDialog(context, periodicBooking: periodicBooking),
            );
          },
        );
      },
    );
  }

  Widget _buildPeriodicTransferList(AppDatabase db) {
    return StreamBuilder<List<PeriodicTransferWithAccountAndAsset>>(
      stream: db.periodicTransfersDao.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          showErrorDialog(context, snapshot.error.toString());
        }
        final periodicTransfers = snapshot.data ?? [];
        if (periodicTransfers.isEmpty) {
          return Center(child: Text(l10n.noPeriodicTransfersYet));
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            bottom: 92,
          ),
          itemCount: periodicTransfers.length,
          itemBuilder: (context, index) {
            final item = periodicTransfers[index];
            final periodicTransfer = item.periodicTransfer;
            final fromAccount = item.fromAccount;
            final toAccount = item.toAccount;
            final valueColor = periodicTransfer.value < 0 ? Colors.red : Colors.green;
            final dateText = dateFormat.format(intToDateTime(periodicTransfer.nextExecutionDate)!);

            return ListTile(
              title: Text('${fromAccount.name} -> ${toAccount.name}'),
              subtitle: Text(l10n.transfer),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(periodicTransfer.value),
                    style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
                  ),
                  Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              onTap: () => StandingOrdersScreen.showPeriodicTransferForm(context, periodicTransfer, preloadedAssets: assets, preloadedAccounts: accounts),
              onLongPress: () => showDeleteDialog(context, periodicTransfer: periodicTransfer),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _widgetOptions,
                ),
              ),
            ],
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.standingOrders)),
          Positioned(
            bottom: 16,
            left: 8,
            right: 8,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navBarVisible,
              builder: (context, visible, child) {
                return visible
                    ? RepaintBoundary(child: child!)
                    : const SizedBox.shrink();
              },
              child: LiquidGlassBottomNav(
                key: _navBarKey,
                icons: const [
                  Icons.book,
                  Icons.compare_arrows,
                ],
                labels: [
                  l10n.bookings,
                  l10n.transfers,
                ],
                keys: const [
                  Key('nav_periodic_bookings'),
                  Key('nav_periodic_transfers'),
                ],
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                onLeftTap: () {
                  // No left tap functionality needed for now
                },
                leftVisibleForIndices: const {},
                rightIcon: Icons.add,
                onRightTap: () {
                  if (_selectedIndex == 0) {
                    StandingOrdersScreen.showPeriodicBookingForm(context, null, preloadedAssets: assets, preloadedAccounts: accounts);
                  } else {
                    StandingOrdersScreen.showPeriodicTransferForm(context, null, preloadedAssets: assets, preloadedAccounts: accounts);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}