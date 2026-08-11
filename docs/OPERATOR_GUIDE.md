# Operator Guide – Restaurant / Cafe Staff

## 1. First-time setup (Main Device)

1. Install the APK (or desktop app) on the device that will be the **Main** (usually a tablet or PC that stays in the restaurant).
2. Open the app → **Start as Main Device**.
3. Go to **License / Activation** and enter the license key you received.
4. On the Main screen, tap the play button to **start the local server**.
5. Note the IP address shown (or the QR code). Keep this device powered and on the same Wi-Fi as the other devices.
6. Configure:
   - Restaurant name, currency, tax %
   - Menu (categories + items + prices)
   - Kitchen printer IP (usually the thermal printer’s network address, port 9100) or Bluetooth printer
   - Inventory (optional)

## 2. Connecting Order Taker / Kitchen / Cashier devices

1. Install the **same APK** on phones or tablets.
2. Open app → choose the role (Order Taker / Kitchen / Cashier).
3. Tap the link/connect icon.
4. Either:
   - Scan the QR code shown on the Main device, or
   - Enter the IP address shown on the Main device, or
   - Wait for automatic discovery (same Wi-Fi, multicast allowed).
5. Once connected, the menu and live orders appear automatically.

**Tip – SoftAP / Hotspot:** If venue Wi-Fi is unreliable, turn on Hotspot on the Main Android device and have other devices join it. Orders stay in sync and never mix.

## 3. Taking an order

1. On Order Taker → New Order.
2. Select table number **or** create a custom ticket number.
3. Add items from the menu. You can add modifiers and notes.
4. Submit. The order is saved on the Main device and appears on Kitchen + Cashier instantly.
5. Kitchen printer should print the ticket automatically (if configured).

## 4. Adding more items later

1. Open the existing open order (by table or order number).
2. Add new items.
3. Save. Only the new items can be sent to the kitchen printer as a “delta” ticket.

## 5. Kitchen workflow

- New orders appear in the Kitchen view.
- Staff marks items or whole order as Preparing → Ready.
- When ready, waiters are notified (or they just see the status).

## 6. Closing the bill (Cashier)

1. Find the table / ticket.
2. Review items, apply discount if needed.
3. Print payment ticket / invoice.
4. Mark as Paid. Order moves to history.

## 7. Important notes

- The Main device **must stay on** and on the network while the restaurant is open.
- If Wi-Fi drops, already-synced devices can still view recent data, but new orders require the Main device.
- All data lives on the Main device’s local SQLite database.
- Updates: when a new APK is available, download it from the link provided by your software provider and install over the existing app. Data is preserved.
