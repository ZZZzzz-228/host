<!-- ═══ MODAL: DISCIPLINE ═══ -->
<div class="mo" id="mDisc"><div class="modal">
  <div class="mh"><div class="mt" id="mDiscT">Дисциплина</div><button class="mc" onclick="cm('mDisc')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="dcId">
    <div class="fg">
      <div class="fr"><label>Название *</label><input class="fc" id="dcNm"></div>
      <div class="fr"><label>Код</label><input class="fc" id="dcCd"></div>
    </div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="dcDesc" style="min-height:70px"></textarea></div>
    <div class="fchk"><input type="checkbox" id="dcAct" checked><label for="dcAct">Активна</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mDisc')">Отмена</button>
    <button class="btn btn-primary" onclick="saveDisc()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
