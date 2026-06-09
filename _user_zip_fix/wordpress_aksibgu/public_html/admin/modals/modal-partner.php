<!-- ═══ MODAL: PARTNER ═══ -->
<div class="mo" id="mPartner"><div class="modal">
  <div class="mh"><div class="mt" id="mPartnerT">Партнёр</div><button class="mc" onclick="cm('mPartner')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="ptId">
    <div class="fr"><label>Название *</label><input class="fc" id="ptNm"></div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="ptDesc" style="min-height:70px"></textarea></div>
    <div class="fg">
      <div class="fr"><label>URL сайта</label><input class="fc" id="ptSt" placeholder="https://..."></div>
      <!-- Логотип с кроппером -->
      <div class="fr">
        <label>Логотип</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="ptLg" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('ptLg',{title:'Логотип партнёра',ratio:1})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>Категория</label>
        <select class="fs" id="ptCat">
          <option value="career_center">Карьерный центр</option>
          <option value="college">Колледж</option>
        </select>
      </div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="ptOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="ptPub" checked><label for="ptPub">Опубликован</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mPartner')">Отмена</button>
    <button class="btn btn-primary" onclick="savePartner()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
