const $root = document.getElementById('root');
const $time = document.getElementById('time');
const $user = document.getElementById('user');
const $job  = document.getElementById('job');
const $cash = document.getElementById('cash');
const $bankBal = document.getElementById('bank-bal');
const $jobsList = document.getElementById('jobs-list');
const $contactsList = document.getElementById('contacts-list');
const $dock = document.querySelectorAll('.dockbtn');
const $views = document.querySelectorAll('.view');

let state = { cash: 0, job: 'unemployed', jobLabel: 'Unemployed', onDuty: false, catalog: {} };

function setView(name) {
    $views.forEach(v => v.style.display = (v.id === 'view-' + name) ? '' : 'none');
    $dock.forEach(b => b.classList.toggle('active', b.dataset.view === name));
}

function renderJobs() {
    $jobsList.innerHTML = '';
    for (const id in state.catalog) {
        const j = state.catalog[id];
        const row = document.createElement('div');
        row.className = 'row' + (id === state.job ? ' active' : '');
        row.innerHTML = `<div><div class="title">${j.label}</div><div class="meta">$${j.salary}/payday</div></div><div class="meta">${id === state.job ? '✓' : 'apply'}</div>`;
        row.onclick = () => {
            fetch(`https://${GetParentResourceName()}/applyJob`, { method: 'POST', body: JSON.stringify({ job: id }) });
        };
        $jobsList.appendChild(row);
    }
}

function renderContacts(list) {
    $contactsList.innerHTML = '';
    if (!list || list.length === 0) {
        $contactsList.innerHTML = '<div class="row"><div class="title">(no one online)</div></div>';
        return;
    }
    list.forEach(p => {
        const row = document.createElement('div');
        row.className = 'row' + (p.self ? ' active' : '');
        row.innerHTML = `<div><div class="title">${escapeHtml(p.name)}</div><div class="meta">id ${p.id}${p.self ? ' (you)' : ''}</div></div>`;
        if (!p.self) {
            row.onclick = () => {
                document.getElementById('pay-id').value = p.id;
                setView('bank');
            };
        }
        $contactsList.appendChild(row);
    });
}

function escapeHtml(s) { return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

function updateTime() {
    const d = new Date();
    $time.textContent = d.getHours().toString().padStart(2,'0') + ':' + d.getMinutes().toString().padStart(2,'0');
}
setInterval(updateTime, 10000); updateTime();

$dock.forEach(b => b.addEventListener('click', () => setView(b.dataset.view)));

document.getElementById('duty-btn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/duty`, { method: 'POST', body: '{}' });
});

document.getElementById('pay-btn').addEventListener('click', () => {
    const id = document.getElementById('pay-id').value;
    const amt = document.getElementById('pay-amt').value;
    if (!id || !amt) return;
    fetch(`https://${GetParentResourceName()}/pay`, { method: 'POST', body: JSON.stringify({ targetId: parseInt(id), amount: parseInt(amt) }) });
    document.getElementById('pay-amt').value = '';
});

document.getElementById('gps-btn').addEventListener('click', () => {
    const x = document.getElementById('gps-x').value;
    const y = document.getElementById('gps-y').value;
    if (!x || !y) return;
    fetch(`https://${GetParentResourceName()}/setWaypoint`, { method: 'POST', body: JSON.stringify({ x, y }) });
});

const presets = [
    { n: 'Legion Sq',     x: 215,   y: -810 },
    { n: 'LSIA Airport',  x: -1037, y: -2737 },
    { n: 'Pillbox Hosp',  x: 307,   y: -599 },
    { n: 'Mission Row PD',x: 428,   y: -981 },
    { n: 'Casino',        x: 925,   y: 46 },
    { n: 'Paleto Bay',    x: -275,  y: 6635 },
];
const $presets = document.getElementById('gps-presets');
presets.forEach(p => {
    const b = document.createElement('button');
    b.textContent = p.n;
    b.onclick = () => fetch(`https://${GetParentResourceName()}/setWaypoint`, { method: 'POST', body: JSON.stringify({ x: p.x, y: p.y }) });
    $presets.appendChild(b);
});

document.addEventListener('keydown', (e) => {
    if ((e.key === 'F1' || e.key === 'Escape') && $root.style.display === 'flex') {
        fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' });
    }
});

window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d) return;
    if (d.action === 'open') {
        $root.style.display = 'flex';
        setView('jobs');
    } else if (d.action === 'close') {
        $root.style.display = 'none';
    } else if (d.action === 'cash') {
        state.cash = d.value;
        $cash.textContent = '$' + d.value.toLocaleString();
        $bankBal.textContent = '$' + d.value.toLocaleString();
    } else if (d.action === 'job') {
        state.job = d.job;
        state.jobLabel = d.label;
        state.onDuty = d.onDuty;
        $job.textContent = d.label + (d.onDuty ? ' • ON DUTY' : '');
        renderJobs();
    } else if (d.action === 'jobCatalog') {
        state.catalog = d.catalog;
        renderJobs();
    } else if (d.action === 'contacts') {
        renderContacts(d.list);
    }
});
