<!-- ═══ STAFF ═══ -->
<section class="sec" id="s-staff">
  <div class="card">
    <div class="card-hd">
      <div class="card-title"><i class="fas fa-chalkboard-teacher" style="color:var(--warn)"></i> Сотрудники</div>
      <button class="btn btn-primary" onclick="openStaff()"><i class="fas fa-plus"></i>Добавить</button>
    </div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="stfSrch" placeholder="ФИО, должность..." oninput="loadStaff()"></div>
      <select class="fs" id="stfDep" onchange="loadStaff()" style="max-width:180px">
        <option value="">Все отделы</option>
        <option value="college">Колледж</option>
        <option value="career_center">Карьерный центр</option>
      </select>
      <div style="margin-left:auto;color:var(--tx2);font-size:12px;display:flex;align-items:center;gap:6px">
        <i class="fas fa-grip-vertical"></i>
        Перетащите строки за иконку слева, чтобы изменить порядок отображения в приложении
      </div>
    </div>
    <div class="tw">
      <table class="tbl" id="staffTable">
        <thead>
          <tr>
            <th style="width:38px"></th>
            <th>ID</th>
            <th>Фото</th>
            <th>ФИО</th>
            <th>Должность</th>
            <th>Отдел</th>
            <th>Статус</th>
            <th>Порядок</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody id="sfTb"><tr><td colspan="9"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
  </div>
</section>

<!-- SortableJS подключаем один раз на странице (если уже подключён выше — этот тег браузер проигнорирует за счёт идентичного src) -->
<script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js"></script>

<style>
  /* Подсветка для drag-and-drop сотрудников */
  #sfTb .drag-handle{cursor:grab;color:var(--tx3);padding:0 6px;font-size:14px;user-select:none}
  #sfTb .drag-handle:active{cursor:grabbing}
  #sfTb tr.sortable-ghost{opacity:.35;background:var(--bg2)}
  #sfTb tr.sortable-chosen{background:rgba(21,101,192,.05)}
  #sfTb tr.sortable-drag{box-shadow:0 6px 18px rgba(0,0,0,.18)}
</style>
