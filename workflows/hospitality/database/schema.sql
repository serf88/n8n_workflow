-- ═══════════════════════════════════════════════════════════
-- Hotel Cruise Como — PostgreSQL Schema
-- Agentico AI Automation Stack v1.0
-- ═══════════════════════════════════════════════════════════

-- Extension per UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────
-- TABLE: guests
-- CRM centrale ospiti
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS guests (
    id                  SERIAL PRIMARY KEY,
    uuid                UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) UNIQUE NOT NULL,
    phone               VARCHAR(50),
    nationality         VARCHAR(100),
    language            VARCHAR(10) DEFAULT 'it',

    -- Canali chat
    channel_id          VARCHAR(255),  -- WhatsApp/Telegram sender_id
    channel_type        VARCHAR(50),   -- whatsapp | telegram | web

    -- Preferenze ospite
    room_preference     VARCHAR(100),  -- es: 'lake_view', 'quiet', 'high_floor'
    dietary_restrictions TEXT,         -- es: 'vegetariano, senza glutine'
    allergies           TEXT,
    preferences         JSONB DEFAULT '{}', -- campo flessibile per preferenze varie

    -- Ricorrenze
    birthday            DATE,
    anniversary         DATE,

    -- CRM Stats
    total_stays         INTEGER DEFAULT 0,
    total_spent         DECIMAL(10,2) DEFAULT 0.00,
    last_stay_date      DATE,
    source              VARCHAR(100),  -- booking.com | airbnb | direct | referral

    -- Loyalty
    loyalty_points      INTEGER DEFAULT 0,
    loyalty_tier        VARCHAR(20) DEFAULT 'STANDARD', -- STANDARD | SILVER | GOLD
    loyalty_member_since DATE,

    -- Segmentazione
    segment             VARCHAR(50) DEFAULT 'prospect', -- VIP | regular | one_time_active | churned | prospect

    -- Marketing
    email_opt_in        BOOLEAN DEFAULT true,
    sms_opt_in          BOOLEAN DEFAULT false,
    last_email_sent     TIMESTAMP,
    email_sent_count    INTEGER DEFAULT 0,

    -- Meta
    active              BOOLEAN DEFAULT true,
    notes               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_guests_email ON guests(email);
CREATE INDEX idx_guests_segment ON guests(segment);
CREATE INDEX idx_guests_loyalty_tier ON guests(loyalty_tier);
CREATE INDEX idx_guests_last_stay ON guests(last_stay_date);

-- ─────────────────────────────────────────────
-- TABLE: rooms
-- Inventario camere hotel
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rooms (
    id                  SERIAL PRIMARY KEY,
    room_number         VARCHAR(10) UNIQUE NOT NULL,
    room_type           VARCHAR(50) NOT NULL, -- standard | superior | deluxe | suite
    floor               INTEGER,
    capacity            INTEGER DEFAULT 2,
    has_lake_view       BOOLEAN DEFAULT false,
    has_balcony         BOOLEAN DEFAULT false,
    base_price          DECIMAL(8,2),
    status              VARCHAR(30) DEFAULT 'available', -- available | occupied | needs_cleaning | maintenance
    current_guest_id    INTEGER REFERENCES guests(id) ON DELETE SET NULL,
    needs_cleaning      BOOLEAN DEFAULT false,
    notes               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_type ON rooms(room_type);

-- ─────────────────────────────────────────────
-- TABLE: bookings
-- Prenotazioni da tutti i canali
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
    id                  SERIAL PRIMARY KEY,
    booking_ref         VARCHAR(50) UNIQUE NOT NULL,
    guest_id            INTEGER REFERENCES guests(id) ON DELETE RESTRICT,
    room_id             INTEGER REFERENCES rooms(id) ON DELETE RESTRICT,

    -- Dati prenotazione
    source              VARCHAR(100) NOT NULL, -- booking.com | airbnb | expedia | direct | walk_in
    external_booking_id VARCHAR(255),           -- ID originale sulla piattaforma
    checkin_date        DATE NOT NULL,
    checkout_date       DATE NOT NULL,
    nights              INTEGER GENERATED ALWAYS AS (checkout_date - checkin_date) STORED,
    room_type           VARCHAR(50),
    num_guests          INTEGER DEFAULT 1,

    -- Importi
    total_amount        DECIMAL(10,2),
    amount_paid         DECIMAL(10,2) DEFAULT 0,
    final_amount        DECIMAL(10,2),
    currency            VARCHAR(3) DEFAULT 'EUR',

    -- Richieste speciali
    special_requests    TEXT,
    dietary_restrictions TEXT,
    early_checkin       BOOLEAN DEFAULT false,
    late_checkout       BOOLEAN DEFAULT false,

    -- Status lifecycle
    status              VARCHAR(30) DEFAULT 'CONFIRMED',
    -- CONFIRMED → CHECKED_IN → CHECKED_OUT | CANCELLED | NO_SHOW
    actual_checkin_time  TIMESTAMP,
    actual_checkout_time TIMESTAMP,

    -- Meta
    notes               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bookings_guest_id ON bookings(guest_id);
CREATE INDEX idx_bookings_checkin ON bookings(checkin_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_source ON bookings(source);

-- ─────────────────────────────────────────────
-- TABLE: interactions
-- Log tutte le conversazioni AI Agent
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS interactions (
    id                  SERIAL PRIMARY KEY,
    guest_id            INTEGER REFERENCES guests(id) ON DELETE SET NULL,
    channel             VARCHAR(50) NOT NULL, -- whatsapp | telegram | web
    message_in          TEXT NOT NULL,
    message_out         TEXT,
    escalated           BOOLEAN DEFAULT false,
    escalation_reason   TEXT,
    confidence_flag     VARCHAR(20),  -- high | medium | low | faq_match
    response_time_ms    INTEGER,
    tokens_used         INTEGER,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_interactions_guest_id ON interactions(guest_id);
CREATE INDEX idx_interactions_channel ON interactions(channel);
CREATE INDEX idx_interactions_escalated ON interactions(escalated);
CREATE INDEX idx_interactions_created ON interactions(created_at);

-- ─────────────────────────────────────────────
-- TABLE: housekeeping_tasks
-- Task pulizia/preparazione camere
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS housekeeping_tasks (
    id                  SERIAL PRIMARY KEY,
    room_id             INTEGER REFERENCES rooms(id),
    room_number         VARCHAR(10),
    booking_id          INTEGER REFERENCES bookings(id),
    task_type           VARCHAR(50) NOT NULL, -- pre_checkin | post_checkout | daily | maintenance
    checkin_date        DATE,
    special_notes       TEXT,
    dietary_restrictions TEXT,
    priority            VARCHAR(20) DEFAULT 'normal', -- urgent | high | normal | low
    assigned_to         VARCHAR(100),
    status              VARCHAR(30) DEFAULT 'pending', -- pending | in_progress | completed
    completed_at        TIMESTAMP,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_housekeeping_status ON housekeeping_tasks(status);
CREATE INDEX idx_housekeeping_date ON housekeeping_tasks(checkin_date);

-- ─────────────────────────────────────────────
-- TABLE: loyalty_events
-- Storico eventi punti loyalty
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS loyalty_events (
    id                  SERIAL PRIMARY KEY,
    guest_id            INTEGER REFERENCES guests(id) ON DELETE CASCADE,
    event_type          VARCHAR(50) NOT NULL, -- stay | referral | review | birthday_bonus | promo
    points_earned       INTEGER NOT NULL,
    source              VARCHAR(100),
    booking_id          INTEGER REFERENCES bookings(id),
    notes               TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_loyalty_events_guest ON loyalty_events(guest_id);

-- ─────────────────────────────────────────────
-- FUNCTION: update_updated_at
-- Auto-aggiorna campo updated_at
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_guests_updated_at
    BEFORE UPDATE ON guests
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at
    BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_housekeeping_updated_at
    BEFORE UPDATE ON housekeeping_tasks
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
