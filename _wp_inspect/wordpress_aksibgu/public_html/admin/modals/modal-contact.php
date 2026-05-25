<!-- ═══ MODAL: CONTACT ═══ -->
<div class="mo" id="mContact"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mContactT">Добавить контакт</div><button class="mc" onclick="cm('mContact')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="ctId">
    <div class="fg">
      <div class="fr"><label>Категория *</label>
        <select class="fs" id="ctCatM">
          <option value="college">Колледж</option>
          <option value="career_center">Карьерный центр</option>
        </select>
      </div>
      <div class="fr"><label>Подпись / Отдел</label><input class="fc" id="ctLbl" placeholder="Приёмная комиссия"></div>
      <div class="fr"><label>ФИО</label><input class="fc" id="ctName" placeholder="Иванов Иван Иванович"></div>
      <div class="fr"><label>Должность</label><input class="fc" id="ctPos" placeholder="Руководитель"></div>
      <div class="fr"><label>Телефон</label><input class="fc" id="ctPhone" placeholder="+7 (800) 000-00-00"></div>
      <div class="fr"><label>Email</label><input type="email" class="fc" id="ctEmail" placeholder="info@example.ru"></div>
      <div class="fr"><label>Адрес</label><input class="fc" id="ctAddress" placeholder="ул. Ленина, 1"></div>
      <div class="fr"><label>Кабинет №</label><input class="fc" id="ctRoom" placeholder="101"></div>
      <div class="fr"><label>График работы</label><input class="fc" id="ctSched" placeholder="Пн–Пт 9:00–17:00"></div>
      <div class="fr"><label>ВКонтакте (URL)</label><input class="fc" id="ctVk" placeholder="https://vk.com/..."></div>
      <!-- Фото с кроппером -->
      <div class="fr">
        <label>Фото</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="ctPhoto" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('ctPhoto',{title:'Фото контакта',ratio:1})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="ctOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="ctAct" checked><label for="ctAct">Активен</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mContact')">Отмена</button>
    <button class="btn btn-primary" onclick="saveContact()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
