/* career-contacts.js — Контакты Центр карьеры (category = career_center) */
'use strict';

const CCC_CATEGORY = 'career_center';

async function loadCareerContacts() {
    const tb = $('cccTb');
    try {
        const r = await api('GET', `api/contacts.php?limit=200&category=${CCC_CATEGORY}`);
        const d = r && r.data ? r.data : [];
        if (!tb) return;
        tb.innerHTML = d.length ? d.map(c => `<tr>
        <td>${c.id}</td>
        <td>${c.photo_url ? `<img class="ithumb" src="${esc(c.photo_url)}" onclick="openLB('${esc(c.photo_url)}')" style="cursor:pointer;border-radius:50%">` : '<span style="color:var(--tx3);font-size:11px">—</span>'}</td>
        <td><strong>${esc(c.name || c.label || '—')}</strong>${c.label && c.name ? `<div style="font-size:11px;color:var(--tx3)">${esc(c.label)}</div>` : ''}</td>
        <td>${esc(c.position || '—')}</td>
        <td>${c.phone ? `<a href="tel:${esc(c.phone)}">${esc(c.phone)}</a>` : '—'}</td>
        <td>${c.email ? `<a href="mailto:${esc(c.email)}">${esc(c.email)}</a>` : '—'}</td>
        <td>${actBdg(c.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editCareerContact(${c.id})" title="Редактировать"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delCareerContact(${c.id})" title="Удалить"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Нет контактов. Нажмите «Добавить».');
    } catch (e) {
        console.error('loadCareerContacts:', e);
        if (tb) tb.innerHTML = empty('Ошибка загрузки');
        toast('Ошибка загрузки контактов', 'error');
    }
}

function openCareerContact(it) {
    $('ctId').value = it ? it.id : '';
    $('ctCatM').value = CCC_CATEGORY;
    const catRow = $('ctCatM') && $('ctCatM').closest('.fr');
    if (catRow) catRow.style.display = 'none';
    $('ctLbl').value = it ? (it.label || '') : '';
    $('ctName').value = it ? (it.name || '') : '';
    $('ctPos').value = it ? (it.position || '') : '';
    $('ctPhone').value = it ? (it.phone || '') : '';
    $('ctEmail').value = it ? (it.email || '') : '';
    $('ctAddress').value = it ? (it.address || '') : '';
    $('ctRoom').value = it ? (it.room || '') : '';
    $('ctSched').value = it ? (it.schedule || '') : '';
    $('ctVk').value = it ? (it.vk_url || '') : '';
    $('ctPhoto').value = it ? (it.photo_url || '') : '';
    $('ctOrd').value = it ? (it.sort_order || 0) : 0;
    $('ctAct').checked = !it || !!+it.is_active;
    $('mContactT').textContent = it ? 'Редактировать контакт' : 'Добавить контакт';
    const saveBtn = document.querySelector('#mContact .mf .btn-primary');
    if (saveBtn) saveBtn.setAttribute('onclick', 'saveCareerContact()');
    om('mContact');
}

async function editCareerContact(id) {
    const r = await api('GET', `api/contacts.php?id=${id}`);
    if (r && r.id) openCareerContact(r);
    else toast('Не удалось загрузить', 'error');
}

async function saveCareerContact() {
    $('ctCatM').value = CCC_CATEGORY;
    const id = $('ctId').value;
    const d = {
        category: CCC_CATEGORY,
        label: v('ctLbl'),
        name: v('ctName'),
        position: v('ctPos'),
        phone: v('ctPhone'),
        email: v('ctEmail'),
        address: v('ctAddress'),
        room: v('ctRoom'),
        schedule: v('ctSched'),
        vk_url: v('ctVk'),
        photo_url: v('ctPhoto'),
        sort_order: +$('ctOrd').value,
        is_active: $('ctAct').checked ? 1 : 0,
    };
    if (!d.name && !d.label && !d.phone && !d.email) {
        toast('Заполните ФИО, подпись, телефон или email', 'error');
        return;
    }
    const r = await api(
        id ? 'PUT' : 'POST',
        id ? `api/contacts.php?id=${id}` : 'api/contacts.php',
        d
    );
    if (r && (r.id || r.success)) {
        toast(id ? 'Обновлено' : 'Добавлено');
        cm('mContact');
        loadCareerContacts();
    } else {
        toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
    }
}

async function delCareerContact(id) {
    if (!confirm('Удалить контакт?')) return;
    await api('DELETE', `api/contacts.php?id=${id}`);
    toast('Удалено');
    loadCareerContacts();
}

window.loadCareerContacts = loadCareerContacts;
window.openCareerContact = openCareerContact;
window.editCareerContact = editCareerContact;
window.saveCareerContact = saveCareerContact;
window.delCareerContact = delCareerContact;