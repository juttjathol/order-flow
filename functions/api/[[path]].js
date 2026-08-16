/**
 * Cloudflare Pages Function – handles all /api/* routes
 * Bind D1 as DB. Set JWT_SECRET, ADMIN_EMAIL, GITHUB_REPO.
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
  const b64 = (obj) =>
    btoa(String.fromCharCode(...enc.encode(JSON.stringify(obj))))
      .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const data = `${b64(header)}.${b64(payload)}`;
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
  } catch { return null; }
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
  const hash = await crypto.subtle.digest('SHA-256', enc.encode(password + 'orderflow-salt'));
  return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
}

export async function onRequest(context) {
  const { request, env } = context;
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });

  if (!env.DB) {
    return error('Database not bound. Pages Settings → Bindings → add D1 named DB.', 500);
  }

  const url = new URL(request.url);
  const path = url.pathname;
  const secret = env.JWT_SECRET || 'dev-secret-change-me-in-production';

  // Ensure binding columns exist (safe on every request)
  try { await env.DB.prepare('ALTER TABLE licenses ADD COLUMN bound_device_id TEXT').run(); } catch (_) {}
  try { await env.DB.prepare('ALTER TABLE licenses ADD COLUMN bound_at TEXT').run(); } catch (_) {}

  if (path === '/api/v1/license/validate' && request.method === 'POST') {
    try {
      const body = await request.json();
      const licenseKey = (body.licenseKey || body.license_key || '').toString().trim();
      const deviceId = (body.deviceId || body.device_id || '').toString().trim();
      if (!licenseKey) return error('licenseKey required');
      if (!deviceId) return error('deviceId required');

      const row = await env.DB.prepare(
        'SELECT l.*, c.name as customer_name FROM licenses l JOIN customers c ON c.id = l.customer_id WHERE l.license_key = ?'
      ).bind(licenseKey).first();
      if (!row) return error('Invalid license', 401);
      if (!row.is_active) return error('License revoked', 403);
      if (new Date(row.expires_at) < new Date()) return error('License expired', 403);

      const bound = (row.bound_device_id || '').toString().trim();
      let firstActivation = false;

      if (!bound) {
        // First Main device wins — bind permanently until admin resets
        await env.DB.prepare(
          "UPDATE licenses SET bound_device_id = ?, bound_at = datetime('now'), last_validated_at = datetime('now'), validation_count = COALESCE(validation_count, 0) + 1 WHERE id = ?"
        ).bind(deviceId, row.id).run();
        firstActivation = true;
      } else if (bound !== deviceId) {
        return error('This license is already activated on another device. Ask the seller to Reset device in the dashboard.', 403);
      } else {
        await env.DB.prepare(
          "UPDATE licenses SET last_validated_at = datetime('now'), validation_count = COALESCE(validation_count, 0) + 1 WHERE id = ?"
        ).bind(row.id).run();
      }

      try {
        await env.DB.prepare(
          'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 1, ?)'
        ).bind(row.id, deviceId, request.headers.get('CF-Connecting-IP'), firstActivation ? 'first bind' : 'ok').run();
      } catch (_) {}

      return json({
        valid: true,
        customerId: row.customer_id,
        customerName: row.customer_name,
        expiresAt: row.expires_at,
        maxDevices: row.max_devices,
        firstActivation,
        boundDeviceId: firstActivation ? deviceId : bound || deviceId,
      });
    } catch (e) { return error(e.message || 'validate failed', 500); }
  }

  if ((path === '/api/v1/download/android' || path === '/download/android') && request.method === 'GET') {
    const repo = env.GITHUB_REPO || 'juttjathol/order-flow';
    try {
      const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
        headers: { 'User-Agent': 'Order-Flow-Dashboard', Accept: 'application/vnd.github+json' },
      });
      if (!res.ok) return error('No release found. Create a GitHub Release with an APK first.', 404);
      const data = await res.json();
      const assets = data.assets || [];
      const apk = assets.find(a => (a.name || '').toLowerCase().endsWith('.apk')) || assets.find(a => (a.name || '').toLowerCase().includes('apk'));
      if (!apk || !apk.browser_download_url) return error('No APK in latest release.', 404);
      return Response.redirect(apk.browser_download_url, 302);
    } catch (e) { return error('Download failed: ' + e.message, 502); }
  }

  if (path === '/api/v1/releases/latest' && request.method === 'GET') {
    const repo = env.GITHUB_REPO || 'juttjathol/order-flow';
    try {
      const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
        headers: { 'User-Agent': 'Order-Flow-Dashboard', Accept: 'application/vnd.github+json' },
      });
      if (!res.ok) return json({ tag: null, assets: [] });
      const data = await res.json();
      const assets = (data.assets || []).map(a => ({ name: a.name, downloadUrl: a.browser_download_url, size: a.size }));
      return json({ tag: data.tag_name, name: data.name, publishedAt: data.published_at, body: data.body, assets });
    } catch (e) { return error('Could not fetch releases', 502); }
  }

  if (path === '/api/v1/admin/reset' && request.method === 'POST') {
    try {
      const body = await request.json();
      const email = String(body.email || '').trim().toLowerCase();
      const password = String(body.password || '');
      const resetSecret = String(body.resetSecret || '');
      if (!email || !password) return error('email & password required');
      if (!resetSecret || resetSecret !== secret) {
        return error('Invalid reset secret. Use the same value as JWT_SECRET from Cloudflare env vars.', 403);
      }
      const hash = await hashPassword(password);
      const existing = await env.DB.prepare('SELECT * FROM admins WHERE email = ?').bind(email).first();
      if (existing) {
        await env.DB.prepare('UPDATE admins SET password_hash = ? WHERE email = ?').bind(hash, email).run();
      } else {
        await env.DB.prepare('DELETE FROM admins').run();
        const id = crypto.randomUUID();
        await env.DB.prepare('INSERT INTO admins (id, email, password_hash, name) VALUES (?, ?, ?, ?)').bind(id, email, hash, 'Admin').run();
      }
      return json({ ok: true, message: 'Password updated. You can log in now.' });
    } catch (e) { return error(e.message || 'Reset failed', 500); }
  }

  if (path === '/api/v1/admin/login' && request.method === 'POST') {
    try {
      const body = await request.json();
      const email = String(body.email || '').trim().toLowerCase();
      const password = String(body.password || '');
      if (!email || !password) return error('email & password required');

      let admin = await env.DB.prepare('SELECT * FROM admins WHERE lower(email) = ?').bind(email).first();

      if (!admin) {
        const count = await env.DB.prepare('SELECT COUNT(*) as c FROM admins').first();
        if (count && count.c === 0) {
          const id = crypto.randomUUID();
          const hash = await hashPassword(password);
          await env.DB.prepare('INSERT INTO admins (id, email, password_hash, name) VALUES (?, ?, ?, ?)').bind(id, email, hash, 'Admin').run();
          admin = { id, email, password_hash: hash, name: 'Admin' };
        }
      }

      if (!admin) return error('Invalid credentials. Wrong email, or admin already exists under a different email. Use password reset.', 401);
      const hash = await hashPassword(password);
      if (hash !== admin.password_hash) return error('Invalid credentials. Wrong password for this email.', 401);

      const token = await signJwt({
        sub: admin.id, email: admin.email,
        exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 7,
      }, secret);
      return json({ token, admin: { id: admin.id, email: admin.email, name: admin.name } });
    } catch (e) { return error(e.message || 'Login failed', 500); }
  }

  if (path === '/api/v1/signup' && request.method === 'POST') {
    try {
      const body = await request.json();
      const name = (body.name || '').trim();
      const phone = (body.phone || '').trim();
      const email = (body.email || '').trim() || null;
      const deviceId = (body.deviceId || '').trim() || null;
      if (!name && !phone && !email) return error('name or email required');
      const id = crypto.randomUUID();
      const notes = ['App signup', deviceId ? 'device:' + deviceId : null].filter(Boolean).join(' | ');
      await env.DB.prepare(
        'INSERT INTO customers (id, name, contact_email, contact_phone, notes) VALUES (?, ?, ?, ?, ?)'
      ).bind(id, name || (email || 'App user'), email, phone || null, notes).run();
      return json({ ok: true, customerId: id }, 201);
    } catch (e) { return error(e.message, 500); }
  }

  const auth = request.headers.get('Authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  const payload = token ? await verifyJwt(token, secret) : null;
  if (!payload) return error('Unauthorized', 401);

  if (path === '/api/v1/customers' && request.method === 'GET') {
    const { results } = await env.DB.prepare(
      'SELECT c.*, (SELECT COUNT(*) as c FROM licenses l WHERE l.customer_id = c.id AND l.is_active = 1) as active_licenses FROM customers c ORDER BY created_at DESC'
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
    const parts = path.split('/').filter(Boolean);
    const id = parts[parts.length - 1] === 'reset-device' ? parts[parts.length - 2] : parts[parts.length - 1];
    const body = await request.json().catch(() => ({}));
    if (parts[parts.length - 1] === 'reset-device' || body.reset_device) {
      try { await env.DB.prepare('ALTER TABLE licenses ADD COLUMN bound_device_id TEXT').run(); } catch (_) {}
      try { await env.DB.prepare('ALTER TABLE licenses ADD COLUMN bound_at TEXT').run(); } catch (_) {}
      await env.DB.prepare('UPDATE licenses SET bound_device_id = NULL, bound_at = NULL WHERE id = ?').bind(id).run();
      return json({ ok: true, reset: true });
    }
    if (body.is_active !== undefined) await env.DB.prepare('UPDATE licenses SET is_active = ? WHERE id = ?').bind(body.is_active ? 1 : 0, id).run();
    if (body.expires_at) await env.DB.prepare('UPDATE licenses SET expires_at = ? WHERE id = ?').bind(body.expires_at, id).run();
    return json({ ok: true });
  }
  if (path === '/api/v1/stats' && request.method === 'GET') {
    const customers = await env.DB.prepare('SELECT COUNT(*) as c FROM customers').first();
    const activeLicenses = await env.DB.prepare("SELECT COUNT(*) as c FROM licenses WHERE is_active = 1 AND expires_at > datetime('now')").first();
    const validationsToday = await env.DB.prepare("SELECT COUNT(*) as c FROM validation_logs WHERE date(created_at) = date('now') AND success = 1").first();
    return json({ totalCustomers: customers.c, activeLicenses: activeLicenses.c, validationsToday: validationsToday.c });
  }

  // DELETE customer + all their licenses and validation logs
  if (path.startsWith('/api/v1/customers/') && request.method === 'DELETE') {
    try {
      const id = path.split('/').filter(Boolean).pop();
      if (!id || id === 'customers') return error('customer id required');
      try {
        await env.DB.prepare(
          'DELETE FROM validation_logs WHERE license_id IN (SELECT id FROM licenses WHERE customer_id = ?)'
        ).bind(id).run();
      } catch (_) {}
      try {
        await env.DB.prepare('DELETE FROM licenses WHERE customer_id = ?').bind(id).run();
      } catch (e) { return error('Failed deleting licenses: ' + (e.message || e), 500); }
      await env.DB.prepare('DELETE FROM customers WHERE id = ?').bind(id).run();
      return json({ ok: true, deleted: id });
    } catch (e) { return error(e.message || 'Delete customer failed', 500); }
  }

  // DELETE single license key
  if (path.startsWith('/api/v1/licenses/') && request.method === 'DELETE') {
    try {
      const parts = path.split('/').filter(Boolean);
      const id = parts[parts.length - 1];
      if (!id || id === 'licenses') return error('license id required');
      try {
        await env.DB.prepare('DELETE FROM validation_logs WHERE license_id = ?').bind(id).run();
      } catch (_) {}
      await env.DB.prepare('DELETE FROM licenses WHERE id = ?').bind(id).run();
      return json({ ok: true, deleted: id });
    } catch (e) { return error(e.message || 'Delete license failed', 500); }
  }

  return error('Not found', 404);
}
