// =========================================================
// account_ollie NUI script - EZK TEAM login/register
// =========================================================

let MODE = 'login';
let BUSY = false;

const $root   = document.getElementById('root');
const $sub    = document.getElementById('sub');
const $user   = document.getElementById('user');
const $pass   = document.getElementById('pass');
const $msg    = document.getElementById('msg');
const $submit = document.getElementById('submit');
const $tabs   = document.querySelectorAll('.tab');
const $form   = document.getElementById('form');

function setMode(m) {
    MODE = m;
    $tabs.forEach(t => t.classList.toggle('active', t.dataset.mode === m));
    $submit.textContent = (m === 'login' ? 'SIGN IN' : 'CREATE ACCOUNT');
    $sub.textContent = (m === 'login')
        ? 'welcome back — sign in to drop'
        : 'new to the bench — pick a user + pass';
    $msg.textContent = '';
    $msg.classList.remove('ok');
    $user.focus();
}

$tabs.forEach(t => t.addEventListener('click', () => setMode(t.dataset.mode)));

function msg(txt, ok) {
    $msg.textContent = txt;
    $msg.classList.toggle('ok', !!ok);
}

async function submit() {
    if (BUSY) return;
    const u = $user.value.trim();
    const p = $pass.value;
    if (!u || !p) { msg('fill both fields'); return; }
    if (u.length < 2) { msg('username too short'); return; }
    if (p.length < 3) { msg('password too short'); return; }

    BUSY = true; $submit.disabled = true;
    msg(MODE === 'login' ? 'signing in…' : 'creating…', true);

    try {
        const r = await fetch(`https://${GetParentResourceName()}/${MODE}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: u, password: p }),
        });
        const data = await r.json();
        if (data.ok) {
            msg(data.msg || 'welcome', true);
            setTimeout(() => close(), 600);
        } else {
            msg(data.msg || 'failed');
        }
    } catch (e) {
        msg('network error');
    } finally {
        BUSY = false; $submit.disabled = false;
    }
}

$form.addEventListener('submit', (e) => { e.preventDefault(); submit(); });
$submit.addEventListener('click', submit);

function open() {
    $root.style.display = 'flex';
    setTimeout(() => $user.focus(), 50);
}
function close() {
    $root.style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closed`, { method: 'POST', body: '{}' });
}

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'open') {
        setMode('login');
        $user.value = '';
        $pass.value = '';
        open();
    } else if (d.action === 'close') {
        close();
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && $root.style.display === 'flex') {
        close();
    }
});
