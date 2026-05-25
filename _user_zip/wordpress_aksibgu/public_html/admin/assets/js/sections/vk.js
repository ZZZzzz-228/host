/* ── VK PENDING / PARSER ─────────────────────────────────────── */

/* ══ Галерея (лайтбокс с навигацией) ══════════════════════════ */
const vkGal = {
    imgs: [], idx: 0, postId: null,

    open(imgs, idx, postId) {
        this.imgs = imgs; this.idx = idx; this.postId = postId;
        this._ensure();
        this._render();
        document.getElementById('vk-gal').classList.add('active');
        document.body.style.overflow = 'hidden';
    },

    close() {
        const g = document.getElementById('vk-gal');
        if (g) g.classList.remove('active');
        document.body.style.overflow = '';
    },

    go(dir) {
        this.idx = (this.idx + dir + this.imgs.length) % this.imgs.length;
        this._render();
    },

    _render() {
        const g = document.getElementById('vk-gal');
        if (!g) return;
        const img = this.imgs[this.idx];
        const sel = this._isSelected(img);
        g.querySelector('.vk-gal-img').src = img;
        g.querySelector('.vk-gal-cnt').textContent = `${this.idx + 1} / ${this.imgs.length}`;
        g.querySelector('.vk-gal-prev').style.display = this.imgs.length > 1 ? '' : 'none';
        g.querySelector('.vk-gal-next').style.display = this.imgs.length > 1 ? '' : 'none';
        const cb = g.querySelector('.vk-gal-cb');
        cb.classList.toggle('checked', sel);
        cb.title = sel ? 'Снять выбор' : 'Выбрать для публикации';
        cb.innerHTML = sel
            ? '<i class="fas fa-check-square"></i> Выбрана'
            : '<i class="far fa-square"></i> Выбрать';
    },

    toggleSel() {
        const img = this.imgs[this.idx];
        // find the photo element in the card
        const card = document.getElementById('vkcard-' + this.postId);
        if (!card) return;
        const ph = [...card.querySelectorAll('.vk-ph[data-src]')]
            .find(e => e.dataset.src === img || e.src === img);
        if (ph) {
            ph.classList.toggle('sel');
            // update checkbox overlay
            const wrap = ph.closest('.vk-ph-wrap');
            if (wrap) wrap.classList.toggle('sel', ph.classList.contains('sel'));
        }
        // update count
        const cnt = card.querySelectorAll('.vk-ph.sel').length;
        const allPh = card.querySelectorAll('.vk-ph').length;
        const cntEl = document.getElementById('vselcnt-' + this.postId);
        if (cntEl) cntEl.textContent = cnt;
        this._render();
    },

    _isSelected(img) {
        if (!this.postId) return false;
        const card = document.getElementById('vkcard-' + this.postId);
        if (!card) return false;
        const ph = [...card.querySelectorAll('.vk-ph[data-src]')]
            .find(e => e.dataset.src === img || e.src === img);
        return ph ? ph.classList.contains('sel') : false;
    },

    _ensure() {
        if (document.getElementById('vk-gal')) return;
        const d = document.createElement('div');
        d.id = 'vk-gal';
        d.innerHTML = `
            <div class="vk-gal-bg" onclick="vkGal.close()"></div>
            <div class="vk-gal-box">
                <button class="vk-gal-close" onclick="vkGal.close()"><i class="fas fa-times"></i></button>
                <button class="vk-gal-prev" onclick="vkGal.go(-1)"><i class="fas fa-chevron-left"></i></button>
                <div class="vk-gal-center">
                    <img class="vk-gal-img" src="" alt="">
                    <div class="vk-gal-footer">
                        <span class="vk-gal-cnt"></span>
                        <button class="vk-gal-cb" onclick="vkGal.toggleSel()"></button>
                    </div>
                </div>
                <button class="vk-gal-next" onclick="vkGal.go(1)"><i class="fas fa-chevron-right"></i></button>
            </div>`;
        document.body.appendChild(d);
        // keyboard navigation
        document.addEventListener('keydown', e => {
            if (!document.getElementById('vk-gal')?.classList.contains('active')) return;
            if (e.key === 'ArrowLeft')  vkGal.go(-1);
            if (e.key === 'ArrowRight') vkGal.go(1);
            if (e.key === 'Escape')     vkGal.close();
        });
    }
};

/* ══ Обёртка одного фото с чекбоксом ══════════════════════════ */
function buildPhotoWrap(img, idx, allImgs, postId, selectable) {
    if (selectable) {
        return `<div class="vk-ph-wrap" onclick="vkGal.open(${JSON.stringify(allImgs).replace(/"/g,'&quot;')},${idx},${postId})">
            <img class="vk-ph" src="${esc(img)}" data-src="${esc(img)}" data-post="${postId}">
            <span class="vk-ph-cb" onclick="event.stopPropagation();togVkPhWrap(this,${postId})" title="Выбрать для публикации">
                <i class="far fa-square vk-cb-off"></i>
                <i class="fas fa-check-square vk-cb-on"></i>
            </span>
        </div>`;
    } else {
        return `<img class="vk-ph-view" src="${esc(img)}" data-src="${esc(img)}"
            onclick="vkGal.open(${JSON.stringify(allImgs).replace(/"/g,'&quot;')},${idx},null)">`;
    }
}

/* ══ Сетка фото ════════════════════════════════════════════════ */
function buildPhotoGrid(imgs, postId, selectable) {
    if (!imgs || !imgs.length) return '';
    const n = imgs.length;
    const w = (img, i) => buildPhotoWrap(img, i, imgs, postId, selectable);

    if (n === 1) return `<div class="vk-grid vk-grid-1">${w(imgs[0],0)}</div>`;

    if (n === 2) return `<div class="vk-grid vk-grid-2">${imgs.map(w).join('')}</div>`;

    if (n === 3) return `<div class="vk-grid vk-grid-3">
        ${w(imgs[0],0)}
        <div class="vk-grid-col">${imgs.slice(1).map((img,i)=>w(img,i+1)).join('')}</div>
    </div>`;

    if (n === 4) return `<div class="vk-grid vk-grid-4">${imgs.map(w).join('')}</div>`;

    // 5+ : показываем 4, последняя с счётчиком "+N"
    const extra = n - 4;
    const tiles = imgs.slice(0, 4).map((img, i) => {
        if (i === 3 && extra > 0) {
            return `<div class="vk-grid-more" onclick="vkGal.open(${JSON.stringify(imgs).replace(/"/g,'&quot;')},${i},${postId})">
                <img class="vk-ph" src="${esc(img)}" data-src="${esc(img)}" data-post="${postId}" style="pointer-events:none">
                ${selectable ? `<span class="vk-ph-cb" onclick="event.stopPropagation();togVkPhWrap(this,${postId})" title="Выбрать">
                    <i class="far fa-square vk-cb-off"></i><i class="fas fa-check-square vk-cb-on"></i>
                </span>` : ''}
                <span class="vk-more-cnt">+${extra}</span>
            </div>`;
        }
        return w(img, i);
    });
    // скрытые фото для выбора
    const hidden = selectable ? imgs.slice(4).map((img,i) =>
        `<img class="vk-ph" src="${esc(img)}" data-src="${esc(img)}" data-post="${postId}" style="display:none">`
    ).join('') : '';
    return `<div class="vk-grid vk-grid-4">${tiles.join('')}${hidden}</div>`;
}

/* ══ Переключение чекбокса на карточке ═══════════════════════ */
function togVkPhWrap(cbEl, postId) {
    const wrap = cbEl.closest('.vk-ph-wrap, .vk-grid-more');
    const ph = wrap ? wrap.querySelector('.vk-ph') : null;
    if (ph) {
        ph.classList.toggle('sel');
        wrap.classList.toggle('sel', ph.classList.contains('sel'));
    }
    const card = document.getElementById('vkcard-' + postId);
    if (!card) return;
    const cnt = card.querySelectorAll('.vk-ph.sel').length;
    const cntEl = document.getElementById('vselcnt-' + postId);
    if (cntEl) cntEl.textContent = cnt;
}

/* ── (Старая функция — оставляем для совместимости) ── */
function togVkPh(el, postId) {
    el.classList.toggle('sel');
    const wrap = el.closest('.vk-ph-wrap,.vk-grid-more');
    if (wrap) wrap.classList.toggle('sel', el.classList.contains('sel'));
    const cnt = document.querySelectorAll(`#vphotos-${postId} .vk-ph.sel`).length;
    const cntEl = document.getElementById('vselcnt-' + postId);
    if (cntEl) cntEl.textContent = cnt;
}

/* ══ Загрузка списка постов ════════════════════════════════════ */
async function loadVK() {
    $('vkList').innerHTML = '<div class="ldo"><div class="spin"></div></div>';
    const r = await api('GET', 'api/vk_pending.php?limit=30');
    const d = r && r.data ? r.data : [];
    if (!d.length) {
        $('vkList').innerHTML = '<div class="empty"><i class="fab fa-vk" style="font-size:44px;color:#4c75a3;opacity:.4"></i><p>Нет постов на модерации</p></div>';
        if ($('vkB')) { $('vkB').textContent = '0'; $('vkB').style.display = 'none'; }
        return;
    }
    if ($('vkB')) { $('vkB').textContent = d.length; $('vkB').style.display = ''; }

    $('vkList').innerHTML = d.map(p => {
        const imgs = p.images_json
            ? (Array.isArray(p.images_json) ? p.images_json : (JSON.parse(p.images_json || '[]') || []))
            : (p.images || []);
        const textFull  = (p.content || p.vk_text || p.text || '').trim();
        const textShort = textFull.length > 500 ? textFull.substring(0, 500) : textFull;
        const hasMore   = textFull.length > 500;
        const textShortFmt = textShort.replace(/\n/g, '<br>');
        const textFullFmt  = textFull.replace(/\n/g, '<br>');

        return `<div class="vk-card" id="vkcard-${p.id}">

            <!-- Шапка -->
            <div class="vk-card-hd">
                <div class="vk-card-meta">
                    <span class="vk-post-num"><i class="fab fa-vk" style="color:#4c75a3"></i> Пост: ${esc(String(p.vk_post_id || p.id))}</span>
                    <span class="vk-post-date"><i class="far fa-clock" style="opacity:.5"></i> ${fd(p.parsed_at || p.vk_date || p.created_at)}</span>
                    ${p.vk_post_url ? `<a href="${esc(p.vk_post_url)}" target="_blank" class="vk-post-link"><i class="fas fa-external-link-alt"></i> Открыть в ВК</a>` : ''}
                </div>
                <div class="vk-card-actions">
                    <button class="btn btn-success btn-sm" onclick="vkApproveInline(${p.id})"><i class="fas fa-check"></i>Одобрить</button>
                    <button class="btn btn-danger btn-sm" onclick="vkReject(${p.id})"><i class="fas fa-ban"></i>Отклонить</button>
                    <button class="btn btn-sec btn-sm" onclick="vkSkip(${p.id})"><i class="fas fa-forward"></i>Пропустить</button>
                </div>
            </div>

            <!-- Тело: фото слева, текст справа -->
            <div class="vk-body">

                ${imgs.length ? `
                <div class="vk-col-photo">
                    <div class="vk-photo-hint"><i class="fas fa-expand-alt"></i> Клик — просмотр &nbsp;|&nbsp; <i class="far fa-check-square"></i> Галочка — выбор</div>
                    <div id="vphotos-${p.id}">${buildPhotoGrid(imgs, p.id, true)}</div>
                    <div class="vk-sel-info" id="vsel-${p.id}">Выбрано: <b id="vselcnt-${p.id}">0</b> из ${imgs.length}</div>
                </div>` : ''}

                <div class="vk-col-text">
                    ${textFull ? `
                    <div class="vk-txt" id="vtxt-${p.id}">
                        <div class="vk-txt-body" id="vtxtb-${p.id}">${textShortFmt}${hasMore ? '<span style="opacity:.5">…</span>' : ''}</div>
                        ${hasMore ? `<button class="vk-txt-more" onclick="vkExpand(${p.id})"><i class="fas fa-chevron-down"></i> Читать полностью</button>` : ''}
                        <div class="vk-txt-full" id="vtxtf-${p.id}" style="display:none">${textFullFmt}</div>
                    </div>` : '<div class="vk-no-text"><i class="fas fa-align-slash"></i> Без текста</div>'}
                </div>

            </div>
        </div>`;
    }).join('');
}

function vkExpand(id) {
    const b = $('vtxtb-' + id), f = $('vtxtf-' + id);
    if (!b || !f) return;
    b.style.display = 'none'; f.style.display = '';
    const btn = b.parentElement.querySelector('.vk-txt-more');
    if (btn) btn.style.display = 'none';
}

/* ══ Одобрение ═════════════════════════════════════════════════ */
function vkApproveInline(id) {
    const card = $('vkcard-' + id);
    if (!card) return;
    const textEl = $('vtxtf-' + id) || $('vtxtb-' + id);
    const txt = textEl ? textEl.textContent.trim() : '';
    const selImgs = [...card.querySelectorAll('.vk-ph.sel')].map(e => e.dataset.src || e.src);
    const allImgs = [...card.querySelectorAll('.vk-ph:not([style*="display:none"])')].map(e => e.dataset.src || e.src);
    openVkApp(id, txt, selImgs.length ? selImgs : allImgs);
}

function openVkApp(id, txt, imgs) {
    $('vkAId').value = id;
    $('vkATit').value = '';
    $('vkACnt').value = txt;
    $('vkAPhotos').innerHTML = imgs.map((img, i) =>
        `<img class="vk-ph" src="${esc(img)}" data-src="${esc(img)}" data-idx="${i}" onclick="togVkPhModal(this)">`
    ).join('');
    $('vkAPhotos').querySelectorAll('.vk-ph').forEach(e => e.classList.add('sel'));
    om('mVkApp');
}

function togVkPhModal(el) { el.classList.toggle('sel'); }

async function vkApprove() {
    const id = $('vkAId').value;
    const tit = v('vkATit');
    const cnt = v('vkACnt');
    if (!tit) { toast('Укажите заголовок', 'error'); return; }
    if (!cnt) { toast('Укажите текст', 'error'); return; }
    const sel = [...$('vkAPhotos').querySelectorAll('.vk-ph.sel')].map(e => e.dataset.src || e.src);
    const r = await api('POST', 'api/vk_pending.php?action=approve', {
        action: 'approve', id: parseInt(id),
        title: tit, content: cnt, description: cnt,
        selected_images: sel,
        publish_now: $('vkAPubNow').checked
    });
    if (r && (r.status === 'approved' || r.story_id || r.success)) {
        toast('Пост одобрен и опубликован как история!');
        cm('mVkApp'); loadVK();
    } else {
        toast((r && (r.message || r.error)) || 'Ошибка при одобрении', 'error');
    }
}

async function vkReject(id) {
    if (!confirm('Отклонить этот пост?')) return;
    cm('mVkApp');
    const r = await api('POST', 'api/vk_pending.php?action=reject', { action: 'reject', id: parseInt(id) });
    if (r && (r.status === 'rejected' || r.success)) { toast('Пост отклонён', 'warning'); loadVK(); }
    else toast((r && (r.message || r.error)) || 'Ошибка при отклонении', 'error');
}

async function vkSkip(id) {
    const r = await api('POST', 'api/vk_pending.php?action=skip', { action: 'skip', id: parseInt(id) });
    if (r && (r.status === 'skipped' || r.success)) { toast('Пост пропущен', 'info'); loadVK(); }
    else toast((r && (r.message || r.error)) || 'Ошибка', 'error');
}

async function runParser() {
    toast('Сбор постов с ВК...', 'info');
    const r = await api('POST', 'api/vk_parser_run.php');
    if (r && (r.status === 'success' || r.status === 'started')) {
        toast(`Собрано постов с ВК: ${r.imported || r.count || 0}`); loadVK();
    } else toast((r && (r.message || r.error)) || 'Ошибка сбора постов', 'error');
}