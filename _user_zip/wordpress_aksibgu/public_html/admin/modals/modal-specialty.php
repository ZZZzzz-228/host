<!-- ═══ MODAL: SPECIALTY ═══ -->
<div class="mo" id="mSpec"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mSpecT">Специальность</div><button class="mc" onclick="cm('mSpec')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="spId">
    <div class="fg">
      <div class="fr"><label>Код *</label><input class="fc" id="spCode" placeholder="09.02.07"></div>
      <div class="fr"><label>Название *</label><input class="fc" id="spTit"></div>
      <div class="fr"><label>Короткое название</label><input class="fc" id="spShort"></div>
      <div class="fr"><label>Форма обучения</label><input class="fc" id="spForm" placeholder="Очная"></div>
      <div class="fr"><label>Длительность</label><input class="fc" id="spDur" placeholder="3 г. 10 мес."></div>
      <div class="fr"><label>Квалификация</label><input class="fc" id="spQual"></div>
      <div class="fr"><label>Зарплата</label><input class="fc" id="spSal" placeholder="от 40 000 ₽"></div>
      <div class="fr"><label>Цвет</label><input type="color" class="fc" id="spCol" value="#1565C0" style="height:36px;padding:3px"></div>
      <!-- Изображение специальности с кроппером -->
      <div class="fr">
        <label>Изображение</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="spImg" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('spImg',{title:'Изображение специальности',ratio:4/3})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <!-- Ссылка на Госуслуги -->
      <div class="fr">
        <label>Ссылка на Госуслуги</label>
        <input class="fc" id="spGos" placeholder="https://www.gosuslugi.ru/sponavigator/...">
      </div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="spOrd" value="0"></div>
    </div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="spDesc"></textarea></div>
    <div class="fr"><label>Карьера</label><textarea class="ft" id="spCar"></textarea></div>
    <div class="fr"><label>Навыки</label><textarea class="ft" id="spSkl"></textarea></div>
    <div class="fchk"><input type="checkbox" id="spPub" checked><label for="spPub">Опубликовано</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mSpec')">Отмена</button>
    <button class="btn btn-primary" onclick="saveSpec()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>