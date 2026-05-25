<!-- ═══ MODAL: GROUP ═══ -->
<div class="mo" id="mGroup"><div class="modal">
  <div class="mh"><div class="mt" id="mGroupT">Учебная группа</div><button class="mc" onclick="cm('mGroup')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="grId">
    <div class="fg">
      <div class="fr"><label>Название *</label><input class="fc" id="grNm" placeholder="ИС-21"></div>
      <div class="fr"><label>Курс</label><input type="number" class="fc" id="grCr" min="1" max="5"></div>
      <div class="fr"><label>Специальность</label><input class="fc" id="grSp" placeholder="09.02.07"></div>
      <div class="fr"><label>Учебный год</label><input class="fc" id="grYr" placeholder="2024-2025"></div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="grOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="grAct" checked><label for="grAct">Активна</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mGroup')">Отмена</button>
    <button class="btn btn-primary" onclick="saveGroup()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
