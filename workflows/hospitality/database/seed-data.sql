-- ═══════════════════════════════════════════════════════════
-- Hotel Cruise Como — Seed Data Demo
-- 5 ospiti campione + camere + prenotazioni di test
-- ═══════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- SEED: rooms (35 camere Hotel Cruise Como)
-- ─────────────────────────────────────────────
INSERT INTO rooms (room_number, room_type, floor, capacity, has_lake_view, has_balcony, base_price, status) VALUES
-- Piano 1 — Standard
('101', 'standard', 1, 2, false, false, 120.00, 'available'),
('102', 'standard', 1, 2, false, false, 120.00, 'available'),
('103', 'standard', 1, 2, false, false, 120.00, 'available'),
('104', 'standard', 1, 2, false, false, 120.00, 'available'),
('105', 'standard', 1, 2, false, false, 120.00, 'available'),
-- Piano 2 — Superior
('201', 'superior', 2, 2, true, false, 170.00, 'available'),
('202', 'superior', 2, 2, true, false, 170.00, 'available'),
('203', 'superior', 2, 2, true, true, 185.00, 'available'),
('204', 'superior', 2, 2, false, true, 165.00, 'available'),
('205', 'superior', 2, 2, true, false, 170.00, 'available'),
-- Piano 3 — Deluxe
('301', 'deluxe', 3, 2, true, true, 230.00, 'available'),
('302', 'deluxe', 3, 2, true, true, 230.00, 'available'),
('303', 'deluxe', 3, 3, true, true, 260.00, 'available'),
('304', 'deluxe', 3, 2, true, false, 220.00, 'available'),
-- Piano 4 — Suite
('401', 'suite', 4, 4, true, true, 380.00, 'available'),
('402', 'suite', 4, 2, true, true, 420.00, 'available'),
('403', 'suite', 4, 4, true, true, 450.00, 'available')
ON CONFLICT (room_number) DO NOTHING;

-- ─────────────────────────────────────────────
-- SEED: guests (5 ospiti campione demo)
-- ─────────────────────────────────────────────
INSERT INTO guests (
    first_name, last_name, email, phone, nationality, language,
    channel_id, channel_type,
    room_preference, dietary_restrictions, allergies, preferences,
    birthday, anniversary,
    total_stays, total_spent, last_stay_date, source,
    loyalty_points, loyalty_tier, loyalty_member_since,
    segment, email_opt_in, notes
) VALUES
-- Ospite 1: Marco Bianchi — VIP, ospite fidelizzato
(
    'Marco', 'Bianchi', 'marco.bianchi@email.it', '+39 339 1234567',
    'Italiana', 'it',
    '+393391234567', 'whatsapp',
    'lake_view', 'nessuna', 'nessuna',
    '{"preferred_room": "301", "minibar": true, "extra_pillows": true, "newspaper": "Corriere della Sera"}',
    '1975-03-15', '2005-09-20',
    8, 3840.00, '2024-11-15', 'direct',
    480, 'SILVER', '2021-06-01',
    'VIP', true,
    'Cliente abituale. Preferisce camera 301 o simile con vista lago. Porta sempre la moglie per anniversari. Appassionato di vela.'
),
-- Ospite 2: Sarah Johnson — Regular, internazionale
(
    'Sarah', 'Johnson', 'sarah.johnson@gmail.com', '+44 7911 123456',
    'Britannica', 'en',
    '5511987654321', 'whatsapp',
    'quiet', 'vegetariana', 'noci',
    '{"language": "en", "quiet_room": true, "yoga_mat": true}',
    '1988-07-22', NULL,
    3, 890.00, '2024-08-20', 'booking.com',
    90, 'STANDARD', '2023-08-01',
    'regular', true,
    'Turista britannica, viene ogni estate. Vegetariana, allergia alle noci. Preferisce camere lato giardino, tranquille.'
),
-- Ospite 3: Familie Mueller — Regular, tedesca con bambini
(
    'Hans', 'Mueller', 'hans.mueller@web.de', '+49 170 9876543',
    'Tedesca', 'de',
    NULL, 'web',
    'high_floor', 'nessuna', 'nessuna',
    '{"language": "de", "crib_needed": true, "children": 2, "ages": [4, 7]}',
    '1982-12-01', '2010-06-15',
    2, 1240.00, '2024-07-10', 'airbnb',
    60, 'STANDARD', '2023-07-01',
    'regular', true,
    'Famiglia tedesca con 2 bambini piccoli (4 e 7 anni). Prenotano sempre camera tripla/quadrupla. Gradiscono lettino culla.'
),
-- Ospite 4: Lucia Ferraris — Churned, ex ospite frequente
(
    'Lucia', 'Ferraris', 'lucia.ferraris@libero.it', '+39 347 9988776',
    'Italiana', 'it',
    '+393479988776', 'telegram',
    'balcony', 'senza lattosio', 'nessuna',
    '{"balcony": true, "spa_fan": true, "wine_lover": true}',
    '1990-04-08', NULL,
    4, 1520.00, '2024-01-05', 'direct',
    160, 'STANDARD', '2022-01-01',
    'churned', true,
    'Ospite abituale che non torna da oltre 6 mesi. Era molto attiva e recensiva sempre positivamente. Recovery campaign da attivare.'
),
-- Ospite 5: Alessandro Rossi — Nuovo ospite, prenotazione futura
(
    'Alessandro', 'Rossi', 'a.rossi@company.it', '+39 335 5544332',
    'Italiana', 'it',
    '+393355544332', 'whatsapp',
    'lake_view', 'nessuna', 'nessuna',
    '{"business_traveler": false, "anniversary_trip": true}',
    '1985-11-25', '2015-06-20',
    0, 0.00, NULL, 'booking.com',
    0, 'STANDARD', NULL,
    'prospect', true,
    'Prima prenotazione. Viene per anniversario di matrimonio. Ha richiesto champagne in camera e petali di rosa.'
)
ON CONFLICT (email) DO NOTHING;

-- ─────────────────────────────────────────────
-- SEED: bookings (3 prenotazioni demo)
-- ─────────────────────────────────────────────
INSERT INTO bookings (
    booking_ref, guest_id, room_id,
    source, checkin_date, checkout_date,
    room_type, num_guests, total_amount, currency,
    special_requests, status
) VALUES
(
    'HCC-20250620-DEMO01',
    (SELECT id FROM guests WHERE email = 'marco.bianchi@email.it'),
    (SELECT id FROM rooms WHERE room_number = '301'),
    'direct', '2025-07-15', '2025-07-18',
    'deluxe', 2, 690.00, 'EUR',
    'Vista lago, bottiglia di Franciacorta in camera al arrivo, cena romantica sabato sera',
    'CONFIRMED'
),
(
    'HCC-20250620-DEMO02',
    (SELECT id FROM guests WHERE email = 'sarah.johnson@gmail.com'),
    (SELECT id FROM rooms WHERE room_number = '204'),
    'booking.com', '2025-07-20', '2025-07-25',
    'superior', 1, 825.00, 'EUR',
    'Menù vegetariano, camera tranquilla, allergia noci - segnalare a cucina',
    'CONFIRMED'
),
(
    'HCC-20250620-DEMO03',
    (SELECT id FROM guests WHERE email = 'a.rossi@company.it'),
    (SELECT id FROM rooms WHERE room_number = '402'),
    'booking.com', '2025-06-20', '2025-06-22',
    'suite', 2, 840.00, 'EUR',
    'Anniversario di matrimonio - champagne e petali di rosa in camera, sorpresa romantica',
    'CONFIRMED'
)
ON CONFLICT (booking_ref) DO NOTHING;

-- ─────────────────────────────────────────────
-- SEED: loyalty_events (storico punti demo)
-- ─────────────────────────────────────────────
INSERT INTO loyalty_events (guest_id, event_type, points_earned, source, notes) VALUES
((SELECT id FROM guests WHERE email = 'marco.bianchi@email.it'), 'stay', 80, 'direct', '8 notti × 10 punti'),
((SELECT id FROM guests WHERE email = 'marco.bianchi@email.it'), 'review', 20, 'google', 'Recensione 5 stelle Google'),
((SELECT id FROM guests WHERE email = 'marco.bianchi@email.it'), 'referral', 50, 'word_of_mouth', 'Referral amico Hans Mueller'),
((SELECT id FROM guests WHERE email = 'sarah.johnson@gmail.com'), 'stay', 30, 'booking.com', '3 notti × 10 punti'),
((SELECT id FROM guests WHERE email = 'hans.mueller@web.de'), 'stay', 20, 'airbnb', '2 notti × 10 punti'),
((SELECT id FROM guests WHERE email = 'lucia.ferraris@libero.it'), 'stay', 40, 'direct', '4 soggiorni storici'),
((SELECT id FROM guests WHERE email = 'lucia.ferraris@libero.it'), 'review', 20, 'booking.com', 'Recensione 5 stelle')
ON CONFLICT DO NOTHING;
