<!-- ═══ MODAL: CAREER EVENT ═══ -->
<div class="mo" id="mCEv"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mCEvT">Мероприятие</div><button class="mc" onclick="cm('mCEv')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="ceId">
    <div class="fr"><label>Название *</label><input class="fc" id="ceTit"></div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="ceDesc"></textarea></div>
    <div class="fg">
      <div class="fr"><label>Место проведения</label><input class="fc" id="ceLoc"></div>
      <div class="fr"><label>Дата начала</label><input type="datetime-local" class="fc" id="ceDate"></div>
      <div class="fr"><label>Дата конца</label><input type="datetime-local" class="fc" id="ceEnd"></div>
      <!-- Изображение мероприятия с кроппером -->
      <div class="fr">
        <label>Изображение</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="ceImg" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('ceImg',{title:'Изображение мероприятия',ratio:16/9})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>Ссылка регистрации</label><input class="fc" id="ceReg"></div>
      <div class="fr"><label>Макс. мест</label><input type="number" class="fc" id="ceSts"></div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="ceOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="cePub" checked><label for="cePub">Опубликовано</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mCEv')">Отмена</button>
    <button class="btn btn-primary" onclick="saveCEv()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
