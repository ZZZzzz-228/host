<!-- ═══════════════ SIDEBAR ═══════════════ -->
<aside class="sidebar" id="sb">
  <div class="sb-logo">
<div class="sb-logo-icon" style="background:transparent;width:72px;height:72px">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 550 550" preserveAspectRatio="xMidYMid meet" width="72" height="72">
    <g transform="translate(0,550) scale(0.1,-0.1)" fill="#4F7BC1" stroke="none">
      <path d="M2667 4674 c-4 -4 -7 -76 -7 -160 0 -84 -3 -155 -7 -157 -5 -3 -60 -12 -123 -21 -201 -29 -381 -86 -561 -176 -82 -42 -254 -160 -323 -221 l-59 -53 -86 92 c-47 51 -92 92 -99 92 -18 0 -112 -82 -112 -97 0 -7 39 -53 88 -104 48 -50 88 -95 90 -100 2 -5 -18 -37 -45 -71 -78 -102 -169 -261 -214 -376 -62 -158 -92 -290 -112 -492 l-2 -25 -170 -5 -170 -5 0 -75 0 -75 171 -3 171 -2 7 -73 c28 -291 156 -594 353 -841 l56 -68 -112 -112 c-61 -61 -111 -116 -111 -122 0 -12 94 -104 106 -104 4 0 58 50 119 111 l113 110 110 -83 c183 -139 423 -250 642 -298 72 -15 186 -32 290 -43 l25 -2 5 -145 5 -145 225 0 225 0 0 75 0 75 -147 3 -148 3 0 68 0 68 98 12 c309 40 583 148 815 322 58 43 109 79 112 79 4 0 48 -38 97 -85 50 -47 96 -85 102 -85 14 0 106 92 106 105 0 6 -43 50 -95 98 l-94 88 66 82 c199 246 306 497 348 816 19 137 19 233 0 374 -51 387 -211 700 -497 971 -264 252 -606 409 -976 447 l-122 13 -2 161 -3 160 -70 3 c-39 1 -74 0 -78 -4z"/>
    </g>
  </svg>
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
    <div class="nav-item" onclick="go('universities',this)"><span class="ni"><i class="fas fa-university"></i></span>Университеты</div>
    <div class="nav-item" onclick="go('partners',this)"><span class="ni"><i class="fas fa-handshake"></i></span>Партнёры</div>
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
