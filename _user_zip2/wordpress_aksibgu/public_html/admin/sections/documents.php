<!-- ═══ DOCUMENTS ═══ -->
<section class="sec" id="s-docs">
  <div class="card">
    <div class="card-hd"><div class="card-title"><i class="fas fa-folder-open" style="color:var(--warn)"></i> Документы</div>
    <button class="btn btn-primary" onclick="openDoc()"><i class="fas fa-plus"></i>Добавить</button></div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="docSrch" placeholder="Поиск..." oninput="loadDocs()"></div>
      <input class="fc" id="docCat" placeholder="Категория" oninput="loadDocs()" style="max-width:170px">
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr><th>ID</th><th>Название</th><th>Категория</th><th>Файл</th><th>Статус</th><th>Дата</th><th>Действия</th></tr></thead>
        <tbody id="doTb"><tr><td colspan="7"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
  </div>
</section>
