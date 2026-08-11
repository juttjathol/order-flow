# One-click style deploy (GitHub → Cloudflare)

## First time only

1. Open https://dash.cloudflare.com → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
2. Select repo **juttjathol/order-flow**
3. Settings:
   - Framework: **None**
   - Build command: *(empty)*
   - Build output directory: `cloudflare_dashboard/public`
4. Create D1 database `order-flow-db`
5. Pages project → **Settings** → bind D1 as `DB`
6. Add secrets/vars: `JWT_SECRET`, `ADMIN_EMAIL`, `GITHUB_REPO=juttjathol/order-flow`
7. Run `schema.sql` once on the D1 database
8. Click **Save and Deploy**

After that, every push to `main` auto-updates the dashboard.

## Android APK for customers (no GitHub browsing)

Share this link only:

`https://YOUR-PROJECT.pages.dev/api/v1/download/android`

(You must still attach an APK to a GitHub Release once, or tag `v1.0.0` so Actions builds it. Customers only use your link.)

## PC as Main = local webpage (no extra host)

1. Run Order Flow Main on the PC or Android.
2. Start the local server.
3. On the PC browser open: `http://MAIN-IP:8787/`
4. That page is served by the Main device itself on the LAN/hotspot.
