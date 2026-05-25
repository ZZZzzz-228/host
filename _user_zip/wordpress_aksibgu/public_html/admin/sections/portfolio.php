<!-- ═══ PORTFOLIO ═══ -->
<!-- Путь на хостинге: public_html/admin/sections/portfolio.php -->
<section class="sec" id="s-portfolio">
  <div class="card">
    <div class="card-hd">
      <div class="card-title"><i class="fas fa-briefcase" style="color:var(--info)"></i> Портфолио студентов</div>
    </div>
    <!-- Фильтры -->
    <div style="display:flex;gap:10px;align-items:center;padding:12px 16px;border-bottom:1px solid rgba(255,255,255,.06);flex-wrap:wrap">
      <input class="fc" id="pfSearch" placeholder="Поиск по студенту, названию…" style="max-width:280px"
             oninput="clearTimeout(window._pfST);window._pfST=setTimeout(()=>loadPortfolio(),400)">
      <select class="fc" id="pfPub" style="width:160px" onchange="loadPortfolio()">
        <option value="">Все статусы</option>
        <option value="1">Опубликованные</option>
        <option value="0">Неопубликованные</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead>
          <tr>
            <th>ID</th>
            <th>Студент</th>
            <th>Название проекта</th>
            <th>Категория</th>
            <th>Ссылка</th>
            <th>Опубликовано</th>
            <th>Дата</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody id="pfTb">
          <tr><td colspan="8"><div class="ldo"><div class="spin"></div></div></td></tr>
        </tbody>
      </table>
    </div>
    <div id="pfPgn" style="padding:10px 16px;display:flex;gap:6px;justify-content:center"></div>
  </div>
</section>
