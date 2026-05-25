<!-- ═══ UNIVERSITIES ═══ -->
<!-- Путь на хостинге: public_html/admin/sections/universities.php -->
<section class="sec" id="s-universities">
  <div class="card">
    <div class="card-hd">
      <div class="card-title"><i class="fas fa-university" style="color:var(--acc)"></i> Университеты / ВУЗы</div>
      <button class="btn btn-primary" onclick="openUniversity()"><i class="fas fa-plus"></i>Добавить</button>
    </div>
    <!-- Фильтры -->
    <div style="display:flex;gap:10px;align-items:center;padding:12px 16px;border-bottom:1px solid rgba(255,255,255,.06)">
      <input class="fc" id="uniSearch" placeholder="Поиск по названию, городу…" style="max-width:320px"
             oninput="clearTimeout(window._uniST);window._uniST=setTimeout(()=>loadUniversities(),400)">
      <select class="fc" id="uniActive" style="width:160px" onchange="loadUniversities()">
        <option value="">Все</option>
        <option value="1">Активные</option>
        <option value="0">Неактивные</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead>
          <tr>
            <th>ID</th>
            <th>Логотип</th>
            <th>Название</th>
            <th>Краткое</th>
            <th>Город</th>
            <th>Сайт</th>
            <th>Статус</th>
            <th>Порядок</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody id="uniTb">
          <tr><td colspan="9"><div class="ldo"><div class="spin"></div></div></td></tr>
        </tbody>
      </table>
    </div>
    <div id="uniPgn" style="padding:10px 16px;display:flex;gap:6px;justify-content:center"></div>
  </div>
</section>
