<!-- ═══ CONTACTS ═══ -->
<section class="sec" id="s-contacts">
  <div class="card">
    <div class="card-hd"><div class="card-title"><i class="fas fa-address-book" style="color:var(--success)"></i> Контакты</div>
    <button class="btn btn-primary" onclick="openContact()"><i class="fas fa-plus"></i>Добавить</button></div>
    <div class="fbar">
      <select class="fs" id="ctCat" onchange="loadContacts()" style="max-width:200px">
        <option value="">Все категории</option>
        <option value="college">Колледж</option>
        <option value="career_center">Карьерный центр</option>
      </select>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr><th>ID</th><th>Фото</th><th>Подпись / ФИО</th><th>Должность</th><th>Телефон</th><th>Email</th><th>Категория</th><th>Статус</th><th>Действия</th></tr></thead>
        <tbody id="ctTb"><tr><td colspan="8"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
  </div>
</section>
