/* ═══════════════════════════════════════════════════════════════
   career.js — Карьерный раздел (Portfolio, Resumes, Vacancies,
                                  Events, Universities)
   ═══════════════════════════════════════════════════════════════ */

/* ── RESUMES ────────────────────────────────────────────────── */
let _rvPage = 1;

async function loadResumes(page) {
    if (page) _rvPage = page;
    const search = ($('rvSearch') || {}).value || '';
    const pub    = ($('rvPub')    || {}).value || '';
    const r = await api('GET', `api/career/resumes.php?limit=25&page=${_rvPage}&search=${encodeURIComponent(search)}&is_published=${pub}`);
    const d = r && r.data ? r.data : [];
    $('rvTb').innerHTML = d.length ? d.map(rv => `<tr>
        <td>${rv.id}</td>
        <td>${esc(rv.full_name || rv.student_name || '—')}</td>
        <td><strong>${esc(rv.desired_position || rv.title || '—')}</strong></td>
        <td>${esc(rv.specialty_title || '—')}</td>
        <td>${esc(rv.city || '—')}</td>
        <td>${rv.desired_salary ? rv.desired_salary + ' руб.' : '—'}</td>
        <td>${pubBdg(rv.is_published)}</td>
        <td>${fd(rv.created_at)}</td>
        <td>
            <button class="btn btn-info btn-sm btn-ico" title="Просмотр" onclick="viewResume(${rv.id})">
                <i class="fas fa-eye"></i>
            </button>
            <button class="btn btn-success btn-sm btn-ico" title="${rv.is_published ? 'Снять публикацию' : 'Опубликовать'}"
                    onclick="toggleResumePub(${rv.id}, ${rv.is_published})">
                <i class="fas fa-${rv.is_published ? 'eye-slash' : 'check'}"></i>
            </button>
            <button class="btn btn-danger btn-sm btn-ico" title="Удалить" onclick="delResume(${rv.id})">
                <i class="fas fa-trash"></i>
            </button>
        </td>
    </tr>`).join('') : empty('Резюме нет');

    if ($('rvPgn') && r && r.pages > 1) {
        renderPagination('rvPgn', _rvPage, r.pages, loadResumes);
    } else if ($('rvPgn')) {
        $('rvPgn').innerHTML = '';
    }
}

async function viewResume(id) {
    const r = await api('GET', `api/career/resumes.php?id=${id}`);
    if (!r || !r.id) { toast('Не удалось загрузить резюме', 'error'); return; }

    const expHtml = r.work_experience ? (() => {
        try {
            const exp = JSON.parse(r.work_experience);
            if (!Array.isArray(exp) || !exp.length) return '<em>Не указан</em>';
            return exp.map(e => `<div style="margin-bottom:8px">
                <strong>${esc(e.company || '')}</strong> — ${esc(e.position || '')}<br>
                <small style="color:var(--muted)">${esc(e.period || e.from || '')} ${e.to ? '— ' + esc(e.to) : ''}</small>
                ${e.description ? '<br><span>' + esc(e.description) + '</span>' : ''}
            </div>`).join('');
        } catch { return esc(r.work_experience); }
    })() : '<em>Не указан</em>';

    const eduHtml = r.education ? (() => {
        try {
            const edu = JSON.parse(r.education);
            if (!Array.isArray(edu) || !edu.length) return '<em>Не указано</em>';
            return edu.map(e => `<div style="margin-bottom:6px">
                <strong>${esc(e.institution || '')}</strong><br>
                ${esc(e.specialization || e.faculty || '')} ${e.year ? '(' + esc(e.year) + ')' : ''}
            </div>`).join('');
        } catch { return esc(r.education); }
    })() : '<em>Не указано</em>';

    const skillsHtml = r.skills ? (() => {
        try {
            const sk = JSON.parse(r.skills);
            if (!Array.isArray(sk) || !sk.length) return '<em>Не указаны</em>';
            return sk.map(s => `<span style="display:inline-block;background:var(--bg2);padding:3px 10px;border-radius:20px;margin:3px;font-size:13px">${esc(s)}</span>`).join('');
        } catch { return esc(r.skills); }
    })() : '<em>Не указаны</em>';

    const content = `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px">
        <div>
            <div style="font-size:22px;font-weight:700;color:var(--acc)">${esc((r.last_name||'') + ' ' + (r.first_name||'') + ' ' + (r.middle_name||''))}</div>
            <div style="font-size:16px;margin-top:4px">${esc(r.desired_position || '—')}</div>
            ${r.desired_salary ? `<div style="color:var(--green);font-weight:600;margin-top:4px">${r.desired_salary} руб.</div>` : ''}
        </div>
        <div style="font-size:13px;color:var(--muted)">
            ${r.city ? `<div><i class="fas fa-map-marker-alt"></i> ${esc(r.city)}</div>` : ''}
            ${r.phone ? `<div><i class="fas fa-phone"></i> ${esc(r.phone)}</div>` : ''}
            ${r.email ? `<div><i class="fas fa-envelope"></i> ${esc(r.email)}</div>` : ''}
            ${r.birth_date ? `<div><i class="fas fa-birthday-cake"></i> ${fd(r.birth_date)}</div>` : ''}
        </div>
    </div>
    <hr style="border-color:rgba(255,255,255,.1);margin:12px 0">
    <div style="margin-bottom:12px">
        <div style="font-weight:700;color:var(--acc);margin-bottom:6px"><i class="fas fa-briefcase"></i> Опыт работы</div>
        ${expHtml}
    </div>
    <div style="margin-bottom:12px">
        <div style="font-weight:700;color:var(--acc);margin-bottom:6px"><i class="fas fa-graduation-cap"></i> Образование</div>
        ${eduHtml}
    </div>
    <div style="margin-bottom:12px">
        <div style="font-weight:700;color:var(--acc);margin-bottom:6px"><i class="fas fa-tools"></i> Навыки</div>
        ${skillsHtml}
    </div>
    ${r.about ? `<div style="margin-bottom:12px">
        <div style="font-weight:700;color:var(--acc);margin-bottom:6px"><i class="fas fa-user"></i> О себе</div>
        <div>${esc(r.about)}</div>
    </div>` : ''}`;

    showInfoModal('Резюме студента', content);
}

function showInfoModal(title, content) {
    // Удаляем предыдущий если есть
    const existing = document.getElementById('_infoModal');
    if (existing) existing.remove();

    const el = document.createElement('div');
    el.id = '_infoModal';
    el.className = 'mo';
    el.style.display = 'flex';
    el.innerHTML = `<div class="modal mlg" style="max-height:90vh;overflow-y:auto">
        <div class="mh">
            <div class="mt">${title}</div>
            <button class="mc" onclick="document.getElementById('_infoModal').remove()"><i class="fas fa-times"></i></button>
        </div>
        <div class="mb">${content}</div>
        <div class="mf">
            <button class="btn btn-sec" onclick="document.getElementById('_infoModal').remove()">Закрыть</button>
        </div>
    </div>`;
    document.body.appendChild(el);
}

async function toggleResumePub(id, current) {
    const newVal = current ? 0 : 1;
    const r = await api('PATCH', `api/career/resumes.php?id=${id}`, { is_published: newVal });
    if (r && (r.id || r.is_published !== undefined)) {
        toast(newVal ? 'Резюме опубликовано' : 'Резюме снято с публикации');
        loadResumes();
    } else {
        toast('Ошибка обновления', 'error');
    }
}

async function delResume(id) {
    if (!confirm('Удалить резюме? Это действие необратимо.')) return;
    await api('DELETE', `api/career/resumes.php?id=${id}`);
    toast('Резюме удалено');
    loadResumes();
}

/* ── PORTFOLIO ──────────────────────────────────────────────── */
let _pfPage = 1;

async function loadPortfolio(page) {
    if (page) _pfPage = page;
    const search = ($('pfSearch') || {}).value || '';
    const pub    = ($('pfPub')    || {}).value || '';
    const r = await api('GET', `api/career/portfolio.php?limit=25&page=${_pfPage}&search=${encodeURIComponent(search)}&is_published=${pub}`);
    const d = r && r.data ? r.data : [];
    $('pfTb').innerHTML = d.length ? d.map(p => `<tr>
        <td>${p.id}</td>
        <td>${esc(p.full_name || p.student_name || '—')}</td>
        <td><strong>${esc(p.title)}</strong></td>
        <td>${esc(p.category || '—')}</td>
        <td>${p.project_url ? `<a href="${esc(p.project_url)}" target="_blank" style="color:var(--acc)"><i class="fas fa-external-link-alt"></i></a>` : '—'}</td>
        <td>${pubBdg(p.is_published)}</td>
        <td>${fd(p.created_at)}</td>
        <td>
            <button class="btn btn-success btn-sm btn-ico" title="${p.is_published ? 'Снять публикацию' : 'Опубликовать'}"
                    onclick="togglePortfolioPub(${p.id}, ${p.is_published})">
                <i class="fas fa-${p.is_published ? 'eye-slash' : 'check'}"></i>
            </button>
            <button class="btn btn-danger btn-sm btn-ico" title="Удалить" onclick="delPortfolio(${p.id})">
                <i class="fas fa-trash"></i>
            </button>
        </td>
    </tr>`).join('') : empty('Портфолио нет');

    if ($('pfPgn') && r && r.pages > 1) {
        renderPagination('pfPgn', _pfPage, r.pages, loadPortfolio);
    } else if ($('pfPgn')) {
        $('pfPgn').innerHTML = '';
    }
}

async function togglePortfolioPub(id, current) {
    const newVal = current ? 0 : 1;
    const r = await api('PATCH', `api/career/portfolio.php?id=${id}`, { is_published: newVal });
    if (r && (r.id || r.is_published !== undefined)) {
        toast(newVal ? 'Опубликовано' : 'Снято с публикации');
        loadPortfolio();
    } else {
        toast('Ошибка обновления', 'error');
    }
}

async function delPortfolio(id) {
    if (!confirm('Удалить запись портфолио?')) return;
    await api('DELETE', `api/career/portfolio.php?id=${id}`);
    toast('Портфолио удалено');
    loadPortfolio();
}

/* ── VACANCIES ──────────────────────────────────────────────── */
async function loadVacs() {
    const r = await api('GET', 'api/vacancies.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('vcTb').innerHTML = d.length ? d.map(vc => `<tr>
        <td>${vc.id}</td>
        <td><strong>${esc(vc.title)}</strong></td>
        <td>${esc(vc.company || '—')}</td>
        <td>${esc(vc.city || '—')}</td>
        <td>${esc(vc.employment_type || '—')}</td>
        <td>${esc(vc.salary || '—')}</td>
        <td>${actBdg(vc.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" title="Редактировать" onclick="editVac(${vc.id})">
                <i class="fas fa-edit"></i>
            </button>
            <button class="btn btn-danger btn-sm btn-ico" title="Удалить" onclick="delVac(${vc.id})">
                <i class="fas fa-trash"></i>
            </button>
        </div></td>
    </tr>`).join('') : empty('Вакансий нет');
}

function openVac(it) {
    $('vcId').value    = it ? it.id   : '';
    $('vcTit').value   = it ? it.title : '';
    $('vcCom').value   = it ? it.company || '' : '';
    $('vcCit').value   = it ? it.city || '' : '';
    $('vcEmp').value   = it ? it.employment_type || '' : '';
    $('vcSal').value   = it ? it.salary || '' : '';
    $('vcExp').value   = it ? it.expires_at || '' : '';
    $('vcDesc').value  = it ? it.description || '' : '';
    $('vcReq').value   = it ? it.requirements || '' : '';
    $('vcCon').value   = it ? it.contact_info || '' : '';
    $('vcAct').checked = !it || !!+it.is_active;
    $('mVacT').textContent = it ? 'Редактировать вакансию' : 'Добавить вакансию';
    om('mVac');
}

async function editVac(id) {
    const r = await api('GET', `api/vacancies.php?id=${id}`);
    if (r && r.id)        openVac(r);
    else if (r && r.data) openVac(r.data);
    else toast('Не удалось загрузить вакансию', 'error');
}

async function saveVac() {
    const id = $('vcId').value;
    const d = {
        title          : v('vcTit'),
        company        : v('vcCom'),
        city           : v('vcCit'),
        employment_type: v('vcEmp'),
        salary         : v('vcSal'),
        expires_at     : v('vcExp') || null,
        description    : v('vcDesc'),
        requirements   : v('vcReq'),
        contact_info   : v('vcCon'),
        is_active      : $('vcAct').checked ? 1 : 0,
    };
    if (!d.title) { toast('Введите название вакансии', 'error'); return; }
    const r = await api(
        id ? 'PUT'  : 'POST',
        id ? `api/vacancies.php?id=${id}` : 'api/vacancies.php',
        d
    );
    if (r && (r.id || r.success)) {
        toast(id ? 'Вакансия обновлена' : 'Вакансия создана');
        cm('mVac');
        loadVacs();
    } else {
        toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
    }
}

async function delVac(id) {
    if (!confirm('Удалить вакансию?')) return;
    await api('DELETE', `api/vacancies.php?id=${id}`);
    toast('Вакансия удалена');
    loadVacs();
}

/* ── CAREER EVENTS ──────────────────────────────────────────── */
async function loadCEvents() {
    const r = await api('GET', 'api/career/events.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('ceTb').innerHTML = d.length ? d.map(ce => `<tr>
        <td>${ce.id}</td>
        <td><strong>${esc(ce.title)}</strong></td>
        <td>${esc(ce.location || '—')}</td>
        <td>${fd(ce.event_date)}</td>
        <td>${ce.max_seats ? ce.max_seats : '∞'}</td>
        <td>${pubBdg(ce.is_published)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" title="Редактировать" onclick="editCEv(${ce.id})">
                <i class="fas fa-edit"></i>
            </button>
            <button class="btn btn-danger btn-sm btn-ico" title="Удалить" onclick="delCEv(${ce.id})">
                <i class="fas fa-trash"></i>
            </button>
        </div></td>
    </tr>`).join('') : empty('Мероприятий нет');
}

function openCEvent(it) {
    $('ceId').value   = it ? it.id   : '';
    $('ceTit').value  = it ? it.title : '';
    $('ceDesc').value = it ? it.description || '' : '';
    $('ceLoc').value  = it ? it.location || '' : '';
    $('ceDate').value = it && it.event_date ? it.event_date.replace(' ', 'T').slice(0, 16) : '';
    $('ceEnd').value  = it && it.event_end  ? it.event_end.replace(' ', 'T').slice(0, 16)  : '';
    $('ceImg').value  = it ? it.image_url || '' : '';
    $('ceReg').value  = it ? it.registration_url || '' : '';
    $('ceSts').value  = it ? it.max_seats || '' : '';
    $('ceOrd').value  = it ? it.sort_order : 0;
    $('cePub').checked = !it || !!+it.is_published;
    $('mCEvT').textContent = it ? 'Редактировать мероприятие' : 'Добавить мероприятие';
    om('mCEv');
}

async function editCEv(id) {
    const r = await api('GET', `api/career/events.php?id=${id}`);
    if (r && r.id)        openCEvent(r);
    else if (r && r.data) openCEvent(r.data);
    else toast('Не удалось загрузить мероприятие', 'error');
}

async function saveCEv() {
    const id = $('ceId').value;
    const d = {
        title            : v('ceTit'),
        description      : v('ceDesc'),
        location         : v('ceLoc'),
        event_date       : v('ceDate') ? v('ceDate').replace('T', ' ') : null,
        event_end        : v('ceEnd')  ? v('ceEnd').replace('T', ' ')  : null,
        image_url        : v('ceImg'),
        registration_url : v('ceReg'),
        max_seats        : +$('ceSts').value || null,
        sort_order       : +$('ceOrd').value,
        is_published     : $('cePub').checked ? 1 : 0,
    };
    if (!d.title) { toast('Введите название мероприятия', 'error'); return; }
    const r = await api(
        id ? 'PUT'  : 'POST',
        id ? `api/career/events.php?id=${id}` : 'api/career/events.php',
        d
    );
    if (r && (r.id || r.success)) {
        toast(id ? 'Мероприятие обновлено' : 'Мероприятие создано');
        cm('mCEv');
        loadCEvents();
    } else {
        toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
    }
}

async function delCEv(id) {
    if (!confirm('Удалить мероприятие?')) return;
    await api('DELETE', `api/career/events.php?id=${id}`);
    toast('Мероприятие удалено');
    loadCEvents();
}


/* ── Вспомогательная: пагинация ─────────────────────────────── */
function renderPagination(containerId, currentPage, totalPages, loadFn) {
    const el = $(containerId);
    if (!el) return;
    let html = '';
    const start = Math.max(1, currentPage - 2);
    const end   = Math.min(totalPages, currentPage + 2);

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