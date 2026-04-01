import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../database/daos/periodic_bookings_dao.dart';
import '../database/daos/periodic_transfers_dao.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/aurora_background.dart';
import '../widgets/dialogs.dart';
import '../widgets/forms/periodic_booking_form.dart';
import '../widgets/forms/periodic_transfer_form.dart';
import '../widgets/liquid_glass_widgets.dart';

class StandingOrdersScreen extends StatefulWidget {
  const StandingOrdersScreen({super.key});

  @override
  State<StandingOrdersScreen> createState() => _StandingOrdersScreenState();
}

class _StandingOrdersScreenState extends State<StandingOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnimController;
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
    _sheetAnimController =
        AnimationController(vsync: this, duration: Duration.zero)..value = 1.0;
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

  void _showPeriodicBookingForm(BuildContext context, PeriodicBooking? periodicBooking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: _sheetAnimController,
      builder: (_) => PeriodicBookingForm(periodicBooking: periodicBooking, preloadedAssets: assets, preloadedAccounts: accounts),
    );
  }

  void _showPeriodicTransferForm(BuildContext context, PeriodicTransfer? periodicTransfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: _sheetAnimController,
      builder: (_) => PeriodicTransferForm(periodicTransfer: periodicTransfer, preloadedAssets: assets, preloadedAccounts: accounts),
    );
  }

  @override
  void dispose() {
    _sheetAnimController.dispose();
    super.dispose();
  }

  Widget _buildPeriodicBookingList(AppDatabase db) {
    return StreamBuilder<List<PeriodicBookingWithAccountAndAsset>>(
      stream: db.periodicBookingsDao.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          showErrorDialog(context, l10n.errorLoadingData);
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
              onTap: () => _showPeriodicBookingForm(context, periodicBooking),
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
          showErrorDialog(context, l10n.errorLoadingData);
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
              onTap: () => _showPeriodicTransferForm(context, periodicTransfer),
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
      backgroundColor:
          context.watch<ThemeProvider>().isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
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
                onLeftTap: null,
                leftVisibleForIndices: const {},
                keepLeftPlaceholder: true,
                rightIcon: Icons.add,
                onRightTap: () {
                  if (_selectedIndex == 0) {
                    _showPeriodicBookingForm(context, null);
                  } else {
                    _showPeriodicTransferForm(context, null);
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