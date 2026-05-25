<!-- ═══ MODAL: STORY ═══ -->
<div class="mo" id="mStory"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mStoryT">Добавить историю</div><button class="mc" onclick="cm('mStory')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="stId">
    <div class="fr"><label>Заголовок *</label><input class="fc" id="stTit"></div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="stCnt" style="min-height:90px"></textarea></div>
    <div class="fg">
      <!-- Главное фото с кроппером -->
      <div class="fr">
        <label>Главное фото</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="stImg" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('stImg',{title:'Фото истории',ratio:9/16})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>URL видео</label><input class="fc" id="stVid"></div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="stOrd" value="0"></div>
    </div>
    <div class="fr"><label>Доп. фото (по URL на строку)</label><textarea class="ft" id="stImgs" style="min-height:70px" placeholder="https://img1.jpg&#10;https://img2.jpg"></textarea></div>
    <div class="fchk"><input type="checkbox" id="stPub" checked><label for="stPub">Опубликовано</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mStory')">Отмена</button>
    <button class="btn btn-primary" onclick="saveStory()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
