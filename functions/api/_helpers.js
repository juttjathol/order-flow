/**
 * Order Flow – Cloudflare Pages /api/*
 * D1 binding: DB. Env: JWT_SECRET, ADMIN_EMAIL, GITHUB_REPO
 */
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function err(message, status = 400) {
  return json({ ok: false, error: message }, status);
}

export async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

export function genId(prefix = 'id') {
  return `${prefix}_${crypto.randomUUID().replace(/-/g, '').slice(0, 12)}`;
}

export function genLicenseKey() {
  const parts = [];
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  for (let i = 0; i < 4; i++) {
    let p = '';
    for (let j = 0; j < 4; j++) p += chars[Math.floor(Math.random() * chars.length)];
    parts.push(p);
  }
  return parts.join('-');
}

export async function requireAdmin(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return null;
  const token = auth.slice(7);
  // Simple token check – token is base64(email:secret) or JWT-like
  try {
    const decoded = atob(token);
    const [email] = decoded.split(':');
    if (email && email === (env.ADMIN_EMAIL || 'admin@orderflow.local')) {
      return { email };
    }
  } catch {}
  // Also accept plain admin token from localStorage style
  if (token === (env.JWT_SECRET || 'order-flow-admin')) {
    return { email: env.ADMIN_EMAIL || 'admin@orderflow.local' };
  }
  return null;
}

export async function ensureSchema(db) {
  // Best-effort migrations
  const alters = [
    "ALTER TABLE licenses ADD COLUMN bound_device_id TEXT",
    "ALTER TABLE licenses ADD COLUMN bound_at TEXT",
    "ALTER TABLE licenses ADD COLUMN is_trial INTEGER DEFAULT 0",
    "ALTER TABLE licenses ADD COLUMN notes TEXT",
    "ALTER TABLE customers ADD COLUMN notes TEXT",
  ];
  for (const sql of alters) {
    try { await db.prepare(sql).run(); } catch {}
  }
  try {
    await db.prepare(`CREATE TABLE IF NOT EXISTS activity_log (
      id TEXT PRIMARY KEY,
      action TEXT,
      detail TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )`).run();
  } catch {}
}

export async function logActivity(db, action, detail) {
  try {
    await db.prepare(
      'INSERT INTO activity_log (id, action, detail) VALUES (?, ?, ?)'
    ).bind(genId('log'), action, detail).run();
  } catch {}
}
