<!-- ═══ MODAL: DEPARTMENT ═══ -->
<div class="mo" id="mDept"><div class="modal">
  <div class="mh"><div class="mt" id="mDeptT">Отделение</div><button class="mc" onclick="cm('mDept')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="dpId">
    <div class="fr"><label>Название *</label><input class="fc" id="dpNm"></div>
    <div class="fg">
      <div class="fr"><label>Код</label><input class="fc" id="dpCd"></div>
      <div class="fr"><label>Руководитель</label><input class="fc" id="dpHd"></div>
      <div class="fr"><label>Телефон</label><input class="fc" id="dpPh"></div>
      <div class="fr"><label>Email</label><input type="email" class="fc" id="dpEm"></div>
      <div class="fr"><label>Аудитория</label><input class="fc" id="dpRm"></div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="dpOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="dpAct" checked><label for="dpAct">Активно</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mDept')">Отмена</button>
    <button class="btn btn-primary" onclick="saveDept()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
