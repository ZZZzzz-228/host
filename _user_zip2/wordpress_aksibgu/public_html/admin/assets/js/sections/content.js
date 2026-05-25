/* ── CMS PAGES ────────────────────────────────────────────────── */
async function loadPages() {
    const r = await api('GET', 'api/pages.php?limit=100');
    const d = r && r.data ? r.data : [];
    $('pgTb').innerHTML = d.length ? d.map(p => `<tr>
        <td>${p.id}</td><td><code>${esc(p.slug)}</code></td><td>${esc(p.title)}</td>
        <td>${pubBdg(p.is_published)}</td><td>${p.sort_order}</td><td>${fd(p.updated_at)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editPage(${p.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delPage(${p.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Страниц нет');
}
function openPage(it) {
    $('pgId').value=it?it.id:''; $('pgSlug').value=it?it.slug:''; $('pgTit').value=it?it.title:'';
    $('pgCnt').value=it?it.content||'':''; $('pgMeta').value=it?it.meta_desc||'':'';
    $('pgPub').checked=!it||!!+it.is_published;
    $('mPageT').textContent=it?'Редактировать страницу':'Добавить страницу'; om('mPage');
}
async function editPage(id){const r=await api('GET',`api/pages.php?id=${id}`);if(r&&r.data)openPage(r.data);}
async function savePage(){
    const id=$('pgId').value;
    const d={slug:v('pgSlug'),title:v('pgTit'),content:v('pgCnt'),meta_desc:v('pgMeta'),is_published:$('pgPub').checked?1:0};
    if(!d.slug||!d.title){toast('Заполните Slug и Заголовок','error');return;}
    const r=await api(id?'PUT':'POST',id?`api/pages.php?id=${id}`:'api/pages.php',d);
    if(r&&r.success){toast(id?'Обновлено':'Создано');cm('mPage');loadPages();}else toast(r&&r.message||'Ошибка','error');
}
async function delPage(id){if(!confirm('Удалить?'))return;const r=await api('DELETE',`api/pages.php?id=${id}`);if(r&&r.success){toast('Удалено');loadPages();}}

/* ── CONTACTS ─────────────────────────────────────────────────── */
async function loadContacts() {
    const cat = $('ctCat').value;
    const r = await api('GET', `api/contacts.php?limit=100${cat ? '&category=' + cat : ''}`);
    const d = r && r.data ? r.data : [];
    const cRu = {college:'Колледж', career_center:'Карьерный центр'};

    $('ctTb').innerHTML = d.length ? d.map(c => `<tr>
        <td>${c.id}</td>
        <td>${c.photo_url ? `<img class="ithumb" src="${esc(c.photo_url)}" onclick="openLB('${esc(c.photo_url)}')" style="cursor:pointer;border-radius:50%">` : '<span style="color:var(--tx3);font-size:11px">—</span>'}</td>
        <td>${esc(c.label || c.name || '—')}</td>
        <td>${esc(c.position || '—')}</td>
        <td>${c.phone ? `<a href="tel:${esc(c.phone)}">${esc(c.phone)}</a>` : '—'}</td>
        <td>${c.email ? `<a href="mailto:${esc(c.email)}">${esc(c.email)}</a>` : '—'}</td>
        <td>${cRu[c.category] || c.category || '—'}</td>
        <td>${actBdg(c.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editContact(${c.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delContact(${c.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Контактов нет');
}

function openContact(it) {
    $('ctId').value      = it ? it.id : '';
    $('ctCatM').value    = it ? (it.category || 'college') : 'college';
    $('ctLbl').value     = it ? (it.label || '') : '';
    $('ctName').value    = it ? (it.name || '') : '';
    $('ctPos').value     = it ? (it.position || '') : '';
    $('ctPhone').value   = it ? (it.phone || '') : '';
    $('ctEmail').value   = it ? (it.email || '') : '';
    $('ctAddress').value = it ? (it.address || '') : '';
    $('ctRoom').value    = it ? (it.room || '') : '';
    $('ctSched').value   = it ? (it.schedule || '') : '';
    $('ctVk').value      = it ? (it.vk_url || '') : '';
    $('ctPhoto').value   = it ? (it.photo_url || '') : '';
    $('ctOrd').value     = it ? (it.sort_order || 0) : 0;
    $('ctAct').checked   = !it || !!+it.is_active;
    $('mContactT').textContent = it ? 'Редактировать контакт' : 'Добавить контакт';
    om('mContact');
}
async function editContact(id) {
    // API GET ?id= возвращает объект напрямую
    const r = await api('GET', `api/contacts.php?id=${id}`);
    if (r && r.id) openContact(r);
    else if (r && r.data) openContact(r.data);
}
async function saveContact() {
    const id = $('ctId').value;
    const d = {
        category   : $('ctCatM').value,
        label      : v('ctLbl'),
        name       : v('ctName'),
        position   : v('ctPos'),
        phone      : v('ctPhone'),
        email      : v('ctEmail'),
        address    : v('ctAddress'),
        room       : v('ctRoom'),
        schedule   : v('ctSched'),
        vk_url     : v('ctVk'),
        photo_url  : v('ctPhoto'),
        sort_order : +$('ctOrd').value,
        is_active  : $('ctAct').checked ? 1 : 0
    };
    if (!d.label && !d.name && !d.phone && !d.email) {
        toast('Заполните хотя бы одно поле: Подпись, ФИО, Телефон или Email', 'error'); return;
    }
    // API POST/PUT возвращает объект (не {success:true}) — проверяем по наличию id
    const r = await api(id ? 'PUT' : 'POST', id ? `api/contacts.php?id=${id}` : 'api/contacts.php', d);
    if (r && (r.id || r.success)) { toast(id ? 'Обновлено' : 'Создано'); cm('mContact'); loadContacts(); }
    else toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
}
async function delContact(id) {
    if (!confirm('Удалить контакт?')) return;
    // DELETE возвращает 204 (null)
    await api('DELETE', `api/contacts.php?id=${id}`);
    toast('Удалено'); loadContacts();
}

/* ── DOCUMENTS ────────────────────────────────────────────────── */
async function loadDocs() {
    const q = v('docSrch'), cat = v('docCat');
    let u = 'api/documents.php?limit=100';
    if (q) u += '&q=' + encodeURIComponent(q);
    if (cat) u += '&category=' + encodeURIComponent(cat);
    const r = await api('GET', u);
    const d = r && r.data ? r.data : [];
    $('doTb').innerHTML = d.length ? d.map(dc => `<tr>
        <td>${dc.id}</td>
        <td>${esc(dc.title)}</td>
        <td><span class="bdg bi">${esc(dc.category || '—')}</span></td>
        <td>${dc.file_url
            ? `<a href="${esc(dc.file_url)}" target="_blank" class="btn btn-info btn-sm"><i class="fas fa-download"></i> Открыть</a>`
            : '—'}</td>
        <td>${pubBdg(dc.is_published)}</td>
        <td>${fdo(dc.created_at)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editDoc(${dc.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delDoc(${dc.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Документов нет');
}
function openDoc(it) {
    $('doId').value  = it ? it.id : '';
    $('doTit').value = it ? it.title : '';
    $('doDesc').value = it ? (it.description || '') : '';
    $('doUrl').value  = it ? (it.file_url || '') : '';
    $('doCat').value  = it ? (it.category || '') : '';
    $('doOrd').value  = it ? (it.sort_order || 0) : 0;
    $('doPub').checked = !it || !!+it.is_published;
    $('mDocT').textContent = it ? 'Редактировать документ' : 'Добавить документ';
    om('mDoc');
}
async function editDoc(id) {
    const r=await api('GET',`api/documents.php?id=${id}`);
    if(r&&r.id) openDoc(r); else if(r&&r.data) openDoc(r.data);
}
async function saveDoc() {
    const id = $('doId').value;
    const d = {
        title       : v('doTit'),
        description : v('doDesc'),
        file_url    : v('doUrl'),
        category    : v('doCat'),
        sort_order  : +$('doOrd').value,
        is_published: $('doPub').checked ? 1 : 0
    };
    if (!d.title || !d.file_url) { toast('Введите название и URL файла', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/documents.php?id=${id}`:'api/documents.php', d);
    if (r&&(r.id||r.success)) { toast(id?'Обновлено':'Создано'); cm('mDoc'); loadDocs(); }
    else toast((r&&(r.error||r.message))||'Ошибка','error');
}
async function delDoc(id) {
    if (!confirm('Удалить документ?')) return;
    await api('DELETE', `api/documents.php?id=${id}`);
    toast('Удалено'); loadDocs();
}

/* ── PARTNERS ─────────────────────────────────────────────────── */
async function loadPartners() {
    const r = await api('GET', 'api/partners.php?limit=100');
    const d = r && r.data ? r.data : [];
    const cRu = {college:'Колледж', career_center:'Карьерный центр'};
    $('ptTb').innerHTML = d.length ? d.map(pt => `<tr>
        <td>${pt.id}</td>
        <td>${pt.logo_url
            ? `<img class="ithumb" src="${esc(pt.logo_url)}" onclick="openLB('${esc(pt.logo_url)}')" style="cursor:pointer" title="Увеличить">`
            : '<span style="color:var(--tx2);font-size:11px">нет лого</span>'}</td>
        <td><strong>${esc(pt.name)}</strong></td>
        <td>${cRu[pt.category] || pt.category || '—'}</td>
        <td>${pt.website_url
            ? `<a href="${esc(pt.website_url)}" target="_blank" class="btn btn-info btn-sm btn-ico" title="${esc(pt.website_url)}"><i class="fas fa-link"></i></a>`
            : '—'}</td>
        <td>${pubBdg(pt.is_published)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editPartner(${pt.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delPartner(${pt.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Партнёров нет');
}
function openPartner(it) {
    $('ptId').value   = it ? it.id : '';
    $('ptNm').value   = it ? it.name : '';
    $('ptDesc').value = it ? (it.description || '') : '';
    $('ptSt').value   = it ? (it.website_url || '') : '';
    $('ptLg').value   = it ? (it.logo_url || '') : '';
    $('ptCat').value  = it ? (it.category || 'career_center') : 'career_center';
    $('ptOrd').value  = it ? (it.sort_order || 0) : 0;
    $('ptPub').checked = !it || !!+it.is_published;
    $('mPartnerT').textContent = it ? 'Редактировать партнёра' : 'Добавить партнёра';
    om('mPartner');
}
async function editPartner(id) {
    const r=await api('GET',`api/partners.php?id=${id}`);
    if(r&&r.id) openPartner(r); else if(r&&r.data) openPartner(r.data);
}
async function savePartner() {
    const id = $('ptId').value;
    const d = {
        name        : v('ptNm'),
        description : v('ptDesc'),
        website_url : v('ptSt'),
        logo_url    : v('ptLg'),
        category    : $('ptCat').value,
        sort_order  : +$('ptOrd').value,
        is_published: $('ptPub').checked ? 1 : 0
    };
    if (!d.name) { toast('Введите название партнёра', 'error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/partners.php?id=${id}`:'api/partners.php', d);
    if (r&&(r.id||r.success)) { toast(id?'Обновлено':'Создано'); cm('mPartner'); loadPartners(); }
    else toast((r&&(r.error||r.message))||'Ошибка','error');
}
async function delPartner(id) {
    if (!confirm('Удалить партнёра?')) return;
    await api('DELETE', `api/partners.php?id=${id}`);
    toast('Удалено'); loadPartners();
}
