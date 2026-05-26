<!-- ═══ STUDENTS ═══ -->
<section class="sec" id="s-students">
  <div class="card">
    <div class="card-hd"><div class="card-title"><i class="fas fa-user-graduate" style="color:var(--success)"></i> Студенты</div></div>
    <div class="fbar">
      <div class="sw-wrap"><i class="fas fa-search si"></i><input class="fc" id="stuSrch" placeholder="ФИО, email..." oninput="loadStudents()"></div>
    </div>
    <div class="tw">
      <table class="tbl">
        <thead><tr><th>ID</th><th>ФИО</th><th>Email</th><th>Группа</th><th>Статус</th><th>Дата</th><th></th></tr></thead>
        <tbody id="suTb"><tr><td colspan="7"><div class="ldo"><div class="spin"></div></div></td></tr></tbody>
      </table>
    </div>
    <div class="pgn" id="suPgn"></div>
  </div>
</section>
