# XFin - Personal Finance Tracker

## Overview
XFin is a cross-platform personal finance management application built with Flutter. It tracks income, expenses, investments, and overall financial position. Data is stored locally on-device (privacy-focused, no cloud).

## Tech Stack
- **Framework**: Flutter (Dart SDK >=3.2.3 <4.0.0)
- **Database**: Drift 2.19.0 (SQLite ORM) with platform-specific connections
- **State Management**: Provider 6.1.2 (ChangeNotifier pattern)
- **Charts**: fl_chart 0.68.0
- **UI Theme**: Liquid Glass design system (custom glass morphism)
- **Localization**: Flutter intl with ARB files (English + German)
- **Testing**: flutter_test + mockito + mocktail + in-memory SQLite

## Architecture
```
lib/
├── constants/       # Spacing, visual constants
├── controllers/     # Bookings pagination controller
├── database/
│   ├── connection/  # Platform-specific SQLite connections
│   ├── daos/        # 10 Data Access Objects
│   ├── tables.dart  # Schema: 9 tables, enums
│   └── app_database.dart
├── l10n/            # Localization (EN/DE)
├── mixins/          # DatabaseProvider, FormBase, Pagination
├── models/filter/   # Filter rules and configs per entity
├── providers/       # Database, Theme, Language, BaseCurrency
├── screens/         # 11 screens
├── utils/           # Formatting, validation, indicators, backup
└── widgets/         # Forms (7), filters (5), charts, common UI
```

## Key Concepts
- **Base Currency**: Set at first launch (assetId=1), immutable after. CostBasis always 1.
- **Assets**: Stocks, crypto, ETFs, funds, fiat, derivatives - tracked per account.
- **Accounts**: Cash, bank accounts, portfolios, crypto wallets.
- **Trades**: Buy/sell with P&L, fees, tax, return on investment.
- **Recurring**: Periodic bookings and transfers with cycle scheduling.
- **Filter System**: Composable filter rules with operators per field type.
- **Keyset Pagination**: Efficient cursor-based pagination for large datasets.

## Database Schema (9 Tables)
| Table | Purpose |
|-------|---------|
| Accounts | Bank/portfolio/wallet accounts |
| Assets | Investment assets (stocks, crypto, etc.) |
| Bookings | Income/expense transactions |
| Transfers | Inter-account transfers |
| Trades | Buy/sell trades with P&L |
| PeriodicBookings | Recurring bookings |
| PeriodicTransfers | Recurring transfers |
| AssetsOnAccounts | Asset holdings per account (join) |
| Goals | Financial targets |

## Current State
- **Version**: 1.1.0 (Code Quality & Architecture shipped)
- **Test Suite**: 80+ test files, 971 tests
- **Static Analysis**: Zero issues (flutter analyze clean)
- **Screens**: 11 functional screens with search/filter
- **Platforms**: Mobile (iOS/Android), Desktop, Web (via platform connection abstraction)

## Shipped Milestones
- **v1.1.0**: Code Quality & Architecture — 7 phases, 459 new tests (512→971), SearchFilterMixin, large file refactoring, DAO error handling, dead code cleanup
- **v1.2.0**: UX Polish — Filter/search UX fixes (nav bar hiding, input focus, capitalization)


## Team & Workflow
- Solo developer
- Git-based version control (main branch)
- Flutter testing + analyze as quality gates
- Comprehensive test coverage is a project priority
