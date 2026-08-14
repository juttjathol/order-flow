# One-click deploy: GitHub → Cloudflare

You do **not** need to run many terminal commands every time.

## First time only (about 5 minutes)

### 1. Open Cloudflare
Go to: https://dash.cloudflare.com → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**

### 2. Connect this repo
- Choose GitHub
- Select repository: **juttjathol/order-flow**
- Click **Begin setup**

### 3. Build settings (copy exactly)
| Setting | Value |
|--------|--------|
| Project name | `order-flow` |
| Production branch | `main` |
| Framework preset | **None** |
| Build command | *(leave empty)* |
| Build output directory | `cloudflare_dashboard/public` |
| Root directory | *(leave empty / `/`)* |

### 4. Add D1 database (still first time only)
1. In Cloudflare dashboard → **Workers & Pages** → **D1** → **Create database**  
   Name: `order-flow-db`
2. Open your Pages project → **Settings** → **Functions** → **D1 database bindings**  
   - Variable name: `DB`  
   - Database: `order-flow-db`
3. Open **Settings** → **Environment variables** (Production):
   - `JWT_SECRET` = any long random password (mark as Secret)
   - `ADMIN_EMAIL` = your email (or keep `admin@example.com`)
   - `GITHUB_REPO` = `juttjathol/order-flow`

### 5. Create tables once
In Cloudflare → D1 → `order-flow-db` → **Console**, paste the contents of `cloudflare_dashboard/schema.sql` and run.  
Or one terminal command once:
```bash
npx wrangler d1 execute order-flow-db --remote --file=./cloudflare_dashboard/schema.sql
```

### 6. Deploy
Click **Save and Deploy**.

Your dashboard URL will look like:
`https://order-flow.pages.dev`

---

## After the first time = almost one click

Every time you push to `main` on GitHub, Cloudflare Pages **auto-deploys**.

No need to run deploy commands again.

---

## One-click APK for customers (they never open GitHub)

On your dashboard:
- Link **Download Android App** goes to:  
  `https://YOUR-DASHBOARD.pages.dev/api/v1/download/android`  
- That route finds the latest APK on GitHub Releases and **redirects** the user to download it.  
- Customers only see **your** link, not the GitHub releases page.

You still attach the APK to a GitHub Release once (or via tag + Actions). Users only use your dashboard link.

---

## PC as Main device = local webpage (no separate hosting)

You do **not** host the restaurant PC app on Cloudflare.

1. Main device (PC or Android) runs Order Flow and starts the local server.
2. On the PC, open a browser to:  
   `http://MAIN-IP:8787/`  
   (IP is shown on the Main screen / QR)
3. That page is served **by the Main device itself** on the local network.
4. Staff on PC use the browser; phones use the Android APK; all share the same live orders.

No extra server and no public hosting for the restaurant UI.
