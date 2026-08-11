/**
 * Order Flow – Cloudflare Worker
 * Admin auth, customers, licenses, validation, GitHub releases
 */
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}
function error(msg, status = 400) {
  return json({ error: msg }, status);
}

async function signJwt(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const enc = new TextEncoder();
  const b64 = (obj) => btoa(String.fromCharCode(...enc.encode(JSON.stringify(obj))))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const head = b64(header);
  const body = b64(payload);
  const data = `${head}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${data}.${sigB64}`;
}

async function verifyJwt(token, secret) {
  try {
    const [head, body, sig] = token.split('.');
    const data = `${head}.${body}`;
    const enc = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
    );
    const sigBytes = Uint8Array.from(atob(sig.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));
    const ok = await crypto.subtle.verify('HMAC', key, sigBytes, enc.encode(data));
    if (!ok) return null;
    const payload = JSON.parse(atob(body.replace(/-/g, '+').replace(/_/g, '/')));
    if (payload.exp && Date.now() / 1000 > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

function generateLicenseKey() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let key = '';
  for (let i = 0; i < 4; i++) {
    if (i > 0) key += '-';
    for (let j = 0; j < 4; j++) key += chars[Math.floor(Math.random() * chars.length)];
  }
  return key;
}

async function hashPassword(password) {
  const enc = new TextEncoder();
  const data = enc.encode(password + 'orderflow-salt');
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    const url = new URL(request.url);
    const path = url.pathname;
    const secret = env.JWT_SECRET || 'dev-secret-change-me-in-production';

    if (path === '/api/v1/license/validate' && request.method === 'POST') {
      try {
        const body = await request.json();
        const { licenseKey, deviceId } = body;
        if (!licenseKey) return error('licenseKey required');
        const row = await env.DB.prepare(
          'SELECT l.*, c.name as customer_name FROM licenses l JOIN customers c ON c.id = l.customer_id WHERE l.license_key = ?'
        ).bind(licenseKey).first();
        if (!row) return error('Invalid license', 401);
        if (!row.is_active) return error('License revoked', 403);
        if (new Date(row.expires_at) < new Date()) return error('License expired', 403);
        await env.DB.prepare(
          'UPDATE licenses SET last_validated_at = datetime(\'now\'), validation_count = validation_count + 1 WHERE id = ?'
        ).bind(row.id).run();
        return json({
          valid: true,
          customerId: row.customer_id,
          customerName: row.customer_name,
          expiresAt: row.expires_at,
          maxDevices: row.max_devices,
        });
      } catch (e) {
        return error(e.message, 500);
      }
    }

    if (path === '/api/v1/releases/latest' && request.method === 'GET') {
      const repo = env.GITHUB_REPO || 'juttjathol/order-flow';
      try {
        const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
          headers: { 'User-Agent': 'Order-Flow-Dashboard', 'Accept': 'application/vnd.github+json' },
        });
        if (!res.ok) return json({ tag: null, assets: [] });
        const data = await res.json();
        const assets = (data.assets || []).map(a => ({
          name: a.name, downloadUrl: a.browser_download_url, size: a.size,
        }));
        return json({ tag: data.tag_name, name: data.name, publishedAt: data.published_at, body: data.body, assets });
      } catch (e) {
        return error('Could not fetch releases', 502);
      }
    }

    if (path === '/api/v1/admin/login' && request.method === 'POST') {
      const body = await request.json();
      const { email, password } = body;
      if (!email || !password) return error('email & password required');
      let admin = await env.DB.prepare('SELECT * FROM admins WHERE email = ?').bind(email).first();
      if (!admin && email === (env.ADMIN_EMAIL || 'admin@example.com')) {
        const id = crypto.randomUUID();
        const hash = await hashPassword(password);
        await env.DB.prepare('INSERT INTO admins (id, email, password_hash, name) VALUES (?, ?, ?, ?)').bind(id, email, hash, 'Admin').run();
        admin = { id, email, password_hash: hash, name: 'Admin' };
      }
      if (!admin) return error('Invalid credentials', 401);
      const hash = await hashPassword(password);
      if (hash !== admin.password_hash) return error('Invalid credentials', 401);
      const token = await signJwt({
        sub: admin.id, email: admin.email,
        exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 7,
      }, secret);
      return json({ token, admin: { id: admin.id, email: admin.email, name: admin.name } });
    }

    const auth = request.headers.get('Authorization') || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    const payload = token ? await verifyJwt(token, secret) : null;
    if (!payload) return error('Unauthorized', 401);

    if (path === '/api/v1/customers' && request.method === 'GET') {
      const { results } = await env.DB.prepare(
        'SELECT c.*, (SELECT COUNT(*) FROM licenses l WHERE l.customer_id = c.id AND l.is_active = 1) as active_licenses FROM customers c ORDER BY created_at DESC'
      ).all();
      return json({ customers: results });
    }
    if (path === '/api/v1/customers' && request.method === 'POST') {
      const body = await request.json();
      const id = crypto.randomUUID();
      await env.DB.prepare('INSERT INTO customers (id, name, contact_email, contact_phone, notes) VALUES (?, ?, ?, ?, ?)').bind(id, body.name, body.contact_email || null, body.contact_phone || null, body.notes || null).run();
      return json({ id, ...body }, 201);
    }
    if (path === '/api/v1/licenses' && request.method === 'POST') {
      const body = await request.json();
      const { customerId, expiresAt, maxDevices = 20 } = body;
      if (!customerId || !expiresAt) return error('customerId and expiresAt required');
      const id = crypto.randomUUID();
      const key = generateLicenseKey();
      await env.DB.prepare('INSERT INTO licenses (id, customer_id, license_key, expires_at, max_devices) VALUES (?, ?, ?, ?, ?)').bind(id, customerId, key, expiresAt, maxDevices).run();
      return json({ id, licenseKey: key, customerId, expiresAt, maxDevices }, 201);
    }
    if (path === '/api/v1/licenses' && request.method === 'GET') {
      const customerId = url.searchParams.get('customerId');
      let q = 'SELECT l.*, c.name as customer_name FROM licenses l JOIN customers c ON c.id = l.customer_id';
      if (customerId) q += ' WHERE l.customer_id = ?';
      q += ' ORDER BY l.created_at DESC';
      const stmt = env.DB.prepare(q);
      const { results } = customerId ? await stmt.bind(customerId).all() : await stmt.all();
      return json({ licenses: results });
    }
    if (path.startsWith('/api/v1/licenses/') && request.method === 'PUT') {
      const id = path.split('/').pop();
      const body = await request.json();
      if (body.is_active !== undefined) {
        await env.DB.prepare('UPDATE licenses SET is_active = ? WHERE id = ?').bind(body.is_active ? 1 : 0, id).run();
      }
      if (body.expires_at) {
        await env.DB.prepare('UPDATE licenses SET expires_at = ? WHERE id = ?').bind(body.expires_at, id).run();
      }
      return json({ ok: true });
    }
    if (path === '/api/v1/stats' && request.method === 'GET') {
      const customers = await env.DB.prepare('SELECT COUNT(*) as c FROM customers').first();
      const activeLicenses = await env.DB.prepare("SELECT COUNT(*) as c FROM licenses WHERE is_active = 1 AND expires_at > datetime('now')").first();
      const validationsToday = await env.DB.prepare("SELECT COUNT(*) as c FROM validation_logs WHERE date(created_at) = date('now') AND success = 1").first();
      return json({ totalCustomers: customers.c, activeLicenses: activeLicenses.c, validationsToday: validationsToday.c });
    }
    return error('Not found', 404);
  },
};
