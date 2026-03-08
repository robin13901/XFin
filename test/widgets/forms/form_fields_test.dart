import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/utils/validators.dart';
import 'package:xfin/widgets/form_fields/form_fields.dart';

import '../test_helpers.dart';

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;
  late Validator validator;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = FormTestHelpers.createTestDatabase();
    DatabaseProvider.instance.initialize(db);
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);
    validator = Validator(l10n);

    await FormTestHelpers.insertBaseCurrency(db);
    await FormTestHelpers.insertTestAssets(db);
    await FormTestHelpers.insertTestAccounts(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('FormFields', () {
    group('dateAndAssetRow', () {
      testWidgets('renders date field and asset dropdown', (tester) async {
        final dateController = TextEditingController(text: '01.01.2024');
        final date = DateTime(2024, 1, 1);
        final assets = await db.assetsDao.getAllAssets();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateAndAssetRow(
                dateController: dateController,
                date: date,
                onDateChanged: (_) {},
                assets: assets,
                assetId: 1,
                onAssetChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.byKey(const Key('date_field')), findsOneWidget);
        expect(find.byKey(const Key('assets_dropdown')), findsOneWidget);
        expect(find.text('01.01.2024'), findsOneWidget);
      });

      testWidgets('date picker opens and updates controller', (tester) async {
        final dateController = TextEditingController(text: '01.01.2024');
        var date = DateTime(2024, 1, 1);
        final assets = await db.assetsDao.getAllAssets();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateAndAssetRow(
                dateController: dateController,
                date: date,
                onDateChanged: (d) => date = d,
                assets: assets,
                assetId: 1,
                onAssetChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Tap calendar icon to open date picker
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Date picker should be shown
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets('asset dropdown shows all assets', (tester) async {
        final dateController = TextEditingController(text: '01.01.2024');
        final date = DateTime(2024, 1, 1);
        final assets = await db.assetsDao.getAllAssets();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateAndAssetRow(
                dateController: dateController,
                date: date,
                onDateChanged: (_) {},
                assets: assets,
                assetId: 1,
                onAssetChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Tap dropdown to open
        await tester.tap(find.byKey(const Key('assets_dropdown')));
        await tester.pumpAndSettle();

        // All assets should be in dropdown
        expect(find.text('EUR').hitTestable(), findsOneWidget);
        expect(find.text('Apple Inc.').hitTestable(), findsOneWidget);
        expect(find.text('US Dollar').hitTestable(), findsOneWidget);
        expect(find.text('Bitcoin').hitTestable(), findsOneWidget);
      });

      testWidgets('asset selection triggers callback', (tester) async {
        final dateController = TextEditingController(text: '01.01.2024');
        final date = DateTime(2024, 1, 1);
        final assets = await db.assetsDao.getAllAssets();
        int? selectedAssetId;

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateAndAssetRow(
                dateController: dateController,
                date: date,
                onDateChanged: (_) {},
                assets: assets,
                assetId: 1,
                onAssetChanged: (id) => selectedAssetId = id,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Select different asset
        await FormTestHelpers.selectDropdownItem(
          tester,
          dropdownFinder: find.byKey(const Key('assets_dropdown')),
          itemText: 'Apple Inc.',
        );

        expect(selectedAssetId, isNotNull);
        expect(selectedAssetId, isNot(1)); // Should have changed from EUR
      });

      testWidgets('assetsEditable=false disables dropdown', (tester) async {
        final dateController = TextEditingController(text: '01.01.2024');
        final date = DateTime(2024, 1, 1);
        final assets = await db.assetsDao.getAllAssets();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateAndAssetRow(
                dateController: dateController,
                date: date,
                onDateChanged: (_) {},
                assets: assets,
                assetId: 1,
                onAssetChanged: (_) {},
                assetsEditable: false,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Find the dropdown and check if it's disabled
        final dropdown = tester.widget<DropdownButtonFormField>(
          find.byKey(const Key('assets_dropdown')),
        );
        expect(dropdown.onChanged, isNull); // Disabled dropdowns have null onChanged
      });
    });

    group('sharesField', () {
      testWidgets('shows "Amount" for fiat asset', (tester) async {
        final controller = TextEditingController();
        final eurAsset = await db.assetsDao.getAsset(1); // EUR is fiat

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.sharesField(controller, eurAsset);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Amount'), findsOneWidget);
      });

      testWidgets('shows "Shares" for non-fiat asset', (tester) async {
        final controller = TextEditingController();
        final assets = await db.assetsDao.getAllAssets();
        final stockAsset = assets.firstWhere((a) => a.type == AssetTypes.stock);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.sharesField(controller, stockAsset);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Shares'), findsOneWidget);
      });

      testWidgets('shows correct suffix for asset', (tester) async {
        final controller = TextEditingController();
        final assets = await db.assetsDao.getAllAssets();
        final btcAsset = assets.firstWhere((a) => a.tickerSymbol == 'BTC');

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.sharesField(controller, btcAsset);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Find TextFormField - we can't directly access decoration
        // but we can verify the suffix text is rendered
        expect(find.text('₿'), findsOneWidget);
      });

      testWidgets('validates fiat with max 2 decimals', (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = TextEditingController(text: '100.123'); // 3 decimals - invalid
        final eurAsset = await db.assetsDao.getAsset(1);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Form(
            key: formKey,
            child: Builder(
              builder: (context) {
                final formFields = FormFields(l10n, validator, context);
                return formFields.sharesField(controller, eurAsset);
              },
            ),
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(formKey.currentState!.validate(), isFalse);
      });

      testWidgets('rejects zero value', (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = TextEditingController(text: '0');
        final eurAsset = await db.assetsDao.getAsset(1);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Form(
            key: formKey,
            child: Builder(
              builder: (context) {
                final formFields = FormFields(l10n, validator, context);
                return formFields.sharesField(controller, eurAsset);
              },
            ),
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(formKey.currentState!.validate(), isFalse);
      });
    });

    group('sharesAndCostBasisRow', () {
      testWidgets('shows both fields for non-base-currency assets',
          (tester) async {
        final sharesController = TextEditingController();
        final costBasisController = TextEditingController();
        final assets = await db.assetsDao.getAllAssets();
        final stockAsset = assets.firstWhere((a) => a.type == AssetTypes.stock);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.sharesAndCostBasisRow(
                sharesController,
                costBasisController,
                stockAsset,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.byKey(const Key('shares_field')), findsOneWidget);
        expect(find.byKey(const Key('cost_basis_field')), findsOneWidget);
      });

      testWidgets('hides cost basis for base currency', (tester) async {
        final sharesController = TextEditingController();
        final costBasisController = TextEditingController();
        final eurAsset = await db.assetsDao.getAsset(1); // Base currency

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.sharesAndCostBasisRow(
                sharesController,
                costBasisController,
                eurAsset,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.byKey(const Key('shares_field')), findsOneWidget);
        expect(find.byKey(const Key('cost_basis_field')), findsNothing);
      });

      testWidgets('hideCostBasis parameter works', (tester) async {
        final sharesController = TextEditingController();
        final costBasisController = TextEditingController();
        final assets = await db.assetsDao.getAllAssets();
        final stockAsset = assets.firstWhere((a) => a.type == AssetTypes.stock);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.sharesAndCostBasisRow(
                sharesController,
                costBasisController,
                stockAsset,
                hideCostBasis: true,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.byKey(const Key('shares_field')), findsOneWidget);
        expect(find.byKey(const Key('cost_basis_field')), findsNothing);
      });
    });

    group('notesField', () {
      testWidgets('renders with correct label', (tester) async {
        final controller = TextEditingController();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.notesField(controller);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Notes'), findsOneWidget);
      });

      testWidgets('accepts text input', (tester) async {
        final controller = TextEditingController();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.notesField(controller);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.enterText(
          find.descendant(
            of: find.ancestor(of: find.text('Notes'), matching: find.byType(TextFormField)),
            matching: find.byType(EditableText),
          ),
          'Test note',
        );
        expect(controller.text, equals('Test note'));
      });
    });

    group('categoryField', () {
      testWidgets('renders with correct label', (tester) async {
        final controller = TextEditingController();
        final categories = ['Food', 'Transport', 'Entertainment'];

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.categoryField(controller, categories);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.byKey(const Key('category_field')), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
      });

      testWidgets('syncs controller with autocomplete', (tester) async {
        final controller = TextEditingController();
        final categories = ['Food', 'Transport', 'Entertainment'];

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.categoryField(controller, categories);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Enter text to trigger autocomplete
        await tester.enterText(
          find.byType(TextFormField),
          'Food',
        );
        await tester.pump();

        expect(controller.text, equals('Food'));
      });
    });

    group('accountDropdown', () {
      testWidgets('shows all accounts', (tester) async {
        final accounts = await db.accountsDao.getAllAccounts();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.accountDropdown(
                accounts: accounts,
                value: null,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Tap dropdown to open
        await tester.tap(FormTestHelpers.dropdownByLabel('Account'));
        await tester.pumpAndSettle();

        // All accounts should be present
        expect(find.text('Test Cash Account').hitTestable(), findsOneWidget);
        expect(find.text('Test Bank Account').hitTestable(), findsOneWidget);
        expect(find.text('Test Portfolio').hitTestable(), findsOneWidget);
        expect(find.text('Test Crypto Wallet').hitTestable(), findsOneWidget);
      });

      testWidgets('disabled state works', (tester) async {
        final accounts = await db.accountsDao.getAllAccounts();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.accountDropdown(
                accounts: accounts,
                value: accounts[0].id,
                onChanged: (_) {},
                enabled: false,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        final dropdown = tester.widget<DropdownButtonFormField<int>>(
          FormTestHelpers.dropdownByLabel('Account'),
        );
        expect(dropdown.onChanged, isNull); // Disabled
      });
    });

    group('assetsDropdown', () {
      testWidgets('shows all assets', (tester) async {
        final assets = await db.assetsDao.getAllAssets();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.assetsDropdown(
                assets: assets,
                value: null,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Tap dropdown
        await tester.tap(find.byKey(const Key('assets_dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('EUR').hitTestable(), findsOneWidget);
        expect(find.text('Apple Inc.').hitTestable(), findsOneWidget);
      });
    });

    group('cyclesDropdown', () {
      testWidgets('shows all cycle options', (tester) async {
        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.cyclesDropdown(
                cycles: Cycles.values,
                value: null,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Tap dropdown
        await tester.tap(find.byKey(const Key('cycles_dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('Daily').hitTestable(), findsOneWidget);
        expect(find.text('Weekly').hitTestable(), findsOneWidget);
        expect(find.text('Monthly').hitTestable(), findsOneWidget);
        expect(find.text('Quarterly').hitTestable(), findsOneWidget);
        expect(find.text('Yearly').hitTestable(), findsOneWidget);
      });
    });

    group('footerButtons', () {
      testWidgets('renders cancel and save buttons', (tester) async {
        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.footerButtons(context, () {});
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('save calls onPressed callback', (tester) async {
        bool pressed = false;

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.footerButtons(context, () => pressed = true);
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.tap(find.text('Save'));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    // NEW COMPONENT TESTS (Phase 1.2)

    group('basicTextField', () {
      testWidgets('renders with label and accepts input', (tester) async {
        final controller = TextEditingController();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.basicTextField(
                controller: controller,
                label: 'Test Label',
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Test Label'), findsOneWidget);

        // Enter text via finding the text field
        await tester.enterText(
          find.byType(TextFormField),
          'Test input',
        );
        expect(controller.text, equals('Test input'));
      });

      testWidgets('validator works', (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = TextEditingController(text: '');

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Form(
            key: formKey,
            child: Builder(
              builder: (context) {
                final formFields = FormFields(l10n, validator, context);
                return formFields.basicTextField(
                  controller: controller,
                  label: 'Name',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                );
              },
            ),
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(formKey.currentState!.validate(), isFalse);
      });
    });

    group('dateTimeField', () {
      testWidgets('renders with correct label', (tester) async {
        final controller = TextEditingController(text: '01.01.2024, 14:30 Uhr');
        final datetime = DateTime(2024, 1, 1, 14, 30);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateTimeField(
                controller: controller,
                datetime: datetime,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Time'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('opens date picker on tap', (tester) async {
        final controller = TextEditingController(text: '01.01.2024, 14:30 Uhr');
        final datetime = DateTime(2024, 1, 1, 14, 30);

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.dateTimeField(
                controller: controller,
                datetime: datetime,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.tap(find.byType(TextFormField));
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);
      });
    });

    group('numericInputRow', () {
      testWidgets('shows two numeric fields side by side', (tester) async {
        final controller1 = TextEditingController();
        final controller2 = TextEditingController();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.numericInputRow(
                controller1: controller1,
                label1: 'Shares',
                validator1: (_) => null,
                controller2: controller2,
                label2: 'Fee',
                validator2: (_) => null,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Shares'), findsOneWidget);
        expect(find.text('Fee'), findsOneWidget);
      });

      testWidgets('both fields accept numeric input', (tester) async {
        final controller1 = TextEditingController();
        final controller2 = TextEditingController();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.numericInputRow(
                controller1: controller1,
                label1: 'Shares',
                validator1: (_) => null,
                controller2: controller2,
                label2: 'Fee',
                validator2: (_) => null,
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        // Enter numeric input in both fields
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), '100');
        await tester.enterText(textFields.at(1), '5.50');

        expect(controller1.text, equals('100'));
        expect(controller2.text, equals('5.50'));
      });
    });

    group('accountTypeDropdown', () {
      testWidgets('shows all account types', (tester) async {
        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.accountTypeDropdown(
                value: AccountTypes.cash,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.tap(find.byKey(const Key('account_type_dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('Cash').hitTestable(), findsOneWidget);
        expect(find.text('Bank Account').hitTestable(), findsOneWidget);
        expect(find.text('Portfolio').hitTestable(), findsOneWidget);
        expect(find.text('Crypto Wallet').hitTestable(), findsOneWidget);
      });
    });

    group('assetTypeDropdown', () {
      testWidgets('shows all asset types', (tester) async {
        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.assetTypeDropdown(
                value: AssetTypes.stock,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.tap(find.byKey(const Key('asset_type_dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('Stock').hitTestable(), findsOneWidget);
        expect(find.text('Fiat Currency').hitTestable(), findsOneWidget);
        expect(find.text('Crypto').hitTestable(), findsOneWidget);
      });
    });

    group('tradeTypeDropdown', () {
      testWidgets('shows buy and sell options', (tester) async {
        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.tradeTypeDropdown(
                value: TradeTypes.buy,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.tap(find.byKey(const Key('trade_type_dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('buy').hitTestable(), findsOneWidget);
        expect(find.text('sell').hitTestable(), findsOneWidget);
      });

      testWidgets('validates null value', (tester) async {
        final formKey = GlobalKey<FormState>();

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Form(
            key: formKey,
            child: Builder(
              builder: (context) {
                final formFields = FormFields(l10n, validator, context);
                return formFields.tradeTypeDropdown(
                  value: null,
                  onChanged: (_) {},
                );
              },
            ),
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(formKey.currentState!.validate(), isFalse);
      });
    });

    group('checkboxField', () {
      testWidgets('renders with label and value', (tester) async {
        bool value = false;

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: Builder(
            builder: (context) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.checkboxField(
                label: 'Exclude from Average',
                value: value,
                onChanged: (_) {},
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        expect(find.text('Exclude from Average'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
      });

      testWidgets('toggles value on tap', (tester) async {
        bool value = false;

        await FormTestHelpers.pumpFormInPlace(
          tester: tester,
          form: StatefulBuilder(
            builder: (context, setState) {
              final formFields = FormFields(l10n, validator, context);
              return formFields.checkboxField(
                label: 'Exclude from Average',
                value: value,
                onChanged: (v) => setState(() => value = v ?? false),
              );
            },
          ),
          db: db,
          currencyProvider: currencyProvider,
        );

        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();

        expect(value, isTrue);
      });
    });
  });
}
