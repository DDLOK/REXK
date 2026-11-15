const $toasts = document.getElementById('toasts');
const ICONS = { info: 'i', success: '✓', warning: '!', error: '✕', cash: '$' };

function esc(s) { return String(s||'').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

function toast(title, body, kind, duration) {
    const el = document.createElement('div');
    el.className = 'toast ' + (kind || 'info');
    el.innerHTML = `
        <div class="icon">${ICONS[kind] || 'i'}</div>
        <div class="body">
            <div class="title">${esc(title)}</div>
            ${body ? `<div class="text">${esc(body)}</div>` : ''}
        </div>
        <div class="progress" style="animation-duration:${duration}ms"></div>
    `;
    $toasts.appendChild(el);
    setTimeout(() => {
        el.classList.add('closing');
        setTimeout(() => el.remove(), 260);
    }, duration);
}

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'notify') toast(d.title, d.body, d.kind, d.duration || 4000);
});
