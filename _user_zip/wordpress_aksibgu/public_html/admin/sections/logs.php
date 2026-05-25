<!-- ═══ LOGS ═══ -->
<section class="sec" id="s-logs">
  <div class="card">
    <div class="card-hd"><div class="card-title"><i class="fas fa-list-alt" style="color:var(--txt3)"></i> Журнал действий</div>
    <button class="btn btn-sec btn-sm" onclick="loadLogs()"><i class="fas fa-sync"></i>Обновить</button></div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="lgSrch" placeholder="Поиск..." oninput="loadLogs()"></div>
      <select class="fs" id="lgAct" onchange="loadLogs()" style="max-width:155px">
        <option value="">Все действия</option>
        <option value="create">Создание</option>
        <option value="update">Обновление</option>
        <option value="delete">Удаление</option>
        <option value="login">Вход</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr><th>ID</th><th>Время</th><th>Администратор</th><th>Действие</th><th>Объект</th><th>ID объекта</th><th>Сообщение</th><th>IP</th></tr></thead>
        <tbody id="lgTb"><tr><td colspan="8"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
    <div class="pgn" id="lgPgn"></div>
  </div>
</section>