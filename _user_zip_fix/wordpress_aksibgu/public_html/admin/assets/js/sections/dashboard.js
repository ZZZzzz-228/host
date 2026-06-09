/* ── DASHBOARD ─────────────────────────────────────────────────────────── */

// Хелпер: находит nav-item по id раздела
function qn(id) { return document.querySelector(`.nav-item[onclick*="go('${id}'"]`); }

// Глобальные инстансы Chart.js
let _chartActivity = null;
let _chartApps     = null;
let _chartContent  = null;
let _chartEdu      = null;

// Глобальный кэш данных для переключения периода
let _dashData = null;

/* ═══════════════════════════════════════════════════════════════════
   ГЛАВНАЯ ФУНКЦИЯ ЗАГРУЗКИ
═══════════════════════════════════════════════════════════════════ */
async function loadDash() {
    // Сброс спиннеров
    $('statsGrid').innerHTML = '<div class="ldo"><div class="spin"></div></div>';

    const r = await api('GET', 'api/stats.php');
    if (!r || !r.success) {
        $('statsGrid').innerHTML = '<div class="ldo" style="color:var(--danger)"><i class="fas fa-exclamation-circle"></i> Ошибка загрузки статистики</div>';
        return;
    }

    _dashData = r;
    const s = r.data;

    // ── 1. KPI-плитки ─────────────────────────────────────────────
    renderKPI(s);

    // ── 2. Алерт-баннер ───────────────────────────────────────────
    renderAlerts(s);

    // ── 3. Параллельная загрузка таблиц ───────────────────────────
    loadDashTables(r);

    // ── 4. Диаграммы ──────────────────────────────────────────────
    renderChartActivity(r.chart_news || [], 12);
    renderChartApps(r.chart_apps || []);
    renderChartContent(s);
    renderChartEdu(s);

    // ── 5. Навбадж ────────────────────────────────────────────────
    if (s.vk_pending > 0) { $('vkB').textContent = s.vk_pending; $('vkB').style.display = ''; }
    if (s.apps_new   > 0) { $('apB').textContent = s.apps_new;   $('apB').style.display = ''; }
}

/* ═══════════════════════════════════════════════════════════════════
   KPI-ПЛИТКИ
═══════════════════════════════════════════════════════════════════ */
function renderKPI(s) {
    const cards = [
        { i:'fa-newspaper',     c:'ic-blue',   v: s.news_total||0,       l:'Новостей',        sub: `${s.news_published||0} опубл.`,   sec:'news'       },
        { i:'fa-inbox',         c:'ic-orange', v: s.apps_new||0,         l:'Новых заявок',    sub: `${s.apps_total||0} всего`,        sec:'apps'       },
        { i:'fa-images',        c:'ic-purple', v: s.stories_total||0,    l:'Историй',         sub: `${s.stories_published||0} видно`, sec:'stories'    },
        { i:'fa-graduation-cap',c:'ic-green',  v: s.specialties_total||0,l:'Специальностей',  sub: `${s.specialties_pub||0} публич.`, sec:'specs'      },
        { i:'fa-users',         c:'ic-teal',   v: s.students_total||0,   l:'Студентов',       sub: `${s.resumes_total||0} резюме`,    sec:'students'   },
        { i:'fa-briefcase',     c:'ic-orange', v: s.vacancies_active||0, l:'Активных вакансий',sub:`${s.vacancies_total||0} всего`,   sec:'vacancies'  },
        { i:'fa-handshake',     c:'ic-blue',   v: s.partners_total||0,   l:'Партнёров',       sub: `${s.partners_active||0} актив.`, sec:'partners'   },
        { i:'fab fa-vk',        c:'ic-vk',     v: s.vk_pending||0,       l:'ВК на модерации', sub: `${s.vk_approved||0} одобрено`,   sec:'vk'         },
        { i:'fa-chalkboard-teacher',c:'ic-green',v:s.staff_active||0,    l:'Сотрудников',     sub: `из ${s.staff_total||0}`,         sec:'staff'      },
        { i:'fa-clipboard-list',c:'ic-purple', v: s.career_events||0,    l:'Мероприятий',     sub: '',                               sec:'cevents'    },
        { i:'fa-book',          c:'ic-teal',   v: s.disciplines||0,      l:'Дисциплин',       sub: `${s.groups_total||0} групп`,     sec:'disciplines'},
        { i:'fa-file-alt',      c:'ic-orange', v: s.documents_total||0,  l:'Документов',      sub: '',                               sec:'docs'       },
    ];

    $('statsGrid').innerHTML = cards.map(c => `
      <div class="dash-kpi-card" onclick="go('${c.sec}',qn('${c.sec}'))" title="Перейти в раздел">
        <div class="dash-kpi-ico ${c.c}">
          <i class="${c.i.includes(' ') ? c.i : 'fas ' + c.i}"></i>
        </div>
        <div class="dash-kpi-body">
          <div class="dash-kpi-val">${fmtNum(c.v)}</div>
          <div class="dash-kpi-lbl">${c.l}</div>
          ${c.sub ? `<div class="dash-kpi-sub">${c.sub}</div>` : ''}
        </div>
        <i class="fas fa-chevron-right dash-kpi-arr"></i>
      </div>
    `).join('');
}

function fmtNum(n) {
    return n >= 1000 ? (n/1000).toFixed(1).replace('.0','') + 'K' : n;
}

/* ═══════════════════════════════════════════════════════════════════
   АЛЕРТ-БАННЕР
═══════════════════════════════════════════════════════════════════ */
function renderAlerts(s) {
    const alerts = [];
    if (s.apps_new > 0)     alerts.push({ t:'warning', i:'fa-inbox',      msg:`<b>${s.apps_new}</b> новых заявок ожидают обработки`, sec:'apps' });
    if (s.vk_pending > 0)   alerts.push({ t:'info',    i:'fab fa-vk',     msg:`<b>${s.vk_pending}</b> постов ВКонтакте ждут модерации`, sec:'vk' });

    $('dashAlerts').innerHTML = alerts.map(a => `
      <div class="dash-alert dash-alert-${a.t}" onclick="go('${a.sec}',qn('${a.sec}'))">
        <i class="${a.i.includes(' ') ? a.i : 'fas '+a.i}"></i>
        <span>${a.msg}</span>
        <i class="fas fa-arrow-right" style="margin-left:auto;opacity:.5"></i>
      </div>
    `).join('');
}

/* ═══════════════════════════════════════════════════════════════════
   ТАБЛИЦЫ
═══════════════════════════════════════════════════════════════════ */
async function loadDashTables(r) {
    // Заявки — используем данные из stats.php если есть, иначе грузим отдельно
    const apData = (r.recent_apps && r.recent_apps.length)
        ? r.recent_apps
        : await api('GET', 'api/applications.php?limit=6&status=new').then(x => x && x.data ? x.data : []);

    const statusMap = {
        new:        { cls:'bw',  lbl:'Новая'       },
        processing: { cls:'bi',  lbl:'В обработке' },
        approved:   { cls:'bs',  lbl:'Одобрена'    },
        rejected:   { cls:'bd',  lbl:'Отклонена'   },
    };

    $('dashApps').innerHTML = apData.length
        ? `<div class="tw"><table class="tbl">
            <thead><tr>
              <th>ID</th><th>ФИО</th><th>Тип</th><th>Статус</th><th>Дата</th>
            </tr></thead>
            <tbody>${apData.map(a => {
                const st = statusMap[a.status] || { cls:'bm', lbl: a.status };
                return `<tr>
                  <td style="color:var(--txt3)">#${a.id}</td>
                  <td style="font-weight:500">${esc(a.full_name)}</td>
                  <td>${esc(a.type||'—')}</td>
                  <td><span class="bdg ${st.cls}">${st.lbl}</span></td>
                  <td style="color:var(--txt3);white-space:nowrap">${fd(a.created_at)}</td>
                </tr>`;
            }).join('')}</tbody>
           </table></div>`
        : '<div class="empty"><i class="fas fa-check-circle"></i><p>Нет новых заявок</p></div>';

    // Лента активности
    const logs = r.recent_logs || [];
    const actionMap = {
        create: { cls:'bs',  ico:'fa-plus',       lbl:'Создан'  },
        update: { cls:'bi',  ico:'fa-pen',        lbl:'Изменён' },
        delete: { cls:'bd',  ico:'fa-trash',      lbl:'Удалён'  },
        login:  { cls:'bm',  ico:'fa-sign-in-alt',lbl:'Вход'    },
    };

    $('dashLogs').innerHTML = logs.length
        ? `<div class="dash-log-list">${logs.map(l => {
            const am = actionMap[l.action] || { cls:'bm', ico:'fa-dot-circle', lbl: l.action };
            return `<div class="dash-log-item">
              <div class="dash-log-ico ${am.cls}"><i class="fas ${am.ico}"></i></div>
              <div class="dash-log-body">
                <div class="dash-log-title">
                  <span class="bdg ${am.cls}" style="font-size:10px">${am.lbl}</span>
                  <span style="font-size:12px;color:var(--txt)">${esc(l.table_name||'')}</span>
                  ${l.comment ? `<span style="font-size:11px;color:var(--txt2)">— ${esc(l.comment)}</span>` : ''}
                </div>
                <div class="dash-log-meta">
                  <i class="fas fa-user" style="font-size:10px"></i> ${esc(l.admin_login||'—')}
                  <span style="opacity:.4">·</span>
                  ${fd(l.created_at)}
                </div>
              </div>
            </div>`;
          }).join('')}</div>`
        : '<div class="empty"><i class="fas fa-history"></i><p>Нет активности</p></div>';

    // Новости
    const nwData = (r.recent_news && r.recent_news.length)
        ? r.recent_news
        : await api('GET', 'api/news.php?limit=6').then(x => x && x.data ? x.data : []);

    $('dashNews').innerHTML = nwData.length
        ? `<div class="tw"><table class="tbl">
            <thead><tr>
              <th style="width:50px">ID</th><th>Заголовок</th>
              <th style="width:120px">Категория</th>
              <th style="width:100px">Статус</th>
              <th style="width:150px">Дата</th>
            </tr></thead>
            <tbody>${nwData.map(n => `<tr>
              <td style="color:var(--txt3)">#${n.id}</td>
              <td style="font-weight:500">${esc(n.title)}</td>
              <td>${n.category ? `<span class="bdg bp" style="font-size:10px">${esc(n.category)}</span>` : '—'}</td>
              <td>${pubBdg(n.is_published)}</td>
              <td style="color:var(--txt3);white-space:nowrap">${fd(n.published_at||n.created_at)}</td>
            </tr>`).join('')}</tbody>
           </table></div>`
        : '<div class="empty"><i class="fas fa-newspaper"></i><p>Нет новостей</p></div>';
}

/* ═══════════════════════════════════════════════════════════════════
   ДИАГРАММА 1 — Активность (линейная, новости + истории)
═══════════════════════════════════════════════════════════════════ */
function renderChartActivity(chartNews, months) {
    // Генерируем последние N месяцев
    const labels = [];
    const newsMap = {};
    chartNews.forEach(row => { newsMap[row.month] = parseInt(row.cnt); });

    const now = new Date();
    const newsData = [];

    for (let i = months - 1; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`;
        labels.push(dashMonthLabel(key));
        newsData.push(newsMap[key] || 0);
    }

    const ctx = document.getElementById('chartActivity');
    if (!ctx) return;

    if (_chartActivity) { _chartActivity.destroy(); _chartActivity = null; }

    const isDark = !document.documentElement.classList.contains('light');
    const gridColor = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)';
    const txtColor  = isDark ? '#8e9bb5' : '#4a5068';

    _chartActivity = new Chart(ctx, {
        type: 'line',
        data: {
            labels,
            datasets: [{
                label: 'Новости',
                data: newsData,
                borderColor: '#6c63ff',
                backgroundColor: 'rgba(108,99,255,0.12)',
                borderWidth: 2.5,
                pointBackgroundColor: '#6c63ff',
                pointRadius: 4,
                pointHoverRadius: 6,
                fill: true,
                tension: 0.4,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: isDark ? '#1e2130' : '#fff',
                    borderColor: 'rgba(108,99,255,0.4)',
                    borderWidth: 1,
                    titleColor: isDark ? '#e8eaf6' : '#1a1d2e',
                    bodyColor: isDark ? '#8e9bb5' : '#4a5068',
                    padding: 10,
                    cornerRadius: 8,
                    callbacks: {
                        label: ctx => ` ${ctx.parsed.y} публикаций`
                    }
                }
            },
            scales: {
                x: {
                    grid: { color: gridColor },
                    ticks: { color: txtColor, font: { size: 11 } }
                },
                y: {
                    grid: { color: gridColor },
                    ticks: { color: txtColor, font: { size: 11 }, precision: 0 },
                    beginAtZero: true
                }
            }
        }
    });
}

function dashSetPeriod(months, btn) {
    document.querySelectorAll('.dash-period-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    if (_dashData) renderChartActivity(_dashData.chart_news || [], months);
}

function dashMonthLabel(ym) {
    const months = ['Янв','Фев','Мар','Апр','Май','Июн','Июл','Авг','Сен','Окт','Ноя','Дек'];
    const [y, m] = ym.split('-');
    return months[parseInt(m)-1] + ' ' + y.slice(2);
}

/* ═══════════════════════════════════════════════════════════════════
   ДИАГРАММА 2 — Заявки Donut
═══════════════════════════════════════════════════════════════════ */
function renderChartApps(chartApps) {
    const statusLabels = { new:'Новые', processing:'В обработке', approved:'Одобрены', rejected:'Отклонены' };
    const statusColors = { new:'#f39c12', processing:'#3498db', approved:'#27ae60', rejected:'#e74c3c' };

    const labels = chartApps.map(r => statusLabels[r.status] || r.status);
    const data   = chartApps.map(r => parseInt(r.cnt));
    const colors = chartApps.map(r => statusColors[r.status] || '#8e9bb5');

    const ctx = document.getElementById('chartApps');
    if (!ctx) return;
    if (_chartApps) { _chartApps.destroy(); _chartApps = null; }

    const isDark = !document.documentElement.classList.contains('light');

    _chartApps = new Chart(ctx, {
        type: 'doughnut',
        data: { labels, datasets: [{ data, backgroundColor: colors, borderWidth: 0, hoverOffset: 6 }] },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '72%',
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: isDark ? '#1e2130' : '#fff',
                    borderColor: 'rgba(108,99,255,0.3)',
                    borderWidth: 1,
                    titleColor: isDark ? '#e8eaf6' : '#1a1d2e',
                    bodyColor: isDark ? '#8e9bb5' : '#4a5068',
                    padding: 10,
                    cornerRadius: 8,
                }
            }
        }
    });

    const total = data.reduce((a, b) => a + b, 0);
    $('dashAppsLegend').innerHTML = labels.map((lbl, i) => `
      <div class="dash-legend-item">
        <span class="dash-legend-dot" style="background:${colors[i]}"></span>
        <span class="dash-legend-lbl">${lbl}</span>
        <span class="dash-legend-val">${data[i]}</span>
        <span class="dash-legend-pct">${total ? Math.round(data[i]/total*100) : 0}%</span>
      </div>
    `).join('');
}

/* ═══════════════════════════════════════════════════════════════════
   ДИАГРАММА 3 — Контент Donut
═══════════════════════════════════════════════════════════════════ */
function renderChartContent(s) {
    const items = [
        { lbl: 'Новости',      val: s.news_total||0,       clr: '#6c63ff' },
        { lbl: 'Истории',      val: s.stories_total||0,    clr: '#e91e63' },
        { lbl: 'Документы',    val: s.documents_total||0,  clr: '#3498db' },
        { lbl: 'Специальности',val: s.specialties_total||0,clr: '#27ae60' },
        { lbl: 'Вакансии',     val: s.vacancies_total||0,  clr: '#f39c12' },
        { lbl: 'Партнёры',     val: s.partners_total||0,   clr: '#1abc9c' },
    ].filter(it => it.val > 0);

    const ctx = document.getElementById('chartContent');
    if (!ctx) return;
    if (_chartContent) { _chartContent.destroy(); _chartContent = null; }

    const isDark = !document.documentElement.classList.contains('light');

    _chartContent = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: items.map(i => i.lbl),
            datasets: [{
                data: items.map(i => i.val),
                backgroundColor: items.map(i => i.clr),
                borderWidth: 0,
                hoverOffset: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '68%',
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: isDark ? '#1e2130' : '#fff',
                    borderColor: 'rgba(108,99,255,0.3)',
                    borderWidth: 1,
                    titleColor: isDark ? '#e8eaf6' : '#1a1d2e',
                    bodyColor: isDark ? '#8e9bb5' : '#4a5068',
                    padding: 10,
                    cornerRadius: 8,
                }
            }
        }
    });

    const total = items.reduce((a, b) => a + b.val, 0);
    $('dashContentLegend').innerHTML = items.map(it => `
      <div class="dash-legend-item">
        <span class="dash-legend-dot" style="background:${it.clr}"></span>
        <span class="dash-legend-lbl">${it.lbl}</span>
        <span class="dash-legend-val">${it.val}</span>
        <span class="dash-legend-pct">${total ? Math.round(it.val/total*100) : 0}%</span>
      </div>
    `).join('');
}

/* ═══════════════════════════════════════════════════════════════════
   ДИАГРАММА 4 — Образование (горизонтальные бары)
═══════════════════════════════════════════════════════════════════ */
function renderChartEdu(s) {
    const items = [
        { lbl: 'Студентов',        val: s.students_total||0,  clr: 'rgba(108,99,255,0.8)' },
        { lbl: 'Сотрудников',      val: s.staff_total||0,     clr: 'rgba(39,174,96,0.8)'  },
        { lbl: 'Учебных групп',    val: s.groups_total||0,    clr: 'rgba(52,152,219,0.8)' },
        { lbl: 'Дисциплин',        val: s.disciplines||0,     clr: 'rgba(26,188,156,0.8)' },
        { lbl: 'Резюме',           val: s.resumes_total||0,   clr: 'rgba(243,156,18,0.8)' },
        { lbl: 'Портфолио',        val: s.portfolio_total||0, clr: 'rgba(233,30,99,0.8)'  },
        { lbl: 'Записей расписания',val: s.schedule_records||0,clr:'rgba(155,89,182,0.8)' },
    ];

    const ctx = document.getElementById('chartEdu');
    if (!ctx) return;
    if (_chartEdu) { _chartEdu.destroy(); _chartEdu = null; }

    const isDark = !document.documentElement.classList.contains('light');
    const gridColor = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)';
    const txtColor  = isDark ? '#8e9bb5' : '#4a5068';

    _chartEdu = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: items.map(i => i.lbl),
            datasets: [{
                data: items.map(i => i.val),
                backgroundColor: items.map(i => i.clr),
                borderRadius: 6,
                borderSkipped: false,
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: isDark ? '#1e2130' : '#fff',
                    borderColor: 'rgba(108,99,255,0.3)',
                    borderWidth: 1,
                    titleColor: isDark ? '#e8eaf6' : '#1a1d2e',
                    bodyColor: isDark ? '#8e9bb5' : '#4a5068',
                    padding: 10,
                    cornerRadius: 8,
                    callbacks: { label: ctx => ` ${ctx.parsed.x} записей` }
                }
            },
            scales: {
                x: {
                    grid: { color: gridColor },
                    ticks: { color: txtColor, font: { size: 11 }, precision: 0 },
                    beginAtZero: true
                },
                y: {
                    grid: { display: false },
                    ticks: { color: txtColor, font: { size: 11.5 } }
                }
            }
        }
    });
}
