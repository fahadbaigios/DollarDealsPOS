# QA / Dev Sanity Checklist

Use this checklist to verify core flows after changes.

## Setup

- [ ] Run `flutter pub get`
- [ ] Run `dart run build_runner build` if schema changed
- [ ] Launch app: `flutter run -d macos` (or windows/linux)

## Master Data

- [ ] **Create category** – Products → Categories → Add → Save
- [ ] **Create unit** – Products → Units → Add → Save
- [ ] **Create supplier** – Products → Suppliers → Add → Save
- [ ] **Create product** – Products → Products → Add → Fill required fields → Save

## Purchases

- [ ] **Create purchase** – Purchases → New → Select supplier, add items → Save
- [ ] **Verify stock increase** – Inventory → check product stock increased

## Inventory

- [ ] **Stock adjustment IN** – Inventory → Transactions → Adjust → In → quantity → Save
- [ ] **Stock adjustment OUT** – Inventory → Adjust → Out → quantity → Save
- [ ] **Verify transaction log** – Inventory → Transactions tab shows entries

## Sales (POS)

- [ ] **Add items to cart** – Sales → POS → search/add products
- [ ] **Complete sale** – Enter payment → Complete Sale
- [ ] **Verify stock decrease** – Inventory → check product stock decreased
- [ ] **Print receipt** – Sale details → Print menu → Preview thermal / A4
- [ ] **Reprint** – Verify printed count increments

## Expenses

- [ ] **Create expense** – Expenses → Add → Title, category, amount → Save
- [ ] **Create expense category** – Expenses → Categories tab → Add

## Dashboard

- [ ] **Verify summary cards** – Revenue, purchases, expenses, low stock
- [ ] **Verify recent sales** – List shows completed sales
- [ ] **Verify low stock** – Products at or below reorder level

## Reports

- [ ] **Sales report** – Reports → Sales → apply date filter
- [ ] **Purchase report** – Reports → Purchases
- [ ] **Inventory report** – Reports → Inventory
- [ ] **Low stock report** – Reports → Low Stock
- [ ] **Expense report** – Reports → Expenses
- [ ] **Profit & Loss** – Reports → Profit & Loss → set date range

## Settings

- [ ] **Business profile** – Settings → Business Profile → Save
- [ ] **Receipt settings** – Settings → Receipt Settings → Save
- [ ] **Printer settings** – Settings → Printer Settings → Add printer
- [ ] **System preferences** – Settings → System Preferences → Save

## Backup & Restore

- [ ] **Backup** – Settings → Backup & Restore → Backup Now → success message
- [ ] **Restore** – Select backup → Restore → confirm → success → restart app
- [ ] **Verify data** – After restore, data matches backup

## Edge Cases

- [ ] **Empty cart checkout** – Should not allow (validation)
- [ ] **Negative stock** – Blocked unless allow negative stock is on
- [ ] **Invalid form** – Required fields show validation messages
- [ ] **Delete confirmation** – Risky actions show confirm dialog
