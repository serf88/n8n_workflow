/**
 * ═══════════════════════════════════════════════════════════
 * Hotel Cruise Como — Chat Widget JS
 * Agentico AI Automation Stack v1.0
 *
 * Comunica con n8n webhook: POST /webhook/hotel-cruise-chat
 * Payload: { channel: "web", sender_id, sender_name, message, timestamp }
 * ═══════════════════════════════════════════════════════════
 */

// ─────────────────────────────────────────────
// CONFIG — adatta per ogni hotel
// ─────────────────────────────────────────────
const HCC_CONFIG = {
    webhookUrl: window.HCC_WEBHOOK_URL || 'https://your-n8n-instance.com/webhook/hotel-cruise-chat',
    hotelName: 'Hotel Cruise Como',
    primaryColor: '#1a3a5c',
    language: 'it',
    sessionKey: 'hcc_session_id',
    welcomeDelay: 800,
};

// ─────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────
let hccSessionId = localStorage.getItem(HCC_CONFIG.sessionKey) || generateSessionId();
let hccIsOpen = false;
let hccMessageCount = 0;

localStorage.setItem(HCC_CONFIG.sessionKey, hccSessionId);

function generateSessionId() {
    return 'web-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
}

// ─────────────────────────────────────────────
// TOGGLE CHAT
// ─────────────────────────────────────────────
function hccToggleChat() {
    const win = document.getElementById('hcc-chat-window');
    hccIsOpen = !hccIsOpen;

    if (hccIsOpen) {
        win.classList.add('open');
        if (hccMessageCount === 0) {
            setTimeout(hccShowWelcome, HCC_CONFIG.welcomeDelay);
        }
        document.getElementById('hcc-input').focus();
    } else {
        win.classList.remove('open');
    }
}

document.getElementById('hcc-chat-launcher').addEventListener('click', hccToggleChat);

// ─────────────────────────────────────────────
// WELCOME MESSAGE
// ─────────────────────────────────────────────
function hccShowWelcome() {
    hccAddMessage(
        'bot',
        '👋 Benvenuto/a a <strong>Hotel Cruise Como</strong>!<br><br>' +
        'Sono il tuo assistente virtuale, disponibile 24/7. ' +
        'Posso aiutarti con informazioni sull\'hotel, attività sul lago, ' +
        'o qualsiasi richiesta durante il tuo soggiorno.<br><br>' +
        '💬 Come posso aiutarti oggi?'
    );
}

// ─────────────────────────────────────────────
// ADD MESSAGE TO UI
// ─────────────────────────────────────────────
function hccAddMessage(role, text) {
    const container = document.getElementById('hcc-messages');

    const msgDiv = document.createElement('div');
    msgDiv.className = 'hcc-msg hcc-msg-' + role;

    const textDiv = document.createElement('div');
    textDiv.innerHTML = text;
    msgDiv.appendChild(textDiv);

    const timeDiv = document.createElement('div');
    timeDiv.className = 'hcc-msg-time';
    timeDiv.textContent = new Date().toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });
    msgDiv.appendChild(timeDiv);

    container.appendChild(msgDiv);
    container.scrollTop = container.scrollHeight;
    hccMessageCount++;
}

// ─────────────────────────────────────────────
// TYPING INDICATOR
// ─────────────────────────────────────────────
function hccShowTyping() {
    const container = document.getElementById('hcc-messages');
    const typing = document.createElement('div');
    typing.id = 'hcc-typing';
    typing.className = 'hcc-typing';
    typing.innerHTML = '<span></span><span></span><span></span>';
    container.appendChild(typing);
    container.scrollTop = container.scrollHeight;
}

function hccHideTyping() {
    const t = document.getElementById('hcc-typing');
    if (t) t.remove();
}

// ─────────────────────────────────────────────
// SEND MESSAGE
// ─────────────────────────────────────────────
async function hccSendMessage() {
    const input = document.getElementById('hcc-input');
    const text = input.value.trim();
    if (!text) return;

    // Mostra messaggio utente
    hccAddMessage('user', text);
    input.value = '';

    // Mostra typing
    hccShowTyping();

    try {
        const response = await fetch(HCC_CONFIG.webhookUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                channel: 'web',
                sender_id: hccSessionId,
                sender_name: 'Ospite Web',
                message: text,
                timestamp: new Date().toISOString(),
                language: HCC_CONFIG.language,
            }),
        });

        hccHideTyping();

        if (!response.ok) throw new Error('HTTP ' + response.status);

        const data = await response.json();
        const reply = data.reply || data.message || 'Risposta non disponibile.';
        hccAddMessage('bot', reply);

    } catch (error) {
        hccHideTyping();
        console.error('[HCC Widget] Errore:', error);

        // Fallback offline — risposte FAQ statiche
        const fallback = hccGetFallbackResponse(text);
        hccAddMessage('bot', fallback);
    }
}

// ─────────────────────────────────────────────
// QUICK REPLY SHORTCUT
// ─────────────────────────────────────────────
function hccSendQuick(text) {
    document.getElementById('hcc-input').value = text;
    hccSendMessage();
}

// ─────────────────────────────────────────────
// FALLBACK OFFLINE (se n8n non raggiungibile)
// ─────────────────────────────────────────────
function hccGetFallbackResponse(message) {
    const msg = message.toLowerCase();

    if (msg.includes('check-in') || msg.includes('checkin')) {
        return '🛎 <strong>Check-in:</strong> dalle 14:00. Per check-in anticipato, contattaci entro le 10:00 del giorno di arrivo.';
    }
    if (msg.includes('check-out') || msg.includes('checkout')) {
        return '🔑 <strong>Check-out:</strong> entro le 11:00. Late checkout disponibile su richiesta (soggetto a disponibilità, €30).';
    }
    if (msg.includes('wifi') || msg.includes('wi-fi') || msg.includes('internet')) {
        return '📶 <strong>WiFi:</strong> Rete <em>HotelCruise_Guest</em>. Password disponibile alla reception o nel welcome folder in camera.';
    }
    if (msg.includes('ristorante') || msg.includes('colazione') || msg.includes('cena')) {
        return '🍽 <strong>Ristorante:</strong><br>• Colazione: 7:00 – 10:30<br>• Cena: 19:00 – 22:30<br>• Room service: 7:00 – 23:00<br><br>Prenotazione cena consigliata!';
    }
    if (msg.includes('parcheggio') || msg.includes('auto') || msg.includes('macchina')) {
        return '🚗 <strong>Parcheggio:</strong> convenzionato Parcheggio Valduce a 200m. Tariffa speciale ospiti: <strong>€8/giorno</strong>. Pass disponibile in reception.';
    }
    if (msg.includes('lago') || msg.includes('como') || msg.includes('tour') || msg.includes('attività')) {
        return '🌊 <strong>Attività sul Lago di Como:</strong><br>• Tour in battello (prenotazione in reception)<br>• Villa del Balbianello<br>• Bellagio (30 min in barca)<br>• Monte Brunate con funicolare<br>• Transfer privato disponibile<br><br>Parliamo in reception per organizzare!';
    }
    if (msg.includes('spa') || msg.includes('benessere') || msg.includes('massaggio')) {
        return '💆 <strong>SPA:</strong> disponibile su prenotazione, ore 9:00 – 20:00. Trattamenti individuali e di coppia. Prenota in reception o via chat!';
    }

    return '🙏 Grazie per il messaggio! Al momento il sistema è temporaneamente non disponibile.<br><br>📞 Per assistenza immediata: <strong>+39 031 XXX XXX</strong><br>📧 Oppure: <strong>info@hotelcruisecomo.it</strong><br><br>Il nostro staff ti risponderà entro pochi minuti.';
}

// ─────────────────────────────────────────────
// AUTO-OPEN dopo 5 secondi (opzionale)
// Decommentare per attivare su sito hotel
// ─────────────────────────────────────────────
// setTimeout(() => {
//     if (!hccIsOpen && !localStorage.getItem('hcc_shown')) {
//         hccToggleChat();
//         localStorage.setItem('hcc_shown', '1');
//     }
// }, 5000);
