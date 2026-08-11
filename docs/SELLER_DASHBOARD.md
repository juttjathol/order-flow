# Seller Dashboard Guide

## Deploying the Dashboard (Cloudflare)

1. Create a Cloudflare account and enable Workers + D1.
2. Install Wrangler: `npm install -g wrangler`
3. Login: `wrangler login`
4. Create D1 database:
   ```bash
   cd cloudflare_dashboard
   wrangler d1 create order-flow-db
   ```
   Copy the `database_id` into `wrangler.toml`.
5. Apply schema:
   ```bash
   wrangler d1 execute order-flow-db --file=./schema.sql
   ```
6. Set secrets:
   ```bash
   wrangler secret put JWT_SECRET
   # enter a long random string
   ```
7. (Optional) Set `GITHUB_REPO=juttjathol/order-flow` in wrangler.toml so the dashboard can list APK downloads.
8. Deploy the Worker:
   ```bash
   wrangler deploy
   ```
9. Serve `public/index.html` via Cloudflare Pages (or same Worker) and point API calls to your Worker URL.

After deploy, open the dashboard URL, login with the bootstrap email (default `admin@example.com` + any password on first login).

## Daily operations

1. **Add a customer** (restaurant name + optional contact).
2. **Generate a license**:
   - Select customer
   - Choose expiry date (e.g. +30 days for monthly)
   - Generate → copy the key (ABCD-EFGH-…)
3. Send the key + APK download link to the customer.
4. They activate once on their Main device.
5. You can **revoke** a license any time from the dashboard; the next online validation will lock it (after the offline grace period ends).

## APK distribution without R2

- Build the APK yourself (`flutter build apk --release`) or let GitHub Actions do it on tag.
- Create a GitHub Release and attach the APK.
- The dashboard calls the GitHub Releases API and shows the download links automatically.
- Customers download the APK directly from GitHub. No need to store the binary on Cloudflare R2.

## Updating the APK in the future

1. Make code changes in the Flutter project.
2. Bump version in `pubspec.yaml`.
3. Tag and push → GitHub Actions builds new APK → new GitHub Release.
4. Dashboard immediately shows the new download link.
5. Restaurants download and install the new APK over the old one. Local data stays intact.

## Subscription model

- **Manual (current)**: Every month generate or extend a license key and send it to the customer.
- Long offline grace so temporary payment delays do not brick the restaurant.
