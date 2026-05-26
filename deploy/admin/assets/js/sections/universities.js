/* universities.js — раздел «Университеты» (отдельный файл, если career.js на сервере старый) */
'use strict';

let _uniPage = 1;

function _uniPaginate(containerId, currentPage, totalPages, loadFn) {
    const el = $(containerId);
    if (!el) return;
    let html = '';
    const start = Math.max(1, currentPage - 2);
    const end = Math.min(totalPages, currentPage + 2);
    if (currentPage > 1) {
        html += `<button class="btn btn-sec btn-sm" onclick="${loadFn.name}(${currentPage - 1})"><i class="fas fa-chevron-left"></i></button>`;
    }
    for (let p = start; p <= end; p++) {
        html += `<button class="btn ${p === currentPage ? 'btn-primary' : 'btn-sec'} btn-sm" onclick="${loadFn.name}(${p})">${p}</button>`;
    }
    if (currentPage < totalPages) {
        html += `<button class="btn btn-sec btn-sm" onclick="${loadFn.name}(${currentPage + 1})"><i class="fas fa-chevron-right"></i></button>`;
    }
    el.innerHTML = html;
}

async function loadUniversities(page) {
    const tb = $('uniTb');
    try {
        if (page) _uniPage = page;
        if (tb) {
            tb.innerHTML = '<tr><td colspan="9"><div class="ldo"><div class="spin"></div></div></td></tr>';
        }
        const search = ($('uniSearch') || {}).value || '';
        const active = ($('uniActive') || {}).value || '';
        const r = await api('GET',
            `api/career/universities.php?limit=25&page=${_uniPage}` +
            `&search=${encodeURIComponent(search)}&is_active=${active}`
        );
        if (!r) {
            if (tb) tb.innerHTML = empty('Не удалось загрузить. Войдите в админку снова.');
            return;
        }
        if (r.error) {
            if (r.redirect) { location.href = r.redirect; return; }
            if (tb) tb.innerHTML = empty(esc(r.error));
            toast(r.error, 'error');
            return;
        }
        const d = r && r.data ? r.data : [];
        if (!tb) return;
        tb.innerHTML = d.length ? d.map(u => `<tr>
        <td>${u.id}</td>
        <td>${u.logo_url ? `<img src="${esc(u.logo_url)}" style="width:40px;height:40px;object-fit:contain;border-radius:6px;background:#fff;padding:2px" onerror="this.style.display='none'">` : '<i class="fas fa-university" style="font-size:24px;color:var(--muted)"></i>'}</td>
        <td><strong>${esc(u.name)}</strong>${u.description ? `<div style="font-size:12px;color:var(--muted);margin-top:2px">${esc(u.description.substring(0, 60))}${u.description.length > 60 ? '…' : ''}</div>` : ''}</td>
        <td>${esc(u.short_name || '—')}</td>
        <td>${esc(u.city || '—')}</td>
        <td>${u.url ? `<a href="${esc(u.url)}" target="_blank" style="color:var(--acc);font-size:12px"><i class="fas fa-external-link-alt"></i> Сайт</a>` : '—'}</td>
        <td>${actBdg(u.is_active)}</td>
        <td>
            <input type="number" value="${u.sort_order}" min="0" style="width:60px;padding:3px 6px;border-radius:6px;background:var(--bg2);border:1px solid var(--border);color:var(--txt)"
                   onchange="quickUniOrder(${u.id}, this.value)">
        </td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" title="Редактировать" onclick="editUniversity(${u.id})"><i class="fas fa-edit"></i></button>
            <button class="btn ${u.is_active ? 'btn-warning' : 'btn-success'} btn-sm btn-ico"
                    title="${u.is_active ? 'Деактивировать' : 'Активировать'}"
                    onclick="toggleUniActive(${u.id}, ${u.is_active})"><i class="fas fa-${u.is_active ? 'eye-slash' : 'eye'}"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" title="Удалить" onclick="delUniversity(${u.id})"><i class="fas fa-trash"></i></button>
        </div></td>
    </tr>`).join('') : empty('Университетов нет. Нажмите «Добавить».');

        if ($('uniPgn') && r && r.pages > 1) {
            _uniPaginate('uniPgn', _uniPage, r.pages, loadUniversities);
        } else if ($('uniPgn')) {
            $('uniPgn').innerHTML = '';
        }
    } catch (e) {
        console.error('loadUniversities:', e);
        if (tb) tb.innerHTML = empty('Ошибка: ' + (e.message || e));
        toast('Ошибка загрузки университетов', 'error');
    }
}

function openUniversity(it) {
    $('uniId').value = it ? it.id : '';
    $('uniName').value = it ? it.name : '';
    $('uniShort').value = it ? it.short_name || '' : '';
    $('uniCity').value = it ? it.city || '' : '';
    $('uniDesc').value = it ? it.description || '' : '';
    $('uniFullText').value = it ? it.full_text || '' : '';
    $('uniPhone').value = it ? it.phone || '' : '';
    $('uniEmail').value = it ? it.email || '' : '';
    $('uniAddress').value = it ? it.address || '' : '';
    $('uniUrl').value = it ? it.url || '' : '';
    $('uniAdmUrl').value = it ? it.admission_url || '' : '';
    $('uniVk').value = it ? it.vk_url || '' : '';
    $('uniTg').value = it ? it.telegram_url || '' : '';
    $('uniLogo').value = it ? it.logo_url || '' : '';
    $('uniCover').value = it ? it.cover_url || '' : '';
    $('uniTags').value = it ? it.tags || '' : '';
    $('uniOrd').value = it ? it.sort_order : 0;
    const chk = document.querySelector('#mUni #uniActive');
    if (chk) chk.checked = !it || !!+it.is_active;
    $('mUniT').textContent = it ? 'Редактировать университет' : 'Добавить университет';
    om('mUni');
}

async function editUniversity(id) {
    const r = await api('GET', `api/career/universities.php?id=${id}`);
    if (r && r.id) openUniversity(r);
    else toast('Не удалось загрузить университет', 'error');
}

async function saveUniversity() {
    const id = $('uniId').value;
    const chk = document.querySelector('#mUni #uniActive');
    const d = {
        name: v('uniName'),
        short_name: v('uniShort'),
        city: v('uniCity'),
        description: v('uniDesc'),
        full_text: $('uniFullText').value,
        phone: v('uniPhone'),
        email: v('uniEmail'),
        address: v('uniAddress'),
        url: v('uniUrl'),
        admission_url: v('uniAdmUrl'),
        vk_url: v('uniVk'),
        telegram_url: v('uniTg'),
        logo_url: v('uniLogo'),
        cover_url: v('uniCover'),
        tags: v('uniTags'),
        sort_order: +$('uniOrd').value || 0,
        is_active: chk ? (chk.checked ? 1 : 0) : 1,
    };
    if (!d.name) { toast('Введите название университета', 'error'); return; }
    const r = await api(
        id ? 'PUT' : 'POST',
        id ? `api/career/universities.php?id=${id}` : 'api/career/universities.php',
        d
    );
    if (r && (r.id || r.name)) {
        toast(id ? 'Университет обновлён' : 'Университет создан');
        cm('mUni');
        loadUniversities();
    } else {
        toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
    }
}

async function toggleUniActive(id, current) {
    const r = await api('PATCH', `api/career/universities.php?id=${id}`, { is_active: current ? 0 : 1 });
    if (r && r.id) {
        toast('Статус обновлён');
        loadUniversities();
    } else toast('Ошибка', 'error');
}

async function quickUniOrder(id, val) {
    await api('PATCH', `api/career/universities.php?id=${id}`, { sort_order: +val });
}

async function delUniversity(id) {
    if (!confirm('Удалить университет?')) return;
    await api('DELETE', `api/career/universities.php?id=${id}`);
    toast('Удалён');
    loadUniversities();
}

window.loadUniversities = loadUniversities;
window.openUniversity = openUniversity;
window.editUniversity = editUniversity;
window.saveUniversity = saveUniversity;
window.toggleUniActive = toggleUniActive;
window.quickUniOrder = quickUniOrder;
window.delUniversity = delUniversity;

(function () {
    const origGo = window.go;
    if (typeof origGo !== 'function') return;
    window.go = function (id, el) {
        origGo(id, el);
        if (id === 'universities') loadUniversities();
    };
})();

console.log('[admin] universities.js OK');
