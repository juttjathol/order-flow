/**
 * Order Flow – Cloudflare Worker
 * - Admin auth
 * - Customer / License CRUD + delete
 * - One-device license binding + reset
 * - Public signup + license validate
 * - GitHub APK releases
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
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');
  const head = b64(header);
  const body = b64(payload);
  const data = `${head}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${data}.${sigB64}`;
}

async function verifyJwt(token, secret) {
  try {
    const [head, body, sig] = token.split('.');
    const data = `${head}.${body}`;
    const enc = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      enc.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );
    const sigBytes = Uint8Array.from(
      atob(sig.replace(/-/g, '+').replace(/_/g, '/')),
      (c) => c.charCodeAt(0)
    );
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
    for (let j = 0; j < 4; j++) {
      key += chars[Math.floor(Math.random() * chars.length)];
    }
  }
  return key;
}

async function hashPassword(password) {
  const enc = new TextEncoder();
  const data = enc.encode(password + 'order-flow-salt');
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** Ensure bound_device_id column exists (safe on every request for D1). */
async function ensureSchema(env) {
  try {
    await env.DB.prepare(
      'ALTER TABLE licenses ADD COLUMN bound_device_id TEXT'
    ).run();
  } catch (_) {}
  try {
    await env.DB.prepare('ALTER TABLE licenses ADD COLUMN bound_at TEXT').run();
  } catch (_) {}
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;
    const secret = env.JWT_SECRET || 'dev-secret-change-me-in-production';

    await ensureSchema(env);

    // ---------- Public: App signup ----------
    if (path === '/api/v1/signup' && request.method === 'POST') {
      try {
        const body = await request.json();
        const name = (body.name || '').toString().trim();
        const email = (body.email || '').toString().trim().toLowerCase();
        if (!name && !email) return error('name or email required');
        const displayName = name || email.split('@')[0] || 'Restaurant';

        if (email) {
          const existing = await env.DB.prepare(
            'SELECT id FROM customers WHERE lower(contact_email) = ? LIMIT 1'
          )
            .bind(email)
            .first();
          if (existing) {
            await env.DB.prepare(
              'UPDATE customers SET name = ?, contact_email = ? WHERE id = ?'
            )
              .bind(displayName, email, existing.id)
              .run();
            return json({ ok: true, id: existing.id, updated: true });
          }
        }

        const id = crypto.randomUUID();
        await env.DB.prepare(
          'INSERT INTO customers (id, name, contact_email, contact_phone, notes) VALUES (?, ?, ?, ?, ?)'
        )
          .bind(
            id,
            displayName,
            email || null,
            null,
            body.deviceId ? `device:${body.deviceId}` : null
          )
          .run();
        return json({ ok: true, id, created: true }, 201);
      } catch (e) {
        return error(e.message || 'signup failed', 500);
      }
    }

    // ---------- Public: License validation (one device binding) ----------
    if (path === '/api/v1/license/validate' && request.method === 'POST') {
      try {
        const body = await request.json();
        const { licenseKey, deviceId } = body;
        if (!licenseKey) return error('licenseKey required');
        if (!deviceId) return error('deviceId required');

        const row = await env.DB.prepare(
          'SELECT l.*, c.name as customer_name FROM licenses l JOIN customers c ON c.id = l.customer_id WHERE l.license_key = ?'
        )
          .bind(licenseKey)
          .first();

        if (!row) {
          await env.DB.prepare(
            'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 0, ?)'
          )
            .bind(
              'unknown',
              deviceId || null,
              request.headers.get('CF-Connecting-IP'),
              'License not found'
            )
            .run();
          return error('Invalid license', 401);
        }

        if (!row.is_active) {
          await env.DB.prepare(
            'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 0, ?)'
          )
            .bind(
              row.id,
              deviceId,
              request.headers.get('CF-Connecting-IP'),
              'License revoked'
            )
            .run();
          return error('License revoked', 403);
        }

        const expires = new Date(row.expires_at);
        if (expires < new Date()) {
          await env.DB.prepare(
            'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 0, ?)'
          )
            .bind(
              row.id,
              deviceId,
              request.headers.get('CF-Connecting-IP'),
              'License expired'
            )
            .run();
          return error('License expired', 403);
        }

        // One-device binding
        const bound = row.bound_device_id;
        if (bound && bound !== deviceId) {
          await env.DB.prepare(
            'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 0, ?)'
          )
            .bind(
              row.id,
              deviceId,
              request.headers.get('CF-Connecting-IP'),
              'Device not allowed – license bound to another device'
            )
            .run();
          return error(
            'This license is already activated on another device. Contact your provider to reset the device binding.',
            403
          );
        }

        if (!bound) {
          await env.DB.prepare(
            "UPDATE licenses SET bound_device_id = ?, bound_at = datetime('now'), last_validated_at = datetime('now'), validation_count = validation_count + 1 WHERE id = ?"
          )
            .bind(deviceId, row.id)
            .run();
        } else {
          await env.DB.prepare(
            "UPDATE licenses SET last_validated_at = datetime('now'), validation_count = validation_count + 1 WHERE id = ?"
          )
            .bind(row.id)
            .run();
        }

        await env.DB.prepare(
          'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 1, ?)'
        )
          .bind(
            row.id,
            deviceId,
            request.headers.get('CF-Connecting-IP'),
            bound ? 'OK' : 'OK – first activation, device bound'
          )
          .run();

        return json({
          valid: true,
          customerId: row.customer_id,
          customerName: row.customer_name,
          expiresAt: row.expires_at,
          maxDevices: 1,
          boundDeviceId: bound || deviceId,
          firstActivation: !bound,
        });
      } catch (e) {
        return error(e.message, 500);
      }
    }

    // ---------- Public: APK download ----------
    if (
      (path === '/api/v1/download/android' || path === '/download/android') &&
      request.method === 'GET'
    ) {
      const repo = env.GITHUB_REPO || 'juttjathol/order-flow';
      try {
        const res = await fetch(
          `https://api.github.com/repos/${repo}/releases/latest`,
          {
            headers: {
              'User-Agent': 'Order-Flow-Dashboard',
              Accept: 'application/vnd.github+json',
            },
          }
        );
        if (!res.ok) {
          return error(
            'No release found. Upload an APK to a GitHub Release first.',
            404
          );
        }
        const data = await res.json();
        const assets = data.assets || [];
        const apk =
          assets.find((a) => (a.name || '').toLowerCase().endsWith('.apk')) ||
          assets.find((a) => (a.name || '').toLowerCase().includes('apk'));
        if (!apk || !apk.browser_download_url) {
          return error('No APK asset in the latest GitHub Release.', 404);
        }
        return Response.redirect(apk.browser_download_url, 302);
      } catch (e) {
        return error('Download failed: ' + e.message, 502);
      }
    }

    // ---------- Public: Latest release ----------
    if (path === '/api/v1/releases/latest' && request.method === 'GET') {
      const repo = env.GITHUB_REPO || 'juttjathol/order-flow';
      try {
        const res = await fetch(
          `https://api.github.com/repos/${repo}/releases/latest`,
          {
            headers: {
              'User-Agent': 'Order-Flow-Dashboard',
              Accept: 'application/vnd.github+json',
            },
          }
        );
        if (!res.ok) return json({ tag: null, assets: [] });
        const data = await res.json();
        const assets = (data.assets || []).map((a) => ({
          name: a.name,
          downloadUrl: a.browser_download_url,
          size: a.size,
        }));
        return json({
          tag: data.tag_name,
          name: data.name,
          publishedAt: data.published_at,
          body: data.body,
          assets,
        });
      } catch (e) {
        return error('Could not fetch releases', 502);
      }
    }

    // ---------- Admin login ----------
    if (path === '/api/v1/admin/login' && request.method === 'POST') {
      const body = await request.json();
      const { email, password } = body;
      if (!email || !password) return error('email & password required');

      let admin = await env.DB.prepare('SELECT * FROM admins WHERE email = ?')
        .bind(email)
        .first();

      if (!admin && email === (env.ADMIN_EMAIL || 'admin@example.com')) {
        const id = crypto.randomUUID();
        const hash = await hashPassword(password);
        await env.DB.prepare(
          'INSERT INTO admins (id, email, password_hash, name) VALUES (?, ?, ?, ?)'
        )
          .bind(id, email, hash, 'Admin')
          .run();
        admin = { id, email, password_hash: hash, name: 'Admin' };
      }

      if (!admin) return error('Invalid credentials', 401);
      const hash = await hashPassword(password);
      if (hash !== admin.password_hash) return error('Invalid credentials', 401);

      const token = await signJwt(
        {
          sub: admin.id,
          email: admin.email,
          exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 7,
        },
        secret
      );

      return json({
        token,
        admin: { id: admin.id, email: admin.email, name: admin.name },
      });
    }

    // Auth required below
    const auth = request.headers.get('Authorization') || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    const payload = token ? await verifyJwt(token, secret) : null;
    if (!payload) return error('Unauthorized', 401);

    // ---------- Customers list / create ----------
    if (path === '/api/v1/customers' && request.method === 'GET') {
      const { results } = await env.DB.prepare(
        `SELECT c.*,
          (SELECT COUNT(*) FROM licenses l WHERE l.customer_id = c.id AND l.is_active = 1) as active_licenses
         FROM customers c ORDER BY created_at DESC`
      ).all();
      return json({ customers: results });
    }

    if (path === '/api/v1/customers' && request.method === 'POST') {
      const body = await request.json();
      if (!body.name) return error('name required');
      const id = crypto.randomUUID();
      await env.DB.prepare(
        'INSERT INTO customers (id, name, contact_email, contact_phone, notes) VALUES (?, ?, ?, ?, ?)'
      )
        .bind(
          id,
          body.name,
          body.contact_email || null,
          body.contact_phone || null,
          body.notes || null
        )
        .run();
      return json({ id, ...body }, 201);
    }

    // DELETE customer (cascades licenses + logs conceptually)
    if (path.startsWith('/api/v1/customers/') && request.method === 'DELETE') {
      const id = path.split('/').pop();
      if (!id) return error('id required');
      await env.DB.prepare(
        'DELETE FROM validation_logs WHERE license_id IN (SELECT id FROM licenses WHERE customer_id = ?)'
      )
        .bind(id)
        .run();
      await env.DB.prepare('DELETE FROM licenses WHERE customer_id = ?')
        .bind(id)
        .run();
      await env.DB.prepare('DELETE FROM customers WHERE id = ?').bind(id).run();
      return json({ ok: true, deleted: id });
    }

    // ---------- Licenses ----------
    if (path === '/api/v1/licenses' && request.method === 'POST') {
      const body = await request.json();
      let { customerId, expiresAt, maxDevices = 1, isTrial = false, trialDays = 7 } = body;
      if (!customerId) return error('customerId required');

      // Trial: auto-set expiry to N days from now if not provided
      if (isTrial && !expiresAt) {
        const d = new Date();
        d.setDate(d.getDate() + (parseInt(trialDays, 10) || 7));
        expiresAt = d.toISOString();
      }
      if (!expiresAt) return error('expiresAt required (or set isTrial: true)');

      const id = crypto.randomUUID();
      const key = generateLicenseKey();
      // notes column not on licenses – store trial flag in a safe way via notes on customer not needed;
      // use max_devices=0 as trial marker is fragile; store is_trial if column exists
      try {
        await env.DB.prepare(
          'ALTER TABLE licenses ADD COLUMN is_trial INTEGER DEFAULT 0'
        ).run();
      } catch (_) {}

      await env.DB.prepare(
        'INSERT INTO licenses (id, customer_id, license_key, expires_at, max_devices, is_trial) VALUES (?, ?, ?, ?, ?, ?)'
      )
        .bind(id, customerId, key, expiresAt, maxDevices || 1, isTrial ? 1 : 0)
        .run()
        .catch(async () => {
          await env.DB.prepare(
            'INSERT INTO licenses (id, customer_id, license_key, expires_at, max_devices) VALUES (?, ?, ?, ?, ?)'
          )
            .bind(id, customerId, key, expiresAt, maxDevices || 1)
            .run();
        });

      return json(
        {
          id,
          licenseKey: key,
          customerId,
          expiresAt,
          maxDevices: maxDevices || 1,
          isTrial: !!isTrial,
        },
        201
      );
    }

    if (path === '/api/v1/licenses' && request.method === 'GET') {
      const customerId = url.searchParams.get('customerId');
      let q =
        'SELECT l.*, c.name as customer_name FROM licenses l JOIN customers c ON c.id = l.customer_id';
      if (customerId) q += ' WHERE l.customer_id = ?';
      q += ' ORDER BY l.created_at DESC';
      const stmt = env.DB.prepare(q);
      const { results } = customerId
        ? await stmt.bind(customerId).all()
        : await stmt.all();
      return json({ licenses: results });
    }

    // PUT license: revoke/activate, extend expiry, OR reset device
    if (path.startsWith('/api/v1/licenses/') && request.method === 'PUT') {
      const parts = path.split('/');
      const id = parts[4];
      if (!id) return error('id required');

      // /api/v1/licenses/:id/reset-device
      if (parts[5] === 'reset-device') {
        await env.DB.prepare(
          'UPDATE licenses SET bound_device_id = NULL, bound_at = NULL WHERE id = ?'
        )
          .bind(id)
          .run();
        await env.DB.prepare(
          'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 1, ?)'
        )
          .bind(
            id,
            null,
            request.headers.get('CF-Connecting-IP'),
            'Device binding reset by admin'
          )
          .run();
        return json({
          ok: true,
          message: 'Device binding cleared. License can activate on a new device.',
        });
      }

      // /api/v1/licenses/:id/extend  body: { days: 30 }
      if (parts[5] === 'extend') {
        const body = await request.json().catch(() => ({}));
        const days = parseInt(body.days, 10) || 30;
        const row = await env.DB.prepare(
          'SELECT expires_at FROM licenses WHERE id = ?'
        )
          .bind(id)
          .first();
        if (!row) return error('License not found', 404);
        const base =
          new Date(row.expires_at) > new Date()
            ? new Date(row.expires_at)
            : new Date();
        base.setDate(base.getDate() + days);
        const newExp = base.toISOString();
        await env.DB.prepare('UPDATE licenses SET expires_at = ? WHERE id = ?')
          .bind(newExp, id)
          .run();
        await env.DB.prepare(
          'INSERT INTO validation_logs (license_id, device_id, ip, success, message) VALUES (?, ?, ?, 1, ?)'
        )
          .bind(
            id,
            null,
            request.headers.get('CF-Connecting-IP'),
            `Expiry extended by ${days} days to ${newExp.slice(0, 10)}`
          )
          .run();
        return json({ ok: true, expiresAt: newExp, days });
      }

      const body = await request.json();
      if (body.is_active !== undefined) {
        await env.DB.prepare('UPDATE licenses SET is_active = ? WHERE id = ?')
          .bind(body.is_active ? 1 : 0, id)
          .run();
      }
      if (body.expires_at) {
        await env.DB.prepare('UPDATE licenses SET expires_at = ? WHERE id = ?')
          .bind(body.expires_at, id)
          .run();
      }
      if (body.reset_device === true) {
        await env.DB.prepare(
          'UPDATE licenses SET bound_device_id = NULL, bound_at = NULL WHERE id = ?'
        )
          .bind(id)
          .run();
      }
      if (body.extend_days) {
        const days = parseInt(body.extend_days, 10) || 30;
        const row = await env.DB.prepare(
          'SELECT expires_at FROM licenses WHERE id = ?'
        )
          .bind(id)
          .first();
        if (row) {
          const base =
            new Date(row.expires_at) > new Date()
              ? new Date(row.expires_at)
              : new Date();
          base.setDate(base.getDate() + days);
          await env.DB.prepare('UPDATE licenses SET expires_at = ? WHERE id = ?')
            .bind(base.toISOString(), id)
            .run();
        }
      }
      return json({ ok: true });
    }

    // DELETE license
    if (path.startsWith('/api/v1/licenses/') && request.method === 'DELETE') {
      const id = path.split('/').pop();
      if (!id || id === 'licenses') return error('id required');
      await env.DB.prepare('DELETE FROM validation_logs WHERE license_id = ?')
        .bind(id)
        .run();
      await env.DB.prepare('DELETE FROM licenses WHERE id = ?').bind(id).run();
      return json({ ok: true, deleted: id });
    }

    // ---------- Validation logs (recent activity) ----------
    if (path === '/api/v1/validation-logs' && request.method === 'GET') {
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '30', 10), 100);
      const { results } = await env.DB.prepare(
        `SELECT v.*, l.license_key, c.name as customer_name
         FROM validation_logs v
         LEFT JOIN licenses l ON l.id = v.license_id
         LEFT JOIN customers c ON c.id = l.customer_id
         ORDER BY v.created_at DESC
         LIMIT ?`
      )
        .bind(limit)
        .all();
      return json({ logs: results });
    }

    // ---------- Stats ----------
    if (path === '/api/v1/stats' && request.method === 'GET') {
      const customers = await env.DB.prepare(
        'SELECT COUNT(*) as c FROM customers'
      ).first();
      const activeLicenses = await env.DB.prepare(
        "SELECT COUNT(*) as c FROM licenses WHERE is_active = 1 AND expires_at > datetime('now')"
      ).first();
      const validationsToday = await env.DB.prepare(
        "SELECT COUNT(*) as c FROM validation_logs WHERE date(created_at) = date('now') AND success = 1"
      ).first();
      const boundLicenses = await env.DB.prepare(
        'SELECT COUNT(*) as c FROM licenses WHERE bound_device_id IS NOT NULL AND is_active = 1'
      ).first();
      const expiringSoon = await env.DB.prepare(
        "SELECT COUNT(*) as c FROM licenses WHERE is_active = 1 AND expires_at > datetime('now') AND expires_at <= datetime('now', '+7 days')"
      ).first();
      return json({
        totalCustomers: customers.c,
        activeLicenses: activeLicenses.c,
        validationsToday: validationsToday.c,
        boundLicenses: boundLicenses.c,
        expiringSoon: expiringSoon.c,
      });
    }

    return error('Not found', 404);
  },
};
