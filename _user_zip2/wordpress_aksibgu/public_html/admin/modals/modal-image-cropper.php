<!-- ═══ MODAL: IMAGE CROPPER (универсальный) ═══ -->
<div class="mo" id="mCropper" style="z-index:9999">
<div class="modal" style="max-width:560px;width:96%">
  <div class="mh">
    <div class="mt" id="mCropperT">Загрузка фото</div>
    <button class="mc" onclick="cropperCancel()"><i class="fas fa-times"></i></button>
  </div>
  <div class="mb" style="padding:0">

    <!-- Зона выбора файла -->
    <div id="cropDropZone" style="
        border:2px dashed rgba(91,127,206,.5);border-radius:10px;
        margin:16px;padding:32px 20px;text-align:center;cursor:pointer;
        transition:border-color .2s,background .2s;background:rgba(91,127,206,.04)
    " onclick="document.getElementById('cropFileInput').click()"
       ondragover="event.preventDefault();this.style.borderColor='#5b7fce'"
       ondragleave="this.style.borderColor='rgba(91,127,206,.5)'"
       ondrop="cropHandleDrop(event)">
      <i class="fas fa-cloud-upload-alt" style="font-size:36px;color:#5b7fce;opacity:.7;margin-bottom:10px;display:block"></i>
      <div style="font-size:14px;font-weight:600;color:#c0cbe0">Перетащите фото сюда</div>
      <div style="font-size:12px;color:#5b6478;margin-top:4px">или нажмите, чтобы выбрать файл</div>
      <div style="font-size:11px;color:#3d4558;margin-top:8px">JPG, PNG, WebP · до 10 МБ</div>
    </div>
    <input type="file" id="cropFileInput" accept="image/*" style="display:none" onchange="cropFileSelected(this)">

    <!-- Рабочая область кроппера (скрыта до выбора файла) -->
    <div id="cropWorkArea" style="display:none;padding:0 16px 16px">

      <!-- Canvas-область обрезки -->
      <div style="position:relative;overflow:hidden;border-radius:10px;background:#0a0d14;margin-bottom:12px;
                  display:flex;align-items:center;justify-content:center;min-height:300px;user-select:none"
           id="cropStage"
           onmousedown="cropDragStart(event)" ontouchstart="cropTouchStart(event)">
        <canvas id="cropCanvas" style="display:block;max-width:100%;touch-action:none"></canvas>
        <!-- Рамка обрезки -->
        <div id="cropFrame" style="
            position:absolute;pointer-events:none;
            border:2px solid #5b7fce;
            box-shadow:0 0 0 9999px rgba(0,0,0,.55);
            border-radius:4px
        "></div>
      </div>

      <!-- Слайдер масштаба -->
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px">
        <i class="fas fa-search-minus" style="color:#5b6478;font-size:13px"></i>
        <input type="range" id="cropScale" min="0.1" max="4" step="0.01" value="1"
               style="flex:1;accent-color:#5b7fce" oninput="cropRedraw()">
        <i class="fas fa-search-plus" style="color:#5b6478;font-size:13px"></i>
      </div>

      <!-- Кнопки поворота и сброса -->
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px">
        <button class="btn btn-sec btn-sm" onclick="cropRotate(-90)" title="Повернуть влево">
          <i class="fas fa-undo"></i> -90°
        </button>
        <button class="btn btn-sec btn-sm" onclick="cropRotate(90)" title="Повернуть вправо">
          <i class="fas fa-redo"></i> +90°
        </button>
        <button class="btn btn-sec btn-sm" onclick="cropFlipH()" title="Отразить горизонтально">
          <i class="fas fa-arrows-alt-h"></i> Отразить
        </button>
        <button class="btn btn-sec btn-sm" onclick="cropReset()" title="Сбросить">
          <i class="fas fa-sync-alt"></i> Сброс
        </button>
        <button class="btn btn-sec btn-sm" onclick="document.getElementById('cropFileInput').click()">
          <i class="fas fa-folder-open"></i> Другое фото
        </button>
      </div>

      <!-- Предпросмотр результата -->
      <div style="display:flex;gap:14px;align-items:center;background:rgba(255,255,255,.03);
                  border:1px solid rgba(255,255,255,.07);border-radius:8px;padding:12px;margin-bottom:4px">
        <canvas id="cropPreview" width="72" height="72"
                style="border-radius:8px;flex-shrink:0;border:2px solid rgba(91,127,206,.4);
                       background:#0a0d14"></canvas>
        <div>
          <div style="font-size:12px;font-weight:600;color:#c0cbe0">Предпросмотр</div>
          <div style="font-size:11px;color:#5b6478;margin-top:2px" id="cropDimInfo">72 × 72 px</div>
          <div style="font-size:11px;color:#3d8bcd;margin-top:4px" id="cropStatusMsg"></div>
        </div>
      </div>

    </div>

    <!-- Опции сохранения (скрыты до выбора файла) -->
    <div id="cropSaveOpts" style="display:none;padding:0 16px 8px">
      <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
        <label style="font-size:12px;color:#7a8496">Соотношение:</label>
        <button class="btn btn-sec btn-sm" onclick="setCropRatio(1,1)" id="crBtn11">1:1</button>
        <button class="btn btn-sec btn-sm" onclick="setCropRatio(4,3)" id="crBtn43">4:3</button>
        <button class="btn btn-sec btn-sm" onclick="setCropRatio(16,9)" id="crBtn169">16:9</button>
        <button class="btn btn-sec btn-sm" onclick="setCropRatio(3,4)" id="crBtn34">3:4</button>
        <button class="btn btn-sec btn-sm" onclick="setCropRatio(0,0)" id="crBtnFree">Свободно</button>
      </div>
    </div>

  </div>
  <div class="mf" id="cropFooter" style="display:none">
    <button class="btn btn-sec" onclick="cropperCancel()">Отмена</button>
    <div style="display:flex;gap:8px">
      <button class="btn btn-sec" onclick="cropUseOriginal()">
        <i class="fas fa-image"></i> Оригинал
      </button>
      <button class="btn btn-primary" onclick="cropApply()">
        <i class="fas fa-crop-alt"></i> Применить
      </button>
    </div>
  </div>
</div>
</div>
