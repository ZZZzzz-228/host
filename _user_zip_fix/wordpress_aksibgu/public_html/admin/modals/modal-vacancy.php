<!-- ═══ MODAL: VACANCY ═══ -->
<div class="mo" id="mVac"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mVacT">Вакансия</div><button class="mc" onclick="cm('mVac')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="vcId">
    <div class="fg">
      <div class="fr"><label>Должность *</label><input class="fc" id="vcTit"></div>
      <div class="fr"><label>Компания</label><input class="fc" id="vcCom"></div>
      <div class="fr"><label>Город</label><input class="fc" id="vcCit"></div>
      <div class="fr"><label>Тип занятости</label><input class="fc" id="vcEmp" placeholder="Полная, Стажировка..."></div>
      <div class="fr"><label>Зарплата</label><input class="fc" id="vcSal" placeholder="от 35 000 ₽"></div>
      <div class="fr"><label>Истекает</label><input type="date" class="fc" id="vcExp"></div>
    </div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="vcDesc" style="min-height:110px"></textarea></div>
    <div class="fr"><label>Требования</label><textarea class="ft" id="vcReq"></textarea></div>
    <div class="fr"><label>Контакт</label><input class="fc" id="vcCon"></div>
    <div class="fchk"><input type="checkbox" id="vcAct" checked><label for="vcAct">Активна</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mVac')">Отмена</button>
    <button class="btn btn-primary" onclick="saveVac()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
