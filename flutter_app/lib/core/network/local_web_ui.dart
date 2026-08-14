/// Local web dashboard served by Main device at http://IP:8787/
const String kLocalDashboardHtml = r'''
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Order Flow · Main</title>
<style>
:root,[data-theme="light"]{
  --bg:#f4f6f9;--sidebar:#fff;--card:#fff;--border:#e8ecf1;--text:#1e293b;--muted:#64748b;
  --accent:#f97316;--ok:#16a34a;--warn:#d97706;--danger:#dc2626;--input:#fff;--hover:#f1f5f9;
  --shadow:0 1px 3px rgba(15,23,42,.06),0 8px 24px rgba(15,23,42,.04);--radius:14px;--code-bg:#f1f5f9
}
[data-theme="dark"]{
  --bg:#0f1419;--sidebar:#161b22;--card:#1c2128;--border:#30363d;--text:#e6edf3;--muted:#8b949e;
  --accent:#ff7a1a;--ok:#3fb950;--warn:#d29922;--danger:#f85149;--input:#0d1117;--hover:#21262d;
  --shadow:0 1px 3px rgba(0,0,0,.3);--radius:14px;--code-bg:#21262d
}
*{box-sizing:border-box}body{margin:0;font-family:"Segoe UI",system-ui,sans-serif;background:var(--bg);color:var(--text);line-height:1.5}
.shell{display:flex;min-height:100vh}
.sidebar{width:220px;background:var(--sidebar);border-right:1px solid var(--border);padding:1.1rem .8rem;position:sticky;top:0;height:100vh;display:flex;flex-direction:column;gap:.2rem}
.brand{display:flex;align-items:center;gap:.55rem;padding:.35rem .65rem 1rem;font-weight:800;font-size:1.1rem}
.brand-mark{width:30px;height:30px;border-radius:9px;background:linear-gradient(135deg,var(--accent),#fb923c);color:#fff;display:grid;place-items:center;font-size:12px;font-weight:800}
.nav-item{display:flex;align-items:center;gap:.55rem;padding:.6rem .8rem;border-radius:10px;border:none;background:transparent;width:100%;text-align:left;font:inherit;font-weight:500;cursor:pointer;color:var(--text)}
.nav-item:hover{background:var(--hover)}
.nav-item.active{background:var(--accent);color:#fff;font-weight:700;box-shadow:0 4px 14px rgba(249,115,22,.35)}
.main{flex:1;min-width:0;padding:1.25rem 1.5rem;max-width:1100px}
.welcome{background:linear-gradient(135deg,#f97316 0%,#ea580c 55%,#c2410c 100%);border-radius:18px;padding:1.4rem 1.5rem;color:#fff;margin-bottom:1.1rem;box-shadow:0 12px 28px rgba(234,88,12,.25)}
.welcome h1{margin:0 0 .25rem;font-size:1.4rem;font-weight:800}
.welcome p{margin:0;opacity:.9;font-size:.92rem}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:.85rem;margin-bottom:1.1rem}
.stat{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1rem 1.1rem;box-shadow:var(--shadow)}
.stat .label{font-size:.78rem;color:var(--muted);font-weight:600;margin-bottom:.25rem}
.stat .v{font-size:1.45rem;font-weight:800;letter-spacing:-.02em}
.card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.15rem;margin-bottom:1rem;box-shadow:var(--shadow)}
.card h3{margin:0 0 .85rem;font-size:1.05rem;font-weight:700}
.muted{color:var(--muted);font-size:.85rem}
table{width:100%;border-collapse:collapse;font-size:.9rem}
th,td{text-align:left;padding:.65rem .4rem;border-bottom:1px solid var(--border)}
th{color:var(--muted);font-weight:600;font-size:.78rem;text-transform:uppercase;letter-spacing:.03em}
input,textarea,select{width:100%;background:var(--input);border:1px solid var(--border);color:var(--text);border-radius:10px;padding:.55rem .75rem;margin:.25rem 0 .55rem;font:inherit}
input:focus,textarea:focus{outline:2px solid rgba(249,115,22,.3);border-color:var(--accent)}
button{background:var(--accent);border:none;color:#fff;font-weight:700;padding:.55rem 1rem;border-radius:10px;cursor:pointer;margin:.15rem;font:inherit}
button:hover{filter:brightness(1.06)}
button.ghost{background:var(--hover);border:1px solid var(--border);color:var(--text)}
button.danger{background:var(--danger);color:#fff}
.row{display:flex;gap:.5rem;flex-wrap:wrap;align-items:center}
.hidden{display:none}
code{background:var(--code-bg);padding:.1rem .4rem;border-radius:6px;font-size:.85rem}
.low{color:var(--warn);font-weight:700}
.chip{display:inline-flex;align-items:center;padding:.35rem .7rem;border-radius:999px;border:1px solid var(--border);background:var(--card);cursor:pointer;font-weight:600;font-size:.85rem;margin:.15rem;color:var(--text)}
.chip.active{background:var(--accent);color:#fff;border-color:var(--accent)}
.panel{display:none}.panel.active{display:block}
.side-foot{margin-top:auto;padding-top:.5rem}
@media(max-width:800px){.shell{flex-direction:column}.sidebar{width:100%;height:auto;position:relative;border-right:none;border-bottom:1px solid var(--border);flex-direction:row;flex-wrap:wrap}}
</style></head><body>
<script>document.documentElement.setAttribute('data-theme',localStorage.getItem('of_pc_theme')||'light');</script>
<div class="shell">
<aside class="sidebar">
  <div class="brand"><div class="brand-mark">OF</div><span>Order Flow</span></div>
  <button class="nav-item active" data-t="orders" onclick="tab('orders')">📋 Orders</button>
  <button class="nav-item" data-t="menu" onclick="tab('menu')">🍽 Menu</button>
  <button class="nav-item" data-t="inv" onclick="tab('inv')">📦 Inventory</button>
  <button class="nav-item" data-t="bill" onclick="tab('bill')">🧾 Bill & printers</button>
  <div class="side-foot">
    <button class="nav-item" type="button" onclick="toggleTheme()">◐ Light / Dark</button>
  </div>
</aside>
<div class="main">
  <div class="welcome">
    <h1 id="welcomeTitle">Main device dashboard</h1>
    <p>Live from this device · phones join at <code id="join" style="background:rgba(255,255,255,.2);color:#fff"></code></p>
  </div>
  <div class="stats">
    <div class="stat"><div class="label">Open orders</div><div class="v" id="sOpen">0</div></div>
    <div class="stat"><div class="label">Today sales</div><div class="v" id="sSales">0</div></div>
    <div class="stat"><div class="label">Menu items</div><div class="v" id="sMenu">0</div></div>
    <div class="stat"><div class="label">Inventory</div><div class="v" id="sInv">0</div></div>
  </div>

  <div id="p-orders" class="panel active card">
    <h3>Open orders</h3>
    <table><thead><tr><th>#</th><th>Table</th><th>Status</th><th>Total</th></tr></thead><tbody id="tbOrders"></tbody></table>
  </div>

  <div id="p-menu" class="panel card">
    <h3>Menu prices <span class="muted" id="menuCurHint"></span></h3>
    <p class="muted" style="margin-bottom:.75rem">Prices use the currency you set under Bill &amp; printers. Change currency there — menu &amp; bills update together.</p>
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
    <p class="muted">Import CSV (Excel → Save as CSV). Columns: name, quantity, unit, lowStock</p>
    <textarea id="invCsv" rows="4" placeholder="name,quantity,unit,lowStock&#10;Flour,25,kg,5"></textarea>
    <div class="row">
      <button onclick="importCsv(false)">Import / merge</button>
      <button class="ghost" onclick="importCsv(true)">Replace all</button>
    </div>
    <table><thead><tr><th>Name</th><th>Qty</th><th>Unit</th><th></th></tr></thead><tbody id="tbInv"></tbody></table>
  </div>

  <div id="p-bill" class="panel card">
    <h3>Bill profile &amp; currency</h3>
    <p class="muted" style="margin-bottom:.75rem">Currency symbol is used on menu, cart, kitchen tickets, and customer bills.</p>
    <label class="muted">Restaurant name</label><input id="bName"/>
    <label class="muted">Address</label><input id="bAddr"/>
    <label class="muted">Phone</label><input id="bPhone"/>
    <label class="muted">Tax ID</label><input id="bTax"/>
    <label class="muted">Footer</label><input id="bFooter"/>
    <label class="muted">Currency for menu &amp; bills</label>
    <div class="row" style="margin:.35rem 0 .75rem" id="curChips">
      <span class="chip" data-sym="$" onclick="pickCur(this)">$ USD</span>
      <span class="chip" data-sym="€" onclick="pickCur(this)">€ EUR</span>
      <span class="chip" data-sym="£" onclick="pickCur(this)">£ GBP</span>
      <span class="chip" data-sym="Rs" onclick="pickCur(this)">Rs PKR</span>
      <span class="chip" data-sym="RM" onclick="pickCur(this)">RM MYR</span>
      <span class="chip" data-sym="AED" onclick="pickCur(this)">AED</span>
      <span class="chip" data-sym="₹" onclick="pickCur(this)">₹ INR</span>
    </div>
    <input id="bCur" placeholder="or type symbol" style="max-width:120px"/>
    <label class="muted">Kitchen printer IP</label><input id="bKitchen"/>
    <label class="muted">Cashier printer IP</label><input id="bCashier"/>
    <button onclick="saveBill()">Save bill, currency &amp; printers</button>
  </div>
</div>
</div>
<script>
const join=document.getElementById('join'); join.textContent=location.origin;
let state={orders:[],menuItems:[],inventory:[],bill:{},kitchenPrinterIp:'',cashierPrinterIp:''};
function toggleTheme(){
  const cur=document.documentElement.getAttribute('data-theme')||'light';
  const next=cur==='dark'?'light':'dark';
  document.documentElement.setAttribute('data-theme',next);
  localStorage.setItem('of_pc_theme',next);
}
function tab(name){
  document.querySelectorAll('.nav-item[data-t]').forEach(x=>x.classList.toggle('active',x.dataset.t===name));
  ['orders','menu','inv','bill'].forEach(id=>{
    document.getElementById('p-'+id).classList.toggle('active', id===name);
  });
}
function pickCur(el){
  document.querySelectorAll('#curChips .chip').forEach(c=>c.classList.remove('active'));
  el.classList.add('active');
  document.getElementById('bCur').value=el.dataset.sym;
}
async function load(){
  try{
    const r=await fetch('/state'); state=await r.json();
    render();
  }catch(e){ console.error(e); }
}
function money(a){ const s=(state.bill&&state.bill.currencySymbol)||'$'; return s+((a||0)/100).toFixed(2); }
function orderTotal(o){
  let t=0; (o.items||[]).forEach(i=>{ t+=(i.unitPrice&&i.unitPrice.amount||0)*(i.quantity||1); }); return t;
}
function render(){
  const open=(state.orders||[]).filter(o=>!o.isPaid && o.status!=='cancelled');
  const today=new Date().toISOString().slice(0,10);
  let sales=0;
  (state.orders||[]).forEach(o=>{
    if(o.isPaid && o.paidAt && o.paidAt.slice(0,10)===today){ sales+=orderTotal(o); }
  });
  const sym=(state.bill&&state.bill.currencySymbol)||'$';
  document.getElementById('sOpen').textContent=open.length;
  document.getElementById('sSales').textContent=money(sales);
  document.getElementById('sMenu').textContent=(state.menuItems||[]).length;
  document.getElementById('sInv').textContent=(state.inventory||[]).length;
  document.getElementById('menuCurHint').textContent='· showing '+sym;
  document.getElementById('tbOrders').innerHTML=open.map(o=>`<tr><td>#${o.orderNumber}</td><td>${o.tableNumber||o.ticketNumber||'—'}</td><td>${o.status}</td><td>${money(orderTotal(o))}</td></tr>`).join('')||'<tr><td colspan=4 class=muted>No open orders</td></tr>';
  document.getElementById('tbMenu').innerHTML=(state.menuItems||[]).map(m=>`<tr><td>${m.name}</td><td><strong>${money(m.price&&m.price.amount)}</strong></td></tr>`).join('')||'<tr><td colspan=2 class=muted>No menu items</td></tr>';
  document.getElementById('tbInv').innerHTML=(state.inventory||[]).map(i=>{
    const low=i.quantity<=i.lowStockThreshold?' low':'';
    return `<tr><td>${i.name}</td><td class="${low}">${i.quantity}</td><td>${i.unit||'pcs'}</td>
    <td><button class="ghost" onclick="setQty('${i.id}',${i.quantity})">Edit</button>
    <button class="danger" onclick="delInv('${i.id}')">Del</button></td></tr>`;
  }).join('');
  const b=state.bill||{};
  document.getElementById('bName').value=b.restaurantName||state.restaurantName||'';
  document.getElementById('bAddr').value=b.address||'';
  document.getElementById('bPhone').value=b.phone||'';
  document.getElementById('bTax').value=b.taxId||'';
  document.getElementById('bFooter').value=b.footer||'Thank you!';
  document.getElementById('bCur').value=b.currencySymbol||'$';
  document.querySelectorAll('#curChips .chip').forEach(c=>{
    c.classList.toggle('active', c.dataset.sym===(b.currencySymbol||'$'));
  });
  document.getElementById('bKitchen').value=state.kitchenPrinterIp||'';
  document.getElementById('bCashier').value=state.cashierPrinterIp||'';
  if(b.restaurantName) document.getElementById('welcomeTitle').textContent=b.restaurantName;
}
async function post(type,payload){
  await fetch('/api/event',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({type,deviceId:'web-pc',payload})});
  await load();
}
async function addInv(){
  const name=document.getElementById('invName').value.trim();
  if(!name) return alert('Name required');
  const quantity=parseFloat(document.getElementById('invQty').value)||0;
  const unit=document.getElementById('invUnit').value||'pcs';
  const id=crypto.randomUUID();
  await post('inventory.upsert',{id,name,unit,quantity,lowStockThreshold:5,linkedMenuItemId:null});
  document.getElementById('invName').value='';
}
async function setQty(id,cur){
  const q=prompt('New quantity', cur); if(q===null) return;
  const item=(state.inventory||[]).find(i=>i.id===id); if(!item) return;
  item.quantity=parseFloat(q)||0;
  await post('inventory.upsert',item);
}
async function delInv(id){ if(confirm('Delete?')) await post('inventory.delete',{id}); }
async function importCsv(replace){
  const raw=document.getElementById('invCsv').value;
  const lines=raw.split(/[\r\n]+/).map(l=>l.trim()).filter(Boolean);
  let i=0; if(lines[0] && /name/i.test(lines[0])) i=1;
  for(;i<lines.length;i++){
    const p=lines[i].split(/[,;\t]/).map(x=>x.trim());
    if(!p[0]) continue;
    await post('inventory.upsert',{
      id:crypto.randomUUID(), name:p[0], quantity:parseFloat(p[1])||0,
      unit:p[2]||'pcs', lowStockThreshold:parseFloat(p[3])||5, linkedMenuItemId:null
    });
  }
  alert('Import done');
}
async function saveBill(){
  const sym=document.getElementById('bCur').value.trim()||'$';
  await post('settings.update',{
    bill:{
      restaurantName:document.getElementById('bName').value,
      address:document.getElementById('bAddr').value,
      phone:document.getElementById('bPhone').value,
      taxId:document.getElementById('bTax').value,
      footer:document.getElementById('bFooter').value,
      currencySymbol:sym
    },
    kitchenPrinterIp:document.getElementById('bKitchen').value||null,
    cashierPrinterIp:document.getElementById('bCashier').value||null
  });
  alert('Saved — menu & bills now use '+sym);
}
load(); setInterval(load, 4000);
</script></body></html>
''';
