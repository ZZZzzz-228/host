<!-- ═══ MODAL: CMS PAGE ═══ -->
<div class="mo" id="mPage"><div class="modal mlg">
  <div class="mh"><div class="mt" id="mPageT">Добавить страницу</div><button class="mc" onclick="cm('mPage')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="pgId">
    <div class="fg">
      <div class="fr"><label>Slug *</label><input class="fc" id="pgSlug" placeholder="about, contacts..."></div>
      <div class="fr"><label>Заголовок *</label><input class="fc" id="pgTit"></div>
    </div>
    <div class="fr"><label>Содержание (HTML)</label><textarea class="ft" id="pgCnt" style="min-height:180px"></textarea></div>
    <div class="fr"><label>SEO описание</label><input class="fc" id="pgMeta"></div>
    <div class="fchk"><input type="checkbox" id="pgPub" checked><label for="pgPub">Опубликовано</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mPage')">Отмена</button>
    <button class="btn btn-primary" onclick="savePage()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
