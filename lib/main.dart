import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/app_theme.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/connection/connection.dart' as connection;
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/providers/base_currency_provider.dart'; // Import the new provider
import 'package:xfin/screens/accounts_screen.dart';
import 'package:xfin/screens/analysis_screen.dart';
import 'package:xfin/screens/bookings_screen.dart';
import 'package:xfin/screens/currency_selection_screen.dart'; // Import the new screen
import 'package:xfin/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/dialogs.dart';
import 'package:xfin/widgets/liquid_glass_widgets.dart';
import 'package:xfin/widgets/more_pane.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for the German locale.
  await initializeDateFormatting('de_DE', null);

  await ThemeProvider.instance.loadTheme();

  final languageProvider = LanguageProvider();
  await languageProvider.loadLocale();

  final initialDb = AppDatabase(connection.connect());
  DatabaseProvider.instance.initialize(initialDb);

  // Initialize CurrencyProvider and load the symbol
  final currencyProvider = BaseCurrencyProvider();
  await currencyProvider.initialize(languageProvider.appLocale);

  await loadPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: DatabaseProvider.instance,
        ),
        ChangeNotifierProvider.value(value: ThemeProvider.instance),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: currencyProvider),
      ],
      child: MyApp(
          initialRoute:
              isBaseCurrencySelected ? '/main' : '/currencySelection'),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'XFin',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.appLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
            Locale('de', ''), // German, no country code
          ],
          initialRoute: initialRoute,
          // Set initial route dynamically
          routes: {
            '/currencySelection': (context) => const CurrencySelectionScreen(),
            '/main': (context) => const MainScreen(),
          },
          builder: (context, child) => OKToast(child: child!),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _standingOrdersExecuted = false;
  final GlobalKey _navBarKey = GlobalKey();
  late AppLocalizations l10n;
  final ValueNotifier<bool> _navBarVisible = ValueNotifier<bool>(true);

  static const List<Widget> _widgetOptions = <Widget>[
    AnalysisScreen(),
    AccountsScreen(),
    BookingsScreen(),
  ];

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;

    if (!_standingOrdersExecuted) {
      int executedCount = 0;
      executedCount += await DatabaseProvider.instance.db.periodicBookingsDao
          .executePending(l10n);
      executedCount += await DatabaseProvider.instance.db.periodicTransfersDao
          .executePending(l10n);
      if (executedCount > 0 && mounted) {
        showInfoDialog(context, l10n.standingOrdersExecuted,
            l10n.nStandingOrdersExecuted(executedCount));
      }
      _standingOrdersExecuted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(child: _widgetOptions.elementAt(_selectedIndex)),
          Positioned(
            bottom: 16,
            left: 8,
            right: 8,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navBarVisible,
              builder: (context, visible, child) {
                // If navbar is not visible, return an empty SizedBox to maintain layout
                // Otherwise, show the navbar.
                return visible
                    ? RepaintBoundary(child: child!)
                    : const SizedBox.shrink();
              },
              child: LiquidGlassBottomNav(
                key: _navBarKey,
                icons: const [
                  Icons.analytics,
                  Icons.account_balance_wallet,
                  Icons.book,
                ],
                labels: [
                  l10n.analysis,
                  l10n.accounts,
                  l10n.bookings,
                ],
                keys: const [
                  Key('nav_analytics'),
                  Key('nav_accounts'),
                  Key('nav_bookings'),
                ],
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                onLeftTap: () {
                  if (_selectedIndex == 1) {
                    AccountsScreen.showAccountForm(context);
                  } else if (_selectedIndex == 2) {
                    BookingsScreen.showBookingForm(context, null);
                  }
                },
                leftVisibleForIndices: const {1, 2},
                rightIcon: Icons.more_horiz,
                onRightTap: () {
                  showMorePane(
                      context: context,
                      navBarKey: _navBarKey,
                      navBarVisible: _navBarVisible);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
