<!-- ═══ APPLICATIONS ═══ -->
<section class="sec" id="s-apps">
  <div class="card">
    <div class="card-hd">
      <div>
        <div class="card-title"><i class="fas fa-inbox" style="color:var(--warn)"></i> Заявки</div>
        <div class="card-sub" id="apTotal"></div>
      </div>
      <button class="btn btn-success btn-sm" onclick="exportApps()"><i class="fas fa-download"></i>CSV</button>
    </div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="apSrch" placeholder="ФИО, email, телефон..."></div>
      <select class="fs" id="apSt" onchange="loadApps()" style="max-width:155px">
        <option value="">Все</option>
        <option value="new">Новые</option>
        <option value="processing">В работе</option>
        <option value="approved">Принятые</option>
        <option value="rejected">Отклонённые</option>
        <option value="archived">Архив</option>
      </select>
      <select class="fs" id="apTp" onchange="loadApps()" style="max-width:140px">
        <option value="">Все типы</option>
        <option value="documents">Документы</option>
        <option value="courses">Курсы</option>
      </select>
      <input type="date" class="fc" id="apDf" onchange="loadApps()" style="max-width:150px">
      <input type="date" class="fc" id="apDt" onchange="loadApps()" style="max-width:150px">
      <button class="btn btn-sec btn-sm" onclick="loadApps()"><i class="fas fa-search"></i></button>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr>
          <th><input type="checkbox" id="apAll" onchange="togAllApps(this)"></th>
          <th>ID</th><th>Дата</th><th>ФИО</th><th>Email</th><th>Телефон</th><th>Статус</th><th>Тип</th><th>Действия</th>
        </tr></thead>
        <tbody id="apTb"><tr><td colspan="9"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
    <div style="display:flex;align-items:center;gap:10px;margin-top:10px;flex-wrap:wrap">
      <button class="btn btn-warn btn-sm" onclick="bulkApps()"><i class="fas fa-play"></i>Выбранные → В работу</button>
      <div class="pgn" id="apPgn"></div>
    </div>
  </div>
</section>