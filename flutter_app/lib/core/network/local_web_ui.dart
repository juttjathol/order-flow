/// Local web dashboard served by Main device at http://IP:8787/
const String kLocalDashboardHtml = r'''
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Order Flow · Main</title>
<style>
:root{--bg:#0b1220;--card:#1e293b;--border:#334155;--text:#f1f5f9;--muted:#94a3b8;--primary:#0ea5e9;--ok:#14b8a6;--warn:#f59e0b}
*{box-sizing:border-box}body{margin:0;font-family:system-ui,sans-serif;background:var(--bg);color:var(--text)}
.wrap{max-width:1100px;margin:0 auto;padding:1.25rem}
header{display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem;flex-wrap:wrap;gap:.75rem}
h1{margin:0;font-size:1.35rem} .muted{color:var(--muted);font-size:.85rem}
.tabs{display:flex;gap:.4rem;flex-wrap:wrap;margin-bottom:1rem}
.tab{background:var(--card);border:1px solid var(--border);color:var(--text);padding:.45rem .9rem;border-radius:999px;cursor:pointer}
.tab.active{background:linear-gradient(135deg,#0ea5e9,#14b8a6);color:#0b1220;font-weight:700;border:none}
.card{background:var(--card);border:1px solid var(--border);border-radius:14px;padding:1rem;margin-bottom:1rem}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:.75rem;margin-bottom:1rem}
.stat{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:.9rem}
.stat .v{font-size:1.4rem;font-weight:800;color:var(--primary)}
table{width:100%;border-collapse:collapse;font-size:.9rem}
th,td{text-align:left;padding:.5rem;border-bottom:1px solid var(--border)}
input,textarea,select{width:100%;background:#0f172a;border:1px solid var(--border);color:var(--text);border-radius:8px;padding:.5rem;margin:.25rem 0 .6rem}
button{background:linear-gradient(135deg,#0ea5e9,#14b8a6);border:none;color:#0b1220;font-weight:700;padding:.5rem 1rem;border-radius:8px;cursor:pointer;margin:.2rem}
button.ghost{background:transparent;border:1px solid var(--border);color:var(--text)}
button.danger{background:#ef4444;color:#fff}
.row{display:flex;gap:.5rem;flex-wrap:wrap;align-items:center}
.hidden{display:none}
code{color:var(--primary)}
.low{color:var(--warn);font-weight:700}
</style></head><body><div class="wrap">
<header>
  <div><h1>Order Flow</h1><p class="muted">PC main dashboard · live from this device</p></div>
  <div class="muted">Connect phones to <code id="join"></code></div>
</header>
<div class="stats">
  <div class="stat"><div class="muted">Open orders</div><div class="v" id="sOpen">0</div></div>
  <div class="stat"><div class="muted">Today sales</div><div class="v" id="sSales">0</div></div>
  <div class="stat"><div class="muted">Menu</div><div class="v" id="sMenu">0</div></div>
  <div class="stat"><div class="muted">Inventory</div><div class="v" id="sInv">0</div></div>
</div>
<div class="tabs">
  <button class="tab active" data-t="orders">Orders</button>
  <button class="tab" data-t="menu">Menu</button>
  <button class="tab" data-t="inv">Inventory</button>
  <button class="tab" data-t="bill">Bill & printers</button>
</div>
<div id="p-orders" class="card">
  <h3>Orders</h3>
  <table><thead><tr><th>#</th><th>Table</th><th>Status</th><th>Total</th></tr></thead><tbody id="tbOrders"></tbody></table>
</div>
<div id="p-menu" class="card hidden">
  <h3>Menu</h3>
  <table><thead><tr><th>Name</th><th>Price</th></tr></thead><tbody id="tbMenu"></tbody></table>
</div>
<div id="p-inv" class="card hidden">
  <h3>Inventory</h3>
  <div class="row">
    <input id="invName" placeholder="Item name" style="max-width:180px"/>
    <input id="invQty" placeholder="Qty" type="number" style="max-width:90px"/>
    <input id="invUnit" placeholder="Unit" value="pcs" style="max-width:80px"/>
    <button onclick="addInv()">Add item</button>
  </div>
  <p class="muted">Import CSV (Excel → Save as CSV). Columns: name, quantity, unit, lowStock</p>
  <textarea id="invCsv" rows="4" placeholder="name,quantity,unit,lowStock"></textarea>
  <div class="row">
    <button onclick="importCsv()">Import / merge</button>
  </div>
  <table><thead><tr><th>Name</th><th>Qty</th><th>Unit</th><th></th></tr></thead><tbody id="tbInv"></tbody></table>
</div>
<div id="p-bill" class="card hidden">
  <h3>Bill profile (customer receipt)</h3>
  <label class="muted">Restaurant name</label><input id="bName"/>
  <label class="muted">Address</label><input id="bAddr"/>
  <label class="muted">Phone</label><input id="bPhone"/>
  <label class="muted">Tax ID</label><input id="bTax"/>
  <label class="muted">Footer</label><input id="bFooter"/>
  <label class="muted">Currency</label><input id="bCur" style="max-width:80px"/>
  <label class="muted">Kitchen printer IP</label><input id="bKitchen"/>
  <label class="muted">Cashier printer IP</label><input id="bCashier"/>
  <button onclick="saveBill()">Save bill & printers</button>
</div>
<footer class="muted" style="text-align:center;margin-top:1.5rem">Order Flow · local network</footer>
</div>
<script>
const join=document.getElementById('join'); join.textContent=location.origin;
let state={orders:[],menuItems:[],inventory:[],bill:{}};
document.querySelectorAll('.tab').forEach(t=>t.onclick=()=>{
  document.querySelectorAll('.tab').forEach(x=>x.classList.remove('active')); t.classList.add('active');
  ['orders','menu','inv','bill'].forEach(id=>{
    document.getElementById('p-'+id).classList.toggle('hidden', t.dataset.t!==id);
  });
});
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
  document.getElementById('tbOrders').innerHTML=open.map(o=>'<tr><td>#'+o.orderNumber+'</td><td>'+(o.tableNumber||o.ticketNumber||'—')+'</td><td>'+o.status+'</td><td>'+money(orderTotal(o))+'</td></tr>').join('')||'<tr><td colspan=4 class=muted>No open orders</td></tr>';
  document.getElementById('tbMenu').innerHTML=(state.menuItems||[]).map(m=>'<tr><td>'+m.name+'</td><td>'+money(m.price&&m.price.amount)+'</td></tr>').join('');
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
  const q=prompt('New quantity', cur); if(q===null) return;
  const item=(state.inventory||[]).find(i=>i.id===id); if(!item) return;
  item.quantity=parseFloat(q)||0;
  await post('inventory.upsert',item);
}
async function delInv(id){ if(confirm('Delete?')) await post('inventory.delete',{id}); }
async function importCsv(){
  const raw=document.getElementById('invCsv').value;
  const lines=raw.split(/[\r\n]+/).map(l=>l.trim()).filter(Boolean);
  let i=0; if(lines[0] && /name/i.test(lines[0])) i=1;
  for(;i<lines.length;i++){
    const p=lines[i].split(/[,;\t]/).map(x=>x.trim());
    if(!p[0]) continue;
    await post('inventory.upsert',{id:crypto.randomUUID(),name:p[0],quantity:parseFloat(p[1])||0,unit:p[2]||'pcs',lowStockThreshold:parseFloat(p[3])||5,linkedMenuItemId:null});
  }
  alert('Import done');
}
async function saveBill(){
  await post('settings.update',{
    bill:{restaurantName:document.getElementById('bName').value,address:document.getElementById('bAddr').value,phone:document.getElementById('bPhone').value,taxId:document.getElementById('bTax').value,footer:document.getElementById('bFooter').value,currencySymbol:document.getElementById('bCur').value||'$'},
    kitchenPrinterIp:document.getElementById('bKitchen').value||null,
    cashierPrinterIp:document.getElementById('bCashier').value||null
  });
  alert('Saved');
}
load(); setInterval(load, 4000);
</script></body></html>
''';
