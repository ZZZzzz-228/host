/* ═══════════════════════════════════════════════════════════════
   image-cropper.js — Универсальный компонент загрузки и обрезки фото
   Использование:
     openCropper(targetInputId, options)
       targetInputId — id инпута (текстовое поле URL), куда вставится результат
       options.ratio — 1/1 | 4/3 | 16/9 | 3/4 | null (свободно, по умолчанию 1/1)
       options.title — заголовок модалки
       options.onDone(url) — callback после выбора (если нужна своя логика)
   ═══════════════════════════════════════════════════════════════ */

let _crTargetId    = null;   // id инпута-получателя URL
let _crCallback    = null;   // callback(url) после выбора
let _crImg         = null;   // HTMLImageElement оригинала
let _crImgOrigSrc  = null;   // data URL оригинала
let _crScale       = 1;
let _crAngle       = 0;
let _crFlip        = 1;      // 1 или -1
let _crOffX        = 0;      // смещение X центра изображения в координатах stage
let _crOffY        = 0;
let _crDrag        = false;
let _crDragSX      = 0;
let _crDragSY      = 0;
let _crDragOX      = 0;
let _crDragOY      = 0;
let _crRatioW      = 1;
let _crRatioH      = 1;
let _crFreeRatio   = false;
let _crStageW      = 480;
let _crStageH      = 300;
let _crFrameX      = 0;
let _crFrameY      = 0;
let _crFrameW      = 0;
let _crFrameH      = 0;
let _crUploadPending = false;

/* ─── Открыть кроппер ──────────────────────────────────────────── */
function openCropper(targetInputId, options) {
    options = options || {};
    _crTargetId  = targetInputId;
    _crCallback  = options.onDone || null;
    _crAngle     = 0;
    _crFlip      = 1;
    _crScale     = 1;
    _crOffX      = 0;
    _crOffY      = 0;
    _crImg       = null;
    _crUploadPending = false;

    /* Соотношение сторон */
    const ratio = options.ratio !== undefined ? options.ratio : 1;
    if (!ratio || ratio === 0) {
        _crFreeRatio = true; _crRatioW = 1; _crRatioH = 1;
    } else if (typeof ratio === 'number') {
        _crFreeRatio = false;
        _crRatioW = ratio >= 1 ? ratio : 1;
        _crRatioH = ratio >= 1 ? 1 : 1/ratio;
        if (ratio === 4/3) { _crRatioW=4; _crRatioH=3; }
        if (ratio === 16/9){ _crRatioW=16;_crRatioH=9; }
        if (ratio === 3/4) { _crRatioW=3; _crRatioH=4; }
    }
    _highlightRatioBtn();

    const title = options.title || 'Загрузка фото';
    document.getElementById('mCropperT').textContent = title;

    /* Скрываем рабочую область, показываем дропзону */
    document.getElementById('cropWorkArea').style.display  = 'none';
    document.getElementById('cropSaveOpts').style.display  = 'none';
    document.getElementById('cropFooter').style.display    = 'none';
    document.getElementById('cropDropZone').style.display  = 'block';
    document.getElementById('cropFileInput').value         = '';
    document.getElementById('cropStatusMsg').textContent   = '';
    document.getElementById('cropScale').value             = 1;

    om('mCropper');
}

function _highlightRatioBtn() {
    ['crBtn11','crBtn43','crBtn169','crBtn34','crBtnFree'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.classList.remove('btn-primary');
    });
    if (_crFreeRatio) {
        const el = document.getElementById('crBtnFree');
        if (el) el.classList.add('btn-primary');
    } else {
        const map = {'1_1':'crBtn11','4_3':'crBtn43','16_9':'crBtn169','3_4':'crBtn34'};
        const key = _crRatioW + '_' + _crRatioH;
        const el = document.getElementById(map[key]);
        if (el) el.classList.add('btn-primary');
    }
}

/* ─── Смена соотношения из кнопок ──────────────────────────────── */
function setCropRatio(w, h) {
    if (!w || !h) { _crFreeRatio = true; }
    else { _crFreeRatio = false; _crRatioW = w; _crRatioH = h; }
    _highlightRatioBtn();
    if (_crImg) _cropInitFrame();
}

/* ─── Выбор файла ──────────────────────────────────────────────── */
function cropFileSelected(input) {
    const file = input.files[0];
    if (!file) return;
    if (file.size > 10 * 1024 * 1024) { toast('Файл слишком большой (макс. 10 МБ)', 'error'); return; }
    if (!file.type.startsWith('image/')) { toast('Выберите изображение', 'error'); return; }
    const reader = new FileReader();
    reader.onload = function(e) { _cropLoadSrc(e.target.result, file); };
    reader.readAsDataURL(file);
}

function cropHandleDrop(event) {
    event.preventDefault();
    document.getElementById('cropDropZone').style.borderColor = 'rgba(91,127,206,.5)';
    const file = event.dataTransfer.files[0];
    if (!file) return;
    const fakeInput = { files: [file] };
    cropFileSelected(fakeInput);
}

function _cropLoadSrc(src, file) {
    _crImgOrigSrc = src;
    _crAngle = 0; _crFlip = 1; _crScale = 1; _crOffX = 0; _crOffY = 0;

    const img = new Image();
    img.onload = function() {
        _crImg = img;
        document.getElementById('cropDropZone').style.display = 'none';
        document.getElementById('cropWorkArea').style.display = 'block';
        document.getElementById('cropSaveOpts').style.display = 'block';
        document.getElementById('cropFooter').style.display   = '';
        document.getElementById('cropStatusMsg').textContent  = file ? `${file.name} · ${(file.size/1024).toFixed(0)} KB` : '';

        /* Вычисляем размеры stage */
        const stageEl = document.getElementById('cropStage');
        _crStageW = stageEl.offsetWidth || 480;
        _crStageH = Math.round(_crStageW * 0.6);
        stageEl.style.height = _crStageH + 'px';

        const canvas = document.getElementById('cropCanvas');
        canvas.width  = _crStageW;
        canvas.height = _crStageH;

        /* Авто-масштаб: вписать изображение */
        const fitScaleW = _crStageW / img.naturalWidth;
        const fitScaleH = _crStageH / img.naturalHeight;
        _crScale = Math.min(fitScaleW, fitScaleH) * 0.9;
        document.getElementById('cropScale').value = _crScale;

        _cropInitFrame();
    };
    img.src = src;
}

/* ─── Инициализация рамки ──────────────────────────────────────── */
function _cropInitFrame() {
    /* Рамка занимает 80% наименьшей стороны stage с учётом ratio */
    const maxW = _crStageW * 0.85;
    const maxH = _crStageH * 0.85;
    let fw, fh;
    if (_crFreeRatio) {
        fw = maxW; fh = maxH;
    } else {
        const r = _crRatioW / _crRatioH;
        if (maxW / r <= maxH) { fw = maxW; fh = maxW / r; }
        else { fh = maxH; fw = maxH * r; }
    }
    _crFrameW = fw;
    _crFrameH = fh;
    _crFrameX = (_crStageW - fw) / 2;
    _crFrameY = (_crStageH - fh) / 2;
    _cropUpdateFrame();
    cropRedraw();
}

function _cropUpdateFrame() {
    const frame = document.getElementById('cropFrame');
    frame.style.left   = _crFrameX + 'px';
    frame.style.top    = _crFrameY + 'px';
    frame.style.width  = _crFrameW + 'px';
    frame.style.height = _crFrameH + 'px';
    document.getElementById('cropDimInfo').textContent =
        Math.round(_crFrameW) + ' × ' + Math.round(_crFrameH) + ' px (предпросмотр)';
}

/* ─── Рисуем изображение ────────────────────────────────────────── */
function cropRedraw() {
    if (!_crImg) return;
    _crScale = parseFloat(document.getElementById('cropScale').value) || 1;
    const canvas = document.getElementById('cropCanvas');
    const ctx    = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const cx = _crStageW / 2 + _crOffX;
    const cy = _crStageH / 2 + _crOffY;

    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(_crAngle * Math.PI / 180);
    ctx.scale(_crFlip * _crScale, _crScale);
    ctx.drawImage(_crImg, -_crImg.naturalWidth/2, -_crImg.naturalHeight/2);
    ctx.restore();

    _cropUpdatePreview();
}

/* ─── Предпросмотр (72×72) ──────────────────────────────────────── */
function _cropUpdatePreview() {
    if (!_crImg) return;
    const prev = document.getElementById('cropPreview');
    const pCtx = prev.getContext('2d');
    const pw = 72, ph = 72;
    prev.width  = pw;
    prev.height = ph;

    /* Вырезаем ту же область что будет в результирующем изображении */
    const canvas = document.getElementById('cropCanvas');
    pCtx.clearRect(0, 0, pw, ph);
    pCtx.drawImage(
        canvas,
        _crFrameX, _crFrameY, _crFrameW, _crFrameH,
        0, 0, pw, ph
    );
}

/* ─── Drag ──────────────────────────────────────────────────────── */
function cropDragStart(e) {
    if (e.target === document.getElementById('cropFrame')) return;
    _crDrag  = true;
    _crDragSX = e.clientX;
    _crDragSY = e.clientY;
    _crDragOX = _crOffX;
    _crDragOY = _crOffY;
    e.preventDefault();
}

document.addEventListener('mousemove', function(e) {
    if (!_crDrag) return;
    _crOffX = _crDragOX + (e.clientX - _crDragSX);
    _crOffY = _crDragOY + (e.clientY - _crDragSY);
    cropRedraw();
});

document.addEventListener('mouseup', function() { _crDrag = false; });

/* ─── Touch (мобильные) ─────────────────────────────────────────── */
let _crTouchDist = 0;
let _crTouchScaleStart = 1;

function cropTouchStart(e) {
    if (e.touches.length === 1) {
        _crDrag   = true;
        _crDragSX = e.touches[0].clientX;
        _crDragSY = e.touches[0].clientY;
        _crDragOX = _crOffX;
        _crDragOY = _crOffY;
    } else if (e.touches.length === 2) {
        _crDrag = false;
        _crTouchDist = Math.hypot(
            e.touches[1].clientX - e.touches[0].clientX,
            e.touches[1].clientY - e.touches[0].clientY
        );
        _crTouchScaleStart = _crScale;
    }
    e.preventDefault();
}

document.addEventListener('touchmove', function(e) {
    if (e.touches.length === 1 && _crDrag) {
        _crOffX = _crDragOX + (e.touches[0].clientX - _crDragSX);
        _crOffY = _crDragOY + (e.touches[0].clientY - _crDragSY);
        cropRedraw();
    } else if (e.touches.length === 2) {
        const dist = Math.hypot(
            e.touches[1].clientX - e.touches[0].clientX,
            e.touches[1].clientY - e.touches[0].clientY
        );
        _crScale = Math.max(0.1, Math.min(4, _crTouchScaleStart * dist / _crTouchDist));
        document.getElementById('cropScale').value = _crScale;
        cropRedraw();
    }
}, {passive: false});

document.addEventListener('touchend', function() { _crDrag = false; });

/* ─── Колесо мыши — масштаб ─────────────────────────────────────── */
document.getElementById('cropStage') && (function() {
    document.getElementById('cropStage').addEventListener('wheel', function(e) {
        if (!_crImg) return;
        e.preventDefault();
        _crScale = Math.max(0.1, Math.min(4, _crScale - e.deltaY * 0.001));
        document.getElementById('cropScale').value = _crScale;
        cropRedraw();
    }, {passive: false});
})();

/* ─── Поворот и отражение ───────────────────────────────────────── */
function cropRotate(deg) { _crAngle = (_crAngle + deg) % 360; cropRedraw(); }
function cropFlipH()      { _crFlip *= -1; cropRedraw(); }

function cropReset() {
    _crAngle = 0; _crFlip = 1; _crOffX = 0; _crOffY = 0;
    if (_crImg) {
        const fitScaleW = _crStageW / _crImg.naturalWidth;
        const fitScaleH = _crStageH / _crImg.naturalHeight;
        _crScale = Math.min(fitScaleW, fitScaleH) * 0.9;
        document.getElementById('cropScale').value = _crScale;
    }
    cropRedraw();
}

/* ─── Применить обрезку ─────────────────────────────────────────── */
async function cropApply() {
    if (!_crImg) return;

    /* Рендерим в выходной canvas с реальными размерами */
    const outW = Math.round(_crFrameW);
    const outH = Math.round(_crFrameH);
    const out  = document.createElement('canvas');
    out.width  = outW;
    out.height = outH;
    const ctx  = out.getContext('2d');

    /* Рисуем ту же трансформацию, но со сдвигом рамки */
    const scaleUp = 1; /* Пиксели — как в stage */
    ctx.save();
    ctx.translate(-_crFrameX, -_crFrameY);
    ctx.translate(_crStageW/2 + _crOffX, _crStageH/2 + _crOffY);
    ctx.rotate(_crAngle * Math.PI / 180);
    ctx.scale(_crFlip * _crScale, _crScale);
    ctx.drawImage(_crImg, -_crImg.naturalWidth/2, -_crImg.naturalHeight/2);
    ctx.restore();

    document.getElementById('cropStatusMsg').textContent = 'Загрузка на сервер...';

    /* Конвертируем в Blob и загружаем */
    out.toBlob(async function(blob) {
        const fd = new FormData();
        fd.append('file', blob, 'cropped_' + Date.now() + '.jpg');
        fd.append('type', 'images');

        try {
            const resp = await fetch('api/upload.php', { method: 'POST', body: fd });
            if (!resp.ok) throw new Error('HTTP ' + resp.status);
            const data = await resp.json();
            if (data.url) {
                _cropDone(data.url);
            } else {
                throw new Error(data.error || 'Ошибка загрузки');
            }
        } catch(err) {
            /* Если загрузка на сервер не удалась — используем data URL */
            toast('Сохранение на сервере не удалось, используется base64', 'warning');
            const dataUrl = out.toDataURL('image/jpeg', 0.92);
            _cropDone(dataUrl);
        }
    }, 'image/jpeg', 0.92);
}

/* ─── Использовать оригинал без обрезки ──────────────────────────── */
async function cropUseOriginal() {
    if (!_crImgOrigSrc) return;
    document.getElementById('cropStatusMsg').textContent = 'Загрузка на сервер...';

    /* Конвертируем data URL в Blob */
    const resp2 = await fetch(_crImgOrigSrc);
    const blob  = await resp2.blob();

    const fd = new FormData();
    fd.append('file', blob, 'original_' + Date.now() + '.jpg');
    fd.append('type', 'images');

    try {
        const resp = await fetch('api/upload.php', { method: 'POST', body: fd });
        const data = await resp.json();
        if (data.url) { _cropDone(data.url); return; }
    } catch(e) {}

    /* Fallback — data URL */
    _cropDone(_crImgOrigSrc);
}

function _cropDone(url) {
    /* Вставляем URL в целевой инпут */
    if (_crTargetId) {
        const inp = document.getElementById(_crTargetId);
        if (inp) {
            inp.value = url;
            /* Показываем превью рядом с полем */
            _showInlinePreview(_crTargetId, url);
            /* Триггерим событие input для реактивных обработчиков */
            inp.dispatchEvent(new Event('input'));
        }
    }
    /* Вызываем callback если есть */
    if (typeof _crCallback === 'function') _crCallback(url);

    cm('mCropper');
    toast('Фото загружено', 'success');
}

function cropperCancel() { cm('mCropper'); }

/* ─── Встроенный предпросмотр рядом с полем ─────────────────────── */
function _showInlinePreview(inputId, url) {
    const inp = document.getElementById(inputId);
    if (!inp) return;
    const existingPrev = document.getElementById('prev_' + inputId);
    if (existingPrev) existingPrev.remove();

    if (!url) return;
    const wrap = document.createElement('div');
    wrap.id = 'prev_' + inputId;
    wrap.style.cssText = 'margin-top:6px;display:flex;align-items:center;gap:8px';
    wrap.innerHTML = `
        <img src="${url}" alt="preview"
             style="width:56px;height:56px;object-fit:cover;border-radius:8px;
                    border:2px solid rgba(91,127,206,.4);cursor:pointer;flex-shrink:0"
             onclick="openLB('${url.replace(/'/g,"\\'")}')">
        <div>
            <div style="font-size:11px;color:#7a8496">Предпросмотр (нажмите для увеличения)</div>
            <button type="button" onclick="clearPhoto('${inputId}')"
                    style="background:none;border:none;color:#ff6b6b;font-size:11px;cursor:pointer;padding:0;margin-top:2px">
                <i class="fas fa-times"></i> Удалить фото
            </button>
        </div>`;
    inp.parentNode.insertBefore(wrap, inp.nextSibling);
}

/* ─── Очистить фото ─────────────────────────────────────────────── */
function clearPhoto(inputId) {
    const inp = document.getElementById(inputId);
    if (inp) inp.value = '';
    const prev = document.getElementById('prev_' + inputId);
    if (prev) prev.remove();
}

/* ─── Инициализируем превью для уже заполненных полей ───────────── */
function initPhotoPreview(inputId) {
    const inp = document.getElementById(inputId);
    if (!inp) return;

    /* При изменении URL — показываем превью */
    inp.addEventListener('change', function() {
        if (inp.value && inp.value.startsWith('http')) {
            _showInlinePreview(inputId, inp.value);
        } else {
            clearPhoto(inputId);
        }
    });

    /* Показываем превью при открытии формы если URL уже есть */
    if (inp.value) setTimeout(() => _showInlinePreview(inputId, inp.value), 50);
}
