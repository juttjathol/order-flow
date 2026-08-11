/// Local Main web UI
library;

const String kLocalDashboardHtml = r'''
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Order Flow · Main</title>
<style>
:root{--bg:#0b1220;--card:#1a2332;--border:#2d3a4f;--text:#f1f5f9;--muted:#94a3b8;--primary:#38bdf8;--teal:#2dd4bf}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,sans-serif;background:radial-gradient(900px 500px at 10% -10%,#0c4a6e55,transparent),var(--bg);color:var(--text);min-height:100vh;padding:1.5rem}
.wrap{max-width:1100px;margin:0 auto}
header{display:flex;justify-content:space-between;align-items:center;margin-bottom:1.5rem;animation:up .5s ease}
.logo{width:48px;height:48px;border-radius:14px;background:linear-gradient(135deg,#0ea5e9,#14b8a6);display:grid;place-items:center;font-size:1.4rem;box-shadow:0 8px 24px #0ea5e955}
h1{font-size:1.35rem;font-weight:800}
.muted{color:var(--muted);font-size:.85rem}
.pill{background:#14532d55;color:#4ade80;border:1px solid #22c55e44;padding:.4rem .85rem;border-radius:999px;font-size:.8rem;font-weight:600}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:1rem;margin:1.25rem 0}
.stat{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:1.1rem;animation:up .55s ease}
.stat .v{font-size:1.8rem;font-weight:800;color:var(--primary)}
.card{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:1.25rem;margin-bottom:1rem;animation:up .6s ease}
.join{background:linear-gradient(135deg,#0c4a6e88,#134e4a66);border:1px solid #0ea5e955;border-radius:16px;padding:1.25rem;margin-bottom:1.25rem}
code{color:var(--primary);font-weight:700;font-size:1.1rem}
button{background:linear-gradient(135deg,#0ea5e9,#14b8a6);border:none;color:#0b1220;font-weight:700;padding:.6rem 1.1rem;border-radius:10px;cursor:pointer}
@keyframes up{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}
table{width:100%;border-collapse:collapse;font-size:.9rem}
th,td{text-align:left;padding:.6rem .4rem;border-bottom:1px solid var(--border)}
th{color:var(--muted)}
</style></head><body><div class="wrap">
<header><div style="display:flex;gap:.85rem;align-items:center"><div class="logo">🍽️</div><div><h1>Order Flow</h1><p class="muted">Main device · local network dashboard</p></div></div>
<div class="pill">● Server online</div></header>
<div class="join"><div class="muted" style="margin-bottom:.35rem">Other devices connect to</div>
<code id="u"></code>
<p class="muted" style="margin-top:.5rem">Same Wi‑Fi or hotspot · no cloud required for service</p>
<button style="margin-top:.75rem" onclick="navigator.clipboard.writeText(document.getElementById('u').textContent)">Copy address</button>
</div>
<div class="stats">
<div class="stat"><div class="muted">Open orders</div><div class="v">3</div></div>
<div class="stat"><div class="muted">Devices</div><div class="v">1</div></div>
<div class="stat"><div class="muted">Today sales</div><div class="v">$0</div></div>
<div class="stat"><div class="muted">Menu items</div><div class="v">8</div></div>
</div>
<div class="card"><h2 style="margin-bottom:1rem">Kitchen queue</h2>
<table><thead><tr><th>Table</th><th>Items</th><th>Status</th></tr></thead>
<tbody>
<tr><td>T-04</td><td>Grilled Chicken · Fries</td><td>New</td></tr>
<tr><td>T-07</td><td>Beef Burger · Cola</td><td>Preparing</td></tr>
<tr><td>T-02</td><td>Pasta · Salad</td><td>New</td></tr>
</tbody></table>
<p class="muted" style="margin-top:1rem">Full live sync, menu editor and inventory ship in upcoming updates.</p>
</div>
<footer class="muted" style="text-align:center;margin-top:2rem">Order Flow · runs on your network</footer>
</div>
<script>document.getElementById('u').textContent=location.origin||('http://'+location.host);</script>
</body></html>
''';
