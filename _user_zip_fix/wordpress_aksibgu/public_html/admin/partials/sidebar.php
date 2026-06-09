<!-- ═══════════════ SIDEBAR ═══════════════ -->
<aside class="sidebar" id="sb">
  <div class="sb-logo">
<div class="sb-logo-icon" style="background:transparent;width:72px;height:72px">
  <img src="/admin/favicon.svg" width="72" height="72" alt="logo">
</div>  
    <div class="sb-logo-txt">АКСИБГУУ<div class="sb-logo-sub">Панель управления</div></div>
  </div>

  <nav class="sb-nav">
    <div class="nav-sec">Главная</div>
    <div class="nav-item active" onclick="go('dashboard',this)"><span class="ni"><i class="fas fa-tachometer-alt"></i></span>Дашборд</div>

    <div class="nav-sec">Контент</div>
    <div class="nav-item" onclick="go('news',this)"><span class="ni"><i class="fas fa-newspaper"></i></span>Новости</div>
    <div class="nav-item" onclick="go('stories',this)"><span class="ni"><i class="fas fa-images"></i></span>Истории</div>
    <div class="nav-item" onclick="go('vk',this)"><span class="ni"><i class="fab fa-vk"></i></span>ВК-очередь<span class="nav-badge" id="vkB" style="display:none">0</span></div>
    <div class="nav-item" onclick="go('about-college',this)"><span class="ni"><i class="fas fa-university"></i></span>О колледже</div>
    <div class="nav-item" onclick="go('contacts',this)"><span class="ni"><i class="fas fa-address-book"></i></span>Контакты</div>

    <div class="nav-sec">Абитуриенты</div>
    <div class="nav-item" onclick="go('apps',this)"><span class="ni"><i class="fas fa-inbox"></i></span>Заявки<span class="nav-badge" id="apB" style="display:none">0</span></div>
    <div class="nav-item" onclick="go('specs',this)"><span class="ni"><i class="fas fa-graduation-cap"></i></span>Специальности</div>
    <div class="nav-item" onclick="go('eduprog',this)"><span class="ni"><i class="fas fa-book-open"></i></span>Доп. программы</div>

    <div class="nav-sec">Учебная структура</div>
    <div class="nav-item" onclick="go('depts',this)"><span class="ni"><i class="fas fa-building"></i></span>Отделения</div>
    <div class="nav-item" onclick="go('groups',this)"><span class="ni"><i class="fas fa-users"></i></span>Группы</div>
    <div class="nav-item" onclick="go('disciplines',this)"><span class="ni"><i class="fas fa-book"></i></span>Дисциплины</div>
    <div class="nav-item" onclick="go('schedule',this)"><span class="ni"><i class="fas fa-calendar-alt"></i></span>Расписание</div>
    <div class="nav-item" onclick="go('staff',this)"><span class="ni"><i class="fas fa-chalkboard-teacher"></i></span>Сотрудники</div>

    <div class="nav-sec">Студенты</div>
    <div class="nav-item" onclick="go('students',this)"><span class="ni"><i class="fas fa-user-graduate"></i></span>Студенты</div>
    <div class="nav-item" onclick="go('resumes',this)"><span class="ni"><i class="fas fa-id-card"></i></span>Резюме</div>
    <div class="nav-item" onclick="go('portfolio',this)"><span class="ni"><i class="fas fa-briefcase"></i></span>Портфолио</div>

    <div class="nav-sec">Карьерный центр</div>
    <div class="nav-item" onclick="go('vacancies',this)"><span class="ni"><i class="fas fa-briefcase"></i></span>Вакансии</div>
    <div class="nav-item" onclick="go('cevents',this)"><span class="ni"><i class="fas fa-calendar-check"></i></span>Мероприятия</div>
    <div class="nav-item" onclick="go('universities',this);if(typeof loadUniversities==='function')loadUniversities();"><span class="ni"><i class="fas fa-university"></i></span>Университеты</div>
    <div class="nav-item" onclick="go('partners',this)"><span class="ni"><i class="fas fa-handshake"></i></span>Партнёры</div>
    <div class="nav-item" onclick="go('career-contacts',this)"><span class="ni"><i class="fas fa-id-card"></i></span>Контакты Центр карьеры</div>
    <div class="nav-item" onclick="go('career-test',this)"><span class="ni"><i class="fas fa-clipboard-list"></i></span>Тесты (профориентация)</div>

    <div class="nav-sec">Прочее</div>
    <div class="nav-item" onclick="go('docs',this)"><span class="ni"><i class="fas fa-folder-open"></i></span>Документы</div>
    <div class="nav-item" onclick="go('admins',this)"><span class="ni"><i class="fas fa-shield-alt"></i></span>Администраторы</div>
    <div class="nav-item" onclick="go('settings',this)"><span class="ni"><i class="fas fa-cog"></i></span>Настройки</div>
    <div class="nav-item" onclick="go('logs',this)"><span class="ni"><i class="fas fa-list-alt"></i></span>Журнал</div>
  </nav>

  <div class="sb-foot">
    <div class="sb-user">
      <div class="sb-av" id="sbAv">A</div>
      <div>
        <div class="sb-uname" id="sbName"><?= htmlspecialchars($_SESSION['admin_name'] ?? 'Admin') ?></div>
        <div class="sb-urole"><?= htmlspecialchars($_SESSION['admin_role'] ?? '') ?></div>
      </div>
    </div>
    <button class="btn-logout" onclick="doLogout()"><i class="fas fa-sign-out-alt"></i>Выйти</button>
  </div>
</aside>