<!-- ═══ STAFF ═══ -->
<section class="sec" id="s-staff">
  <div class="card">
    <div class="card-hd"><div class="card-title"><i class="fas fa-chalkboard-teacher" style="color:var(--warn)"></i> Сотрудники</div>
    <button class="btn btn-primary" onclick="openStaff()"><i class="fas fa-plus"></i>Добавить</button></div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="stfSrch" placeholder="ФИО, должность..." oninput="loadStaff()"></div>
      <select class="fs" id="stfDep" onchange="loadStaff()" style="max-width:180px">
        <option value="">Все отделы</option>
        <option value="college">Колледж</option>
        <option value="career_center">Карьерный центр</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr><th>ID</th><th>Фото</th><th>ФИО</th><th>Должность</th><th>Отдел</th><th>Статус</th><th>Действия</th></tr></thead>
        <tbody id="sfTb"><tr><td colspan="7"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
  </div>
</section>
