<!-- ═══ О КОЛЛЕДЖЕ — v2 ═══ -->
<section class="sec" id="s-about-college">

  <!-- Image Crop Modal -->
  <div class="ac2-crop-modal" id="ac2CropModal">
    <div class="ac2-crop-overlay" onclick="ac2CloseCrop()"></div>
    <div class="ac2-crop-dialog">
      <div class="ac2-crop-header">
        <span><i class="fas fa-crop-alt"></i> Обрезка изображения</span>
        <button class="ac2-crop-close" onclick="ac2CloseCrop()"><i class="fas fa-times"></i></button>
      </div>
      <div class="ac2-crop-stage">
        <div class="ac2-crop-wrapper" id="ac2CropWrapper">
          <img id="ac2CropImg" src="" alt="">
          <div class="ac2-crop-box" id="ac2CropBox">
            <div class="ac2-crop-corner nw" data-dir="nw"></div>
            <div class="ac2-crop-corner ne" data-dir="ne"></div>
            <div class="ac2-crop-corner sw" data-dir="sw"></div>
            <div class="ac2-crop-corner se" data-dir="se"></div>
            <div class="ac2-crop-grid"></div>
          </div>
        </div>
        <div class="ac2-crop-toolbar">
          <div class="ac2-crop-zoom">
            <button onclick="ac2Zoom(-0.1)"><i class="fas fa-search-minus"></i></button>
            <input type="range" id="ac2ZoomRange" min="10" max="300" value="100" oninput="ac2ZoomRange(this.value)">
            <button onclick="ac2Zoom(0.1)"><i class="fas fa-search-plus"></i></button>
          </div>
          <div class="ac2-crop-ratio-btns">
            <button class="ac2-ratio-btn active" onclick="ac2SetRatio(16/9,this)">16:9</button>
            <button class="ac2-ratio-btn" onclick="ac2SetRatio(4/3,this)">4:3</button>
            <button class="ac2-ratio-btn" onclick="ac2SetRatio(1,this)">1:1</button>
            <button class="ac2-ratio-btn" onclick="ac2SetRatio(0,this)">Свободно</button>
          </div>
        </div>
      </div>
      <div class="ac2-crop-footer">
        <button class="btn btn-secondary" onclick="ac2CloseCrop()">Отмена</button>
        <button class="btn btn-primary" onclick="ac2ApplyCrop()"><i class="fas fa-check"></i> Применить</button>
      </div>
    </div>
  </div>

  <div class="ac2-layout">

    <!-- ══ ЛЕВАЯ ПАНЕЛЬ: Редактор ══ -->
    <div class="ac2-editor">

      <!-- Топ-шапка -->
      <div class="ac2-topbar">
        <div class="ac2-topbar-left">
          <i class="fas fa-university" style="color:var(--acc)"></i>
          <span class="ac2-topbar-title">О колледже</span>
          <span class="ac2-badge ac2-badge-saved" id="acSavedBadge" style="display:none">
            <i class="fas fa-check-circle"></i> Сохранено
          </span>
          <span class="ac2-badge ac2-badge-dirty" id="acDirtyBadge" style="display:none">
            <span class="ac2-dot"></span> Есть изменения
          </span>
        </div>
        <div class="ac2-topbar-right">
          <button class="ac2-btn-ghost" onclick="ac2TogglePreview()" id="ac2PreviewToggleBtn">
            <i class="fas fa-eye-slash" id="ac2PreviewIcon"></i>
            <span id="ac2PreviewLabel">Скрыть</span>
          </button>
          <button class="ac2-btn-save" onclick="acSave()" id="acSaveBtn">
            <i class="fas fa-save"></i> Сохранить
          </button>
        </div>
      </div>

      <!-- Прогресс-бар -->
      <div class="ac2-progress" id="acProgress" style="display:none">
        <div class="ac2-progress-bar" id="acProgressBar"></div>
      </div>

      <!-- Вкладки -->
      <div class="ac2-tabs">
        <button class="ac2-tab active" onclick="acTab('hero',this)"><i class="fas fa-image"></i> Главное</button>
        <button class="ac2-tab" onclick="acTab('stats',this)"><i class="fas fa-chart-bar"></i> Цифры</button>
        <button class="ac2-tab" onclick="acTab('advantages',this)"><i class="fas fa-star"></i> Преимущества</button>
        <button class="ac2-tab" onclick="acTab('achievements',this)"><i class="fas fa-trophy"></i> Достижения</button>
        <button class="ac2-tab" onclick="acTab('infra',this)"><i class="fas fa-building"></i> Инфраструктура</button>
      </div>

      <!-- ══ TAB: Главное ══ -->
      <div class="ac2-tab-content active" id="acTab-hero">

        <!-- Заголовок -->
        <div class="ac2-field">
          <label class="ac2-label">Заголовок страницы <span class="ac2-req">*</span></label>
          <input type="text" id="acTitle" class="ac2-inp" placeholder="АКСИБГУ — Аэрокосмический колледж" oninput="acMarkDirty()">
        </div>

        <!-- Обложка — image picker с превью и кропом -->
        <div class="ac2-field">
          <label class="ac2-label">Обложка страницы</label>
          <div class="ac2-cover-block" id="ac2CoverBlock">
            <div class="ac2-cover-empty" id="ac2CoverEmpty">
              <i class="fas fa-cloud-upload-alt"></i>
              <span>Перетащите фото сюда</span>
              <span class="ac2-cover-hint">или</span>
              <button class="ac2-cover-pick-btn" onclick="ac2PickCover()">
                <i class="fas fa-folder-open"></i> Выбрать файл
              </button>
              <span class="ac2-cover-hint">PNG, JPG, WebP · до 5 МБ</span>
            </div>
            <div class="ac2-cover-preview" id="ac2CoverPreview" style="display:none">
              <img id="ac2CoverThumb" src="" alt="Обложка">
              <div class="ac2-cover-overlay">
                <button class="ac2-cover-action" onclick="ac2PickCover()" title="Заменить"><i class="fas fa-sync-alt"></i> Заменить</button>
                <button class="ac2-cover-action" onclick="ac2EditCrop()" title="Обрезать"><i class="fas fa-crop-alt"></i> Обрезать</button>
                <button class="ac2-cover-action ac2-cover-del" onclick="ac2ClearCover()" title="Удалить"><i class="fas fa-trash"></i></button>
              </div>
            </div>
            <input type="hidden" id="acCover">
          </div>
          <div class="ac2-field-sub">
            <span class="ac2-label-hint">Или вставьте URL:</span>
            <input type="text" id="ac2CoverUrl" class="ac2-inp ac2-inp-sm" placeholder="https://example.com/photo.jpg" oninput="ac2OnUrlInput(this.value)">
          </div>
        </div>

        <!-- Миссия + О нас -->
        <div class="ac2-row2">
          <div class="ac2-field">
            <label class="ac2-label">Заголовок «Миссия»</label>
            <input type="text" id="acMissionTitle" class="ac2-inp" placeholder="Наша миссия" oninput="acMarkDirty()">
          </div>
          <div class="ac2-field">
            <label class="ac2-label">Заголовок «О нас»</label>
            <input type="text" id="acAboutTitle" class="ac2-inp" placeholder="О колледже" oninput="acMarkDirty()">
          </div>
        </div>

        <!-- Лид-абзац -->
        <div class="ac2-field">
          <label class="ac2-label">Вступление <span class="ac2-hint">Короткий текст под заголовком «Миссия»</span></label>
          <div class="ac2-textarea-wrap">
            <textarea id="acLead" class="ac2-textarea" rows="3" placeholder="Краткое вступление — 2-3 предложения о колледже..." oninput="acMarkDirty(); ac2AutoGrow(this)"></textarea>
          </div>
        </div>

        <!-- Основной текст -->
        <div class="ac2-field">
          <label class="ac2-label">Основной текст <span class="ac2-hint">Подробнее о колледже</span></label>
          <div class="ac2-textarea-wrap">
            <textarea id="acBody" class="ac2-textarea" rows="4" placeholder="История, ценности, описание колледжа..." oninput="acMarkDirty(); ac2AutoGrow(this)"></textarea>
          </div>
        </div>

        <!-- Аудитория + Публикация -->
        <div class="ac2-row2">
          <div class="ac2-field">
            <label class="ac2-label">Аудитория</label>
            <input type="text" id="acAudience" class="ac2-inp" placeholder="Абитуриенты, студенты" oninput="acMarkDirty()">
          </div>
          <div class="ac2-field ac2-field-center">
            <label class="ac2-toggle-label">
              <input type="checkbox" id="acPublished" onchange="acMarkDirty()">
              <span class="ac2-toggle"><span></span></span>
              <span class="ac2-toggle-text">Опубликовать</span>
            </label>
          </div>
        </div>
      </div>

      <!-- ══ TAB: Цифры ══ -->
      <div class="ac2-tab-content" id="acTab-stats">
        <div class="ac2-hint-box"><i class="fas fa-info-circle"></i> Ключевые показатели: «1 200 студентов», «30 лет», «15 специальностей».</div>
        <div class="ac2-field">
          <label class="ac2-label">Заголовок раздела</label>
          <input type="text" id="acStatsHeading" class="ac2-inp" placeholder="Колледж в цифрах" oninput="acMarkDirty()">
        </div>
        <div id="acStatsContainer" class="ac2-cards-container"></div>
        <button class="ac2-add-btn" onclick="acAddStat()"><i class="fas fa-plus"></i> Добавить показатель</button>
      </div>

      <!-- ══ TAB: Преимущества ══ -->
      <div class="ac2-tab-content" id="acTab-advantages">
        <div class="ac2-hint-box"><i class="fas fa-info-circle"></i> Причины выбрать ваш колледж. Каждый пункт — иконка, заголовок, описание.</div>
        <div class="ac2-field">
          <label class="ac2-label">Заголовок раздела</label>
          <input type="text" id="acAdvHeading" class="ac2-inp" placeholder="Почему выбирают нас" oninput="acMarkDirty()">
        </div>
        <div id="acAdvContainer" class="ac2-cards-container"></div>
        <button class="ac2-add-btn" onclick="acAddAdvantage()"><i class="fas fa-plus"></i> Добавить преимущество</button>
      </div>

      <!-- ══ TAB: Достижения ══ -->
      <div class="ac2-tab-content" id="acTab-achievements">
        <div class="ac2-hint-box"><i class="fas fa-info-circle"></i> Награды, рейтинги, сертификаты колледжа.</div>
        <div class="ac2-field">
          <label class="ac2-label">Заголовок раздела</label>
          <input type="text" id="acAchHeading" class="ac2-inp" placeholder="Наши достижения" oninput="acMarkDirty()">
        </div>
        <div id="acAchContainer" class="ac2-cards-container"></div>
        <button class="ac2-add-btn" onclick="acAddAchievement()"><i class="fas fa-plus"></i> Добавить достижение</button>
      </div>

      <!-- ══ TAB: Инфраструктура ══ -->
      <div class="ac2-tab-content" id="acTab-infra">
        <div class="ac2-hint-box"><i class="fas fa-info-circle"></i> Здания, лаборатории, спортивные объекты.</div>
        <div class="ac2-field">
          <label class="ac2-label">Заголовок раздела</label>
          <input type="text" id="acInfraHeading" class="ac2-inp" placeholder="Инфраструктура" oninput="acMarkDirty()">
        </div>
        <div class="ac2-field">
          <label class="ac2-label">Текст об инфраструктуре</label>
          <div class="ac2-textarea-wrap">
            <textarea id="acInfraText" class="ac2-textarea" rows="5" placeholder="Опишите учебные корпуса, лаборатории, библиотеку, спортивные залы..." oninput="acMarkDirty(); ac2AutoGrow(this)"></textarea>
          </div>
        </div>
      </div>

    </div><!-- /.ac2-editor -->

    <!-- ══ ПРАВАЯ ПАНЕЛЬ: Предпросмотр телефона ══ -->
    <div class="ac2-preview-col" id="ac2PreviewCol">
      <div class="ac2-preview-label"><i class="fas fa-mobile-alt"></i> Предпросмотр приложения</div>
      <div class="ac2-phone">
        <div class="ac2-phone-shell">
          <!-- Dynamic island -->
          <div class="ac2-phone-island"></div>
          <!-- Screen -->
          <div class="ac2-phone-screen" id="acPreviewScreen">
            <!-- JS генерирует содержимое -->
          </div>
          <!-- Home indicator -->
          <div class="ac2-phone-home"></div>
        </div>
      </div>
    </div>

  </div><!-- /.ac2-layout -->
</section>
