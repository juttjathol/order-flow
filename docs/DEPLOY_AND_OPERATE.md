# Full Deploy & Operate Instructions

## A. This repository

Repo is live at: **https://github.com/juttjathol/order-flow**

## B. Cloudflare Dashboard

See `docs/SELLER_DASHBOARD.md` for detailed steps.

Summary:
- Create D1 database `order-flow-db`
- Update `wrangler.toml` with database_id
- Set `JWT_SECRET` secret
- Set `GITHUB_REPO=juttjathol/order-flow`
- `wrangler deploy`
- Open the Worker / Pages URL → login → create first customer + license

## C. Flutter App

### Prerequisites
- Flutter SDK 3.22+
- Android Studio / SDK for APK builds

### First run
```bash
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows   # or chrome / phone
```

### Build release APK
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

### Or let GitHub Actions build it
1. Create a tag: `git tag v1.0.0 && git push origin v1.0.0`
2. Actions builds the APK and attaches it to a GitHub Release.
3. Dashboard automatically shows the download link.

## D. What to give a customer

1. The license key generated from your dashboard.
2. The APK download link (from GitHub Releases or your dashboard).
3. Short operator guide (`docs/OPERATOR_GUIDE.md`).

They install APK on Main + other devices, activate license on Main, start server, connect other devices via QR/IP, configure menu and printers.

## E. Network modes

- **Normal**: All devices on same Wi-Fi / LAN. Main shows IP + QR. Clients connect via WebSocket.
- **SoftAP / Hotspot (recommended for reliability)**: Main Android creates Wi-Fi hotspot. Other devices join it. Same discovery works. This keeps all devices on one private network so orders never get mixed up.

## F. Locked decisions

| Topic | Decision |
|-------|----------|
| Printers | Network IP + **Bluetooth** |
| Inventory | **Auto-deduct** on order |
| Language | English for now |
| Multi-outlet | Managed via SaaS dashboard (one license per location) |
| Billing | Manual monthly license generation |
| Device mesh | Local network + SoftAP so orders stay in sync |
| Branding | **Order Flow** |
| Main device | **PC or Android** |
