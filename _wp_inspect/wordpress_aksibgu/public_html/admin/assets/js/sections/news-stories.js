/* ── NEWS ─────────────────────────────────────────────────────── */
let nP = 1;
async function loadNews() {
    const q = v('nSrch'), st = $('nSt').value;
    let u = `api/news.php?page=${nP}&limit=20`;
    if (q) u += '&q=' + encodeURIComponent(q);
    if (st !== '') u += '&is_published=' + st;
    const r = await api('GET', u);
    const d = r && r.data ? r.data : [];
    const tot = r && r.total ? r.total : 0;
    $('nTb').innerHTML = d.length ? d.map(n => `<tr>
        <td>${n.id}</td>
        <td>${(n.cover_image||n.image_url) ? `<img class="ithumb" src="${esc(n.cover_image||n.image_url)}" onclick="openLB('${esc(n.cover_image||n.image_url)}')" style="cursor:pointer">` : '—'}</td>
        <td><strong>${esc(n.title)}</strong></td><td>${pubBdg(n.is_published)}</td>
        <td>${n.is_pinned ? bdg('Закреп.','bp') : '—'}</td><td>${fd(n.published_at||n.created_at)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editNews(${n.id})"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delNews(${n.id})"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join('') : empty('Новостей нет');
    $('nPgn').innerHTML = pgn(tot, nP, 20, 'goNP');
}
function goNP(p) { nP = p; loadNews(); }

function openNews(it) {
    $('nId').value = it ? it.id : '';
    $('nTit').value = it ? it.title : '';
    $('nCnt').value = it ? it.content : '';
    $('nImg').value = it ? (it.cover_image||it.image_url||'') : '';
    $('nAuth').value = it ? (it.author_name||it.author||'') : '';
    $('nCat').value = it ? it.category||'' : '';
    $('nPub').value = it && it.published_at ? it.published_at.replace(' ','T').slice(0,16) : '';
    $('nPubChk').checked = !it || !!+it.is_published;
    $('nPin').checked = it ? !!+it.is_pinned : false;
    $('mNewsT').textContent = it ? 'Редактировать новость' : 'Добавить новость';
    om('mNews');
}
async function editNews(id) { const r = await api('GET', `api/news.php?id=${id}`); if (r && r.id) openNews(r); else if (r && r.data) openNews(r.data); }
async function saveNews() {
    const id = $('nId').value;
    const d = { title:v('nTit'), content:v('nCnt'), cover_image:v('nImg'), author_name:v('nAuth'), category:v('nCat'),
        published_at:v('nPub')||null, is_published:$('nPubChk').checked?1:0, is_pinned:$('nPin').checked?1:0 };
    if (!d.title || !d.content) { toast('Заполните заголовок и содержание','error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/news.php?id=${id}`:'api/news.php', d);
    if (r && (r.id || r.success)) { toast(id?'Обновлено':'Создано'); cm('mNews'); loadNews(); }
    else toast((r&&(r.error||r.message))||'Ошибка','error');
}
async function delNews(id) {
    if (!confirm('Удалить?')) return;
    const r = await api('DELETE', `api/news.php?id=${id}`);
    toast('Удалено'); loadNews();
}

/* ── STORIES ──────────────────────────────────────────────────── */

// ── VK-стиль: мини-сетка фотографий ──────────────────────────────────────
function vkGrid(images, cover) {
    const all = [];
    if (cover) all.push(cover);
    (images || []).forEach(u => { if (u && u !== cover) all.push(u); });
    if (!all.length) return '<span style="color:var(--tx3);font-size:11px">нет фото</span>';

    const show = all.slice(0, 4);
    const extra = all.length > 4 ? all.length - 4 : 0;
    const n = show.length;
    const W = 96, H = 68, gap = 2;

    let rects = [];
    if (n === 1) {
        rects = [{x:0, y:0, w:W, h:H}];
    } else if (n === 2) {
        const w = (W - gap) / 2;
        rects = [{x:0, y:0, w, h:H}, {x:w+gap, y:0, w, h:H}];
    } else if (n === 3) {
        const w1 = Math.round((W - gap) * 2/3);
        const w2 = W - gap - w1;
        const h2 = (H - gap) / 2;
        rects = [
            {x:0,       y:0,      w:w1, h:H},
            {x:w1+gap,  y:0,      w:w2, h:h2},
            {x:w1+gap,  y:h2+gap, w:w2, h:H-h2-gap},
        ];
    } else {
        const w = (W - gap) / 2;
        const h = (H - gap) / 2;
        rects = [
            {x:0,     y:0,     w, h},
            {x:w+gap, y:0,     w, h},
            {x:0,     y:h+gap, w, h},
            {x:w+gap, y:h+gap, w, h},
        ];
    }

    const inner = show.map((url, i) => {
        const r = rects[i];
        const isLast = i === show.length - 1 && extra > 0;
        return `<div style="position:absolute;left:${r.x}px;top:${r.y}px;width:${r.w}px;height:${r.h}px;overflow:hidden;border-radius:3px;cursor:pointer" onclick="openLB('${esc(url)}')">` +
            `<img src="${esc(url)}" style="width:100%;height:100%;object-fit:cover;display:block">` +
            (isLast ? `<div style="position:absolute;inset:0;background:rgba(0,0,0,.5);display:flex;align-items:center;justify-content:center;color:#fff;font-size:15px;font-weight:700">+${extra}</div>` : '') +
            `</div>`;
    }).join('');

    return `<div style="position:relative;width:${W}px;height:${H}px;flex-shrink:0">${inner}</div>`;
}

// Кэш всех историй для операций с порядком
let _storiesCache = [];

async function loadStories() {
    const r = await api('GET', 'api/stories.php?limit=50');
    const d = r && r.data ? r.data : [];
    _storiesCache = d;

    $('stTb').innerHTML = d.length ? d.map((s, idx) => {
        let imgs = [];
        try {
            imgs = Array.isArray(s.images) ? s.images
                 : (s.images_json ? (typeof s.images_json === 'string' ? JSON.parse(s.images_json||'[]') : s.images_json) : []);
        } catch(e) { imgs = []; }
        const cover = s.cover_image || s.image_url || '';
        const isFirst = idx === 0;
        const isLast  = idx === d.length - 1;
        return `<tr id="str-row-${s.id}">
        <td>${s.id}</td>
        <td>${vkGrid(imgs, cover)}</td>
        <td>${esc(s.title)}</td>
        <td>${pubBdg(s.is_published)}</td>
        <td>
          <div class="st-ord-wrap">
            <button class="btn-ord" onclick="storyMoveUp(${s.id})" ${isFirst ? 'disabled' : ''} title="Выше"><i class="fas fa-chevron-up"></i></button>
            <span class="st-ord-num">${s.sort_order}</span>
            <button class="btn-ord" onclick="storyMoveDown(${s.id})" ${isLast ? 'disabled' : ''} title="Ниже"><i class="fas fa-chevron-down"></i></button>
          </div>
        </td>
        <td>${fd(s.published_at||s.created_at)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="editStory(${s.id})"><i class="fas fa-edit"></i></button>
            <button class="btn btn-danger btn-sm btn-ico" onclick="delStory(${s.id})"><i class="fas fa-trash"></i></button>
        </div></td></tr>`;
    }).join('') : empty('Историй нет');
}

/* Переместить вверх — обменять sort_order с предыдущим */
async function storyMoveUp(id) {
    const idx = _storiesCache.findIndex(s => s.id === id);
    if (idx <= 0) return;
    await _swapOrder(_storiesCache[idx], _storiesCache[idx - 1]);
}

/* Переместить вниз — обменять sort_order со следующим */
async function storyMoveDown(id) {
    const idx = _storiesCache.findIndex(s => s.id === id);
    if (idx < 0 || idx >= _storiesCache.length - 1) return;
    await _swapOrder(_storiesCache[idx], _storiesCache[idx + 1]);
}

async function _swapOrder(a, b) {
    const oa = +a.sort_order, ob = +b.sort_order;
    // Если порядки одинаковые — разводим по индексам
    const newA = ob !== oa ? ob : _storiesCache.indexOf(b);
    const newB = ob !== oa ? oa : _storiesCache.indexOf(a);
    await Promise.all([
        api('PATCH', `api/stories.php?id=${a.id}`, { sort_order: newA }),
        api('PATCH', `api/stories.php?id=${b.id}`, { sort_order: newB }),
    ]);
    loadStories();
}

function openStory(it) {
    $('stId').value = it ? it.id : '';
    $('stTit').value = it ? it.title : '';
    $('stCnt').value = it ? (it.description || it.content || '') : '';
    $('stImg').value = it ? (it.cover_image || it.image_url || '') : '';
    $('stVid').value = it ? it.video_url||'' : '';

    // Авто-порядок при создании: следующий после максимального
    if (!it) {
        const maxOrd = _storiesCache.length
            ? Math.max(..._storiesCache.map(s => +s.sort_order)) + 1
            : 1;
        $('stOrd').value = maxOrd;
    } else {
        $('stOrd').value = it.sort_order;
    }

    const imgs = it && it.images ? (Array.isArray(it.images) ? it.images : [])
               : (it && it.images_json ? (Array.isArray(it.images_json) ? it.images_json : JSON.parse(it.images_json||'[]')) : []);
    $('stImgs').value = imgs.join('\n');
    $('stPub').checked = !it || !!+it.is_published;
    $('mStoryT').textContent = it ? 'Редактировать историю' : 'Добавить историю';
    om('mStory');
}

async function editStory(id) {
    const r = await api('GET', `api/stories.php?id=${id}`);
    if (r && r.id) openStory(r);
    else if (r && r.data) openStory(r.data);
}

async function saveStory() {
    const id = $('stId').value;
    const imgs = $('stImgs').value.trim().split('\n').map(s => s.trim()).filter(Boolean);
    const d = {
        title:        v('stTit'),
        description:  v('stCnt'),
        cover_image:  v('stImg')||null,
        images:       imgs,
        sort_order:   +$('stOrd').value,
        is_published: $('stPub').checked ? 1 : 0
    };
    if (!d.title) { toast('Заполните заголовок','error'); return; }
    const r = await api(id?'PUT':'POST', id?`api/stories.php?id=${id}`:'api/stories.php', d);
    if (r && r.id) { toast(id?'Обновлено':'Создано'); cm('mStory'); loadStories(); }
    else if (r && r.success) { toast(id?'Обновлено':'Создано'); cm('mStory'); loadStories(); }
    else toast((r && (r.error || r.message)) || 'Ошибка','error');
}

async function delStory(id) {
    if (!confirm('Удалить историю?')) return;
    await api('DELETE', `api/stories.php?id=${id}`);
    toast('Удалено', 'warning');
    loadStories();
}