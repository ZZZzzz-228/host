<!-- ═══ DASHBOARD ═══ -->
<section class="sec active" id="s-dashboard">

  <!-- KPI-плитки -->
  <div class="stats-grid" id="statsGrid"><div class="ldo"><div class="spin"></div></div></div>

  <!-- Алерт-баннер (заявки, ВК) -->
  <div id="dashAlerts"></div>

  <!-- Быстрый доступ -->
  <div class="qa-grid">
    <div class="qa-card" onclick="go('news',qn('news'))"><i class="fas fa-plus-circle" style="color:var(--acc)"></i><span>Добавить новость</span></div>
    <div class="qa-card" onclick="go('apps',qn('apps'))"><i class="fas fa-inbox" style="color:var(--warn)"></i><span>Заявки</span></div>
    <div class="qa-card" onclick="go('vk',qn('vk'))"><i class="fab fa-vk" style="color:#4c75a3"></i><span>ВК-очередь</span></div>
    <div class="qa-card" onclick="go('vacancies',qn('vacancies'))"><i class="fas fa-briefcase" style="color:var(--success)"></i><span>Вакансии</span></div>
    <div class="qa-card" onclick="go('settings',qn('settings'))"><i class="fas fa-cog" style="color:var(--info)"></i><span>Настройки</span></div>
    <div class="qa-card" onclick="go('stories',qn('stories'))"><i class="fas fa-images" style="color:#e91e63"></i><span>Истории</span></div>
  </div>

  <!-- Строка 1: Линейная диаграмма активности + Donut заявки -->
  <div class="dash-row">
    <!-- Диаграмма: активность публикаций -->
    <div class="card dash-chart-main">
      <div class="card-hd">
        <div>
          <div class="card-title">Публикационная активность</div>
          <div class="card-sub">Новости за период</div>
        </div>
        <div style="display:flex;gap:6px">
          <button class="btn btn-sec btn-sm dash-period-btn" onclick="dashSetPeriod(3,this)">3 мес</button>
          <button class="btn btn-sec btn-sm dash-period-btn" onclick="dashSetPeriod(6,this)">6 мес</button>
          <button class="btn btn-sec btn-sm dash-period-btn active" onclick="dashSetPeriod(12,this)">12 мес</button>
        </div>
      </div>
      <div class="dash-chart-wrap">
        <canvas id="chartActivity"></canvas>
      </div>
    </div>

    <!-- Diag: заявки по статусам -->
    <div class="card dash-chart-side">
      <div class="card-hd">
        <div class="card-title">Заявки по статусам</div>
      </div>
      <div class="dash-donut-wrap">
        <canvas id="chartApps"></canvas>
      </div>
      <div class="dash-legend" id="dashAppsLegend"></div>
    </div>
  </div>

  <!-- Строка 2: Donut контент + Горизонтальный бар образование -->
  <div class="dash-row">
    <!-- Donut: контент -->
    <div class="card dash-chart-side">
      <div class="card-hd">
        <div class="card-title">Контент сайта</div>
      </div>
      <div class="dash-donut-wrap">
        <canvas id="chartContent"></canvas>
      </div>
      <div class="dash-legend" id="dashContentLegend"></div>
    </div>

    <!-- Бар: образовательная структура -->
    <div class="card dash-chart-main">
      <div class="card-hd">
        <div class="card-title">Образовательная структура</div>
      </div>
      <div class="dash-chart-wrap">
        <canvas id="chartEdu"></canvas>
      </div>
    </div>
  </div>

  <!-- Строка 3: Последние заявки + Лента активности -->
  <div class="dash-row">
    <!-- Последние заявки -->
    <div class="card dash-chart-main">
      <div class="card-hd">
        <div>
          <div class="card-title">Последние заявки</div>
          <div class="card-sub">Новые необработанные</div>
        </div>
        <button class="btn btn-sec btn-sm" onclick="go('apps',qn('apps'))">Все →</button>
      </div>
      <div id="dashApps"><div class="ldo"><div class="spin"></div></div></div>
    </div>

    <!-- Лента активности -->
    <div class="card dash-activity">
      <div class="card-hd">
        <div class="card-title">Лента активности</div>
      </div>
      <div id="dashLogs"><div class="ldo"><div class="spin"></div></div></div>
    </div>
  </div>

  <!-- Последние новости -->
  <div class="card">
    <div class="card-hd">
      <div class="card-title">Последние новости</div>
      <button class="btn btn-sec btn-sm" onclick="go('news',qn('news'))">Все →</button>
    </div>
    <div id="dashNews"><div class="ldo"><div class="spin"></div></div></div>
  </div>

</section>
