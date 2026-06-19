# 🎬 DEMO_SCENARIOS.md — Script Test Hotel Cruise Como

> Scenari funzionali per validare tutti i workflow Agentico.  
> Esegui in ordine per una demo completa end-to-end.

---

## 🛠 Prerequisiti Demo

```bash
# Stack attivo:
docker compose ps
# n8n, postgres, redis → tutti STATUS: running

# URL base (adatta al tuo ambiente):
N8N_URL=http://localhost:5678
```

---

## 📦 SCENARIO 1 — Nuova Prenotazione (Booking.com)

**Cosa testa:** Booking Sync → assegnazione camera → email welcome → housekeeping → notifica staff

```bash
curl -X POST $N8N_URL/webhook/hotel-cruise-booking \
  -H "Content-Type: application/json" \
  -d '{
    "source": "booking.com",
    "booking_id": "BKG-2025-DEMO-001",
    "guest_name": "Giulia Verdi",
    "guest_email": "giulia.verdi@test.it",
    "guest_phone": "+39 347 1122334",
    "checkin_date": "2025-07-05",
    "checkout_date": "2025-07-08",
    "room_type": "superior",
    "special_requests": "Vista lago se possibile",
    "dietary_restrictions": "",
    "total_amount": 510.00
  }'
```

**Risultato atteso:**
- ✅ Guest `giulia.verdi@test.it` inserita in tabella `guests`
- ✅ Prenotazione `HCC-YYYYMMDD-XXXXXX` in tabella `bookings` (status: CONFIRMED)
- ✅ Camera `superior` disponibile assegnata automaticamente
- ✅ Email welcome ricevuta (o su `DEMO_EMAIL_OVERRIDE` se DEMO_MODE=true)
- ✅ Task housekeeping creato per la camera assegnata
- ✅ Notifica Telegram al gruppo staff

---

## 📦 SCENARIO 2 — Ospite Ripetuto (Direct Booking)

**Cosa testa:** Riconoscimento ospite esistente → update CRM invece di insert

```bash
curl -X POST $N8N_URL/webhook/hotel-cruise-booking \
  -H "Content-Type: application/json" \
  -d '{
    "source": "direct",
    "booking_id": "DIRECT-2025-002",
    "guest_name": "Marco Bianchi",
    "guest_email": "marco.bianchi@email.it",
    "guest_phone": "+39 339 1234567",
    "checkin_date": "2025-08-10",
    "checkout_date": "2025-08-13",
    "room_type": "deluxe",
    "special_requests": "Solita camera 301 se disponibile, Franciacorta in frigo",
    "dietary_restrictions": "",
    "total_amount": 690.00
  }'
```

**Risultato atteso:**
- ✅ Ospite Marco Bianchi già in DB → `total_stays` incrementato (9)
- ✅ Prenotazione inserita con riferimento al `guest_id` esistente
- ✅ Email welcome personalizzata con nome e preferenze note
- ✅ Nessun duplicato in tabella `guests`

---

## 💬 SCENARIO 3 — Chat FAQ (Web Widget)

**Cosa testa:** AI Agent → FAQ matcher → risposta statica rapida → logging

```bash
# Domanda su WiFi (FAQ match)
curl -X POST $N8N_URL/webhook/hotel-cruise-chat \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "web",
    "sender_id": "web-test-001",
    "sender_name": "Ospite Web",
    "message": "Qual è la password del WiFi?",
    "timestamp": "2025-06-20T10:00:00Z"
  }'

# Risposta attesa: messaggio con rete WiFi e istruzioni
```

```bash
# Domanda su attività Como (FAQ match)
curl -X POST $N8N_URL/webhook/hotel-cruise-chat \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "web",
    "sender_id": "web-test-001",
    "sender_name": "Ospite Web",
    "message": "Cosa si può fare sul Lago di Como?",
    "timestamp": "2025-06-20T10:01:00Z"
  }'
```

**Risultato atteso:**
- ✅ Risposta ricevuta in <2 secondi (FAQ statica, no OpenAI)
- ✅ Interazione loggata in tabella `interactions` (confidence_flag: faq_match)
- ✅ Nessun token OpenAI consumato

---

## 💬 SCENARIO 4 — Chat AI Generativa (fuori FAQ)

**Cosa testa:** AI Agent → OpenAI GPT-4o → risposta personalizzata

```bash
curl -X POST $N8N_URL/webhook/hotel-cruise-chat \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "web",
    "sender_id": "web-test-002",
    "sender_name": "Sarah Johnson",
    "message": "Do you have vegetarian options for dinner? I also have a nut allergy.",
    "timestamp": "2025-06-20T11:00:00Z"
  }'
```

**Risultato atteso:**
- ✅ Risposta in inglese (rilevato dalla lingua del messaggio)
- ✅ Menzione opzioni vegetariane e gestione allergie
- ✅ Risposta entro 3-5 secondi (GPT-4o)
- ✅ Interazione loggata con tokens_used

---

## 🚨 SCENARIO 5 — Escalation a Staff

**Cosa testa:** AI Agent → rilevamento [ESCALATE] → notifica Telegram staff

```bash
curl -X POST $N8N_URL/webhook/hotel-cruise-chat \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "whatsapp",
    "sender_id": "+393391234567",
    "sender_name": "Marco Bianchi",
    "message": "C'\''è un problema serio con il riscaldamento della camera 301, fa molto freddo stanotte!",
    "timestamp": "2025-06-20T23:30:00Z"
  }'
```

**Risultato atteso:**
- ✅ AI risponde con empatia e conferma passaggio a staff
- ✅ Notifica Telegram inviata al gruppo staff con messaggio originale
- ✅ Interazione loggata con `escalated: true`
- ✅ Staff può rispondere direttamente su Telegram

---

## ✅ SCENARIO 6 — Check-in Ospite

**Cosa testa:** Check-in → aggiornamento stato prenotazione e camera

```bash
curl -X POST $N8N_URL/webhook/hotel-cruise-checkin \
  -H "Content-Type: application/json" \
  -d '{
    "booking_ref": "HCC-20250620-DEMO03",
    "room_number": "402",
    "checkin_timestamp": "2025-06-20T14:30:00Z",
    "guest_id": 5
  }'
```

**Risultato atteso:**
- ✅ Booking status → CHECKED_IN
- ✅ Room 402 → status: OCCUPIED, current_guest_id: 5

---

## ✅ SCENARIO 7 — Checkout + Post-Checkout Email

**Cosa testa:** Checkout → camera libera → email fidelizzazione (dopo 2h wait)

```bash
curl -X POST $N8N_URL/webhook/hotel-cruise-checkout \
  -H "Content-Type: application/json" \
  -d '{
    "booking_ref": "HCC-20250620-DEMO03",
    "guest_id": 5,
    "guest_email": "a.rossi@company.it",
    "room_number": "402",
    "checkout_timestamp": "2025-06-22T10:45:00Z",
    "final_amount": 840.00
  }'
```

**Risultato atteso:**
- ✅ Booking status → CHECKED_OUT
- ✅ Room 402 → status: NEEDS_CLEANING
- ✅ Email post-soggiorno inviata dopo 2 ore (o subito con wait=0 in test)

---

## 🎂 SCENARIO 8 — CRM Daily Run (Compleanno + Recovery)

**Cosa testa:** Cron giornaliero → segmentazione → email birthday → recovery churned

```bash
# Trigger manuale del workflow CRM (da n8n UI: Execute Workflow)
# Oppure simula tramite API n8n:
curl -X POST http://localhost:5678/api/v1/workflows/[WORKFLOW_ID]/execute \
  -H "X-N8N-API-KEY: your-n8n-api-key"
```

**Risultato atteso:**
- ✅ Lucia Ferraris (churned) → riceve email recovery con codice sconto
- ✅ Ospiti con birthday entro 7 giorni → ricevono email birthday
- ✅ Segmenti aggiornati in DB per tutti gli ospiti

---

## 📊 SCENARIO 9 — Loyalty Points

**Cosa testa:** Aggiunta punti loyalty → verifica tier upgrade

```bash
# Marco Bianchi completa un soggiorno: +30 punti (3 notti × 10)
curl -X POST $N8N_URL/webhook/hotel-cruise-loyalty \
  -H "Content-Type: application/json" \
  -d '{
    "guest_id": 1,
    "event_type": "stay",
    "points_earned": 30,
    "source": "direct"
  }'

# Marco ora ha 480+30=510 punti → supera soglia GOLD (500)
```

**Risultato atteso:**
- ✅ Loyalty points aggiornati a 510
- ✅ Tier upgrade: SILVER → GOLD
- ✅ Email congratulazioni GOLD inviata

---

## 📋 Checklist Validazione Demo Completa

- [ ] Scenario 1: Nuova prenotazione → email ricevuta
- [ ] Scenario 2: Ospite repeat → nessun duplicato in DB
- [ ] Scenario 3: FAQ risponde in <2s
- [ ] Scenario 4: AI risponde in lingua corretta
- [ ] Scenario 5: Notifica staff su Telegram
- [ ] Scenario 6: Room status OCCUPIED
- [ ] Scenario 7: Room status NEEDS_CLEANING
- [ ] Scenario 8: Email recovery churned inviata
- [ ] Scenario 9: Tier GOLD assegnato
- [ ] n8n dashboard: tutte le execution verdi ✅
