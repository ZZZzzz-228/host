<!-- ═══ SETTINGS ═══ -->
<section class="sec" id="s-settings">
  <div class="card" style="margin-bottom:14px;background:rgba(52,152,219,.07);border-color:rgba(52,152,219,.2)">
    <div style="display:flex;align-items:flex-start;gap:14px;flex-wrap:wrap">
      <div style="flex:1;min-width:260px">
        <div style="font-size:13px;font-weight:600;color:var(--txt);margin-bottom:6px">
          <i class="fas fa-plug" style="color:var(--info)"></i> Публичный API для гостевого приложения
        </div>
        <div style="font-size:12px;color:var(--txt3);line-height:1.7">
          Все данные доступны для Flutter/React приложения через Public API:<br>
          <code style="background:var(--bghov);padding:2px 6px;border-radius:4px;font-size:11px">GET /admin/api/public/?resource=news</code><br>
          Доступные ресурсы: <code style="font-size:11px">news, stories, contacts, specialties, partners, documents, staff, vacancies, events, eduprog, departments, pages, settings, stats</code>
        </div>
      </div>
      <a href="api/public/" target="_blank" class="btn btn-info btn-sm" style="margin-top:4px">
        <i class="fas fa-external-link-alt"></i>Открыть API
      </a>
    </div>
  </div>
  <div class="card">
    <div class="card-title" style="margin-bottom:14px"><i class="fas fa-cog" style="color:var(--txt3)"></i> Настройки сайта</div>
    <div class="stabs" id="stabs">
      <div class="stab active" onclick="switchSG('general',this)">Основные</div>
      <div class="stab" onclick="switchSG('vk',this)">ВКонтакте</div>
      <div class="stab" onclick="switchSG('smtp',this)">SMTP почта</div>
      <div class="stab" onclick="switchSG('home',this)">Главная</div>
      <div class="stab" onclick="switchSG('career',this)">Карьера</div>
    </div>
    <div id="sgContent"><div class="ldo"><div class="spin"></div></div></div>
  </div>
</section>
