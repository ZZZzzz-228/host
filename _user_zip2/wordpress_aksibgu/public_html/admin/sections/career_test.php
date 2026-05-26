<!-- ═══ CAREER TEST (Профориентационные тесты) ═══ -->
<section class="sec" id="s-career-test">
  <div class="card">
    <div class="card-hd">
      <div class="card-title"><i class="fas fa-clipboard-list" style="color:var(--acc)"></i> Тесты профориентации</div>
      <button class="btn btn-primary" onclick="openCareerTestCreate()"><i class="fas fa-plus"></i> Создать тест</button>
    </div>
    <p style="color:var(--txt2);font-size:13px;margin:0 0 16px">
      Тесты используются в приложении в разделе <b>Профориентация</b>. Первый активный тест загружается автоматически.
    </p>

    <!-- Список тестов -->
    <div id="ctTestList">
      <div class="ldo"><div class="spin"></div></div>
    </div>
  </div>

  <!-- Редактор теста (раскрывается при выборе) -->
  <div class="card" id="ctEditor" style="display:none">
    <div class="card-hd">
      <div class="card-title" id="ctEditorTitle"><i class="fas fa-edit" style="color:var(--acc)"></i> Редактор теста</div>
      <button class="btn" onclick="ctCloseEditor()" style="background:var(--bg3)"><i class="fas fa-times"></i> Закрыть</button>
    </div>

    <!-- Инфо о тесте -->
    <div style="display:flex;gap:12px;flex-wrap:wrap;margin-bottom:20px">
      <div style="flex:1;min-width:220px">
        <label class="lbl">Название теста</label>
        <input class="fc" id="ctEditTitle" placeholder="Название теста профориентации">
      </div>
      <div style="min-width:160px">
        <label class="lbl">Статус</label>
        <select class="fc" id="ctEditActive">
          <option value="1">✅ Активен</option>
          <option value="0">⏸ Отключён</option>
        </select>
      </div>
    </div>
    <div style="margin-bottom:16px">
      <label class="lbl">Описание (необязательно)</label>
      <textarea class="fc" id="ctEditDesc" rows="2" placeholder="Краткое описание теста"></textarea>
    </div>
    <button class="btn btn-primary" onclick="ctSaveTestInfo()" style="margin-bottom:24px">
      <i class="fas fa-save"></i> Сохранить инфо о тесте
    </button>

    <hr style="border:none;border-top:1px solid var(--bdr);margin-bottom:20px">

    <!-- Вопросы -->
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px">
      <div style="font-size:15px;font-weight:600">Вопросы <span id="ctQCount" style="color:var(--txt2);font-size:13px"></span></div>
      <button class="btn btn-primary" onclick="ctAddQuestion()"><i class="fas fa-plus"></i> Добавить вопрос</button>
    </div>
    <div id="ctQuestionList" style="display:flex;flex-direction:column;gap:12px">
      <!-- Вопросы рендерятся JS -->
    </div>
  </div>
</section>
