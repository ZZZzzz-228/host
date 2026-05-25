<!-- ═══ MODAL: Новый тест профориентации ═══ -->
<div class="mo" id="mdCareerTest">
  <div class="modal" style="max-width:500px">
    <div class="mh">
      <div class="mt"><i class="fas fa-clipboard-list"></i> Создать тест профориентации</div>
      <button class="mc" onclick="cm('mdCareerTest')"><i class="fas fa-times"></i></button>
    </div>
    <div class="mb">
      <div class="fr">
        <label>Название теста <span style="color:red">*</span></label>
        <input class="fc" id="mdCtTitle" placeholder="Например: Тест профессиональных предпочтений">
      </div>
      <div class="fr">
        <label>Описание</label>
        <textarea class="fc" id="mdCtDesc" rows="3" placeholder="Краткое описание теста (необязательно)"></textarea>
      </div>
      <div class="fr">
        <label>Статус</label>
        <select class="fc" id="mdCtActive">
          <option value="1">✅ Активен (виден в приложении)</option>
          <option value="0">⏸ Отключён</option>
        </select>
      </div>
    </div>
    <div class="mf">
      <button class="btn" onclick="cm('mdCareerTest')">Отмена</button>
      <button class="btn btn-primary" onclick="ctCreateTest()"><i class="fas fa-plus"></i> Создать</button>
    </div>
  </div>
</div>

<!-- ═══ MODAL: Редактировать вопрос ═══ -->
<div class="mo" id="mdCtQuestion">
  <div class="modal" style="max-width:580px">
    <div class="mh">
      <div class="mt" id="mdCtQTitle"><i class="fas fa-question-circle"></i> Вопрос</div>
      <button class="mc" onclick="cm('mdCtQuestion')"><i class="fas fa-times"></i></button>
    </div>
    <div class="mb">
      <div class="fr">
        <label>Текст вопроса <span style="color:red">*</span></label>
        <textarea class="fc" id="mdCtQText" rows="3" placeholder="Введите текст вопроса..."></textarea>
      </div>
    </div>
    <div class="mf">
      <button class="btn" onclick="cm('mdCtQuestion')">Отмена</button>
      <button class="btn btn-primary" onclick="ctSaveQuestion()"><i class="fas fa-save"></i> Сохранить</button>
    </div>
  </div>
</div>

<!-- ═══ MODAL: Редактировать ответ ═══ -->
<div class="mo" id="mdCtAnswer">
  <div class="modal" style="max-width:620px">
    <div class="mh">
      <div class="mt" id="mdCtATitle"><i class="fas fa-check-circle"></i> Ответ</div>
      <button class="mc" onclick="cm('mdCtAnswer')"><i class="fas fa-times"></i></button>
    </div>
    <div class="mb">
      <div class="fr">
        <label>Текст ответа <span style="color:red">*</span></label>
        <textarea class="fc" id="mdCtAText" rows="2" placeholder="Введите текст ответа..."></textarea>
      </div>
      <div class="fr">
        <label>
          Специальности <span style="color:var(--txt2);font-size:12px">(какие специальности «набирают очки» при выборе этого ответа)</span>
        </label>
        <div id="mdCtASpecsWrap" style="display:flex;flex-direction:column;gap:8px">
          <!-- чекбоксы специальностей подгружаются JS -->
          <div class="ldo"><div class="spin" style="width:20px;height:20px"></div></div>
        </div>
        <div style="margin-top:8px;font-size:12px;color:var(--txt2)">
          <i class="fas fa-info-circle"></i>
          Отметьте специальности, которые соответствуют этому ответу. При прохождении теста каждый ответ начисляет +1 к выбранным специальностям.
        </div>
      </div>
    </div>
    <div class="mf">
      <button class="btn" onclick="cm('mdCtAnswer')">Отмена</button>
      <button class="btn btn-primary" onclick="ctSaveAnswer()"><i class="fas fa-save"></i> Сохранить</button>
    </div>
  </div>
</div>
