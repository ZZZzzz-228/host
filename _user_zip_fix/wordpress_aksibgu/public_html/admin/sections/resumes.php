<!-- ═══ RESUMES ═══ -->
<!-- Путь на хостинге: public_html/admin/sections/resumes.php -->
<section class="sec" id="s-resumes">
  <div class="card">
    <div class="card-hd">
      <div class="card-title"><i class="fas fa-id-card" style="color:var(--acc)"></i> Резюме студентов</div>
    </div>
    <!-- Фильтры -->
    <div style="display:flex;gap:10px;align-items:center;padding:12px 16px;border-bottom:1px solid rgba(255,255,255,.06);flex-wrap:wrap">
      <input class="fc" id="rvSearch" placeholder="Поиск по ФИО, должности, email…" style="max-width:300px"
             oninput="clearTimeout(window._rvST);window._rvST=setTimeout(()=>loadResumes(),400)">
      <select class="fc" id="rvPub" style="width:180px" onchange="loadResumes()">
        <option value="">Все статусы</option>
        <option value="1">Опубликованные</option>
        <option value="0">Черновики</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead>
          <tr>
            <th>ID</th>
            <th>Студент (ФИО)</th>
            <th>Желаемая должность</th>
            <th>Специальность</th>
            <th>Город</th>
            <th>Зарплата</th>
            <th>Статус</th>
            <th>Дата</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody id="rvTb">
          <tr><td colspan="9"><div class="ldo"><div class="spin"></div></div></td></tr>
        </tbody>
      </table>
    </div>
    <div id="rvPgn" style="padding:10px 16px;display:flex;gap:6px;justify-content:center"></div>
  </div>
</section>
