# 🏨 Hotel Cruise Como — Agentico AI Automation Stack

> **Versione:** 1.0.0  
> **Autore:** Toni — CTO Agentico  
> **Cliente:** Hotel Cruise Como, Lago di Como  
> **Ultimo aggiornamento:** Giugno 2025

---

## 📋 Panoramica

Suite completa di automazioni AI per Hotel Cruise Como (35 camere).  
Tre workflow n8n integrati che coprono l'intero ciclo di vita dell'ospite.

```
[Booking.com / Airbnb / Direct]
         ↓
   n8n Orchestration
    ├── AI Agent 24/7 (WhatsApp + Telegram + Web)
    ├── Booking Sync → Camera → Email → Housekeeping
    └── CRM + Upselling + Loyalty
         ↓
   PostgreSQL (ospiti, prenotazioni, interazioni)
```

---

## 🗂 Struttura Repository

```
workflows/hospitality/
├── ai-agent-customer-service.json      # Workflow 1: AI Agent 24/7
├── booking-automation-sync.json         # Workflow 2: Booking → Check-in → Checkout
├── crm-upselling-automation.json        # Workflow 3: CRM + Loyalty + Email
│
├── docker-compose/
│   ├── docker-compose.yml              # Stack: n8n + PostgreSQL + Redis
│   └── .env.example                    # Template variabili ambiente
│
├── database/
│   ├── schema.sql                      # Schema PostgreSQL (5 tabelle)
│   └── seed-data.sql                   # Dati demo (ospiti, camere, prenotazioni)
│
├── frontend/
│   ├── chat-widget.html                # Widget chat embeddable
│   └── chat-widget.js                  # Logica comunicazione con n8n
│
└── docs/
    ├── README.md                       # Questo file
    ├── API_ENDPOINTS.md                # Endpoint webhook n8n
    └── DEMO_SCENARIOS.md               # Script test funzionale
```

---

## 🚀 Setup Rapido (Sviluppo Locale)

### Prerequisiti
- Docker & Docker Compose installati
- Git
- Porta 5678 (n8n), 5432 (PostgreSQL), 6379 (Redis) libere

### Step 1: Clone e configurazione

```bash
git clone https://github.com/serf88/n8n_workflow.git
cd n8n_workflow/workflows/hospitality/docker-compose

# Copia e configura il file .env
cp .env.example .env
# Edita .env con i tuoi valori (vedi sezione Variabili)
nano .env
```

### Step 2: Avvio stack

```bash
# Avvio standard (n8n + PostgreSQL + Redis)
docker compose up -d

# Con pgAdmin per debug DB (porta 5050)
docker compose --profile debug up -d
```

### Step 3: Verifica

```bash
# Controlla che tutti i container siano running
docker compose ps

# Log n8n
docker compose logs -f n8n

# Log PostgreSQL
docker compose logs -f postgres
```

### Step 4: Accesso n8n

Apri nel browser: `http://localhost:5678`
- **Username:** valore di `N8N_USER` nel .env
- **Password:** valore di `N8N_PASSWORD` nel .env

### Step 5: Import workflow

1. In n8n → **Workflows** → **Import from file**
2. Importa in ordine:
   - `ai-agent-customer-service.json`
   - `booking-automation-sync.json`
   - `crm-upselling-automation.json`
3. Configura le credential (vedi sezione sotto)
4. Attiva tutti i workflow

---

## 🔑 Credential n8n da configurare

| Credential Name | Tipo | Note |
|---|---|---|
| `PostgreSQL Hotel Cruise` | Postgres | Host: postgres, DB: hotel_cruise_db |
| `OpenAI Hotel Cruise` | OpenAI API | Key da .env |
| `SendGrid Hotel Cruise` | SMTP | Host: smtp.sendgrid.net, porta 587 |
| `Telegram Bot Hotel Cruise Staff` | Telegram API | Token bot staff |

Per ogni credential: **Settings → Credentials → New** in n8n.

---

## 🌱 Variabili Ambiente (.env)

| Variabile | Descrizione | Esempio |
|---|---|---|
| `N8N_USER` | Username accesso n8n | `admin` |
| `N8N_PASSWORD` | Password accesso n8n | stringa forte |
| `N8N_WEBHOOK_BASE_URL` | URL pubblico n8n | `https://n8n.tuodominio.it` |
| `OPENAI_API_KEY` | Chiave OpenAI | `sk-...` |
| `SENDGRID_API_KEY` | Chiave SendGrid | `SG.xxx` |
| `TELEGRAM_BOT_TOKEN` | Token bot Telegram | `123456:ABC-xxx` |
| `TELEGRAM_STAFF_CHAT_ID` | Chat ID gruppo staff | `-100123456789` |
| `TWILIO_ACCOUNT_SID` | Twilio SID | `ACxxx` |
| `TWILIO_AUTH_TOKEN` | Twilio Token | secret |
| `DEMO_MODE` | Override email a indirizzo test | `true` |

---

## 📡 Webhook Endpoints (n8n attivo)

| Endpoint | Workflow | Descrizione |
|---|---|---|
| `POST /webhook/hotel-cruise-chat` | AI Agent | Riceve messaggi chat (WhatsApp/Telegram/Web) |
| `POST /webhook/hotel-cruise-booking` | Booking Sync | Nuova prenotazione da OTA o direct |
| `POST /webhook/hotel-cruise-checkin` | Booking Sync | Evento check-in ospite |
| `POST /webhook/hotel-cruise-checkout` | Booking Sync | Evento checkout ospite |
| `POST /webhook/hotel-cruise-loyalty` | CRM | Aggiornamento punti loyalty |

---

## 🧪 Test Rapido Demo

```bash
# Test 1: Simula messaggio WhatsApp
curl -X POST http://localhost:5678/webhook/hotel-cruise-chat \
  -H "Content-Type: application/json" \
  -d '{"channel":"web","sender_id":"test-123","sender_name":"Ospite Test","message":"Qual è la password del WiFi?","timestamp":"2025-06-20T10:00:00Z"}'

# Test 2: Simula nuova prenotazione Booking.com
curl -X POST http://localhost:5678/webhook/hotel-cruise-booking \
  -H "Content-Type: application/json" \
  -d '{"source":"booking.com","booking_id":"BK-TEST-001","guest_name":"Mario Rossi","guest_email":"mario.rossi@test.it","guest_phone":"+39333111222","checkin_date":"2025-07-10","checkout_date":"2025-07-13","room_type":"superior","special_requests":"","dietary_restrictions":"","total_amount":510.00}'
```

Per scenari completi → vedi [DEMO_SCENARIOS.md](DEMO_SCENARIOS.md)

---

## 💰 ROI Stimato (Hotel 35 camere)

| KPI | Prima | Dopo | Risparmio |
|---|---|---|---|
| Risposte FAQ (ore/mese) | 40h | 4h | **36h/mese** |
| Gestione prenotazioni (ore/mese) | 20h | 5h | **15h/mese** |
| Email manuali (ore/mese) | 10h | 0.5h | **9.5h/mese** |
| **Totale ore risparmiate** | | | **~60h/mese** |
| **Valore economico (€15/h)** | | | **~€900/mese** |
| Conversione upselling (+5%) | | | **+€400/mese stimato** |

---

## 🔧 Personalizzazione per Altro Hotel

Per adattare questa suite a un nuovo cliente:

1. **`.env`** → Aggiorna tutte le chiavi API e credenziali
2. **`ai-agent-customer-service.json`** → Modifica il system prompt AI (nome hotel, orari, servizi)
3. **`seed-data.sql`** → Sostituisci con dati reali o vuoti
4. **`chat-widget.html`** → Aggiorna colori brand e nome hotel
5. **`docker-compose.yml`** → Nessuna modifica necessaria (usa .env)

Tempo stimato di re-branding: **2-3 ore**.

---

## 📞 Supporto

**Agentico Srl** — Como / Ticino  
🌐 [agentico.it](https://agentico.it)  
📧 info@agentico.it  
👤 CTO: Toni | CEO: Simone
