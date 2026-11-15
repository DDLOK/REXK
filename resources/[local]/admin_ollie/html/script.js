const $root = document.getElementById('root');
const $tbody = document.getElementById('tbody');
const $search = document.getElementById('search');
const $modal = document.getElementById('modal');

let players = [];

function esc(s){ return String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

function render() {
    const q = ($search.value || '').toLowerCase();
    $tbody.innerHTML = '';
    players.filter(p => !q || String(p.id).includes(q) || (p.name||'').toLowerCase().includes(q) || (p.account||'').toLowerCase().includes(q))
    .forEach(p => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="id">${p.id}</td>
            <td class="name">${esc(p.name)}</td>
            <td class="account">${esc(p.account || '—')}</td>
            <td class="job">${esc(p.job)}</td>
            <td class="cash">$${(p.cash||0).toLocaleString()}</td>
            <td class="actions">
                <button data-action="tpto">TP TO</button>
                <button data-action="bring">BRING</button>
                <button data-action="heal">HEAL</button>
                <button data-action="revive">REVIVE</button>
                <button data-action="armor">ARMOR</button>
                <button data-action="givemoney">+$</button>
                <button data-action="takemoney">-$</button>
                <button data-action="setjob">JOB</button>
                <button data-action="giveweap">GIVE GUN</button>
                <button data-action="givecar">GIVE CAR</button>
                <button data-action="spectate">SPECTATE</button>
                <button data-action="freeze">FREEZE</button>
                <button data-action="unfreeze">UNFREEZE</button>
                <button data-action="makeadmin">ADMIN</button>
                <button data-action="kick" class="danger">KICK</button>
                <button data-action="ban" class="danger">BAN</button>
            </td>`;
        tr.querySelectorAll('button[data-action]').forEach(b => {
            b.addEventListener('click', () => run(b.dataset.action, p));
        });
        $tbody.appendChild(tr);
    });
    if (players.length === 0) $tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:#6b7183">no players online</td></tr>';
}

function openModal(title, placeholder, onOk) {
    document.getElementById('modal-title').textContent = title;
    const body = document.getElementById('modal-body');
    body.innerHTML = `<input id="modal-input" type="text" placeholder="${placeholder}">`;
    $modal.style.display = 'flex';
    const input = document.getElementById('modal-input');
    input.focus();
    document.getElementById('modal-ok').onclick = () => { $modal.style.display = 'none'; onOk(input.value); };
    document.getElementById('modal-cancel').onclick = () => { $modal.style.display = 'none'; };
    input.onkeydown = (e) => { if (e.key === 'Enter') { $modal.style.display = 'none'; onOk(input.value); } };
}

function send(action, target, value) {
    fetch(`https://${GetParentResourceName()}/action`, { method: 'POST', body: JSON.stringify({ action, target, value }) });
    setTimeout(() => fetch(`https://${GetParentResourceName()}/refresh`, { method: 'POST', body: '{}' }), 400);
}

function run(action, p) {
    if (action === 'givemoney' || action === 'takemoney') {
        openModal(action.toUpperCase() + ' ' + p.name, 'amount', v => { if (v) send(action, p.id, v); });
    } else if (action === 'setjob') {
        openModal('SET JOB for ' + p.name, 'police/taxi/trucker/mechanic/criminal/ems/unemployed', v => { if (v) send(action, p.id, v); });
    } else if (action === 'giveweap') {
        openModal('GIVE WEAPON to ' + p.name, 'e.g. WEAPON_CARBINERIFLE', v => { if (v) send(action, p.id, v); });
    } else if (action === 'givecar') {
        openModal('GIVE VEHICLE to ' + p.name, 'e.g. zentorno / adder / rhino', v => { if (v) send(action, p.id, v); });
    } else if (action === 'makeadmin') {
        if (confirm(`Promote ${p.account || p.name} to ADMIN?`)) send(action, p.id, '');
    } else if (action === 'kick' || action === 'ban') {
        if (confirm(`${action.toUpperCase()} ${p.name}?`)) send(action, p.id, '');
    } else {
        send(action, p.id, '');
    }
}

$search.addEventListener('input', render);
document.getElementById('refresh').addEventListener('click', () => fetch(`https://${GetParentResourceName()}/refresh`, { method: 'POST', body: '{}' }));
document.getElementById('close').addEventListener('click', () => fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' }));

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && $root.style.display === 'flex') {
        fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' });
    }
});

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'open')  { $root.style.display = 'flex'; }
    if (d.action === 'close') { $root.style.display = 'none'; $modal.style.display = 'none'; }
    if (d.action === 'players') { players = d.list || []; render(); }
});
