const $v = document.getElementById('cash-val');
const $h = document.getElementById('cash-hud');
let prev = 0;

window.addEventListener('message', (e) => {
    if (e.data && e.data.action === 'cash') {
        const n = e.data.value;
        $v.textContent = n.toLocaleString();
        if (n !== prev) {
            $h.classList.remove('flash');
            void $h.offsetWidth;
            $h.classList.add('flash');
            prev = n;
        }
    }
});
