<!-- ═══ MODAL: STAFF ═══ -->
<div class="mo" id="mStaff"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mStaffT">Сотрудник</div><button class="mc" onclick="cm('mStaff')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="sfId">
    <div class="fg">
      <div class="fr"><label>ФИО *</label><input class="fc" id="sfNm"></div>
      <div class="fr"><label>Должность</label><input class="fc" id="sfPos"></div>
      <div class="fr"><label>Email</label><input type="email" class="fc" id="sfEm"></div>
      <div class="fr"><label>Телефон</label><input class="fc" id="sfPh"></div>
      <div class="fr"><label>Отдел</label>
        <select class="fs" id="sfDep">
          <option value="college">Колледж</option>
          <option value="career_center">Карьерный центр</option>
          <option value="other">Другое</option>
        </select>
      </div>
      <!-- Фото с кроппером -->
      <div class="fr">
        <label>Фото</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="sfPht" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('sfPht',{title:'Фото сотрудника',ratio:3/4})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>Цвет</label><input type="color" class="fc" id="sfCol" value="#1565C0" style="height:36px;padding:3px"></div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="sfOrd" value="0"></div>
    </div>
    <div class="fr"><label>График приёма</label><input class="fc" id="sfOH" placeholder="Пн-Пт 9:00-17:00"></div>
    <div class="fr"><label>Биография</label><textarea class="ft" id="sfBio" style="min-height:70px"></textarea></div>
    <div class="fchk"><input type="checkbox" id="sfPub" checked><label for="sfPub">Опубликован</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mStaff')">Отмена</button>
    <button class="btn btn-primary" onclick="saveStaff()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
