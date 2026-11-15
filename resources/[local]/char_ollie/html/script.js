const $root = document.getElementById('root');
const $slots = document.getElementById('slots');
const $modal = document.getElementById('modal');
const $newName = document.getElementById('new-name');
let currentData = { chars: [], selected: null };
let creatingIdx = null;
let gender = 'male';

function render() {
    $slots.innerHTML = '';
    for (let i = 1; i <= 4; i++) {
        const c = currentData.chars[i];
        const sel = currentData.selected === i;
        const row = document.createElement('div');
        row.className = 'slot' + (!c ? ' empty' : '') + (sel ? ' selected' : '');
        if (c) {
            row.innerHTML = `
                <div class="left">
                    <div class="num">${String(i).padStart(2, '0')}</div>
                    <div>
                        <div class="name">${esc(c.name)}</div>
                        <div class="meta">${c.model === 'mp_f_freemode_01' ? 'Female' : 'Male'}</div>
                    </div>
                </div>
                <div class="right">
                    <button class="btn primary" data-act="select" data-idx="${i}">${sel ? 'PICK' : 'LOAD'}</button>
                    <button class="btn danger" data-act="delete" data-idx="${i}">DEL</button>
                </div>`;
        } else {
            row.innerHTML = `
                <div class="left">
                    <div class="num">${String(i).padStart(2, '0')}</div>
                    <div class="empty-text">nothing</div>
                </div>
                <div class="right">
                    <button class="btn primary" data-act="new" data-idx="${i}">CREATE</button>
                </div>`;
        }
        row.querySelectorAll('button[data-act]').forEach(b => {
            b.addEventListener('click', (e) => {
                e.stopPropagation();
                handleAction(b.dataset.act, parseInt(b.dataset.idx));
            });
        });
        $slots.appendChild(row);
    }
}

function handleAction(act, idx) {
    if (act === 'select') {
        fetch(`https://${GetParentResourceName()}/selectChar`, { method: 'POST', body: JSON.stringify({ idx }) });
    } else if (act === 'delete') {
        if (confirm('Delete this character?')) {
            fetch(`https://${GetParentResourceName()}/deleteChar`, { method: 'POST', body: JSON.stringify({ idx }) });
        }
    } else if (act === 'new') {
        creatingIdx = idx;
        $newName.value = '';
        gender = 'male';
        document.getElementById('g-male').classList.add('active');
        document.getElementById('g-female').classList.remove('active');
        $modal.style.display = 'flex';
        setTimeout(() => $newName.focus(), 50);
    }
}

function esc(s){ return String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

document.querySelectorAll('.g').forEach(b => b.addEventListener('click', () => {
    gender = b.dataset.g;
    document.querySelectorAll('.g').forEach(x => x.classList.toggle('active', x.dataset.g === gender));
}));

document.getElementById('create-cancel').addEventListener('click', () => { $modal.style.display = 'none'; });

document.getElementById('create-ok').addEventListener('click', () => {
    const name = $newName.value.trim();
    if (!name || name.length < 2) { alert('name too short'); return; }
    fetch(`https://${GetParentResourceName()}/createChar`, { method: 'POST', body: JSON.stringify({ idx: creatingIdx, name, gender }) });
    $modal.style.display = 'none';
});

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'openChar') { $root.style.display = 'flex'; }
    if (d.action === 'closeChar') { $root.style.display = 'none'; $modal.style.display = 'none'; }
    if (d.action === 'charList') { currentData = d.data || { chars: [], selected: null }; render(); }
});
