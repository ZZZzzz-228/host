/* ─── Вспомогательная функция: API возвращает объект напрямую или {data:...} ──
   ok(r) = true если запрос прошёл успешно */
const ok = r => r && (r.id || r.success || (Array.isArray(r) ? r.length >= 0 : false));

/* ── SPECIALTIES ──────────────────────────────────────────────── */
async function loadSpecs() {
    const r = await api('GET', 'api/specialties.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('spTb').innerHTML = d.length ? d.map(s => `<tr>
        <td>${s.id}</td>
        <td>${s.image_url ? `<img class="ithumb" src="${esc(s.image_url)}" onclick="openLB('${esc(s.image_url)}')" style="cursor:pointer">` : '<span style="color:var(--tx3);font-size:11px">—</span>'}</td>
        <td><code>${esc(s.code)}</code></td>
        <td><strong>${esc(s.title)}</strong>${s.short_title?`<br><small style="color:var(--tx2)">${esc(s.short_title)}</small>`:''}</td>
        <td>${esc(s.study_form_label || '—')}</td>
        <td>${pubBdg(s.is_published)}</td>
        <td>${s.sort_order}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editSpec(${s.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delSpec(${s.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Специальностей нет');
}
function openSpec(it) {
    $('spId').value    = it ? it.id : '';
    $('spCode').value  = it ? it.code : '';
    $('spTit').value   = it ? it.title : '';
    $('spShort').value = it ? (it.short_title || '') : '';
    $('spForm').value  = it ? (it.study_form_label || '') : '';
    $('spDur').value   = it ? (it.duration_label || '') : '';
    $('spQual').value  = it ? (it.qualification_text || '') : '';
    $('spSal').value   = it ? (it.salary_text || '') : '';
    $('spCol').value   = it ? (it.color_hex || '#1565C0') : '#1565C0';
    $('spImg').value   = it ? (it.image_url || '') : '';
    $('spOrd').value   = it ? (it.sort_order || 0) : 0;
    $('spDesc').value  = it ? (it.description || '') : '';
    $('spCar').value   = it ? (it.career_text || '') : '';
    $('spSkl').value   = it ? (it.skills_text || '') : '';
    $('spGos').value   = it ? (it.gosuslugi_url || '') : '';
    $('spPub').checked = !it || !!+it.is_published;
    $('mSpecT').textContent = it ? 'Редактировать специальность' : 'Добавить специальность';
    om('mSpec');
}
async function editSpec(id) {
    const r = await api('GET', `api/specialties.php?id=${id}`);
    if (r && r.id) openSpec(r); else if (r && r.data) openSpec(r.data);
}
async function saveSpec() {
    const id = $('spId').value;
    const d = {
        code: v('spCode'), title: v('spTit'), short_title: v('spShort'),
        study_form_label: v('spForm'), duration_label: v('spDur'),
        qualification_text: v('spQual'), salary_text: v('spSal'),
        color_hex: $('spCol').value, image_url: v('spImg'),
        sort_order: +$('spOrd').value, description: v('spDesc'),
        career_text: v('spCar'), skills_text: v('spSkl'),
        gosuslugi_url: v('spGos'),
        is_published: $('spPub').checked ? 1 : 0
    };
    if (!d.code || !d.title) { toast('Заполните Код и Название', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/specialties.php?id=${id}`:'api/specialties.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mSpec'); loadSpecs(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delSpec(id) {
    if (!confirm('Удалить специальность?')) return;
    await api('DELETE', `api/specialties.php?id=${id}`);
    toast('Удалено'); loadSpecs();
}

/* ── EDU PROGRAMS ─────────────────────────────────────────────── */
const EP_TYPE_RU = { additional: 'Доп. образование', courses: 'Курсы' };
async function loadEduProgs() {
    const r = await api('GET', 'api/education_programs.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('epTb').innerHTML = d.length ? d.map(p => `<tr>
        <td>${p.id}</td>
        <td>${p.image_url ? `<img class="ithumb" src="${esc(p.image_url)}" onclick="openLB('${esc(p.image_url)}')" style="cursor:pointer">` : '<span style="color:var(--tx3);font-size:11px">—</span>'}</td>
        <td><strong>${esc(p.title)}</strong><br><small style="color:var(--tx2)">${EP_TYPE_RU[p.form] || p.form || '—'}</small></td>
        <td>${esc(p.duration_years ? p.duration_years + ' ч.' : '—')}</td>
        <td>${esc(p.tuition_cost ? p.tuition_cost + ' ₽' : '—')}</td>
        <td>${actBdg(p.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editEduProg(${p.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delEduProg(${p.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Программ нет');
}
function epToggleDurType() {
    const t = $('epDurType').value;
    $('epDurYearsRow').style.display = t === 'years' ? '' : 'none';
    $('epDurHoursRow').style.display = t === 'hours' ? '' : 'none';
}
function openEduProg(it) {
    $('epId').value        = it ? it.id : '';
    $('epTit').value       = it ? it.title : '';
    $('epForm').value      = it ? (it.form || 'additional') : 'additional';
    $('epDesc').value      = it ? (it.description || '') : '';
    $('epForWhom').value   = it ? (it.for_whom || '') : '';
    $('epWhatGet').value   = it ? (it.what_you_get || '') : '';
    $('epFormatTxt').value = it ? (it.format_text || '') : '';
    // Срок обучения: определяем тип
    const durType = it ? (it.duration_type || 'years') : 'years';
    $('epDurType').value   = durType;
    $('epDurYears').value  = it ? (it.duration_years || '') : '';
    $('epDurHours').value  = it ? (it.duration_hours || '') : '';
    epToggleDurType();
    $('epPrc').value       = it ? (it.tuition_cost || '') : '';
    $('epImg').value       = it ? (it.image_url || '') : '';
    $('epOrd').value       = it ? (it.sort_order || 0) : 0;
    $('epPub').checked     = !it || !!+it.is_active;
    $('mEprogT').textContent = it ? 'Редактировать программу' : 'Добавить программу';
    om('mEprog');
}
async function editEduProg(id) {
    const r = await api('GET', `api/education_programs.php?id=${id}`);
    if (r && r.id) openEduProg(r); else if (r && r.data) openEduProg(r.data);
}
async function saveEduProg() {
    const id = $('epId').value;
    const durType = $('epDurType').value;
    const d = {
        title:          v('epTit'),
        form:           $('epForm').value,
        description:    v('epDesc'),
        for_whom:       v('epForWhom'),
        what_you_get:   v('epWhatGet'),
        format_text:    v('epFormatTxt'),
        duration_type:  durType,
        duration_years: durType === 'years' ? v('epDurYears') : null,
        duration_hours: durType === 'hours' ? v('epDurHours') : null,
        tuition_cost:   v('epPrc'),
        image_url:      v('epImg'),
        sort_order:     +$('epOrd').value,
        is_active:      $('epPub').checked ? 1 : 0
    };
    if (!d.title) { toast('Введите название', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/education_programs.php?id=${id}`:'api/education_programs.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mEprog'); loadEduProgs(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delEduProg(id) {
    if (!confirm('Удалить программу?')) return;
    await api('DELETE', `api/education_programs.php?id=${id}`);
    toast('Удалено'); loadEduProgs();
}

/* ── DEPARTMENTS ──────────────────────────────────────────────── */
async function loadDepts() {
    const r = await api('GET', 'api/departments.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('dpTb').innerHTML = d.length ? d.map(dp => `<tr>
        <td>${dp.id}</td>
        <td><strong>${esc(dp.name)}</strong></td>
        <td>${esc(dp.code || '—')}</td>
        <td>${esc(dp.head_name || '—')}</td>
        <td>${dp.phone ? `<a href="tel:${esc(dp.phone)}">${esc(dp.phone)}</a>` : '—'}</td>
        <td>${actBdg(dp.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editDept(${dp.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delDept(${dp.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Отделений нет');
}
function openDept(it) {
    $('dpId').value    = it ? it.id : '';
    $('dpNm').value    = it ? it.name : '';
    $('dpCd').value    = it ? (it.code || '') : '';
    $('dpHd').value    = it ? (it.head_name || '') : '';
    $('dpPh').value    = it ? (it.phone || '') : '';
    $('dpEm').value    = it ? (it.email || '') : '';
    $('dpRm').value    = it ? (it.room || '') : '';
    $('dpOrd').value   = it ? (it.sort_order || 0) : 0;
    $('dpAct').checked = !it || !!+it.is_active;
    $('mDeptT').textContent = it ? 'Редактировать отделение' : 'Добавить отделение';
    om('mDept');
}
async function editDept(id) {
    const r = await api('GET', `api/departments.php?id=${id}`);
    if (r && r.id) openDept(r); else if (r && r.data) openDept(r.data);
}
async function saveDept() {
    const id = $('dpId').value;
    const d = {
        name: v('dpNm'), code: v('dpCd'), head_name: v('dpHd'),
        phone: v('dpPh'), email: v('dpEm'), room: v('dpRm'),
        sort_order: +$('dpOrd').value, is_active: $('dpAct').checked ? 1 : 0
    };
    if (!d.name) { toast('Введите название', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/departments.php?id=${id}`:'api/departments.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mDept'); loadDepts(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delDept(id) {
    if (!confirm('Удалить отделение?')) return;
    await api('DELETE', `api/departments.php?id=${id}`);
    toast('Удалено'); loadDepts();
}

/* ── GROUPS ───────────────────────────────────────────────────── */
async function loadGroups() {
    const r = await api('GET', 'api/groups.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('grTb').innerHTML = d.length ? d.map(g => `<tr>
        <td>${g.id}</td>
        <td><strong>${esc(g.name)}</strong></td>
        <td>${g.course || '—'}</td>
        <td>${esc(g.specialty_title || '—')}</td>
        <td>${esc(g.study_year || '—')}</td>
        <td>${actBdg(g.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editGroup(${g.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delGroup(${g.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Групп нет');
}
function openGroup(it) {
    $('grId').value    = it ? it.id : '';
    $('grNm').value    = it ? it.name : '';
    $('grCr').value    = it ? (it.course || '') : '';
    $('grYr').value    = it ? (it.study_year || '') : '';
    $('grOrd').value   = it ? (it.sort_order || 0) : 0;
    $('grAct').checked = !it || !!+it.is_active;
    $('mGroupT').textContent = it ? 'Редактировать группу' : 'Добавить группу';
    om('mGroup');
}
async function editGroup(id) {
    const r = await api('GET', `api/groups.php?id=${id}`);
    if (r && r.id) openGroup(r); else if (r && r.data) openGroup(r.data);
}
async function saveGroup() {
    const id = $('grId').value;
    const d = {
        name: v('grNm'), course: +$('grCr').value || null,
        study_year: v('grYr'), sort_order: +$('grOrd').value,
        is_active: $('grAct').checked ? 1 : 0
    };
    if (!d.name) { toast('Введите название', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/groups.php?id=${id}`:'api/groups.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mGroup'); loadGroups(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delGroup(id) {
    if (!confirm('Удалить группу?')) return;
    await api('DELETE', `api/groups.php?id=${id}`);
    toast('Удалено'); loadGroups();
}

/* ── DISCIPLINES ──────────────────────────────────────────────── */
async function loadDiscs() {
    const r = await api('GET', 'api/disciplines.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('dcTb').innerHTML = d.length ? d.map(dc => `<tr>
        <td>${dc.id}</td>
        <td><strong>${esc(dc.name)}</strong></td>
        <td>${esc(dc.code || '—')}</td>
        <td>${dc.description ? esc(dc.description.substring(0,60)) + (dc.description.length > 60 ? '…' : '') : '—'}</td>
        <td>${actBdg(dc.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editDisc(${dc.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delDisc(${dc.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Дисциплин нет');
}
function openDisc(it) {
    $('dcId').value    = it ? it.id : '';
    $('dcNm').value    = it ? it.name : '';
    $('dcCd').value    = it ? (it.code || '') : '';
    $('dcDesc').value  = it ? (it.description || '') : '';
    $('dcAct').checked = !it || !!+it.is_active;
    $('mDiscT').textContent = it ? 'Редактировать дисциплину' : 'Добавить дисциплину';
    om('mDisc');
}
async function editDisc(id) {
    const r = await api('GET', `api/disciplines.php?id=${id}`);
    if (r && r.id) openDisc(r); else if (r && r.data) openDisc(r.data);
}
async function saveDisc() {
    const id = $('dcId').value;
    const d = {
        name: v('dcNm'), code: v('dcCd'),
        description: v('dcDesc'), is_active: $('dcAct').checked ? 1 : 0
    };
    if (!d.name) { toast('Введите название', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/disciplines.php?id=${id}`:'api/disciplines.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mDisc'); loadDiscs(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delDisc(id) {
    if (!confirm('Удалить дисциплину?')) return;
    await api('DELETE', `api/disciplines.php?id=${id}`);
    toast('Удалено'); loadDiscs();
}

/* ── SCHEDULE ─────────────────────────────────────────────────── */
async function loadSched() {
    const q = v('schSrch'), day = $('schDay').value;
    let u = 'api/schedule.php?limit=100';
    if (q) u += '&q=' + encodeURIComponent(q);
    if (day) u += '&day=' + day;
    const r = await api('GET', u);
    const d = r && r.data ? r.data : [];
    const wRu = {all:'Каждую', odd:'Нечётн.', even:'Чётн.'};
    $('scTb').innerHTML = d.length ? d.map(s => `<tr>
        <td>${DAYS[s.day_of_week] || s.day_of_week}</td>
        <td>${s.lesson_number}</td>
        <td>${s.time_start ? s.time_start + ' – ' + s.time_end : '—'}&nbsp;${bdg(wRu[s.week_type] || '', 'bm')}</td>
        <td><strong>${esc(s.group_name)}</strong></td>
        <td>${esc(s.subject)}</td>
        <td>${esc(s.teacher || '—')}</td>
        <td>${esc(s.room || '—')}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editSched(${s.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delSched(${s.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Занятий нет');
}
function openSched(it) {
    $('scId').value    = it ? it.id : '';
    $('scGr').value    = it ? it.group_name : '';
    $('scDay').value   = it ? it.day_of_week : 1;
    $('scLes').value   = it ? it.lesson_number : 1;
    $('scTS').value    = it ? (it.time_start || '') : '';
    $('scTE').value    = it ? (it.time_end || '') : '';
    $('scWk').value    = it ? (it.week_type || 'all') : 'all';
    $('scSbj').value   = it ? it.subject : '';
    $('scTch').value   = it ? (it.teacher || '') : '';
    $('scRm').value    = it ? (it.room || '') : '';
    $('mSchedT').textContent = it ? 'Редактировать занятие' : 'Добавить занятие';
    om('mSched');
}
async function editSched(id) {
    const r = await api('GET', `api/schedule.php?id=${id}`);
    if (r && r.id) openSched(r); else if (r && r.data) openSched(r.data);
}
async function saveSched() {
    const id = $('scId').value;
    const d = {
        group_name: v('scGr'), day_of_week: +$('scDay').value,
        lesson_number: +$('scLes').value, time_start: v('scTS') || null,
        time_end: v('scTE') || null, week_type: $('scWk').value,
        subject: v('scSbj'), teacher: v('scTch'), room: v('scRm')
    };
    if (!d.group_name || !d.subject) { toast('Заполните Группу и Предмет', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/schedule.php?id=${id}`:'api/schedule.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mSched'); loadSched(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delSched(id) {
    if (!confirm('Удалить занятие?')) return;
    await api('DELETE', `api/schedule.php?id=${id}`);
    toast('Удалено'); loadSched();
}

/* ── STAFF ────────────────────────────────────────────────────── */
async function loadStaff() {
    const q = v('stfSrch'), dep = $('stfDep').value;
    let u = 'api/staff.php?limit=100';
    if (q) u += '&q=' + encodeURIComponent(q);
    if (dep) u += '&department=' + dep;
    const r = await api('GET', u);
    const d = r && r.data ? r.data : [];
    const dRu = {college:'Колледж', career_center:'Карьерный центр', other:'Другое'};
    $('sfTb').innerHTML = d.length ? d.map(s => `<tr>
        <td>${s.id}</td>
        <td>${s.photo_url
            ? `<img class="pthumb" src="${esc(s.photo_url)}" onclick="openLB('${esc(s.photo_url)}')" style="cursor:pointer">`
            : `<div class="pthumb" style="display:flex;align-items:center;justify-content:center;background:${esc(s.color_hex||'#1565C0')};font-weight:700;font-size:14px;color:#fff">${esc(s.full_name||'?').charAt(0)}</div>`}</td>
        <td><strong>${esc(s.full_name)}</strong></td>
        <td>${esc(s.position_title || '—')}</td>
        <td>${bdg(dRu[s.department] || s.department || '—', 'bi')}</td>
        <td>${pubBdg(s.is_published)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editStaff(${s.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delStaff(${s.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Сотрудников нет');
}
function openStaff(it) {
    $('sfId').value    = it ? it.id : '';
    $('sfNm').value    = it ? it.full_name : '';
    $('sfPos').value   = it ? (it.position_title || '') : '';
    $('sfEm').value    = it ? (it.email || '') : '';
    $('sfPh').value    = it ? (it.phone || '') : '';
    $('sfDep').value   = it ? (it.department || 'college') : 'college';
    $('sfPht').value   = it ? (it.photo_url || '') : '';
    $('sfCol').value   = it ? (it.color_hex || '#1565C0') : '#1565C0';
    $('sfOrd').value   = it ? (it.sort_order || 0) : 0;
    $('sfOH').value    = it ? (it.office_hours || '') : '';
    $('sfBio').value   = it ? (it.bio || '') : '';
    $('sfPub').checked = !it || !!+it.is_published;
    $('mStaffT').textContent = it ? 'Редактировать сотрудника' : 'Добавить сотрудника';
    om('mStaff');
}
async function editStaff(id) {
    const r = await api('GET', `api/staff.php?id=${id}`);
    if (r && r.id) openStaff(r); else if (r && r.data) openStaff(r.data);
}
async function saveStaff() {
    const id = $('sfId').value;
    const d = {
        full_name: v('sfNm'), position_title: v('sfPos'),
        email: v('sfEm'), phone: v('sfPh'),
        department: $('sfDep').value,
        photo_url: v('sfPht'), color_hex: $('sfCol').value,
        sort_order: +$('sfOrd').value,
        office_hours: v('sfOH'), bio: v('sfBio'),
        is_published: $('sfPub').checked ? 1 : 0
    };
    if (!d.full_name) { toast('Введите ФИО', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/staff.php?id=${id}`:'api/staff.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mStaff'); loadStaff(); }
    else toast((r && (r.error || r.message)) || 'Ошибка', 'error');
}
async function delStaff(id) {
    if (!confirm('Удалить сотрудника?')) return;
    await api('DELETE', `api/staff.php?id=${id}`);
    toast('Удалено'); loadStaff();
}

/* ── STUDENTS ─────────────────────────────────────────────────── */
let suP = 1;
async function loadStudents() {
    const q = v('stuSrch');
    let u = `api/students.php?page=${suP}&limit=25`;
    if (q) u += '&q=' + encodeURIComponent(q);
    const r = await api('GET', u);
    const d = r && r.data ? r.data : [];
    const tot = r && r.total ? r.total : 0;
    $('suTb').innerHTML = d.length ? d.map(s => `<tr>
        <td>${s.id}</td>
        <td><strong>${esc(s.full_name)}</strong></td>
        <td>${esc(s.email)}</td>
        <td>${esc(s.group_name || '—')}</td>
        <td>${actBdg(s.is_active)}</td>
        <td>${fdo(s.created_at)}</td>
        <td><button class="btn btn-info btn-sm btn-ico" onclick="viewStudent(${s.id})" title="Профиль"><i class="fas fa-eye"></i></button></td>
    </tr>`).join('') : empty('Студентов нет');
    $('suPgn').innerHTML = pgn(tot, suP, 25, 'goSU');
}
function goSU(p) { suP = p; loadStudents(); }

async function viewStudent(id) {
    const r = await api('GET', `api/students.php?id=${id}`);
    const s = r && r.id ? r : (r && r.data ? r.data : null);
    if (!s) return;
    alert(`${s.full_name}\nEmail: ${s.email}\nГруппа: ${s.group_name || '—'}\nТелефон: ${s.phone || '—'}`);
}