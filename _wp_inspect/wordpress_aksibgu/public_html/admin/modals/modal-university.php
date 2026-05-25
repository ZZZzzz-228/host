<!-- ═══ MODAL: UNIVERSITY ═══ -->
<!-- Путь на хостинге: public_html/admin/modals/modal-university.php -->
<div class="mo" id="mUni"><div class="modal mlg">
  <div class="mh">
    <div class="mt" id="mUniT">Университет</div>
    <button class="mc" onclick="cm('mUni')"><i class="fas fa-times"></i></button>
  </div>
  <div class="mb">
    <input type="hidden" id="uniId">

    <!-- Основная информация -->
    <div class="fr"><label>Название *</label><input class="fc" id="uniName" placeholder="Полное название вуза"></div>
    <div class="fg">
      <div class="fr"><label>Краткое название</label><input class="fc" id="uniShort" placeholder="АКСИБГУУ"></div>
      <div class="fr"><label>Город</label><input class="fc" id="uniCity" placeholder="Бишкек"></div>
    </div>
    <div class="fr"><label>Описание (краткое)</label><textarea class="ft" id="uniDesc" style="min-height:80px" placeholder="Краткое описание для карточки…"></textarea></div>
    <div class="fr"><label>Полный текст / HTML</label><textarea class="ft" id="uniFullText" style="min-height:120px" placeholder="Развёрнутое описание, можно использовать HTML-теги…"></textarea></div>

    <!-- Контакты -->
    <div style="font-weight:600;margin:12px 0 6px;color:var(--acc);font-size:13px"><i class="fas fa-address-card"></i> Контакты</div>
    <div class="fg">
      <div class="fr"><label>Телефон</label><input class="fc" id="uniPhone" placeholder="+996 xxx xxx xxx"></div>
      <div class="fr"><label>Email</label><input class="fc" id="uniEmail" placeholder="info@university.kg"></div>
    </div>
    <div class="fr"><label>Адрес</label><input class="fc" id="uniAddress" placeholder="ул. Пример, д. 1"></div>

    <!-- Ссылки -->
    <div style="font-weight:600;margin:12px 0 6px;color:var(--acc);font-size:13px"><i class="fas fa-link"></i> Ссылки</div>
    <div class="fg">
      <div class="fr"><label>Сайт</label><input class="fc" id="uniUrl" placeholder="https://university.kg"></div>
      <div class="fr"><label>Приёмная комиссия</label><input class="fc" id="uniAdmUrl" placeholder="https://university.kg/admission"></div>
    </div>
    <div class="fg">
      <div class="fr"><label>ВКонтакте</label><input class="fc" id="uniVk" placeholder="https://vk.com/university"></div>
      <div class="fr"><label>Telegram</label><input class="fc" id="uniTg" placeholder="https://t.me/university"></div>
    </div>

    <!-- Медиа -->
    <div style="font-weight:600;margin:12px 0 6px;color:var(--acc);font-size:13px"><i class="fas fa-image"></i> Медиа</div>
    <div class="fg">
      <div class="fr">
        <label>Логотип (URL)</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="uniLogo" placeholder="https://... ссылка на логотип" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('uniLogo',{title:'Логотип университета',ratio:1})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr">
        <label>Обложка (URL)</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="uniCover" placeholder="https://... ссылка на обложку" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('uniCover',{title:'Обложка университета',ratio:16/9})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
    </div>

    <!-- Дополнительно -->
    <div style="font-weight:600;margin:12px 0 6px;color:var(--acc);font-size:13px"><i class="fas fa-cog"></i> Дополнительно</div>
    <div class="fg">
      <div class="fr"><label>Теги (через запятую)</label><input class="fc" id="uniTags" placeholder="технический, медицина, экономика"></div>
      <div class="fr"><label>Порядок сортировки</label><input type="number" class="fc" id="uniOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="uniActive" checked><label for="uniActive">Активен (показывать в приложении)</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mUni')">Отмена</button>
    <button class="btn btn-primary" onclick="saveUniversity()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
