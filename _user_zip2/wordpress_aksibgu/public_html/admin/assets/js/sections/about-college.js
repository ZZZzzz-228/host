/* ================================================================
   О КОЛЛЕДЖЕ — Admin Editor JS v2
   ================================================================ */
(function () {
  'use strict';

  /* ── Иконки (name = Material/Flutter icon name, fa = FontAwesome) ── */
  const AC_ICONS = [
    { name: 'school',            fa: 'fas fa-graduation-cap' },
    { name: 'star',              fa: 'fas fa-star' },
    { name: 'people',            fa: 'fas fa-users' },
    { name: 'public',            fa: 'fas fa-globe' },
    { name: 'business',          fa: 'fas fa-building' },
    { name: 'engineering',       fa: 'fas fa-cogs' },
    { name: 'science',           fa: 'fas fa-flask' },
    { name: 'computer',          fa: 'fas fa-laptop-code' },
    { name: 'menu_book',         fa: 'fas fa-book-open' },
    { name: 'rocket_launch',     fa: 'fas fa-rocket' },
    { name: 'emoji_events',      fa: 'fas fa-trophy' },
    { name: 'flag',              fa: 'fas fa-flag' },
    { name: 'verified',          fa: 'fas fa-check-circle' },
    { name: 'auto_awesome',      fa: 'fas fa-magic' },
    { name: 'workspace_premium', fa: 'fas fa-medal' },
    { name: 'apartment',         fa: 'fas fa-city' },
    { name: 'home_work',         fa: 'fas fa-home' },
    { name: 'fitness_center',    fa: 'fas fa-dumbbell' },
    { name: 'local_library',     fa: 'fas fa-book' },
    { name: 'lightbulb',         fa: 'fas fa-lightbulb' },
    { name: 'calculate',         fa: 'fas fa-calculator' },
    { name: 'security',          fa: 'fas fa-shield-alt' },
    { name: 'code',              fa: 'fas fa-code' },
    { name: 'restaurant',        fa: 'fas fa-utensils' },
    { name: 'sports_esports',    fa: 'fas fa-gamepad' },
  ];

  /* ── Цвета ── */
  const AC_COLORS = [
    '#1565C0','#283593','#4A90E2','#00695C','#2E7D32',
    '#1B5E20','#E65100','#BF360C','#880E4F','#4A148C',
    '#006064','#0D47A1','#37474F','#263238','#F57F17',
    '#FF6F00','#1976D2','#388E3C','#D32F2F','#7B1FA2',
  ];

  /* ── Состояние ── */
  let _stats        = [];
  let _advantages   = [];
  let _achievements = [];
  let _dirty        = false;
  let _previewVisible = true;
  let _pageId       = null;

  // Crop state
  let _cropDataUrl  = null;
  let _cropTargetId = null;
  let _cropScale    = 1;
  let _cropRatio    = 16/9;
  let _cropX = 50, _cropY = 30, _cropW = 200, _cropH = 112;
  let _cropDragging = false, _cropResizing = null;
  let _cropStartX, _cropStartY, _cropStartCropX, _cropStartCropY, _cropStartCropW, _cropStartCropH;

  /* ── Утилиты ── */
  function gid(id) { return document.getElementById(id); }
  function gv(id)  { const el = gid(id); return el ? el.value.trim() : ''; }
  function esc(s)  { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
  function uid()   { return Math.random().toString(36).slice(2,8); }
  function iconFa(name) { const ic = AC_ICONS.find(i=>i.name===name); return ic ? ic.fa : 'fas fa-star'; }
  function hex2rgb(hex, a) {
    const r=parseInt(hex.slice(1,3),16), g=parseInt(hex.slice(3,5),16), b=parseInt(hex.slice(5,7),16);
    return `rgba(${r},${g},${b},${a})`;
  }

  /* ── Auto-grow textarea ── */
  window.ac2AutoGrow = function(el) {
    el.style.height = 'auto';
    el.style.height = el.scrollHeight + 'px';
  };

  /* ── Dirty ── */
  window.acMarkDirty = function() {
    _dirty = true;
    const d=gid('acDirtyBadge'), s=gid('acSavedBadge');
    if(d) d.style.display='inline-flex';
    if(s) s.style.display='none';
    ac2RenderPreview();
  };

  /* ── Tabs ── */
  window.acTab = function(name, btn) {
    document.querySelectorAll('.ac2-tab').forEach(t=>t.classList.remove('active'));
    document.querySelectorAll('.ac2-tab-content').forEach(t=>t.classList.remove('active'));
    btn.classList.add('active');
    const tc = gid('acTab-'+name);
    if(tc) tc.classList.add('active');
  };

  /* ── Preview toggle ── */
  window.ac2TogglePreview = function() {
    _previewVisible = !_previewVisible;
    const col   = gid('ac2PreviewCol');
    const icon  = gid('ac2PreviewIcon');
    const label = gid('ac2PreviewLabel');
    if(col)   col.style.display   = _previewVisible ? '' : 'none';
    if(icon)  icon.className      = _previewVisible ? 'fas fa-eye-slash' : 'fas fa-eye';
    if(label) label.textContent   = _previewVisible ? 'Скрыть' : 'Предпросмотр';
    // layout адаптация
    const layout = document.querySelector('.ac2-layout');
    if(layout) layout.classList.toggle('ac2-no-preview', !_previewVisible);
  };

  /* ════════════════════════════════════════════════════
     IMAGE PICKER + CROP
  ════════════════════════════════════════════════════ */
  window.ac2PickCover = function() {
    const inp = document.createElement('input');
    inp.type='file'; inp.accept='image/*';
    inp.onchange = function() {
      const file = inp.files[0];
      if(!file) return;
      // Проверка размера
      if(file.size > 5*1024*1024) {
        if(typeof toast==='function') toast('Файл слишком большой (макс. 5 МБ)', 'error');
        return;
      }
      const reader = new FileReader();
      reader.onload = function(e) {
        // Сначала показываем кроп
        ac2OpenCrop(e.target.result, 'acCover');
      };
      reader.readAsDataURL(file);
    };
    inp.click();
  };

  window.ac2EditCrop = function() {
    const current = gv('acCover') || (gid('ac2CoverThumb') ? gid('ac2CoverThumb').src : '');
    if(!current) return;
    ac2OpenCrop(current, 'acCover');
  };

  window.ac2ClearCover = function() {
    gid('acCover').value = '';
    if(gid('ac2CoverUrl')) gid('ac2CoverUrl').value = '';
    gid('ac2CoverPreview').style.display = 'none';
    gid('ac2CoverEmpty').style.display = 'flex';
    acMarkDirty();
  };

  window.ac2OnUrlInput = function(url) {
    url = url.trim();
    if(!url) { ac2ClearCover(); return; }
    gid('acCover').value = url;
    ac2ShowCoverPreview(url);
    acMarkDirty();
  };

  function ac2ShowCoverPreview(url) {
    const thumb = gid('ac2CoverThumb');
    const preview = gid('ac2CoverPreview');
    const empty = gid('ac2CoverEmpty');
    if(!thumb || !preview || !empty) return;
    thumb.src = url;
    thumb.onerror = function() { ac2ClearCover(); };
    preview.style.display = 'flex';
    empty.style.display = 'none';
  }

  /* ── Crop Modal ── */
  window.ac2OpenCrop = function(dataUrl, targetId) {
    _cropDataUrl  = dataUrl;
    _cropTargetId = targetId;
    _cropScale    = 1;
    _cropRatio    = 16/9;

    const modal = gid('ac2CropModal');
    const img   = gid('ac2CropImg');
    if(!modal || !img) return;

    img.src = dataUrl;
    img.onload = function() {
      _cropW = Math.min(img.naturalWidth * 0.8, 400);
      _cropH = _cropRatio > 0 ? _cropW / _cropRatio : _cropW * 0.5;
      _cropX = (img.width - _cropW) / 2;
      _cropY = (img.height - _cropH) / 2;
      ac2UpdateCropBox();
    };

    modal.style.display = 'flex';
    modal.classList.add('ac2-crop-open');
    ac2InitCropDrag();
  };

  window.ac2CloseCrop = function() {
    const modal = gid('ac2CropModal');
    if(modal) { modal.style.display='none'; modal.classList.remove('ac2-crop-open'); }
  };

  window.ac2SetRatio = function(ratio, btn) {
    _cropRatio = ratio;
    document.querySelectorAll('.ac2-ratio-btn').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
    if(ratio > 0) { _cropH = _cropW / ratio; ac2UpdateCropBox(); }
  };

  window.ac2Zoom = function(delta) {
    const img = gid('ac2CropImg');
    if(!img) return;
    _cropScale = Math.min(3, Math.max(0.2, _cropScale + delta));
    img.style.transform = `scale(${_cropScale})`;
    const slider = gid('ac2ZoomRange');
    if(slider) slider.value = Math.round(_cropScale * 100);
  };

  window.ac2ZoomRange = function(val) {
    const img = gid('ac2CropImg');
    if(!img) return;
    _cropScale = val / 100;
    img.style.transform = `scale(${_cropScale})`;
  };

  function ac2UpdateCropBox() {
    const box = gid('ac2CropBox');
    if(!box) return;
    box.style.left   = _cropX + 'px';
    box.style.top    = _cropY + 'px';
    box.style.width  = Math.max(60, _cropW) + 'px';
    box.style.height = Math.max(40, _cropH) + 'px';
  }

  function ac2InitCropDrag() {
    const box = gid('ac2CropBox');
    if(!box || box._dragInited) return;
    box._dragInited = true;

    // Drag box
    box.addEventListener('mousedown', function(e) {
      if(e.target.classList.contains('ac2-crop-corner')) return;
      _cropDragging = true;
      _cropStartX = e.clientX - _cropX;
      _cropStartY = e.clientY - _cropY;
      e.preventDefault();
    });

    // Resize corners
    box.querySelectorAll('.ac2-crop-corner').forEach(corner => {
      corner.addEventListener('mousedown', function(e) {
        _cropResizing = e.target.dataset.dir;
        _cropStartX = e.clientX; _cropStartY = e.clientY;
        _cropStartCropX = _cropX; _cropStartCropY = _cropY;
        _cropStartCropW = _cropW; _cropStartCropH = _cropH;
        e.stopPropagation(); e.preventDefault();
      });
    });

    document.addEventListener('mousemove', function(e) {
      if(_cropDragging) {
        const wrapper = gid('ac2CropWrapper');
        const maxX = wrapper ? wrapper.clientWidth  - _cropW : 999;
        const maxY = wrapper ? wrapper.clientHeight - _cropH : 999;
        _cropX = Math.max(0, Math.min(maxX, e.clientX - _cropStartX));
        _cropY = Math.max(0, Math.min(maxY, e.clientY - _cropStartY));
        ac2UpdateCropBox();
      } else if(_cropResizing) {
        const dx = e.clientX - _cropStartX;
        const dy = e.clientY - _cropStartY;
        const dir = _cropResizing;
        let nx=_cropStartCropX, ny=_cropStartCropY, nw=_cropStartCropW, nh=_cropStartCropH;
        if(dir.includes('e')) nw = Math.max(60, nw + dx);
        if(dir.includes('s')) nh = Math.max(40, nh + dy);
        if(dir.includes('w')) { nx = _cropStartCropX + dx; nw = Math.max(60, _cropStartCropW - dx); }
        if(dir.includes('n')) { ny = _cropStartCropY + dy; nh = Math.max(40, _cropStartCropH - dy); }
        if(_cropRatio > 0) nh = nw / _cropRatio;
        _cropX=nx; _cropY=ny; _cropW=nw; _cropH=nh;
        ac2UpdateCropBox();
      }
    });

    document.addEventListener('mouseup', function() { _cropDragging=false; _cropResizing=null; });
  }

  window.ac2ApplyCrop = function() {
    const img = gid('ac2CropImg');
    if(!img) return;

    // img.clientWidth/Height — CSS-размер элемента БЕЗ учёта transform:scale
    // _cropX/Y/W/H — координаты в визуальном пространстве (с учётом _cropScale)
    // Формула: визуальные координаты → натуральные пиксели изображения:
    //   srcCoord = (cropCoord / _cropScale) * (naturalSize / clientSize)
    const dispW = img.clientWidth  || img.naturalWidth;
    const dispH = img.clientHeight || img.naturalHeight;
    const natScaleX = img.naturalWidth  / dispW;
    const natScaleY = img.naturalHeight / dispH;

    const srcX = Math.round((_cropX / _cropScale) * natScaleX);
    const srcY = Math.round((_cropY / _cropScale) * natScaleY);
    const srcW = Math.max(1, Math.round((_cropW / _cropScale) * natScaleX));
    const srcH = Math.max(1, Math.round((_cropH / _cropScale) * natScaleY));

    const canvas = document.createElement('canvas');
    canvas.width  = srcW;
    canvas.height = srcH;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(img, srcX, srcY, srcW, srcH, 0, 0, canvas.width, canvas.height);

    const dataUrl = canvas.toDataURL('image/jpeg', 0.92);

    // Загружаем на сервер
    ac2UploadDataUrl(dataUrl).then(url => {
      gid('acCover').value = url || dataUrl;
      if(gid('ac2CoverUrl')) gid('ac2CoverUrl').value = url || '';
      ac2ShowCoverPreview(url || dataUrl);
      acMarkDirty();
      ac2CloseCrop();
    });
  };

  async function ac2UploadDataUrl(dataUrl) {
    try {
      const blob = await (await fetch(dataUrl)).blob();
      const fd   = new FormData();
      fd.append('file', blob, 'cover_' + Date.now() + '.jpg');
      const r = await fetch('api/upload.php', { method:'POST', body:fd });
      const j = await r.json();
      return j.url || j.path || '';
    } catch(e) {
      // Если upload не работает — возвращаем dataUrl как есть
      return '';
    }
  }

  /* ── Drag & Drop на cover block ── */
  function initCoverDrop() {
    const block = gid('ac2CoverBlock');
    if(!block || block._dropInited) return;
    block._dropInited = true;
    block.addEventListener('dragover', e => { e.preventDefault(); block.classList.add('ac2-cover-drag'); });
    block.addEventListener('dragleave', () => block.classList.remove('ac2-cover-drag'));
    block.addEventListener('drop', e => {
      e.preventDefault(); block.classList.remove('ac2-cover-drag');
      const file = e.dataTransfer.files[0];
      if(!file || !file.type.startsWith('image/')) return;
      if(file.size > 5*1024*1024) { if(typeof toast==='function') toast('Файл слишком большой', 'error'); return; }
      const reader = new FileReader();
      reader.onload = ev => ac2OpenCrop(ev.target.result, 'acCover');
      reader.readAsDataURL(file);
    });
  }

  /* ════════════════════════════════════════════════════
     СТАТЫ
  ════════════════════════════════════════════════════ */
  function statHtml(item, idx) {
    const colorOpts = AC_COLORS.map(c=>`<div class="ac2-clr${item.colorHex===c?' sel':''}" style="background:${c}" onclick="acStatColor(${idx},'${c}',this)" title="${c}"></div>`).join('');
    const iconOpts  = AC_ICONS.map(ic=>`<button class="ac2-ico-btn${item.iconName===ic.name?' sel':''}" title="${ic.name}" onclick="acStatIcon(${idx},'${ic.name}',this)" type="button"><i class="${ic.fa}"></i></button>`).join('');
    return `
    <div class="ac2-card-item" id="acStat-${item._uid}">
      <div class="ac2-card-hd">
        <div class="ac2-card-num"><i class="${iconFa(item.iconName)}" style="color:${item.colorHex||'#4A90E2'}"></i> Показатель ${idx+1}</div>
        <button class="ac2-card-del" onclick="acRemoveStat(${idx})" type="button" title="Удалить"><i class="fas fa-trash-alt"></i></button>
      </div>
      <div class="ac2-card-body">
        <div class="ac2-row2" style="margin-bottom:12px">
          <div class="ac2-field">
            <label class="ac2-label">Значение</label>
            <input type="text" class="ac2-inp" value="${esc(item.value)}" placeholder="1 200+" oninput="acStatField(${idx},'value',this.value)">
          </div>
          <div class="ac2-field">
            <label class="ac2-label">Подпись</label>
            <input type="text" class="ac2-inp" value="${esc(item.label)}" placeholder="студентов" oninput="acStatField(${idx},'label',this.value)">
          </div>
        </div>
        <div class="ac2-field" style="margin-bottom:10px">
          <label class="ac2-label">Иконка <span class="ac2-icon-chosen" id="acStatLbl-${item._uid}">— ${item.iconName||'school'}</span></label>
          <div class="ac2-ico-picker">${iconOpts}</div>
        </div>
        <div class="ac2-field">
          <label class="ac2-label">Цвет</label>
          <div class="ac2-clr-row">${colorOpts}</div>
        </div>
      </div>
    </div>`;
  }

  function renderStats() {
    const c=gid('acStatsContainer'); if(!c) return;
    if(!_stats.length) { c.innerHTML='<div class="ac2-empty-state"><i class="fas fa-chart-bar"></i><span>Добавьте показатели колледжа</span></div>'; return; }
    c.innerHTML = _stats.map((s,i)=>statHtml(s,i)).join('');
  }

  window.acAddStat = function() { _stats.push({_uid:uid(),iconName:'school',value:'',label:'',colorHex:'#4A90E2'}); renderStats(); acMarkDirty(); };
  window.acRemoveStat = function(idx) { _stats.splice(idx,1); renderStats(); acMarkDirty(); };
  window.acStatField  = function(idx,field,val) { if(_stats[idx]) { _stats[idx][field]=val; ac2RenderPreview(); } };
  window.acStatIcon   = function(idx,iconName,btn) {
    if(!_stats[idx]) return;
    _stats[idx].iconName = iconName;
    btn.closest('.ac2-card-item').querySelectorAll('.ac2-ico-btn').forEach(b=>b.classList.remove('sel'));
    btn.classList.add('sel');
    const lbl=gid('acStatLbl-'+_stats[idx]._uid); if(lbl) lbl.textContent='— '+iconName;
    acMarkDirty();
  };
  window.acStatColor  = function(idx,hex,sw) {
    if(!_stats[idx]) return;
    _stats[idx].colorHex=hex;
    sw.closest('.ac2-card-item').querySelectorAll('.ac2-clr').forEach(s=>s.classList.remove('sel'));
    sw.classList.add('sel');
    acMarkDirty();
  };

  /* ════════════════════════════════════════════════════
     КАРТОЧКИ (Преимущества / Достижения)
  ════════════════════════════════════════════════════ */
  function cardHtml(item, idx, type) {
    const label = type==='adv' ? 'Преимущество' : 'Достижение';
    const colorOpts = AC_COLORS.map(c=>`<div class="ac2-clr${item.colorHex===c?' sel':''}" style="background:${c}" onclick="acCardColor('${type}',${idx},'${c}',this)" title="${c}"></div>`).join('');
    const iconOpts  = AC_ICONS.map(ic=>`<button class="ac2-ico-btn${item.iconName===ic.name?' sel':''}" title="${ic.name}" onclick="acCardIcon('${type}',${idx},'${ic.name}',this)" type="button"><i class="${ic.fa}"></i></button>`).join('');
    return `
    <div class="ac2-card-item" id="ac${type}-${item._uid}">
      <div class="ac2-card-hd">
        <div class="ac2-card-num"><i class="${iconFa(item.iconName)}" style="color:${item.colorHex||'#1565C0'}"></i> ${label} ${idx+1}</div>
        <button class="ac2-card-del" onclick="acRemoveCard('${type}',${idx})" type="button" title="Удалить"><i class="fas fa-trash-alt"></i></button>
      </div>
      <div class="ac2-card-body">
        <div class="ac2-row2" style="margin-bottom:12px">
          <div class="ac2-field">
            <label class="ac2-label">Заголовок</label>
            <input type="text" class="ac2-inp" value="${esc(item.title)}" placeholder="Современное оборудование" oninput="acCardField('${type}',${idx},'title',this.value)">
          </div>
          <div class="ac2-field">
            <label class="ac2-label">Описание</label>
            <input type="text" class="ac2-inp" value="${esc(item.text)}" placeholder="Краткое описание..." oninput="acCardField('${type}',${idx},'text',this.value)">
          </div>
        </div>
        <div class="ac2-field" style="margin-bottom:10px">
          <label class="ac2-label">Иконка <span class="ac2-icon-chosen" id="ac${type}Lbl-${item._uid}">— ${item.iconName||'star'}</span></label>
          <div class="ac2-ico-picker">${iconOpts}</div>
        </div>
        <div class="ac2-field">
          <label class="ac2-label">Цвет</label>
          <div class="ac2-clr-row">${colorOpts}</div>
        </div>
      </div>
    </div>`;
  }

  function renderCards(type) {
    const arr = type==='adv' ? _advantages : _achievements;
    const cId = type==='adv' ? 'acAdvContainer' : 'acAchContainer';
    const c = gid(cId); if(!c) return;
    const ei = type==='adv' ? 'fa-star' : 'fa-trophy';
    const et = type==='adv' ? 'Добавьте преимущества' : 'Добавьте достижения';
    if(!arr.length) { c.innerHTML=`<div class="ac2-empty-state"><i class="fas ${ei}"></i><span>${et}</span></div>`; return; }
    c.innerHTML = arr.map((it,i)=>cardHtml(it,i,type)).join('');
  }

  window.acAddAdvantage   = function() { _advantages.push({_uid:uid(),iconName:'star',title:'',text:'',colorHex:'#1565C0'}); renderCards('adv'); acMarkDirty(); };
  window.acAddAchievement = function() { _achievements.push({_uid:uid(),iconName:'emoji_events',title:'',text:'',colorHex:'#F57F17'}); renderCards('ach'); acMarkDirty(); };
  window.acRemoveCard     = function(type,idx) { (type==='adv'?_advantages:_achievements).splice(idx,1); renderCards(type); acMarkDirty(); };
  window.acCardField      = function(type,idx,field,val) { const a=type==='adv'?_advantages:_achievements; if(a[idx]) { a[idx][field]=val; ac2RenderPreview(); } };
  window.acCardIcon       = function(type,idx,iconName,btn) {
    const arr=type==='adv'?_advantages:_achievements; if(!arr[idx]) return;
    arr[idx].iconName=iconName;
    btn.closest('.ac2-card-item').querySelectorAll('.ac2-ico-btn').forEach(b=>b.classList.remove('sel'));
    btn.classList.add('sel');
    const lbl=gid('ac'+type+'Lbl-'+arr[idx]._uid); if(lbl) lbl.textContent='— '+iconName;
    acMarkDirty();
  };
  window.acCardColor      = function(type,idx,hex,sw) {
    const arr=type==='adv'?_advantages:_achievements; if(!arr[idx]) return;
    arr[idx].colorHex=hex;
    sw.closest('.ac2-card-item').querySelectorAll('.ac2-clr').forEach(s=>s.classList.remove('sel'));
    sw.classList.add('sel');
    acMarkDirty();
  };

  /* ════════════════════════════════════════════════════
     ПРЕДПРОСМОТР — точно повторяет Flutter CollegeInfoScreen
  ════════════════════════════════════════════════════ */
  function ac2RenderPreview() {
    const screen = gid('acPreviewScreen'); if(!screen) return;

    const cover     = gv('acCover') || (gid('ac2CoverThumb') ? gid('ac2CoverThumb').src : '');
    const title     = gv('acTitle')        || 'Название колледжа';
    const missionT  = gv('acMissionTitle') || 'Наша миссия';
    const aboutT    = gv('acAboutTitle')   || 'О колледже';
    const lead      = gv('acLead');
    const body      = gv('acBody');
    const statsH    = gv('acStatsHeading')  || 'Колледж в цифрах';
    const advH      = gv('acAdvHeading')    || 'Почему выбирают нас';
    const achH      = gv('acAchHeading')    || 'Наши достижения';
    const infraH    = gv('acInfraHeading')  || 'Инфраструктура';
    const infraT    = gv('acInfraText');
    const published = gid('acPublished') && gid('acPublished').checked;

    // ── Flutter-like app screen ──
    let h = `<div class="fl-screen">`;

    // AppBar (как в Flutter) — плашка "Опубликовано" убрана
    h += `<div class="fl-appbar">
      <div class="fl-appbar-back"><i class="fas fa-arrow-left"></i></div>
      <div class="fl-appbar-title">${esc(title)}</div>
    </div>`;

    // Cover image (Hero-виджет)
    if(cover && cover !== '') {
      h += `<div class="fl-hero"><img src="${esc(cover)}" alt="" onerror="this.parentElement.style.display='none'"></div>`;
    } else {
      h += `<div class="fl-hero fl-hero-ph"><i class="fas fa-image"></i><span>Обложка</span></div>`;
    }

    h += `<div class="fl-content">`;

    // Mission section
    h += `<div class="fl-section-title">${esc(missionT)}</div>`;
    if(lead) h += `<div class="fl-paragraph">${esc(lead)}</div>`;
    else     h += `<div class="fl-paragraph fl-placeholder">Текст вступления...</div>`;

    // About section
    h += `<div class="fl-section-title" style="margin-top:16px">${esc(aboutT)}</div>`;
    if(body) h += `<div class="fl-paragraph">${esc(body)}</div>`;
    else     h += `<div class="fl-paragraph fl-placeholder">Основной текст о колледже...</div>`;

    // Stats (Flutter GridView 2 cols)
    if(_stats.length) {
      h += `<div class="fl-section-title" style="margin-top:16px">${esc(statsH)}</div>`;
      h += `<div class="fl-stats-grid">`;
      _stats.forEach(s => {
        if(!s.value && !s.label) return;
        const col = s.colorHex || '#4A90E2';
        h += `<div class="fl-stat-card" style="background:${hex2rgb(col,0.08)};border:1.5px solid ${hex2rgb(col,0.25)}">
          <div class="fl-stat-ico" style="background:${hex2rgb(col,0.15)};color:${col}"><i class="${iconFa(s.iconName)}"></i></div>
          <div class="fl-stat-val" style="color:${col}">${esc(s.value)}</div>
          <div class="fl-stat-lbl">${esc(s.label)}</div>
        </div>`;
      });
      h += `</div>`;
    }

    // Advantages (Flutter Column с карточками)
    if(_advantages.filter(a=>a.title).length) {
      h += `<div class="fl-section-title" style="margin-top:16px">${esc(advH)}</div>`;
      _advantages.forEach(a => {
        if(!a.title) return;
        const col = a.colorHex || '#1565C0';
        h += `<div class="fl-adv-card">
          <div class="fl-adv-ico" style="background:${hex2rgb(col,0.12)};color:${col}"><i class="${iconFa(a.iconName)}"></i></div>
          <div class="fl-adv-text">
            <div class="fl-adv-title">${esc(a.title)}</div>
            <div class="fl-adv-sub">${esc(a.text)}</div>
          </div>
        </div>`;
      });
    }

    // Achievements (Flutter GridView 2 cols)
    if(_achievements.filter(a=>a.title).length) {
      h += `<div class="fl-section-title" style="margin-top:16px">${esc(achH)}</div>`;
      h += `<div class="fl-ach-grid">`;
      _achievements.forEach(a => {
        if(!a.title) return;
        const col = a.colorHex || '#F57F17';
        h += `<div class="fl-ach-card" style="background:${hex2rgb(col,0.07)};border:1.5px solid ${hex2rgb(col,0.2)}">
          <div class="fl-ach-ico" style="background:${hex2rgb(col,0.15)};color:${col}"><i class="${iconFa(a.iconName)}"></i></div>
          <div class="fl-ach-title" style="color:${col}">${esc(a.title)}</div>
          <div class="fl-ach-sub">${esc(a.text)}</div>
        </div>`;
      });
      h += `</div>`;
    }

    // Infrastructure
    if(infraT) {
      h += `<div class="fl-section-title" style="margin-top:16px">${esc(infraH)}</div>`;
      h += `<div class="fl-paragraph">${esc(infraT)}</div>`;
    }

    h += `<div style="height:24px"></div></div></div>`; // bottom padding

    screen.innerHTML = h;
  }

  /* ════════════════════════════════════════════════════
     LOAD
  ════════════════════════════════════════════════════ */
  window.acLoad = async function() {
    try {
      const r = await (typeof api === 'function'
        ? api('GET', 'api/about-college.php?slug=about-college')
        : fetch('api/about-college.php?slug=about-college').then(x=>x.json()));

      const page = r && r.id ? r : (r && r.data && r.data.id ? r.data : null);

      if(!page) { _setDefaults(); _refreshAll(); return; }

      _pageId = page.id;
      let cj = {};
      try {
        const raw = page.content_json || page.content || '{}';
        cj = JSON.parse(typeof raw === 'string' ? raw : JSON.stringify(raw));
      } catch(e) { cj = {}; }

      _set('acTitle',        page.title || '');
      _set('acMissionTitle', cj.mission_title || '');
      _set('acAboutTitle',   cj.about_title   || '');
      _set('acLead',         cj.lead          || '');
      _set('acBody',         cj.body          || '');
      _set('acAudience',     page.audience    || '');
      _set('acStatsHeading', cj.stats_heading || '');
      _set('acAdvHeading',   cj.advantages_heading || '');
      _set('acAchHeading',   cj.achievements_heading || '');
      _set('acInfraHeading', cj.infrastructure_heading || '');
      _set('acInfraText',    cj.infrastructure_text   || '');

      const pub = gid('acPublished'); if(pub) pub.checked = !!+page.is_published;

      // Cover
      const coverUrl = page.cover_image_url || page.cover_image || '';
      gid('acCover').value = coverUrl;
      if(gid('ac2CoverUrl')) gid('ac2CoverUrl').value = coverUrl;
      if(coverUrl) ac2ShowCoverPreview(coverUrl);

      // Обратный маппинг: Flutter сохраняет icon/color, JS ожидает iconName/colorHex
      _stats = (cj.stats || []).map(s => ({
        ...s, _uid: uid(),
        iconName: s.iconName || s.icon || 'school',
        colorHex: s.colorHex || s.color || '#4A90E2'
      }));
      _advantages = (cj.advantages || []).map(a => ({
        ...a, _uid: uid(),
        iconName: a.iconName || a.icon || 'star',
        colorHex: a.colorHex || a.color || '#1565C0'
      }));
      _achievements = (cj.achievements || []).map(a => ({
        ...a, _uid: uid(),
        iconName: a.iconName || a.icon || 'emoji_events',
        colorHex: a.colorHex || a.color || '#F57F17'
      }));

      // Auto-grow textareas
      ['acLead','acBody','acInfraText'].forEach(id => {
        const el = gid(id); if(el && el.value) ac2AutoGrow(el);
      });

      _refreshAll(); _dirty = false;
    } catch(e) {
      console.warn('[about-college] load error:', e);
      _setDefaults(); _refreshAll();
    }
  };

  function _set(id, val) { const el=gid(id); if(el) el.value=val; }
  function _setDefaults() {
    _set('acTitle','АКСИБГУ'); _set('acMissionTitle','Наша миссия');
    _set('acAboutTitle','О колледже');
    _stats=[]; _advantages=[]; _achievements=[];
    const pub=gid('acPublished'); if(pub) pub.checked=true;
  }
  function _refreshAll() { renderStats(); renderCards('adv'); renderCards('ach'); ac2RenderPreview(); }

  /* ════════════════════════════════════════════════════
     SAVE
  ════════════════════════════════════════════════════ */
  window.acSave = async function() {
    const title = gv('acTitle');
    if(!title) { if(typeof toast==='function') toast('Укажите заголовок страницы','error'); return; }

    const prog=gid('acProgress'), bar=gid('acProgressBar'), btn=gid('acSaveBtn');
    if(prog) prog.style.display='block';
    if(bar)  bar.style.width='30%';
    if(btn)  btn.disabled=true;

    const content_json = JSON.stringify({
      lead:                   gv('acLead'),
      body:                   gv('acBody'),
      mission_title:          gv('acMissionTitle'),
      about_title:            gv('acAboutTitle'),
      stats_heading:          gv('acStatsHeading'),
      advantages_heading:     gv('acAdvHeading'),
      achievements_heading:   gv('acAchHeading'),
      infrastructure_heading: gv('acInfraHeading'),
      infrastructure_text:    gv('acInfraText'),
      // Маппинг для Flutter: iconName→icon, colorHex→color (именно так читает _parseStats/_parseCmsCards)
      stats: _stats.map(({_uid, iconName, colorHex, ...rest}) => ({...rest, icon: iconName, color: colorHex})),
      advantages: _advantages.map(({_uid, iconName, colorHex, ...rest}) => ({...rest, icon: iconName, color: colorHex})),
      achievements: _achievements.map(({_uid, iconName, colorHex, ...rest}) => ({...rest, icon: iconName, color: colorHex})),
    });

    const payload = {
      title, slug:'about-college', content_json,
      cover_image_url: gv('acCover'),
      audience:    gv('acAudience'),
      is_published: gid('acPublished') && gid('acPublished').checked ? 1 : 0,
      template:    'about-college',
    };

    if(bar) bar.style.width='60%';
    try {
      const r = _pageId
        ? await (typeof api==='function' ? api('PUT',`api/about-college.php?id=${_pageId}`,payload)
            : fetch(`api/about-college.php?id=${_pageId}`,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)}).then(x=>x.json()))
        : await (typeof api==='function' ? api('POST','api/about-college.php',payload)
            : fetch('api/about-college.php',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)}).then(x=>x.json()));

      if(bar) bar.style.width='100%';
      if(r && (r.id||r.success||(r.data&&r.data.id))) {
        if(r.id) _pageId=r.id; else if(r.data&&r.data.id) _pageId=r.data.id;
        _dirty=false;
        const d=gid('acDirtyBadge'),s=gid('acSavedBadge');
        if(d) d.style.display='none';
        if(s) { s.style.display='inline-flex'; setTimeout(()=>{ if(s) s.style.display='none'; },3000); }
        if(typeof toast==='function') toast('Сохранено','success');
      } else {
        const msg=r&&(r.error||r.message)?(r.error||r.message):'Ошибка сохранения';
        if(typeof toast==='function') toast(msg,'error');
      }
    } catch(e) {
      if(typeof toast==='function') toast('Ошибка: '+e.message,'error');
    } finally {
      setTimeout(()=>{ if(prog) prog.style.display='none'; if(bar) bar.style.width='0'; if(btn) btn.disabled=false; },600);
    }
  };

  /* ════════════════════════════════════════════════════
     INIT
  ════════════════════════════════════════════════════ */
  function init() {
    const sec = gid('s-about-college'); if(!sec) { setTimeout(init,300); return; }
    _setDefaults(); _refreshAll();
    initCoverDrop();
    ['acTitle','acMissionTitle','acAboutTitle','acLead','acBody','acAudience','acStatsHeading','acAdvHeading','acAchHeading','acInfraHeading','acInfraText'].forEach(id=>{
      const el=gid(id); if(el) el.addEventListener('input',()=>acMarkDirty());
    });
    const pub=gid('acPublished'); if(pub) pub.addEventListener('change',()=>acMarkDirty());
  }

  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',init);
  else init();

})();