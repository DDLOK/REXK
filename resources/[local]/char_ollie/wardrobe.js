const $wroot = document.getElementById('wroot');
const $wname = document.getElementById('wname');
const $wtabs = document.getElementById('wtabs');
const $wlist = document.getElementById('wlist');

const TABS = [
    { id: 'head',   label: 'Head',   kind: 'comp', items: [
        { c: 0,  name: 'Face' },
        { c: 2,  name: 'Hair' },
        { c: 1,  name: 'Mask' },
    ] },
    { id: 'top',    label: 'Top',    kind: 'comp', items: [
        { c: 11, name: 'Top' },
        { c: 3,  name: 'Torso' },
        { c: 8,  name: 'Undershirt' },
        { c: 10, name: 'Decals' },
    ] },
    { id: 'bottom', label: 'Bottom', kind: 'comp', items: [
        { c: 4,  name: 'Pants' },
        { c: 6,  name: 'Shoes' },
    ] },
    { id: 'acc',    label: 'Acc',    kind: 'comp', items: [
        { c: 5,  name: 'Bag/Parachute' },
        { c: 7,  name: 'Accessories' },
        { c: 9,  name: 'Body Armor' },
    ] },
    { id: 'props',  label: 'Props',  kind: 'prop', items: [
        { c: 0, name: 'Hat' },
        { c: 1, name: 'Glasses' },
        { c: 2, name: 'Ears' },
        { c: 6, name: 'Watch' },
        { c: 7, name: 'Bracelet' },
    ] },
];

let activeTab = 'head';
let currentName = '';
let state = { comps: {}, props: {} };   // { '3': [drawable, texture], ... }

function setTab(id) {
    activeTab = id;
    document.querySelectorAll('.wtab').forEach(t => t.classList.toggle('active', t.dataset.id === id));
    renderList();
}

function renderTabs() {
    $wtabs.innerHTML = '';
    TABS.forEach(t => {
        const b = document.createElement('button');
        b.className = 'wtab' + (t.id === activeTab ? ' active' : '');
        b.dataset.id = t.id;
        b.textContent = t.label;
        b.onclick = () => setTab(t.id);
        $wtabs.appendChild(b);
    });
}

function current(kind, c) {
    const store = (kind === 'comp') ? state.comps : state.props;
    return store[c] || [0, 0];
}
function setCurrent(kind, c, d, t) {
    const store = (kind === 'comp') ? state.comps : state.props;
    store[c] = [d, t];
    sendLive(kind, c, d, t);
}

function sendLive(kind, c, d, t) {
    fetch(`https://${GetParentResourceName()}/liveChange`, {
        method: 'POST',
        body: JSON.stringify({ kind, component: c, drawable: d, texture: t }),
    });
}

function renderList() {
    $wlist.innerHTML = '';
    const tab = TABS.find(t => t.id === activeTab);
    if (!tab) return;
    tab.items.forEach(it => {
        const row = document.createElement('div');
        row.className = 'wrow';
        const cur = current(tab.kind, it.c);
        row.innerHTML = `
            <div class="label">${it.name}</div>
            <div class="ctrl">
                <button data-dir="-1" data-kind="d">‹</button>
                <div class="val"><span class="dv">${cur[0]}</span> / <span class="tv">${cur[1]}</span></div>
                <button data-dir="+1" data-kind="d">›</button>
            </div>
            <div class="ctrl">
                <button data-dir="-1" data-kind="t">‹ tex</button>
                <div class="val" style="opacity:0.7">texture</div>
                <button data-dir="+1" data-kind="t">tex ›</button>
            </div>`;
        row.querySelectorAll('button').forEach(b => {
            b.addEventListener('click', () => {
                let [d, t] = current(tab.kind, it.c);
                const dir = parseInt(b.dataset.dir);
                if (b.dataset.kind === 'd') { d = Math.max(-1, d + dir); }
                else { t = Math.max(0, t + dir); }
                setCurrent(tab.kind, it.c, d, t);
                row.querySelector('.dv').textContent = d;
                row.querySelector('.tv').textContent = t;
            });
        });
        $wlist.appendChild(row);
    });
}

document.getElementById('wback').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/wardrobeBack`, { method: 'POST', body: '{}' });
});

document.getElementById('wreset').addEventListener('click', () => {
    state = { comps: {}, props: {} };
    fetch(`https://${GetParentResourceName()}/wardrobeReset`, { method: 'POST', body: '{}' });
    renderList();
});

document.getElementById('wrandom').addEventListener('click', () => {
    TABS.forEach(t => t.items.forEach(it => {
        const d = Math.floor(Math.random() * 10);
        const tx = Math.floor(Math.random() * 4);
        setCurrent(t.kind, it.c, d, tx);
    }));
    renderList();
});

document.getElementById('wsave').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/wardrobeSave`, {
        method: 'POST',
        body: JSON.stringify({ comps: state.comps, props: state.props }),
    });
});

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'openWardrobe') {
        currentName = d.name || '';
        state = { comps: d.comps || {}, props: d.props || {} };
        $wname.textContent = currentName;
        $wroot.style.display = 'flex';
        setTab('head');
        renderTabs();
    } else if (d.action === 'closeWardrobe') {
        $wroot.style.display = 'none';
    }
});
