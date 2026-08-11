# Order Flow - Local Network Order Taking System

**Offline-first, multi-device restaurant / cafe / retail order management software** that runs entirely on your local network (or a software-assisted network). No permanent internet required for day-to-day operation.

## What it does

- **Multiple Android devices + PC** share the same live order data in real time over local network.
- One device acts as **Main / Admin** (PC or Android). It holds the menu, inventory, settings, billing rules, and local database.
- **Order Taker** devices (phones/tablets) show the full menu configured on the Main device, let staff pick items + modifiers, assign a **Table number** (or ticket number), and send the order.
- Order appears instantly on all devices and is sent to the **Kitchen** device / printer (ESC/POS thermal printer support – Network + Bluetooth).
- Orders are **editable** – add more items later; new kitchen tickets can be printed for the additions only or full order.
- **Cashier / Reception** can generate payment tickets, invoices, split bills, apply discounts, and mark paid.
- **Inventory** is managed on the Main device and **auto-deducted** on orders (configurable).
- **Active devices status**, sales reports, invoices, and inventory are all controllable from the Main device.
- Fully works **offline** after initial setup. Internet is only needed for:
  - Initial license activation / subscription check (with long offline grace period)
  - Downloading updates
  - Optional cloud backup (future)

## Seller Dashboard (Cloudflare)

You (the software seller) get a Cloudflare-hosted dashboard where you:

- Create restaurant / customer accounts
- Generate monthly subscription licenses / activation keys
- See which customers are active
- Provide the latest APK / Desktop builds (linked from GitHub Releases – no R2 storage needed for APKs)
- Manage future updates

The local apps check license status only when online; they keep working offline for a configurable grace period.

## Tech Stack

| Layer              | Technology                                      |
|--------------------|-------------------------------------------------|
| Mobile + Desktop   | Flutter (Android APK + Windows / Linux / macOS) |
| Local Database     | SQLite via Drift                                |
| Local Server       | Dart Shelf + WebSocket (runs inside Main device)|
| Discovery          | mDNS (multicast_dns) + QR / manual IP           |
| Printing           | ESC/POS (Network IP + Bluetooth thermal printers) |
| Cloud Dashboard    | Cloudflare Pages + Workers + D1                 |
| Auth / Licenses    | JWT + signed license keys                       |
| Updates            | GitHub Releases + GitHub Actions CI             |
| Payments (seller)  | Manual monthly license keys (Stripe optional later) |

## Project Structure

```
order-flow/
├── flutter_app/                 # Cross-platform client (Android + Desktop)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/                # networking, db, models, services
│   │   ├── features/            # order_taking, kitchen, admin, cashier, inventory
│   │   └── ...
│   ├── pubspec.yaml
│   └── android/ ios/ windows/ linux/ macos/
├── cloudflare_dashboard/        # Seller admin + license API
│   ├── public/                  # Frontend dashboard
│   ├── workers/                 # API + license generation
│   ├── schema.sql               # D1 schema
│   └── wrangler.toml
├── docs/                        # Detailed operator manuals
├── .github/workflows/           # Build APK + Desktop on release
└── README.md
```

## Phases (Development Roadmap)

See `PHASES.md` for the full phase breakdown and current status.

This repository already contains a solid foundation for all major phases so you can:

1. Build & run the Flutter app (Main + Order Taker modes)
2. Deploy the Cloudflare dashboard
3. Generate licenses
4. Distribute APKs via GitHub Releases
5. Iterate and add features

## Quick Start for You (Developer / Seller)

1. **Clone this repo**
2. **Flutter side**
   ```bash
   cd flutter_app
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter run -d windows   # or chrome / android
   ```
3. **Cloudflare side**
   ```bash
   cd cloudflare_dashboard
   npm install
   npx wrangler d1 create order-flow-db
   # update wrangler.toml with the DB id
   npx wrangler d1 execute order-flow-db --file=./schema.sql
   npx wrangler deploy
   ```
4. Create your first admin user in the dashboard and generate a license key.
5. In the Flutter app (Main mode) enter the license key to activate.

## How the Local Network Works

1. On the Main device start the app → choose **“Start as Main Server”**.
2. The app starts a local HTTP + WebSocket server (default port 8787) and advertises via mDNS (`_orderflow._tcp`).
3. Other devices open the same APK → choose **“Join existing system”**.
4. They either:
   - Automatically discover the Main device, or
   - Scan the QR code shown on the Main device, or
   - Manually enter the IP shown on the Main device.
5. All devices stay in continuous WebSocket sync. Orders, menu changes, inventory updates, and device status are pushed in real time.
6. If the Wi-Fi goes down, devices that already have the data can still view recent orders; new writes require the Main device to be reachable.

**SoftAP / Hotspot mode (recommended when venue Wi-Fi is unreliable):**
On Android Main device turn on Wi-Fi Hotspot. Other devices join that hotspot. Same discovery + WebSocket mechanism keeps all orders in sync so they never get mixed up.

## Printing

Kitchen and cashier printers are configured on the Main device (Network IP or Bluetooth).  
The app sends raw ESC/POS commands. Compatible with most common 58mm / 80mm thermal printers used in restaurants. Bluetooth support uses `blue_thermal_printer`.

## License & Subscription Model

- You generate a signed license key (or short activation code) from the Cloudflare dashboard.
- The restaurant enters it once on the Main device.
- The Main device stores the license locally (encrypted).
- When online, it periodically validates with your Workers API.
- Long offline grace period (default 45–60 days) so restaurants are never locked out by temporary internet issues.
- You can revoke or change expiry from the dashboard; the next online check will apply it.

## Future Updates of the APK

1. You push code to GitHub.
2. GitHub Actions builds a new signed APK (and desktop packages) and creates a GitHub Release.
3. The Cloudflare dashboard shows the latest release download links (fetched from GitHub API – no need to upload APK to R2).
4. Main devices (or any device) can check for updates and download the new APK directly from GitHub Releases.

## Locked decisions

- Brand: **Order Flow**
- Main device: PC or Android
- Printers: Network + Bluetooth
- Inventory: Auto-deduct on
- Language: English (for now)
- Billing: Manual monthly license keys via dashboard
- Multi-device sync via local network / SoftAP so orders never mix

## Important Notes

- This is a **production-oriented foundation**, not a 100% finished commercial product. You will still need to polish UI/UX, test with real thermal printers, and harden error handling.
- Local server currently uses plain HTTP (fine for private LAN).
- mDNS discovery works best on the same subnet. Manual IP / QR always works.

Built so you can own the full stack, run completely offline for customers, and still manage subscriptions + updates centrally via Cloudflare + GitHub.
