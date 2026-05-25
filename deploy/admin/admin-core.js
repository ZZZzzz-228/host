/* ================================================================
   АКСИБГУУ Admin Panel — Core JS
   Утилиты, навигация, тема, тост, модалки, лайтбокс, клок
   ================================================================ */

/* ── CORE HELPERS ──────────────────────────────────────────────── */
const $ = id => document.getElementById(id);
const v = id => $(id).value.trim();
const esc = s => s == null ? '' : String(s)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const fd  = d => d ? new Date(typeof d === 'number' ? d : d).toLocaleString('ru-RU',{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'}) : '—';
const fdo = d => d ? new Date(d).toLocaleDateString('ru-RU') : '—';

/* Хелпер для миниатюры фото в таблицах */
function thumb(url, alt) {
    if (!url) return '<span style="color:#555;font-size:11px">—</span>';
    return `<img src="${esc(url)}" alt="${esc(alt||'фото')}"
        style="width:36px;height:36px;object-fit:cover;border-radius:6px;cursor:pointer;border:1px solid rgba(255,255,255,.1)"
        onclick="openLB('${esc(url)}')" onerror="this.style.display='none'">`;
}

/* ── API FETCH ─────────────────────────────────────────────────── */
async function api(m, u, d) {
    try {
        const o = { method: m, headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' } };
        if (d) o.body = JSON.stringify(d);
        const r = await fetch(u, o);
        if (r.status === 204) return null;
        const text = await r.text();
        try {
            return JSON.parse(text);
        } catch(e) {
            console.error('API non-JSON response:', text.slice(0, 300));
            toast('Ошибка сервера. Подробности в консоли.', 'error');
            return null;
        }
    } catch(e) {
        console.error('API fetch error:', e);
        toast('Ошибка сети: ' + e.message, 'error');
        return null;
    }
}

/* ── TOAST ─────────────────────────────────────────────────────── */
function toast(msg, type = 'success') {
    const icons = { success:'fa-check-circle', error:'fa-exclamation-circle', warning:'fa-exclamation-triangle', info:'fa-info-circle' };
    const cls   = { success:'ts', error:'te', warning:'tw2', info:'tii' };
    const t = document.createElement('div');
    t.className = `toast ${cls[type] || 'tii'}`;
    t.innerHTML = `<i class="fas ${icons[type] || 'fa-info-circle'} ti"></i><span>${msg}</span>`;
    $('tc').appendChild(t);
    setTimeout(() => { t.classList.add('fo'); setTimeout(() => t.remove(), 320); }, 3500);
}

/* ── MODAL ─────────────────────────────────────────────────────── */
const om = id => $(id).classList.add('open');
const cm = id => $(id).classList.remove('open');
document.addEventListener('click', e => { if (e.target.classList.contains('mo')) e.target.classList.remove('open'); });

/* ── SIDEBAR ───────────────────────────────────────────────────── */
function toggleSB() { $('sb').classList.toggle('open'); $('sbov').classList.toggle('open'); }
function closeSB()  { $('sb').classList.remove('open'); $('sbov').classList.remove('open'); }

/* ── CLOCK ─────────────────────────────────────────────────────── */
function tick() { $('clk').textContent = new Date().toLocaleString('ru-RU',{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'}); }
setInterval(tick, 1000);
tick();

/* ── INIT AVATAR ───────────────────────────────────────────────── */
(function() {
    const n = $('sbName').textContent.trim();
    $('sbAv').textContent = n.charAt(0).toUpperCase();
})();

/* ── LIGHTBOX ──────────────────────────────────────────────────── */
function openLB(s) { $('lb-img').src = s; $('lb').classList.add('open'); }
function closeLB()  { $('lb').classList.remove('open'); }
$('lb').addEventListener('click', e => { if (e.target === $('lb')) closeLB(); });

/* ── RENDER HELPERS ────────────────────────────────────────────── */
function bdg(t, c) { return `<span class="bdg ${c}">${esc(t)}</span>`; }
function pubBdg(vl) { return vl ? bdg('Опубликовано','bs') : bdg('Скрыто','bm'); }
function actBdg(vl) { return vl ? bdg('Активно','bs') : bdg('Неактивно','bm'); }
function empty(t) { return `<tr><td colspan="99"><div class="empty"><i class="fas fa-inbox"></i><p>${t}</p></div></td></tr>`; }

function pgn(total, page, pp, fn) {
    const pages = Math.ceil(total / pp);
    if (pages <= 1) return '';
    let h = '';
    if (page > 1) h += `<button class="pbtn" onclick="${fn}(${page - 1})">‹</button>`;
    for (let i = Math.max(1, page - 2); i <= Math.min(pages, page + 2); i++)
        h += `<button class="pbtn${i === page ? ' act' : ''}" onclick="${fn}(${i})">${i}</button>`;
    if (page < pages) h += `<button class="pbtn" onclick="${fn}(${page + 1})">›</button>`;
    return h;
}

const DAYS = ['','Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'];

/* ── NAVIGATION ────────────────────────────────────────────────── */
const titles = {
    dashboard:'Дашборд', news:'Новости', stories:'Истории', vk:'ВК-очередь',
    'about-college':'О колледже', contacts:'Контакты', apps:'Заявки',
    specs:'Специальности', eduprog:'Доп. программы',
    depts:'Отделения', groups:'Учебные группы', disciplines:'Дисциплины',
    schedule:'Расписание', staff:'Сотрудники', students:'Студенты',
    resumes:'Резюме', portfolio:'Портфолио', vacancies:'Вакансии',
    cevents:'Мероприятия', partners:'Партнёры', universities:'Университеты',
    'career-contacts':'Контакты Центр карьеры',
    docs:'Документы', admins:'Администраторы', settings:'Настройки', logs:'Журнал',
    'career-test':'Тесты профориентации'
};

const loaders = {
    dashboard:()=>loadDash(), news:()=>loadNews(), stories:()=>loadStories(), vk:()=>loadVK(),
    'about-college':()=>acLoad(), contacts:()=>loadContacts(), apps:()=>loadApps(),
    specs:()=>loadSpecs(), eduprog:()=>loadEduProgs(), depts:()=>loadDepts(),
    groups:()=>loadGroups(), disciplines:()=>loadDiscs(), schedule:()=>loadSched(),
    staff:()=>loadStaff(), students:()=>loadStudents(), resumes:()=>loadResumes(),
    portfolio:()=>loadPortfolio(), vacancies:()=>loadVacs(), cevents:()=>loadCEvents(),
    partners:()=>loadPartners(),
    universities:()=>{ if (typeof loadUniversities === 'function') loadUniversities(); },
    'career-contacts':()=>{ if (typeof loadCareerContacts === 'function') loadCareerContacts(); },
    docs:()=>loadDocs(), admins:()=>loadAdmins(),
    settings:()=>loadSettings(), logs:()=>loadLogs(),
    'career-test':()=>loadCareerTests()
};

function go(id, el) {
    document.querySelectorAll('.sec').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const sec = $('s-' + id);
    if (!sec) return;
    sec.classList.add('active');
    if (el) el.classList.add('active');
    /* Активируем нужный nav-item в сайдбаре если вызвано без el */
    if (!el) {
        const navEl = document.querySelector(`.nav-item[onclick*="go('${id}'"]`);
        if (navEl) navEl.classList.add('active');
    }
    $('tbTitle').textContent = titles[id] || id;
    if (loaders[id]) loaders[id]();
    /* Сохраняем активную секцию */
    localStorage.setItem('aksibgu_section', id);
    closeSB();
}

/* ── LOGOUT ────────────────────────────────────────────────────── */
async function doLogout() {
    if (!confirm('Выйти?')) return;
    await api('POST', 'api/logout.php');
    location.href = 'login.php';
}

/* ── THEME TOGGLE ──────────────────────────────────────────────── */
function toggleTheme() {
    const html = document.documentElement;
    const isLight = html.classList.toggle('light');
    const theme = isLight ? 'light' : 'dark';
    localStorage.setItem('aksibgu_theme', theme);
    /* Сохраняем в куку для PHP (нет мигания при перезагрузке) */
    document.cookie = 'aksibgu_theme=' + theme + ';path=/;max-age=31536000';
    const ico = $('themeIco');
    if (ico) ico.className = isLight ? 'fas fa-sun' : 'fas fa-moon';
    const btn = $('btnTheme');
    if (btn) btn.title = isLight ? 'Тёмная тема' : 'Светлая тема';
}

/* ── INIT THEME ────────────────────────────────────────────────── */
(function() {
    /* Тема уже применена в <head> через inline-script.
       Здесь только синхронизируем иконку. */
    const isLight = document.documentElement.classList.contains('light');
    const ico = $('themeIco');
    if (ico) ico.className = isLight ? 'fas fa-sun' : 'fas fa-moon';
    const btn = $('btnTheme');
    if (btn) btn.title = isLight ? 'Тёмная тема' : 'Светлая тема';
})();

/* ── INIT SECTION (восстанавливаем раздел после F5) ─────────────── */
window.addEventListener('DOMContentLoaded', function() {
    const saved = localStorage.getItem('aksibgu_section') || 'dashboard';
    /* Небольшая задержка — ждём загрузки всех JS-модулей */
    setTimeout(function() {
        go(saved);
        loadDash(); /* Дашборд обновляем всегда */
    }, 50);
});