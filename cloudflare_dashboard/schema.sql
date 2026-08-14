-- D1 schema for Order Flow seller dashboard
-- Run once (or apply ALTER on existing DB)

CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact_email TEXT,
  contact_phone TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS licenses (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customers(id),
  license_key TEXT UNIQUE NOT NULL,
  expires_at TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  max_devices INTEGER DEFAULT 1,
  bound_device_id TEXT,
  bound_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_validated_at TEXT,
  validation_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS validation_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  license_id TEXT NOT NULL,
  device_id TEXT,
  ip TEXT,
  user_agent TEXT,
  success INTEGER NOT NULL,
  message TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_licenses_key ON licenses(license_key);
CREATE INDEX IF NOT EXISTS idx_licenses_customer ON licenses(customer_id);
CREATE INDEX IF NOT EXISTS idx_licenses_bound ON licenses(bound_device_id);

-- Migration for existing D1 databases (run in wrangler d1 execute if needed):
-- ALTER TABLE licenses ADD COLUMN bound_device_id TEXT;
-- ALTER TABLE licenses ADD COLUMN bound_at TEXT;
-- ALTER TABLE licenses ADD COLUMN is_trial INTEGER DEFAULT 0;
