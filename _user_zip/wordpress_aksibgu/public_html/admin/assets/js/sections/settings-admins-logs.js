/* ═══════════════════════════════════════════════════════════════
   settings-admins-logs.js — Настройки, Администраторы, Журнал
   Исправлено:
   • editAdmin  — GET ?id= возвращает объект напрямую (не r.data)
   • saveAdmin  — POST/PUT возвращает объект напрямую: r.id || r.success
   • delAdmin   — DELETE → 204, тело null, не проверяем success
   ═══════════════════════════════════════════════════════════════ */

/* ── SETTINGS ────────────────────────────────────────────────── */
let sgData = {}, curSG = 'general';

const SG_DEFAULTS = {
  general:[
    {key:'site_name',       label:'Название сайта',               type:'text',    value:'АКСИБГУУ'},
    {key:'site_url',        label:'URL сайта',                    type:'url',     value:'https://aksibguu.ru'},
    {key:'site_description',label:'Описание сайта',               type:'textarea',value:''},
    {key:'site_phone',      label:'Телефон приёмной',             type:'text',    value:''},
    {key:'site_email',      label:'E-mail сайта',                 type:'email',   value:''},
    {key:'site_address',    label:'Адрес',                        type:'text',    value:''},
    {key:'site_logo',       label:'URL логотипа',                 type:'url',     value:''},
    {key:'site_favicon',    label:'URL favicon',                  type:'url',     value:''},
    {key:'site_maintenance',label:'Режим обслуживания',           type:'bool',    value:'0'},
  ],
  vk:[
    {key:'vk_group_id',    label:'Alias/ID группы ВКонтакте',    type:'text',    value:'media_ak'},
    {key:'vk_token',       label:'Сервисный ключ VK API',         type:'text',    value:''},
    {key:'vk_parse_count', label:'Кол-во постов за запрос',       type:'number',  value:'20'},
    {key:'vk_auto_parse',  label:'Автопарсинг при открытии',      type:'bool',    value:'0'},
    {key:'vk_group_url',   label:'Ссылка на группу ВКонтакте',   type:'url',     value:'https://vk.com/media_ak'},
  ],
  smtp:[
    {key:'smtp_host',      label:'SMTP хост',                    type:'text',    value:''},
    {key:'smtp_port',      label:'SMTP порт',                    type:'number',  value:'465'},
    {key:'smtp_user',      label:'Логин SMTP',                   type:'text',    value:''},
    {key:'smtp_pass',      label:'Пароль SMTP',                  type:'text',    value:''},
    {key:'smtp_from',      label:'Отправитель (From)',            type:'email',   value:''},
    {key:'smtp_from_name', label:'Имя отправителя',              type:'text',    value:'АКСИБГУУ'},
    {key:'smtp_secure',    label:'Безопасное соединение (SSL/TLS)',type:'bool',  value:'1'},
    {key:'smtp_enabled',   label:'Включить отправку почты',       type:'bool',   value:'0'},
  ],
  home:[
    {key:'home_hero_title',    label:'Заголовок главной страницы',    type:'text',    value:'АКСИБГУУ'},
    {key:'home_hero_subtitle', label:'Подзаголовок главной страницы', type:'text',    value:''},
    {key:'home_hero_image',    label:'Фоновое изображение hero',      type:'url',     value:''},
    {key:'home_news_count',    label:'Кол-во новостей на главной',    type:'number',  value:'6'},
    {key:'home_stories_count', label:'Кол-во историй на главной',     type:'number',  value:'8'},
    {key:'home_partners_show', label:'Показывать партнёров',          type:'bool',    value:'1'},
    {key:'home_stats_show',    label:'Показывать статистику',         type:'bool',    value:'1'},
    {key:'home_welcome_text',  label:'Приветственный текст',          type:'textarea',value:''},
  ],
  career:[
    {key:'career_enabled',       label:'Включить карьерный раздел',        type:'bool',  value:'1'},
    {key:'career_email',         label:'Email карьерного центра',           type:'email', value:''},
    {key:'career_phone',         label:'Телефон карьерного центра',         type:'text',  value:''},
    {key:'career_schedule',      label:'График работы',                     type:'text',  value:'Пн–Пт 9:00–17:00'},
    {key:'career_resume_public', label:'Резюме открыты для работодателей',  type:'bool',  value:'0'},
    {key:'career_vacancy_count', label:'Вакансий на странице',             type:'number',value:'12'},
    {key:'career_events_count',  label:'Мероприятий на странице',          type:'number',value:'6'},
  ],
};

async function loadSettings(){
    $('sgContent').innerHTML='<div class="ldo"><div class="spin"></div></div>';
    try {
        const r = await api('GET','api/settings.php');
        const flat    = (r && r.flat)    ? r.flat    : {};
        const grouped = (r && r.grouped) ? r.grouped : {};
        sgData = {};
        for(const [grp, fields] of Object.entries(SG_DEFAULTS)){
            sgData[grp] = fields.map(f=>{
                const dbRows = grouped[grp] || [];
                const dbRow  = dbRows.find(row => row.key === f.key);
                return {
                    key  : f.key,
                    label: dbRow ? (dbRow.label || f.label) : f.label,
                    type : dbRow ? (dbRow.type  || f.type)  : f.type,
                    value: dbRow ? (dbRow.value !== null && dbRow.value !== undefined ? dbRow.value : f.value) : f.value,
                    group: grp,
                };
            });
            const dbExtra = (grouped[grp]||[]).filter(row => !fields.find(f => f.key===row.key));
            dbExtra.forEach(row => {
                sgData[grp].push({key:row.key, label:row.label||row.key, type:row.type||'text', value:row.value||'', group:grp});
            });
        }
        for(const [grp, rows] of Object.entries(grouped)){
            if(!sgData[grp]){
                sgData[grp] = rows.map(r => ({key:r.key, label:r.label||r.key, type:r.type||'text', value:r.value||'', group:grp}));
            }
        }
    } catch(e){
        sgData = {};
        for(const [grp, fields] of Object.entries(SG_DEFAULTS)){
            sgData[grp] = fields.map(f => ({...f, group:grp}));
        }
    }
    renderSG(curSG);
}

function switchSG(g, el){
    document.querySelectorAll('.stab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    curSG = g;
    renderSG(g);
}

function renderSG(g){
    const fields = sgData[g];
    if(!fields || !fields.length){
        $('sgContent').innerHTML = '<div class="empty"><i class="fas fa-sliders-h"></i><p>Нет настроек для этой группы</p></div>';
        return;
    }
    let h = `<form onsubmit="saveSG(event,'${g}')" style="max-width:720px"><div class="fg">`;
    for(const f of fields){
        h += `<div class="fr"><label>${esc(f.label || f.key)}</label>`;
        const val = f.value != null ? String(f.value) : '';
        if(f.type === 'textarea' || f.type === 'json'){
            h += `<textarea class="ft" name="${esc(f.key)}" rows="4" style="font-family:monospace;font-size:12px">${esc(val)}</textarea>`;
        } else if(f.type === 'bool'){
            const chk = (val==='1'||val==='true'||val===true) ? 'checked' : '';
            h += `<div class="fchk" style="padding:6px 0">
                    <input type="checkbox" name="${esc(f.key)}" id="sg_${esc(f.key)}" ${chk}>
                    <label for="sg_${esc(f.key)}" style="font-size:13px;text-transform:none;letter-spacing:0">Включено</label>
                  </div>`;
        } else if(f.type === 'color'){
            h += `<input type="color" class="fc" name="${esc(f.key)}" value="${esc(val||'#6c63ff')}" style="height:38px;padding:3px 6px;cursor:pointer">`;
        } else if(f.type === 'number'){
            h += `<input type="number" class="fc" name="${esc(f.key)}" value="${esc(val)}" min="0">`;
        } else if(f.type === 'email'){
            h += `<input type="email" class="fc" name="${esc(f.key)}" value="${esc(val)}" placeholder="${esc(f.label)}">`;
        } else if(f.type === 'url'){
            h += `<input type="url" class="fc" name="${esc(f.key)}" value="${esc(val)}" placeholder="https://...">`;
        } else {
            const isPass = f.key.toLowerCase().includes('pass') || f.key.toLowerCase().includes('token') || f.key.toLowerCase().includes('secret');
            h += `<input type="${isPass?'password':'text'}" class="fc" name="${esc(f.key)}" value="${esc(val)}" placeholder="${esc(f.label)}" autocomplete="off">`;
        }
        h += '</div>';
    }
    h += `</div><div style="margin-top:8px">
            <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Сохранить настройки</button>
          </div></form>`;
    $('sgContent').innerHTML = h;
}

async function saveSG(e, grp){
    e.preventDefault();
    const settings = {};
    new FormData(e.target).forEach((val, k) => { settings[k] = val; });
    e.target.querySelectorAll('input[type=checkbox]').forEach(cb => { settings[cb.name] = cb.checked ? '1' : '0'; });
    const g = grp || curSG;
    const r = await api('POST','api/settings.php', {group: g, settings});
    if(r && (r.saved !== undefined || r.success)){
        toast(`Настройки «${g}» сохранены`);
        if(sgData[g]) sgData[g].forEach(f => { if(settings[f.key] !== undefined) f.value = settings[f.key]; });
    } else {
        toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
    }
}

/* ── ADMINS ──────────────────────────────────────────────────── */
async function loadAdmins(){
    const r = await api('GET','api/users.php?limit=100');
    const d = r && r.data ? r.data : [];
    const rRu = {
        superadmin    : 'Суперадмин',
        admin         : 'Админ',
        editor        : 'Редактор',
        moderator     : 'Модератор',
        career_manager: 'Менеджер',
    };
    $('adTb').innerHTML = d.length ? d.map(a=>`<tr>
        <td>${a.id}</td>
        <td><strong>${esc(a.login)}</strong></td>
        <td>${esc(a.full_name||'—')}</td>
        <td>${esc(a.email||'—')}</td>
        <td>${bdg(rRu[a.role]||a.role, a.role==='superadmin'?'bd':a.role==='admin'?'bw':'bi')}</td>
        <td>${fd(a.last_login)}</td>
        <td>${actBdg(a.is_active)}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" title="Редактировать" onclick="editAdmin(${a.id})">
                <i class="fas fa-edit"></i>
            </button>
            <button class="btn btn-danger btn-sm btn-ico" title="Удалить" onclick="delAdmin(${a.id})">
                <i class="fas fa-trash"></i>
            </button>
        </div></td>
    </tr>`).join('') : empty('Нет администраторов');
}

function openAdmin(it){
    $('adId').value  = it ? it.id        : '';
    $('adLg').value  = it ? it.login     : '';
    $('adPw').value  = '';
    $('adNm').value  = it ? it.full_name ||'' : '';
    $('adEm').value  = it ? it.email     ||'' : '';
    $('adRl').value  = it ? it.role      : 'editor';
    $('adAct').checked = !it || !!+it.is_active;
    $('adPwHint').textContent  = it ? '(оставьте пустым, чтобы не менять)' : '(обязателен для нового администратора)';
    $('mAdminT').textContent   = it ? 'Редактировать администратора' : 'Добавить администратора';
    om('mAdmin');
}

async function editAdmin(id){
    /* GET ?id= возвращает объект напрямую, без обёртки {data:...} */
    const r = await api('GET',`api/users.php?id=${id}`);
    if(r && r.id)        openAdmin(r);       // объект напрямую ✓
    else if(r && r.data) openAdmin(r.data);  // на случай старого формата
    else toast('Не удалось загрузить данные администратора','error');
}

async function saveAdmin(){
    const id = $('adId').value;
    const pw = v('adPw');
    if(!id && !pw){ toast('Пароль обязателен для нового администратора','error'); return; }
    const d = {
        login    : v('adLg'),
        full_name: v('adNm'),
        email    : v('adEm'),
        role     : $('adRl').value,
        is_active: $('adAct').checked ? 1 : 0,
    };
    if(pw) d.password = pw;
    if(!d.login){ toast('Введите логин','error'); return; }
    const r = await api(
        id ? 'PUT'  : 'POST',
        id ? `api/users.php?id=${id}` : 'api/users.php',
        d
    );
    /* POST/PUT возвращает объект напрямую — проверяем r.id */
    if(r && (r.id || r.success)){
        toast(id ? 'Администратор обновлён' : 'Администратор создан');
        cm('mAdmin');
        loadAdmins();
    } else {
        toast((r && (r.error || r.message)) || 'Ошибка сохранения', 'error');
    }
}

async function delAdmin(id){
    if(!confirm('Удалить администратора? Это действие необратимо.'))return;
    /* DELETE → HTTP 204, тело пустое, не проверяем ответ */
    await api('DELETE',`api/users.php?id=${id}`);
    toast('Администратор удалён');
    loadAdmins();
}

/* ── LOGS ────────────────────────────────────────────────────── */
let lgP = 1;

async function loadLogs(){
    const q   = v('lgSrch');
    const act = $('lgAct').value;
    let u = `api/logs.php?page=${lgP}&limit=30`;
    if(q)   u += '&search=' + encodeURIComponent(q);
    if(act) u += '&action=' + act;
    const r   = await api('GET', u);
    const d   = r && r.data  ? r.data  : [];
    const tot = r && r.total ? r.total : 0;
    const ac  = {create:'bs', update:'bi', delete:'bd', login:'bp', upload:'bm', patch:'bi'};
    const tblRu = {
        admins:'Администраторы', news_items:'Новости', stories:'Истории',
        contacts:'Контакты', specialties:'Специальности', education_programs:'Доп. программы',
        applications:'Заявки', staff_members:'Сотрудники', departments:'Отделения',
        schedule:'Расписание', pages:'Страницы', partners:'Партнёры',
        site_settings:'Настройки', uploaded_files:'Файлы', vacancies:'Вакансии'
    };
    $('lgTb').innerHTML = d.length ? d.map(l=>`<tr>
        <td>${l.id}</td>
        <td>${fd(l.created_at)}</td>
        <td>${esc(l.admin_name || l.admin_login || '—')}</td>
        <td>${bdg(l.action, ac[l.action]||'bm')}</td>
        <td>${l.table_name ? `<span title="${esc(l.table_name)}">${esc(tblRu[l.table_name]||l.table_name)}</span>` : '—'}</td>
        <td>${l.record_id && l.record_id > 0 ? `<code>${l.record_id}</code>` : '—'}</td>
        <td>${l.message ? `<small style="color:var(--tx2)">${esc(l.message)}</small>` : '—'}</td>
        <td><small>${l.ip_address ? esc(l.ip_address) : '—'}</small></td>
    </tr>`).join('') : empty('Журнал пуст');
    $('lgPgn').innerHTML = pgn(tot, lgP, 30, 'goLP');
}

function goLP(p){ lgP = p; loadLogs(); }