# Development Phases

This document tracks the planned phases. The repository already contains working foundations for most of them so you can run, test, and extend immediately.

## Phase 1 – Project Skeleton & Core Models ✅ (Foundation present)

- Flutter project structure (Android + Desktop targets)
- Domain models: MenuItem, Order, OrderItem, Table, InventoryItem, Device, License, Invoice
- Local SQLite schema with Drift
- Basic app shell with role selection (Main / OrderTaker / Kitchen / Cashier)

**Status**: Code present under `flutter_app/lib/core` and `lib/features`

## Phase 2 – Local Server + Realtime Sync ✅ (Foundation present)

- Embedded Shelf HTTP + WebSocket server that runs only on the Main device
- Client connection manager
- mDNS advertisement + discovery
- QR code generation for easy join
- Initial full state sync + incremental WebSocket events (order.created, order.updated, menu.changed, inventory.updated, device.status)

**Status**: Core networking code present. Test on same Wi-Fi.

## Phase 3 – Order Taking Flow ✅ (UI + logic foundation)

- Main device: Menu editor (categories, items, prices, modifiers, availability)
- Order Taker screen: browse menu → add to cart → choose table / ticket number → submit
- Order appears live on all connected devices
- Ability to reopen an existing open order and add more items
- Kitchen ticket generation on submit / on add-more

**Status**: Screens and state management scaffolds present.

## Phase 4 – Kitchen + Printing ✅ (Scaffold + ESC/POS helpers)

- Kitchen display: live list of open / preparing / ready orders
- Mark items / whole order as preparing / ready / served
- ESC/POS command builder for 58mm & 80mm
- Printer configuration (Network IP, Bluetooth) stored on Main device
- Print full order or only the delta (new items)
- Bluetooth support via blue_thermal_printer

**Status**: Print service + example commands present. Real hardware testing required on your side.

## Phase 5 – Cashier, Billing, Invoices, Inventory ✅ (Foundation)

- Cashier view: open orders by table / ticket, apply discount, split, generate payment ticket / invoice
- Inventory management on Main: stock levels, low-stock alerts, **auto-deduct on order**
- Simple sales reports (today / date range) on Main device
- Invoice history

**Status**: Models + basic screens + InventoryService present.

## Phase 6 – License System + Cloudflare Dashboard ✅ (Full scaffold)

- Cloudflare Workers API for:
  - Admin authentication
  - Create / list customers (restaurants)
  - Generate signed license keys with expiry
  - Validate license (called by Main device when online)
  - List latest GitHub Releases for APK download links
- Simple web dashboard (Cloudflare Pages / static) for you to manage everything
- Flutter side: license entry screen + periodic online validation + offline grace period

**Status**: Workers code + D1 schema + basic frontend present.

## Phase 7 – Packaging, CI, Documentation, Distribution ✅

- GitHub Actions workflow that builds Android APK on tag / release
- Detailed operator manuals
- Seller instructions
- Repo ready on GitHub

**Status**: Present.

## Phase 8 – Hardening & Future (Decisions received)

### Locked decisions (2026-08-11)
- Bluetooth printing added (blue_thermal_printer)
- Auto-deduct inventory = default ON
- English only for now
- Licenses / customers managed fully from SaaS dashboard
- Manual monthly license keys
- SoftAP/hotspot documented as the way to keep all devices on one private network
- Brand name: **Order Flow**
- Main device = PC or Android
