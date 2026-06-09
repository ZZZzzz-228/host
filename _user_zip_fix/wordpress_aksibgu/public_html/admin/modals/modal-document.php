<!-- ═══ MODAL: DOCUMENT ═══ -->
<div class="mo" id="mDoc"><div class="modal">
  <div class="mh"><div class="mt" id="mDocT">Документ</div><button class="mc" onclick="cm('mDoc')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="doId">
    <div class="fr"><label>Название *</label><input class="fc" id="doTit"></div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="doDesc" style="min-height:70px"></textarea></div>
    <div class="fg">
      <div class="fr"><label>URL файла *</label><input class="fc" id="doUrl"></div>
      <div class="fr"><label>Категория</label><input class="fc" id="doCat" placeholder="Устав, Лицензии..."></div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="doOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="doPub" checked><label for="doPub">Опубликован</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mDoc')">Отмена</button>
    <button class="btn btn-primary" onclick="saveDoc()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
