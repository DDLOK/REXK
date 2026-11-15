// =========================================================
// loadscreen script - EZK TEAM
// listens to FXServer loadscreen events + animates
// =========================================================

const $step = document.getElementById('step');
const $fill = document.getElementById('fill');
const $pct  = document.getElementById('pct');
const $hint = document.getElementById('hint');
const $host = document.getElementById('hostname');
const $slot = document.getElementById('slots');
const $ping = document.getElementById('ping');
const $tip  = document.getElementById('tip');

const TIPS = [
    'press F5 once in game for the main menu',
    '/login <user> <pass> to use your account',
    '/register <user> <pass> first time',
    '/home teleports to your assigned house',
    'F5 → Self → Clothing to change your outfit',
    'F5 → Vehicles for the spawner',
    'F5 → Teleports for 16 preset locations',
    '/me <action> to emote in chat',
    '/pm <id> <msg> for private messages',
    'welcome to SAN VALLY STATE',
];

let tipIdx = 0;
setInterval(() => {
    tipIdx = (tipIdx + 1) % TIPS.length;
    $tip.style.animation = 'none';
    void $tip.offsetWidth;
    $tip.textContent = TIPS[tipIdx];
    $tip.style.animation = '';
}, 3500);

// FXServer loadscreen events
window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d) return;
    switch (d.eventName) {
        case 'loadProgress':
            const p = Math.round((d.loadFraction || 0) * 100);
            $fill.style.width = p + '%';
            $pct.textContent = p + '%';
            break;
        case 'startInitFunction':
            $step.textContent = labelFor(d.type || d.name) || 'loading';
            $hint.textContent = (d.type || '').toLowerCase();
            break;
        case 'onLogLine':
            $hint.textContent = (d.message || '').slice(0, 60);
            break;
        case 'startDataFileEntries':
            $step.textContent = 'streaming assets';
            break;
        case 'performMapLoadFunction':
            $step.textContent = 'baking the world';
            break;
        case 'onSetServerName':
            $host.textContent = d.data || 'EZK TEAM';
            break;
        case 'serverInfo':
            if (d.hostname) $host.textContent = d.hostname.replace(/\^[0-9]/g, '');
            if (d.slots)    $slot.textContent = (d.players || '0') + ' / ' + d.slots;
            if (d.ping)     $ping.textContent = d.ping + ' ms';
            break;
    }
});

function labelFor(k) {
    const map = {
        'DLC':       'loading dlc packs',
        'ONLINE':    'connecting to the city',
        'MAP':       'streaming map tiles',
        'SESSION':   'joining the session',
        'FINALIZE':  'last pass before you drop in',
        'IPL':       'loading interiors',
        'WEAPON':    'loading weapons',
        'VEHICLE':   'loading vehicles',
        'PED':       'loading characters',
    };
    if (!k) return null;
    const up = String(k).toUpperCase();
    for (const key in map) if (up.indexOf(key) !== -1) return map[key];
    return 'loading ' + String(k).toLowerCase();
}
