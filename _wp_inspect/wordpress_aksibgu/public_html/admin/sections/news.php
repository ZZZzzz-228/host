<!-- ═══ NEWS ═══ -->
<section class="sec" id="s-news">
  <div class="card">
    <div class="card-hd"><div class="card-title"><i class="fas fa-newspaper" style="color:var(--acc)"></i> Новости</div>
    <button class="btn btn-primary" onclick="openNews()"><i class="fas fa-plus"></i>Добавить</button></div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="nSrch" placeholder="Поиск..." oninput="loadNews()"></div>
      <select class="fs" id="nSt" onchange="loadNews()" style="max-width:170px">
        <option value="">Все статусы</option>
        <option value="1">Опубликованные</option>
        <option value="0">Скрытые</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr><th>ID</th><th>Фото</th><th>Заголовок</th><th>Статус</th><th>Закр.</th><th>Дата</th><th>Действия</th></tr></thead>
        <tbody id="nTb"><tr><td colspan="7"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
    <div class="pgn" id="nPgn"></div>
  </div>
</section>
