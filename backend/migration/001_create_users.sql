-- Enable UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users
CREATE TABLE IF NOT EXISTS users (
    user_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) UNIQUE NOT NULL,
    password   VARCHAR(255) NOT NULL,
    nomor_hp   VARCHAR(20) NOT NULL,
    fcm_token  TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Medical profiles
CREATE TABLE IF NOT EXISTS medical_profiles (
    medical_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    gol_darah     VARCHAR(5),
    catatan_medis TEXT
);

-- Emergency contacts
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id_relation  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id  UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status       VARCHAR(20) CHECK (status IN ('pending','accepted','rejected')) DEFAULT 'pending'
);

-- SOS events
CREATE TABLE IF NOT EXISTS sos_events (
    sos_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    trigger_type  VARCHAR(20) CHECK (trigger_type IN ('manual','auto')) NOT NULL,
    status        VARCHAR(20) CHECK (status IN ('active','resolved','false_alarm')) DEFAULT 'active',
    lat_initial   DECIMAL(10,7),
    lng_initial   DECIMAL(10,7),
    med_snapshot  JSONB,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- SOS tracking
CREATE TABLE IF NOT EXISTS sos_tracking (
    sos_tracking UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sos_id       UUID NOT NULL REFERENCES sos_events(sos_id) ON DELETE CASCADE,
    latitude     DECIMAL(10,7) NOT NULL,
    longitude    DECIMAL(10,7) NOT NULL,
    recorded_at  TIMESTAMP DEFAULT NOW()
);