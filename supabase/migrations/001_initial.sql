-- Leave Application System — PostgreSQL schema for Supabase
-- Run this in: Supabase Dashboard → SQL Editor → New Query

-- Sessions table (required for Vercel serverless PHP session persistence)
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  national_id VARCHAR(50) UNIQUE,
  gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee', 'supervisor', 'hr', 'director')),
  phone VARCHAR(30),
  profile_photo_path VARCHAR(255),
  employment_document_path VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive', 'rejected')),
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS directorates (
  id SERIAL PRIMARY KEY,
  name VARCHAR(180) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS departments (
  id SERIAL PRIMARY KEY,
  directorate_id INTEGER REFERENCES directorates(id) ON DELETE SET NULL,
  name VARCHAR(180) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS employees (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  staff_id VARCHAR(50) NOT NULL UNIQUE,
  department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL,
  designation VARCHAR(120),
  supervisor_id INTEGER REFERENCES employees(id) ON DELETE SET NULL,
  employment_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Boolean-like columns use SMALLINT (1=true, 0=false) to match PHP code comparisons
CREATE TABLE IF NOT EXISTS leave_types (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  gender_eligibility VARCHAR(10) NOT NULL DEFAULT 'any' CHECK (gender_eligibility IN ('any', 'male', 'female')),
  default_entitlement NUMERIC(6,2) NOT NULL DEFAULT 0,
  requires_balance SMALLINT NOT NULL DEFAULT 1,
  requires_attachment SMALLINT NOT NULL DEFAULT 0,
  attachment_after_days NUMERIC(6,2),
  is_paid SMALLINT NOT NULL DEFAULT 1,
  is_active SMALLINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS holidays (
  id SERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  holiday_date DATE NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS leave_balances (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  leave_type_id INTEGER NOT NULL REFERENCES leave_types(id) ON DELETE CASCADE,
  year SMALLINT NOT NULL,
  entitlement NUMERIC(6,2) NOT NULL DEFAULT 0,
  carried_forward NUMERIC(6,2) NOT NULL DEFAULT 0,
  used_days NUMERIC(6,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  UNIQUE (employee_id, leave_type_id, year)
);

CREATE TABLE IF NOT EXISTS leave_requests (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  leave_type_id INTEGER NOT NULL REFERENCES leave_types(id) ON DELETE RESTRICT,
  contact_number VARCHAR(30),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_requested NUMERIC(6,2) NOT NULL,
  reason TEXT,
  handover_notes TEXT,
  attachment_path VARCHAR(255),
  status VARCHAR(30) NOT NULL DEFAULT 'pending_supervisor'
    CHECK (status IN ('pending_supervisor', 'approved', 'rejected', 'cancelled')),
  rejection_reason TEXT,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finalized_at TIMESTAMPTZ,
  resumed_at TIMESTAMPTZ,
  resumed_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  resumption_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS approval_steps (
  id SERIAL PRIMARY KEY,
  leave_request_id INTEGER NOT NULL REFERENCES leave_requests(id) ON DELETE CASCADE,
  step_order SMALLINT NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('supervisor')),
  approver_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (action IN ('pending', 'approved', 'rejected')),
  comments TEXT,
  acted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (leave_request_id, role)
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(160) NOT NULL,
  message TEXT NOT NULL,
  link VARCHAR(255),
  is_read SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(120) NOT NULL,
  entity_type VARCHAR(80),
  entity_id INTEGER,
  ip_address VARCHAR(45),
  user_agent VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------
-- Seed data
-- -----------------------------------------------------------------------

-- Default admin (password: Admin1234 — change immediately after first login)
-- Hash is pbkdf2_sha256 format from the original project
INSERT INTO users (full_name, email, password_hash, role, status)
VALUES (
  'System Administrator',
  'admin@leavesystem.local',
  'pbkdf2_sha256$120000$7c3f1e9a2b4d6f8091a3c5e7d9b0f246$a8e6bfd6ba64705dd60789355788371b1b74b568ec55ce0aea9325f1dd1b507d',
  'admin',
  'active'
) ON CONFLICT (email) DO NOTHING;

INSERT INTO directorates (name) VALUES
  ('Education And Industrial Skills Development'),
  ('Health & Sanitation'),
  ('Lands, Housing And Urban Development'),
  ('Public Service Management & Governance'),
  ('Smart Agriculture, Livestock, Fisheries, Blue Economy'),
  ('Strategic Partnerships, ICT And Digital Economy'),
  ('The County Treasury And Economic Planning'),
  ('Trade, Investment, Industrialization, Cooperatives And Small Micro Enterprises (SME)'),
  ('Transport, Roads And Public Works'),
  ('Water, Irrigation, Environment, Natural Resources, Climate Change And Energy'),
  ('Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts')
ON CONFLICT (name) DO NOTHING;

INSERT INTO departments (directorate_id, name)
SELECT id, 'Education' FROM directorates WHERE name = 'Education And Industrial Skills Development' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Industrial Skills Development' FROM directorates WHERE name = 'Education And Industrial Skills Development' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Health' FROM directorates WHERE name = 'Health & Sanitation' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Sanitation' FROM directorates WHERE name = 'Health & Sanitation' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Lands' FROM directorates WHERE name = 'Lands, Housing And Urban Development' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Housing' FROM directorates WHERE name = 'Lands, Housing And Urban Development' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Urban Development' FROM directorates WHERE name = 'Lands, Housing And Urban Development' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Public Service Management' FROM directorates WHERE name = 'Public Service Management & Governance' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Governance' FROM directorates WHERE name = 'Public Service Management & Governance' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Smart Agriculture' FROM directorates WHERE name = 'Smart Agriculture, Livestock, Fisheries, Blue Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Livestock' FROM directorates WHERE name = 'Smart Agriculture, Livestock, Fisheries, Blue Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Fisheries' FROM directorates WHERE name = 'Smart Agriculture, Livestock, Fisheries, Blue Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Blue Economy' FROM directorates WHERE name = 'Smart Agriculture, Livestock, Fisheries, Blue Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Strategic Partnerships' FROM directorates WHERE name = 'Strategic Partnerships, ICT And Digital Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'ICT' FROM directorates WHERE name = 'Strategic Partnerships, ICT And Digital Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Digital Economy' FROM directorates WHERE name = 'Strategic Partnerships, ICT And Digital Economy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'County Treasury' FROM directorates WHERE name = 'The County Treasury And Economic Planning' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Economic Planning' FROM directorates WHERE name = 'The County Treasury And Economic Planning' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Trade' FROM directorates WHERE name = 'Trade, Investment, Industrialization, Cooperatives And Small Micro Enterprises (SME)' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Investment' FROM directorates WHERE name = 'Trade, Investment, Industrialization, Cooperatives And Small Micro Enterprises (SME)' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Industrialization' FROM directorates WHERE name = 'Trade, Investment, Industrialization, Cooperatives And Small Micro Enterprises (SME)' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Cooperatives' FROM directorates WHERE name = 'Trade, Investment, Industrialization, Cooperatives And Small Micro Enterprises (SME)' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Small Micro Enterprises (SME)' FROM directorates WHERE name = 'Trade, Investment, Industrialization, Cooperatives And Small Micro Enterprises (SME)' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Transport' FROM directorates WHERE name = 'Transport, Roads And Public Works' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Roads' FROM directorates WHERE name = 'Transport, Roads And Public Works' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Public Works' FROM directorates WHERE name = 'Transport, Roads And Public Works' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Water' FROM directorates WHERE name = 'Water, Irrigation, Environment, Natural Resources, Climate Change And Energy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Irrigation' FROM directorates WHERE name = 'Water, Irrigation, Environment, Natural Resources, Climate Change And Energy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Environment' FROM directorates WHERE name = 'Water, Irrigation, Environment, Natural Resources, Climate Change And Energy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Natural Resources' FROM directorates WHERE name = 'Water, Irrigation, Environment, Natural Resources, Climate Change And Energy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Climate Change And Energy' FROM directorates WHERE name = 'Water, Irrigation, Environment, Natural Resources, Climate Change And Energy' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Youth' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Sports' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Tourism' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Culture' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Social Protection' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Gender Affairs' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;
INSERT INTO departments (directorate_id, name)
SELECT id, 'Creative Arts' FROM directorates WHERE name = 'Youth, Sports, Tourism, Culture, Social Protection, Gender Affairs And Creative Arts' ON CONFLICT (name) DO NOTHING;

INSERT INTO leave_types (name, gender_eligibility, default_entitlement, requires_balance, requires_attachment, attachment_after_days, is_paid, is_active)
VALUES
  ('Annual Leave',       'any',    24.00, 1, 0, NULL, 1, 1),
  ('Sick Leave',         'any',    12.00, 1, 0, 3.00, 1, 1),
  ('Maternity Leave',    'female', 90.00, 1, 0, NULL, 1, 1),
  ('Paternity Leave',    'male',   14.00, 1, 0, NULL, 1, 1),
  ('Compassionate Leave','any',     5.00, 1, 1, NULL, 1, 1),
  ('Study Leave',        'any',     0.00, 0, 0, NULL, 1, 1),
  ('Unpaid Leave',       'any',     0.00, 0, 0, NULL, 0, 1)
ON CONFLICT (name) DO NOTHING;
