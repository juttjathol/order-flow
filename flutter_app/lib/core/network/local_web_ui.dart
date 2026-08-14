/// Local web dashboard served by Main device at http://IP:8787/
const String kLocalDashboardHtml = r'''
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Order Flow · Main</title>
<style>
:root{--bg:#f4f6fb;--card:#fff;--border:#e2e8f0;--text:#0f172a;--muted:#64748b;--accent:#f97316;--accent2:#ea580c;--ok:#16a34a;--warn:#f59e0b;--shadow:0 4px 20px rgba(15,23,42,.06)}
*{box-sizing:border-box}body{margin:0;font-family:"Segoe UI",system-ui,sans-serif;background:var(--bg);color:var(--text)}
.shell{display:flex;min-height:100vh}
.side{width:220px;background:#fff;border-right:1px solid var(--border);padding:1.1rem .85rem;position:sticky;top:0;height:100vh}
.brand{font-weight:900;font-size:1.1rem;padding:.4rem .6rem 1rem;display:flex;align-items:center;gap:.5rem}
.mark{width:30px;height:30px;border-radius:9px;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;display:grid;place-items:center;font-size:.8rem;font-weight:900}
.nav{display:block;width:100%;text-align:left;border:none;background:transparent;padding:.6rem .75rem;border-radius:12px;font-weight:700;font-size:.9rem;cursor:pointer;margin-bottom:.2rem;color:var(--text)}
.nav:hover{background:#fff7ed;color:var(--accent2)}.nav.active{background:var(--accent);color:#fff}
.main{flex:1;padding:1.25rem 1.5rem;max-width:1100px}
.welcome{background:linear-gradient(135deg,#ea580c,#f97316 55%,#fb923c);color:#fff;border-radius:20px;padding:1.35rem 1.5rem;margin-bottom:1.1rem;box-shadow:0 10px 28px rgba(249,115,22,.22)}
.welcome h1{margin:0;font-size:1.35rem;font-weight:900}.welcome p{margin:.25rem 0 0;opacity:.92;font-weight:600;font-size:.9rem}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:.85rem;margin-bottom:1.1rem}
.stat{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:1rem 1.1rem;box-shadow:var(--shadow)}
.stat .l{font-size:.78rem;color:var(--muted);font-weight:700}.stat .v{font-size:1.55rem;font-weight:900;margin-top:.2rem;letter-spacing:-.02em}
.card{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:1.15rem;margin-bottom:1rem;box-shadow:var(--shadow)}
.card h3{margin:0 0 .75rem;font-size:1rem;font-weight:800}
.muted{color:var(--muted);font-size:.85rem}code{color:var(--accent2);font-weight:700}
table{width:100%;border-collapse:collapse;font-size:.9rem}
th,td{text-align:left;padding:.55rem .4rem;border-bottom:1px solid var(--border)}
th{color:var(--muted);font-size:.72rem;text-transform:uppercase;letter-spacing:.04em}
input,textarea,select{width:100%;background:#fff;border:1px solid var(--border);color:var(--text);border-radius:12px;padding:.55rem .7rem;margin:.2rem 0 .55rem;font:inherit}
button{background:linear-gradient(135deg,var(--accent),var(--accent2));border:none;color:#fff;font-weight:700;padding:.5rem 1rem;border-radius:12px;cursor:pointer;margin:.15rem}
button.ghost{background:#f1f5f9;color:var(--text)}button.danger{background:#ef4444}
.row{display:flex;gap:.5rem;flex-wrap:wrap;align-items:center}
.chip{display:inline-block;padding:.35rem .7rem;border-radius:999px;border:1px solid var(--border);background:#fff;cursor:pointer;font-weight:700;margin:.15rem}
.chip:hover,.chip.on{background:#fff7ed;border-color:var(--accent);color:var(--accent2)}
.panel{display:none}.panel.active{display:block}
.low{color:var(--warn);font-weight:800}
@media(max-width:800px){.shell{flex-direction:column}.side{width:100%;height:auto;position:relative;border-right:none;border-bottom:1px solid var(--border)}}
</style></head><body>
<div class="shell">
<aside class="side">
  <div class="brand"><span class="mark">OF</span> Order Flow</div>
  <button class="nav active" data-p="dash" onclick="go('dash',this)">Dashboard</button>
  <button class="nav" data-p="orders" onclick="go('orders',this)">Orders</button>
  <button class="nav" data-p="menu" onclick="go('menu',this)">Menu</button>
  <button class="nav" data-p="inv" onclick="go('inv',this)">Inventory</button>
  <button class="nav" data-p="bill" onclick="go('bill',this)">Bill & printers</button>
  <p class="muted" style="margin-top:1rem;padding:.5rem">PC main · local only<br/><code id="join"></code></p>
</aside>
<main class="main">
  <div id="p-dash" class="panel active">
    <div class="welcome"><h1 id="wTitle">Welcome back</h1><p>YOUR STORE AT A GLANCE · REALTIME LOCAL DATA</p></div>
    <div class="stats">
      <div class="stat"><div class="l">Open orders</div><div class="v" id="sOpen">0</div></div>
      <div class="stat"><div class="l">Today sales</div><div class="v" id="sSales">0</div></div>
      <div class="stat"><div class="l">Menu items</div><div class="v" id="sMenu">0</div></div>
      <div class="stat"><div class="l">Inventory</div><div class="v" id="sInv">0</div></div>
    </div>
    <div class="card"><h3>Open orders preview</h3><div id="dashOrders" class="muted">Loading…</div></div>
  </div>
  <div id="p-orders" class="panel card">
    <h3>Open orders</h3>
    <table><thead><tr><th>#</th><th>Table</th><th>Status</th><th>Total</th></tr></thead><tbody id="tbOrders"></tbody></table>
  </div>
  <div id="p-menu" class="panel card">
    <h3>Menu (prices use bill currency)</h3>
    <p class="muted">Change currency under <strong>Bill & printers</strong> — all menu rates update.</p>
    <table><thead><tr><th>Name</th><th>Price</th></tr></thead><tbody id="tbMenu"></tbody></table>
  </div>
  <div id="p-inv" class="panel card">
    <h3>Inventory</h3>
    <div class="row">
      <input id="invName" placeholder="Item name" style="max-width:180px"/>
      <input id="invQty" placeholder="Qty" type="number" style="max-width:90px"/>
      <input id="invUnit" placeholder="Unit" value="pcs" style="max-width:80px"/>
      <button onclick="addInv()">Add item</button>
    </div>
    <p class="muted">Import CSV (Excel → Save as CSV): name, quantity, unit, lowStock</p>
    <textarea id="invCsv" rows="4" placeholder="name,quantity,unit,lowStock"></textarea>
    <button onclick="importCsv()">Import / merge</button>
    <table><thead><tr><th>Name</th><th>Qty</th><th>Unit</th><th></th></tr></thead><tbody id="tbInv"></tbody></table>
  </div>
  <div id="p-bill" class="panel card">
    <h3>Bill profile & currency</h3>
    <label class="muted">Restaurant name</label><input id="bName"/>
    <label class="muted">Address</label><input id="bAddr"/>
    <label class="muted">Phone</label><input id="bPhone"/>
    <label class="muted">Tax ID</label><input id="bTax"/>
    <label class="muted">Footer</label><input id="bFooter"/>
    <label class="muted">Menu & bill currency symbol</label>
    <input id="bCur" style="max-width:100px"/>
    <div>
      <span class="chip" onclick="setCur('$')">$</span>
      <span class="chip" onclick="setCur('€')">€</span>
      <span class="chip" onclick="setCur('£')">£</span>
      <span class="chip" onclick="setCur('Rs')">Rs</span>
      <span class="chip" onclick="setCur('RM')">RM</span>
      <span class="chip" onclick="setCur('AED')">AED</span>
      <span class="chip" onclick="setCur('₹')">₹</span>
    </div>
    <label class="muted">Kitchen printer IP</label><input id="bKitchen"/>
    <label class="muted">Cashier printer IP</label><input id="bCashier"/>
    <button onclick="saveBill()">Save bill & printers</button>
  </div>
</main>
</div>
<script>
const join=document.getElementById('join'); join.textContent=location.origin;
let state={orders:[],menuItems:[],inventory:[],bill:{}};
function go(id,btn){
  document.querySelectorAll('.panel').forEach(p=>p.classList.remove('active'));
  document.getElementById('p-'+id).classList.add('active');
  document.querySelectorAll('.nav').forEach(n=>n.classList.remove('active'));
  if(btn) btn.classList.add('active');
}
function setCur(s){ document.getElementById('bCur').value=s; }
async function load(){
  try{ const r=await fetch('/state'); state=await r.json(); render(); }catch(e){ console.error(e); }
}
function money(a){ const s=(state.bill&&state.bill.currencySymbol)||'$'; return s+((a||0)/100).toFixed(2); }
function orderTotal(o){ let t=0; (o.items||[]).forEach(i=>{ t+=(i.unitPrice&&i.unitPrice.amount||0)*(i.quantity||1); }); return t; }
function render(){
  const open=(state.orders||[]).filter(o=>!o.isPaid && o.status!=='cancelled');
  const today=new Date().toISOString().slice(0,10);
  let sales=0;
  (state.orders||[]).forEach(o=>{ if(o.isPaid && o.paidAt && o.paidAt.slice(0,10)===today) sales+=orderTotal(o); });
  document.getElementById('sOpen').textContent=open.length;
  document.getElementById('sSales').textContent=money(sales);
  document.getElementById('sMenu').textContent=(state.menuItems||[]).length;
  document.getElementById('sInv').textContent=(state.inventory||[]).length;
  const name=(state.bill&&state.bill.restaurantName)||state.restaurantName||'Main device';
  document.getElementById('wTitle').textContent='Welcome back, '+name;
  document.getElementById('tbOrders').innerHTML=open.map(o=>'<tr><td>#'+o.orderNumber+'</td><td>'+(o.tableNumber||o.ticketNumber||'—')+'</td><td>'+o.status+'</td><td>'+money(orderTotal(o))+'</td></tr>').join('')||'<tr><td colspan=4 class=muted>No open orders</td></tr>';
  document.getElementById('dashOrders').innerHTML=open.slice(0,6).map(o=>'<div style="padding:.4rem 0;border-bottom:1px solid var(--border)"><strong>#'+o.orderNumber+'</strong> · '+(o.tableNumber||'—')+' · '+money(orderTotal(o))+'</div>').join('')||'<span class="muted">No open orders</span>';
  document.getElementById('tbMenu').innerHTML=(state.menuItems||[]).map(m=>'<tr><td>'+m.name+'</td><td><strong>'+money(m.price&&m.price.amount)+'</strong></td></tr>').join('')||'<tr><td colspan=2 class=muted>No menu items</td></tr>';
  document.getElementById('tbInv').innerHTML=(state.inventory||[]).map(i=>{
    const low=i.quantity<=i.lowStockThreshold?' low':'';
    return '<tr><td>'+i.name+'</td><td class="'+low+'">'+i.quantity+'</td><td>'+(i.unit||'pcs')+'</td><td><button class="ghost" onclick="setQty(\''+i.id+'\','+i.quantity+')">Edit</button> <button class="danger" onclick="delInv(\''+i.id+'\')">Del</button></td></tr>';
  }).join('');
  const b=state.bill||{};
  document.getElementById('bName').value=b.restaurantName||state.restaurantName||'';
  document.getElementById('bAddr').value=b.address||'';
  document.getElementById('bPhone').value=b.phone||'';
  document.getElementById('bTax').value=b.taxId||'';
  document.getElementById('bFooter').value=b.footer||'Thank you!';
  document.getElementById('bCur').value=b.currencySymbol||'$';
  document.getElementById('bKitchen').value=state.kitchenPrinterIp||'';
  document.getElementById('bCashier').value=state.cashierPrinterIp||'';
}
async function post(type,payload){
  await fetch('/api/event',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({type,deviceId:'web-pc',payload})});
  await load();
}
async function addInv(){
  const name=document.getElementById('invName').value.trim();
  if(!name) return alert('Name required');
  const quantity=parseFloat(document.getElementById('invQty').value)||0;
  const unit=document.getElementById('invUnit').value||'pcs';
  await post('inventory.upsert',{id:crypto.randomUUID(),name,unit,quantity,lowStockThreshold:5,linkedMenuItemId:null});
  document.getElementById('invName').value='';
}
async function setQty(id,cur){
  const v=prompt('New quantity', String(cur)); if(v===null) return;
  const item=(state.inventory||[]).find(i=>i.id===id); if(!item) return;
  item.quantity=parseFloat(v)||0;
  await post('inventory.upsert',item);
}
async function delInv(id){ if(confirm('Delete?')) await post('inventory.delete',{id}); }
async function importCsv(){
  const raw=document.getElementById('invCsv').value;
  if(!raw.trim()) return;
  const lines=raw.split(/\r?\n/).filter(l=>l.trim());
  let start=0; if(lines[0]&&/name/i.test(lines[0])) start=1;
  for(let i=start;i<lines.length;i++){
    const p=lines[i].split(/[,;\t]/);
    const name=(p[0]||'').trim(); if(!name) continue;
    const quantity=parseFloat((p[1]||'0').replace(',',''))||0;
    const unit=(p[2]||'pcs').trim()||'pcs';
    const low=parseFloat((p[3]||'5').replace(',',''))||5;
    await post('inventory.upsert',{id:crypto.randomUUID(),name,unit,quantity,lowStockThreshold:low,linkedMenuItemId:null});
  }
  alert('Import done');
}
async function saveBill(){
  await post('settings.update',{
    bill:{restaurantName:document.getElementById('bName').value,address:document.getElementById('bAddr').value,phone:document.getElementById('bPhone').value,taxId:document.getElementById('bTax').value,footer:document.getElementById('bFooter').value,currencySymbol:document.getElementById('bCur').value||'$'},
    kitchenPrinterIp:document.getElementById('bKitchen').value||null,
    cashierPrinterIp:document.getElementById('bCashier').value||null
  });
  alert('Saved — menu prices now use '+document.getElementById('bCur').value);
}
load(); setInterval(load, 4000);
</script></body></html>
''';
