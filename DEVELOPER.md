# One Dollar Deals POS – Developer Guide

## Overview

Offline-first desktop POS for inventory, sales, purchases, expenses, and reports. Built for small retail shops.

## Tech Stack

- **Flutter** (desktop: macOS, Windows, Linux)
- **Riverpod** – state management
- **GoRouter** – navigation
- **Drift + SQLite** – local database
- **Material 3** – UI
- **pdf / printing** – receipts and invoices

## Project Structure

```
lib/
├── app/              # Bootstrap, router, theme, shell
├── core/              # Shared infrastructure
│   ├── constants/     # Route names, app constants
│   ├── services/      # Database provider, seed service
│   └── widgets/       # PageHeader, EmptyState, ConfirmDialog
├── database/          # Drift schema, tables, connection, migrations
└── features/          # Feature modules
    ├── dashboard/
    ├── products/      # Products, categories, units, suppliers
    ├── purchases/
    ├── sales/         # POS, sale history
    ├── inventory/     # Stock overview, adjustments, transactions
    ├── expenses/
    ├── reports/       # Sales, purchases, inventory, expenses, P&L
    ├── settings/      # Business, receipt, printer, backup/restore
    └── printing/      # Receipt PDF, print service
```

## How to Run

```bash
# Get dependencies
flutter pub get

# Generate Drift code (after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Run on macOS
flutter run -d macos

# Run on Windows
flutter run -d windows
```

## Database

- **Path:** `{ApplicationDocumentsDirectory}/pos_database.sqlite`
- **Initialization:** On first run, Drift creates the DB and runs `onCreate` migrations.
- **Migrations:** Defined in `lib/database/app_database.dart`. Bump `schemaVersion` and add `onUpgrade` logic when changing schema.

## Seeding Data

### Initial data (on create)

On first DB creation, the app seeds:

- Roles: Admin, Manager, Cashier
- Payment methods: Cash, Card, Bank Transfer
- Expense categories: Rent, Utilities, Salaries, Miscellaneous
- Units: Piece, Kilogram, Liter, Box
- Categories: General
- Default user: `admin` (password not enforced in current build)

### Demo data

Use `SeedService` for demo content:

```dart
final seedService = SeedService(ref.read(databaseProvider));

// Seed initial data (only when DB is empty)
final result = await seedService.seedInitialData();

// Seed demo products, suppliers, customers (only when no products exist)
final demoResult = await seedService.seedDemoData();
```

Expose via a dev-only "Seed Demo Data" button in Settings if desired.

## Main Features

| Feature | Description |
|--------|-------------|
| **Dashboard** | Summary cards, recent sales, low stock |
| **Products** | CRUD for products, categories, units, suppliers |
| **Purchases** | Create purchase, update stock, view details |
| **Sales** | POS cart, checkout, sale history |
| **Inventory** | Stock overview, adjustments, transaction log |
| **Expenses** | Expense records and categories |
| **Reports** | Sales, purchases, inventory, low stock, expenses, P&L |
| **Settings** | Business profile, receipt, printer, system prefs, backup/restore |
| **Printing** | Thermal receipt, A4 invoice, PDF export |

## Backup & Restore

- **Backup:** Copies DB to `{ApplicationDocumentsDirectory}/backups/pos-backup-YYYY-MM-DD-HH-mm.sqlite`
- **Restore:** Closes DB, replaces file, invalidates providers. User should restart app after restore.

## Important Notes

- **COGS / Profit:** Reports use `sale_items.unit_cost` (historical cost at sale time), not current product cost.
- **Transactions:** Purchase create, sale checkout, and stock adjustment run in DB transactions for consistency.
- **Session:** `cashier_id` on sales and `created_by` on purchases/expenses use user ID. Default admin ID is 1.
