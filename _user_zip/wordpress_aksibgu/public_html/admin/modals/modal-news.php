<!-- ═══ MODAL: NEWS ═══ -->
<div class="mo" id="mNews"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mNewsT">Добавить новость</div><button class="mc" onclick="cm('mNews')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="nId">
    <div class="fr"><label>Заголовок *</label><input class="fc" id="nTit" placeholder="Заголовок новости"></div>
    <div class="fr"><label>Содержание *</label><textarea class="ft" id="nCnt" style="min-height:150px" placeholder="Текст..."></textarea></div>
    <div class="fg">
      <!-- Поле фото с кроппером -->
      <div class="fr">
        <label>Изображение</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="nImg" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('nImg',{title:'Обложка новости',ratio:16/9})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>Автор</label><input class="fc" id="nAuth"></div>
      <div class="fr"><label>Категория</label><input class="fc" id="nCat"></div>
      <div class="fr"><label>Дата публикации</label><input type="datetime-local" class="fc" id="nPub"></div>
    </div>
    <div style="display:flex;gap:18px;flex-wrap:wrap">
      <div class="fchk"><input type="checkbox" id="nPubChk" checked><label for="nPubChk">Опубликовано</label></div>
      <div class="fchk"><input type="checkbox" id="nPin"><label for="nPin">Закрепить</label></div>
    </div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mNews')">Отмена</button>
    <button class="btn btn-primary" onclick="saveNews()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
