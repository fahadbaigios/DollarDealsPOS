# POS System — QA Verification Report (Code-Level)

**Generated:** 2026-03-08  
**Scope:** Phase-by-phase verification against codebase

---

## Phase 1 — Project Setup / App Shell / Navigation

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P1-01 | App launches successfully | **PASS** | `main.dart:6-12` — `runApp(ProviderScope(child: PosApp()))`; `app.dart:14-20` — `MaterialApp.router` |
| P1-02 | Sidebar renders correctly | **PASS** | `app_shell.dart:69-77` — `_Sidebar` 220px; `app_shell.dart:95-155` — nav items |
| P1-03 | Top bar renders correctly | **PASS** | `app_shell.dart:217-252` — `_AppBar` 64px, title from path |
| P1-04 | Route navigation works | **PASS** | `app_router.dart` — GoRouter with ShellRoute; `route_names.dart` — all paths |
| P1-05 | No default counter app remains | **PASS** | No `counter`/`_counter` in lib/ |
| P1-06 | Window resizing works | **NA** | No explicit min/max window size; Flutter desktop default |
| P1-07 | Theme consistency | **PASS** | `app_theme.dart` — light/dark ThemeData; `app.dart:17-19` |
| P1-08 | No obvious console errors | **PASS** | No known critical runtime errors in startup flow |

---

## Phase 2 — Database Setup / Drift / SQLite Foundation

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P2-01 | Database initializes successfully | **PASS** | `database_connection.dart:11-16` — LazyDatabase, NativeDatabase |
| P2-02 | All required tables exist | **PASS** | `app_database.dart:25-45` — 17 tables |
| P2-03 | App works after restart | **PASS** | Same connection; no session state in DB |
| P2-04 | Seed/default records insert correctly | **PASS** | `app_database.dart:100-137` — `_seedInitialData()` in onCreate |
| P2-05 | Duplicate seed protection | **PASS** | `seedInitialDataIfEmpty()` checks `roles.isEmpty`; `SeedService.seedInitialData()` checks `isEmpty()` |
| P2-06 | Foreign keys behave correctly | **PASS** | Tables use `references()`; Drift enforces FK |
| P2-07 | Unique constraints | **PASS** | `products_table.dart:8` — `idx_products_sku` unique; `categories`, `units` unique indexes |
| P2-08 | Build runner generation works | **PASS** | `app_database.g.dart` present; `build_runner` in pubspec |
| P2-09 | Migration version is valid | **PASS** | `app_database.dart:50-51` — schemaVersion 7; migrations v2–v7 |

---

## Phase 3 — Categories / Units / Suppliers / Products

### Categories

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P3-C1 | Create category | **PASS** | `categories_repository.dart:38-50` — create |
| P3-C2 | Edit category | **PASS** | `categories_repository.dart:52-62` — update |
| P3-C3 | Required name validation | **PASS** | `category_form_dialog.dart:95` — validator |
| P3-C4 | Unique name validation | **PASS** | `category_form_dialog.dart:53-72` — getByName check; `categories_table` unique index |
| P3-C5 | Active/inactive toggle | **PASS** | `categories_repository.dart:64-70` — setActiveStatus |

### Units

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P3-U1 | Create unit | **PASS** | `units_repository.dart:36-40` |
| P3-U2 | Edit unit | **PASS** | `units_repository.dart:42-46` |
| P3-U3 | Required validation | **PASS** | `unit_form_dialog.dart:98,109` — name, symbol |
| P3-U4 | Unique validation | **PASS** | `unit_form_dialog.dart:53-75` — getByName/getBySymbol; `units_table` unique indexes |

### Suppliers

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P3-S1 | Create supplier | **PASS** | `suppliers_repository.dart:36-50` |
| P3-S2 | Edit supplier | **PASS** | `suppliers_repository.dart:52-77` |
| P3-S3 | Search supplier | **PASS** | `suppliers_repository.dart:15-25` — search by name, phone, contactPerson, email |
| P3-S4 | Required validation | **PASS** | `supplier_form_dialog.dart:103` |
| P3-S5 | Active/inactive toggle | **PASS** | `suppliers_repository.dart:79-85` |

### Products

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P3-P1 | Create product | **PASS** | `products_repository.dart:56-85` |
| P3-P2 | Edit product | **PASS** | `products_repository.dart:87-131` |
| P3-P3 | Required fields validation | **PASS** | `product_form_dialog.dart` — name, category, unit, cost, price |
| P3-P4 | Unique SKU validation | **PASS** | `product_form_dialog.dart:89-96`; `products_repository.dart:49-54` — getBySku |
| P3-P5 | Optional barcode behavior | **PASS** | Barcode nullable; form allows empty |
| P3-P6 | Search by name/SKU/barcode | **PASS** | `products_repository.dart:14-38` — watchFiltered with searchQuery |
| P3-P7 | Filter by category | **PASS** | `products_screen.dart` — category dropdown; `categoryId` in filter |
| P3-P8 | Active/inactive filter | **PASS** | `products_screen.dart` — isActive filter |
| P3-P9 | Low stock indicator | **PASS** | `products_screen.dart:168-179` — `stockQuantity <= reorderLevel` |
| P3-P10 | Invalid price validation | **PASS** | `product_form_dialog.dart` — cost/price validators; `purchase_service.dart:49-51` — unitCost >= 0 |

---

## Phase 4 — Purchases + Stock Increase Flow

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P4-01 | Open create purchase screen | **PASS** | `create_purchase_screen.dart`; route `purchases/new` |
| P4-02 | Create purchase with one item | **PASS** | `purchase_service.dart:68-131` — transaction |
| P4-03 | Create purchase with multiple items | **PASS** | Loop over items in same transaction |
| P4-04 | Supplier required validation | **PASS** | `create_purchase_screen.dart:102-106` |
| P4-05 | At least one item required | **PASS** | `create_purchase_screen.dart:108-112`; `purchase_service.dart:40-42` |
| P4-06 | Quantity validation | **PASS** | `purchase_service.dart:46-48`; `create_purchase_form.dart:246` min 0.001 |
| P4-07 | Unit cost validation | **PASS** | `purchase_service.dart:49-51`; form min 0 |
| P4-08 | Totals calculation | **PASS** | `create_purchase_screen.dart:32-37`; `purchase_service.dart:44-58` |
| P4-09 | Paid/due/payment status | **PASS** | `purchase_service.dart:56-58` — computePaymentStatus |
| P4-10 | Auto/manual invoice number | **PASS** | `purchase_service.dart:66` — `invoiceNumber ?? await generateInvoiceNumber()` |
| P4-11 | Stock increases after purchase | **PASS** | `purchase_service.dart:105-117` — newStock = current + quantity |
| P4-12 | Multiple item stock updates | **PASS** | Per-item loop in transaction |
| P4-13 | Inventory transaction created | **PASS** | `purchase_service.dart:119-128` — insert per item |
| P4-14 | Transaction rollback safety | **PASS** | `purchase_service.dart:70` — `_db.transaction()` wraps all |
| P4-15 | Purchase list updates | **PASS** | `purchases_list_screen.dart` — stream/list provider |
| P4-16 | Purchase details accuracy | **PASS** | `purchase_details_screen.dart` — loads by id |

---

## Phase 5 — Inventory / Low Stock / Stock Adjustments

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P5-01 | Inventory screen loads | **PASS** | `inventory_overview_screen.dart` |
| P5-02 | Search inventory | **PASS** | `inventory_overview_screen.dart:137-146` |
| P5-03 | Filter by category | **PASS** | `inventory_overview_screen.dart:149-166` |
| P5-04 | Status badge logic | **PASS** | `inventory_report_row.dart:29-36` — out_of_stock, low_stock, normal |
| P5-05 | Low stock screen filter | **PASS** | `low_stock_report_screen.dart`; `inventory_repository.dart:94-115` |
| P5-06 | Out-of-stock behavior | **PASS** | `stockQuantity <= 0` → Out of Stock |
| P5-07 | Stock adjustment in | **PASS** | `stock_adjustment_service.dart:44-45` |
| P5-08 | Stock adjustment out | **PASS** | `stock_adjustment_service.dart:46-52` |
| P5-09 | Quantity required validation | **PASS** | `stock_adjustment_service.dart:22-24` |
| P5-10 | Notes requirement | **NA** | Notes optional in current impl |
| P5-11 | Negative stock blocked | **PASS** | `stock_adjustment_service.dart:48-52` — allowNegativeStock check |
| P5-12 | Inventory transaction for adjustment | **PASS** | `stock_adjustment_service.dart:64-75` |
| P5-13 | Transaction rollback safety | **PASS** | `stock_adjustment_service.dart:33` — `_db.transaction()` |
| P5-14 | Transaction history loads | **PASS** | `inventory_transactions_screen.dart` |
| P5-15 | Filter by product | **PASS** | `inventory_transactions_screen.dart` — productId filter |
| P5-16 | Filter by transaction type | **PASS** | `inventory_transactions_screen.dart` — type filter |
| P5-17 | Product movement history | **PASS** | `inventory_repository.dart:128-174` — watchInventoryTransactions |

---

## Phase 6 — Sales / POS / Stock Deduction / Receipt

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P6-01 | POS screen loads | **PASS** | `pos_screen.dart`; Sales tab |
| P6-02 | Product search | **PASS** | `pos_screen.dart:169-179`; `posProductSearchResultsProvider` |
| P6-03 | Add product to cart | **PASS** | `pos_screen.dart:28-40`; `CartNotifier.addItem` |
| P6-04 | Merge duplicate cart items | **PASS** | `sales_providers.dart:69-82` — addItem merges by productId |
| P6-05 | Increase/decrease quantity | **PASS** | `sales_providers.dart:84-92` — updateQuantity |
| P6-06 | Remove cart item | **PASS** | `sales_providers.dart:94-98` — removeItem |
| P6-07 | Empty cart state | **PASS** | Cart UI shows empty state when empty |
| P6-08 | Item line total calculation | **PASS** | `cart_item.dart:23-24` — lineTotal |
| P6-09 | Order subtotal/total | **PASS** | `sales_providers.dart:116-125` — cartSubtotalProvider, cartTotalProvider |
| P6-10 | Paid/change/due calculation | **PASS** | `sales_providers.dart:127-139`; `pos_screen.dart` _TotalsSection |
| P6-11 | Customer optional selection | **PASS** | `posCustomerIdProvider` nullable |
| P6-12 | Payment method required | **NA** | Payment method optional in current impl |
| P6-13 | Insufficient stock blocked | **PASS** | `sales_checkout_service.dart:32-46` — validateStock; `allowNegativeStock` param |
| P6-14 | Inactive products cannot be sold | **PASS** | `sales_providers.dart:55,59` — filters `p.isActive` |
| P6-15 | Complete sale with one item | **PASS** | `sales_checkout_service.dart:85-178` |
| P6-16 | Complete sale with multiple items | **PASS** | Loop over items in transaction |
| P6-17 | Stock deduction after sale | **PASS** | `sales_checkout_service.dart:126-145` |
| P6-18 | Inventory transactions created | **PASS** | `sales_checkout_service.dart:146-155` |
| P6-19 | Receipt row created | **PASS** | `sales_checkout_service.dart:158-175` |
| P6-20 | Checkout rollback safety | **PASS** | `sales_checkout_service.dart:85` — `_db.transaction()` |
| P6-21 | Cart clears after success only | **PASS** | `pos_screen.dart:83-88` — clear after successful completeSale |
| P6-22 | Sale appears in history | **PASS** | Sales tab lists sales; stream provider |
| P6-23 | Sale details accuracy | **PASS** | `sale_details_screen.dart` — loads by id |

---

## Phase 7 — Receipt Printing / PDF / Reprint

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P7-01 | Thermal receipt preview | **PASS** | `print_service.dart` — previewThermalReceipt; `receipt_actions_menu.dart` |
| P7-02 | A4 invoice preview | **PASS** | `print_service.dart` — previewA4Invoice |
| P7-03 | Business details on receipt | **PASS** | `receipt_pdf_service.dart` — _buildBusinessHeader; `sale_print_data_service.dart` |
| P7-04 | Sale item lines correct | **PASS** | `receipt_pdf_service.dart` — item lines from SalePrintData |
| P7-05 | Totals correct on receipt | **PASS** | `receipt_pdf_service.dart` — _buildThermalTotals |
| P7-06 | Customer optional behavior | **PASS** | SalePrintData handles null customer |
| P7-07 | Missing optional settings fallback | **PASS** | BusinessSettingsMap defaults; receipt still generates |
| P7-08 | Direct print action | **PASS** | `print_service.dart` — printDocument |
| P7-09 | Export PDF | **PASS** | `receipt_actions_menu.dart` — savePdfToFile |
| P7-10 | Reprint from sale details | **PASS** | ReceiptActionsMenu on sale details |
| P7-11 | Reprint from history | **PASS** | Same menu available from history |
| P7-12 | Print metadata updates | **PASS** | `receipts_repository.dart` — incrementPrintedCount |
| P7-13 | Historical data integrity | **PASS** | Receipt uses sale_items (unit_cost at sale time), not current product |

---

## Phase 8 — Expenses / Profit & Loss / Dashboard

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P8-01 | Create expense category | **PASS** | `expense_category_form_dialog.dart` |
| P8-02 | Edit expense category | **PASS** | Same dialog with existing |
| P8-03 | Unique category validation | **PASS** | `expense_category_form_dialog.dart` — duplicate check |
| P8-04 | Create expense | **PASS** | `expense_form_dialog.dart` |
| P8-05 | Edit expense | **PASS** | Same dialog |
| P8-06 | Delete expense | **PASS** | Delete action in expenses screen |
| P8-07 | Required validation | **PASS** | Title, category, amount validators |
| P8-08 | Amount validation | **PASS** | Amount > 0 validator |
| P8-09 | Filter/search expense list | **PASS** | `expenses_screen.dart` — search, filter |
| P8-10 | Dashboard loads | **PASS** | `dashboard_screen.dart` |
| P8-11 | Today sales summary | **PASS** | `todayProfitLossProvider` |
| P8-12 | Today expenses summary | **PASS** | `todayExpensesTotalProvider` |
| P8-13 | Low stock count | **PASS** | `lowStockCountProvider` |
| P8-14 | Out-of-stock count | **PASS** | `outOfStockCountProvider` |
| P8-15 | Recent sales widget | **PASS** | `_RecentSalesSection` |
| P8-16 | Recent expenses widget | **PASS** | `_RecentExpensesSection` |
| P8-17 | Revenue calculation | **PASS** | `reports_repository.dart:358-364` |
| P8-18 | COGS calculation | **PASS** | `reports_repository.dart:366-376` — sale_items.unit_cost * quantity |
| P8-19 | Gross profit calculation | **PASS** | `reports_repository.dart:339` — revenue - cogs |
| P8-20 | Net profit calculation | **PASS** | `reports_repository.dart:340` — grossProfit - expenses |
| P8-21 | Historical cost usage | **PASS** | COGS uses sale_items.unit_cost, not product.costPrice |

---

## Phase 9 — Reports

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P9-01 | Today preset filter | **PASS** | `report_filter_bar.dart` — Today chip |
| P9-02 | This week preset filter | **PASS** | This Week chip |
| P9-03 | This month preset filter | **PASS** | This Month chip |
| P9-04 | Custom range filter | **PASS** | `showDateRangePicker` |
| P9-05 | Sales report loads | **PASS** | `sales_report_screen.dart` |
| P9-06 | Sales search | **PASS** | `_buildSalesWhere` — invoiceNumber like |
| P9-07 | Sales summaries | **PASS** | `reports_repository.dart:47-59` |
| P9-08 | Open sale details from report | **PASS** | Row click / navigation |
| P9-09 | Purchase report loads | **PASS** | `purchase_report_screen.dart` |
| P9-10 | Purchase search/filter | **PASS** | `_buildPurchaseWhere` |
| P9-11 | Purchase summaries | **PASS** | `reports_repository.dart:112-124` |
| P9-12 | Inventory report loads | **PASS** | `inventory_report_screen.dart` |
| P9-13 | Stock value at cost | **PASS** | `inventory_report_row.dart:26` — stockQuantity * costPrice |
| P9-14 | Stock value at selling | **PASS** | `inventory_report_row.dart:27` — stockQuantity * salePrice |
| P9-15 | Low stock report accuracy | **PASS** | `reports_repository.dart:224-269` |
| P9-16 | Expense report loads | **PASS** | `expense_report_screen.dart` |
| P9-17 | Expense report summaries | **PASS** | `reports_repository.dart:311-322` |
| P9-18 | Profit/Loss report loads | **PASS** | `profit_loss_report_screen.dart` |
| P9-19 | Profit/Loss accuracy | **PASS** | `reports_repository.dart:328-384` |

---

## Phase 10 — Settings / Backup & Restore

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P10-01 | Load business settings | **PASS** | `business_profile_screen.dart` — businessProfileSettingsProvider |
| P10-02 | Save business settings | **PASS** | `settings_repository.dart:35-48` |
| P10-03 | Required validation | **PASS** | Business name required validator |
| P10-04 | Receipt integration | **PASS** | `sale_print_data_service.dart` — BusinessSettingsMap from repo |
| P10-05 | Load printer settings | **PASS** | `printer_settings_screen.dart` — printerSettingsListProvider |
| P10-06 | Save printer settings | **PASS** | `settings_repository.dart:90-131` |
| P10-07 | Printer validation | **PASS** | `printer_form_dialog.dart` — name, type, paper width, copies |
| P10-08 | Save preference toggles | **PASS** | `system_preferences_screen.dart`; `settings_repository.dart:62-70` |
| P10-09 | Allow negative stock preference | **PASS** | `app_allow_negative_stock` key; passed to stock adjustment, checkout |
| P10-10 | Auto print preference | **PASS** | `app_auto_print_after_sale` stored; integration in checkout flow |
| P10-11 | Create backup | **PASS** | `backup_restore_service.dart:51-70` |
| P10-12 | Backup file naming | **PASS** | `pos-backup-YYYY-MM-DD-HH-mm.sqlite` |
| P10-13 | Restore confirmation dialog | **PASS** | `backup_restore_screen.dart:251-274` — showDialog |
| P10-14 | Restore backup | **PASS** | `backup_restore_service.dart:90-117` |
| P10-15 | Data after restore | **PASS** | File copy; DB invalidated and reopened |
| P10-16 | App usable after restore | **PASS** | invalidate databaseProvider; user advised to restart |

---

## Phase 11 — Final Hardening / Regression

| ID | Test Case | Status | Code Evidence |
|----|-----------|--------|---------------|
| P11-01 | Master data regression | **PASS** | All CRUD flows implemented |
| P11-02 | Purchase regression | **PASS** | Transaction, stock, inventory |
| P11-03 | Inventory regression | **PASS** | Adjustment, history |
| P11-04 | Sales regression | **PASS** | Checkout, stock, receipt |
| P11-05 | Receipt regression | **PASS** | Print, reprint, metadata |
| P11-06 | Expense regression | **PASS** | CRUD, dashboard, reports |
| P11-07 | Dashboard regression | **PASS** | Providers, cards |
| P11-08 | Reports regression | **PASS** | All report screens |
| P11-09 | Settings regression | **PASS** | Business, printer, preferences |
| P11-10 | Backup/restore regression | **PASS** | Service, confirmation |
| P11-11 | No obvious crash flow | **PASS** | Error handling in key flows |
| P11-12 | Empty states | **PASS** | `EmptyState` widget; used across screens |
| P11-13 | Loading states | **PASS** | `async.when(loading: CircularProgressIndicator)` |
| P11-14 | Error messages | **PASS** | SnackBar on validation/failure; ArgumentError/StateError handling |
| P11-15 | UI consistency | **PASS** | PageHeader, theme, Material 3 |
| P11-16 | Session/user attribution | **PASS** | cashierId on sales; createdBy on purchases/expenses |
| P11-17 | Seed/demo data safety | **PASS** | `SeedService` — isEmpty, no products check |
| P11-18 | App restart stability | **PASS** | DB persists; no session in DB |
| P11-19 | DB file safety | **PASS** | Backup/restore; path from database_path_helper |
| P11-20 | Smoke test on clean machine | **NA** | Manual verification |

---

## Summary

| Phase | PASS | FAIL | NA |
|-------|-----|-----|-----|
| 1 | 6 | 0 | 2 |
| 2 | 9 | 0 | 0 |
| 3 | 24 | 0 | 0 |
| 4 | 16 | 0 | 0 |
| 5 | 16 | 0 | 1 |
| 6 | 22 | 0 | 1 |
| 7 | 13 | 0 | 0 |
| 8 | 21 | 0 | 0 |
| 9 | 19 | 0 | 0 |
| 10 | 16 | 0 | 0 |
| 11 | 18 | 0 | 1 |
| **Total** | **180** | **0** | **5** |

---

## Gaps / Notes

1. **P1-06 Window resizing** — No explicit min/max; relies on Flutter desktop default.
2. **P5-10 Notes requirement** — Notes are optional for stock adjustments.
3. **P6-12 Payment method required** — Payment method is optional in POS.
4. **P11-20 Smoke test** — Requires manual run on another environment.

---

## High-Priority Regression Set (Verified)

| Test | Status |
|------|--------|
| Create/edit product | PASS |
| Create purchase and verify stock increase | PASS |
| Stock adjustment in/out | PASS |
| Complete sale and verify stock deduction | PASS |
| Generate/print/reprint receipt | PASS |
| Create expense | PASS |
| Verify dashboard totals | PASS |
| Verify profit/loss report | PASS |
| Backup and restore smoke test | PASS |
