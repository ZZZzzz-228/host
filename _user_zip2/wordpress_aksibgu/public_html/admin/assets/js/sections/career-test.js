/**
 * career-test.js — управление тестами профориентации
 * =====================================================
 * Глобальные переменные состояния
 */

let ctCurrentTestId = null;    // ID открытого теста в редакторе
let ctCurrentTest   = null;    // Полный объект теста (с вопросами/ответами)
let ctSpecialties   = null;    // Кэш специальностей для чекбоксов

// Контекст редактируемого вопроса / ответа
let ctEditingQid   = null;     // null = создание, число = редактирование
let ctEditingQTestId = null;
let ctEditingAid   = null;     // null = создание, число = редактирование
let ctEditingAQid  = null;

// ═══════════════════════════════════════════════════════
// ЗАГРУЗКА
// ═══════════════════════════════════════════════════════

async function loadCareerTests() {
    document.getElementById('ctTestList').innerHTML = '<div class="ldo"><div class="spin"></div></div>';
    const r = await api('GET', 'api/career_test.php');
    if (!r) {
        document.getElementById('ctTestList').innerHTML = `<div class="empty"><i class="fas fa-exclamation-triangle"></i><p>Ошибка загрузки тестов</p></div>`;
        return;
    }
    renderCtTestList(r.data || []);
}

function renderCtTestList(tests) {
    const el = document.getElementById('ctTestList');
    if (!tests.length) {
        el.innerHTML = `
          <div class="empty">
            <i class="fas fa-clipboard-list"></i>
            <p>Тестов ещё нет. Создайте первый тест.</p>
          </div>`;
        return;
    }

    el.innerHTML = `
      <div class="tw">
        <table class="tbl">
          <thead>
            <tr>
              <th style="width:50px">ID</th>
              <th>Название</th>
              <th style="width:100px">Вопросов</th>
              <th style="width:100px">Статус</th>
              <th style="width:140px">Действия</th>
            </tr>
          </thead>
          <tbody>
            ${tests.map(t => `
              <tr>
                <td>#${t.id}</td>
                <td>
                  <div style="font-weight:600">${esc(t.title)}</div>
                  ${t.description ? `<div style="font-size:12px;color:var(--txt2)">${esc(t.description)}</div>` : ''}
                </td>
                <td>
                  <span style="background:var(--bg3);border-radius:20px;padding:2px 10px;font-size:13px">
                    ${t.questions_count} шт.
                  </span>
                </td>
                <td>
                  ${t.is_active
                    ? '<span class="bdg bs">Активен</span>'
                    : '<span class="bdg bm">Отключён</span>'}
                </td>
                <td>
                  <div style="display:flex;gap:6px">
                    <button class="btn btn-sm" title="Редактировать" onclick="ctOpenEditor(${t.id})">
                      <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" title="Удалить" onclick="ctDeleteTest(${t.id}, '${esc(t.title).replace(/'/g, "\\'")}')">
                      <i class="fas fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>`;
}

// ═══════════════════════════════════════════════════════
// СОЗДАНИЕ ТЕСТА (модальное окно)
// ═══════════════════════════════════════════════════════

function openCareerTestCreate() {
    document.getElementById('mdCtTitle').value = '';
    document.getElementById('mdCtDesc').value  = '';
    document.getElementById('mdCtActive').value = '1';
    om('mdCareerTest');
}

function closeMdCareerTest() { cm('mdCareerTest'); }

async function ctCreateTest() {
    const title = document.getElementById('mdCtTitle').value.trim();
    if (!title) { toast('Укажите название теста', 'warning'); return; }

    const t = await api('POST', 'api/career_test.php', {
        title,
        description: document.getElementById('mdCtDesc').value.trim(),
        is_active:   +document.getElementById('mdCtActive').value,
    });
    if (!t || t.error) { toast(t ? t.error : 'Ошибка создания теста', 'error'); return; }
    cm('mdCareerTest');
    toast('Тест создан');
    loadCareerTests();
    ctOpenEditor(t.id, t);
}

// ═══════════════════════════════════════════════════════
// РЕДАКТОР ТЕСТА
// ═══════════════════════════════════════════════════════

async function ctOpenEditor(testId, testData) {
    ctCurrentTestId = testId;
    document.getElementById('ctEditor').style.display = '';

    // Заполняем поля
    if (!testData) {
        testData = await api('GET', `api/career_test.php?id=${testId}`);
        if (!testData) { toast('Ошибка загрузки теста', 'error'); return; }
    }
    ctCurrentTest = testData;
    document.getElementById('ctEditorTitle').innerHTML = `<i class="fas fa-edit" style="color:var(--acc)"></i> Редактор теста: <b>${esc(testData.title)}</b>`;
    document.getElementById('ctEditTitle').value  = testData.title || '';
    document.getElementById('ctEditDesc').value   = testData.description || '';
    document.getElementById('ctEditActive').value = testData.is_active ? '1' : '0';

    renderCtQuestions(testData.questions || []);

    // Прокрутить к редактору
    document.getElementById('ctEditor').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function ctCloseEditor() {
    document.getElementById('ctEditor').style.display = 'none';
    ctCurrentTestId = null;
    ctCurrentTest   = null;
}

async function ctSaveTestInfo() {
    if (!ctCurrentTestId) return;
    const title = document.getElementById('ctEditTitle').value.trim();
    if (!title) { toast('Укажите название', 'warning'); return; }
    const r = await api('PUT', `api/career_test.php?id=${ctCurrentTestId}`, {
        title,
        description: document.getElementById('ctEditDesc').value.trim(),
        is_active:   +document.getElementById('ctEditActive').value,
    });
    if (!r || r.error) { toast(r ? r.error : 'Ошибка обновления', 'error'); return; }
    toast('Тест обновлён');
    loadCareerTests();
    document.getElementById('ctEditorTitle').innerHTML = `<i class="fas fa-edit" style="color:var(--acc)"></i> Редактор теста: <b>${esc(title)}</b>`;
}

async function ctDeleteTest(id, title) {
    if (!confirm(`Удалить тест «${title}» со всеми вопросами и ответами?`)) return;
    const r = await api('DELETE', `api/career_test.php?id=${id}`);
    if (!r || r.error) { toast(r ? r.error : 'Ошибка удаления', 'error'); return; }
    toast('Тест удалён');
    if (ctCurrentTestId === id) ctCloseEditor();
    loadCareerTests();
}

// ═══════════════════════════════════════════════════════
// РЕНДЕР ВОПРОСОВ
// ═══════════════════════════════════════════════════════

function renderCtQuestions(questions) {
    const el = document.getElementById('ctQuestionList');
    const count = questions.length;
    document.getElementById('ctQCount').textContent = count ? `(${count})` : '';

    if (!count) {
        el.innerHTML = `
          <div style="text-align:center;padding:32px;color:var(--txt2);border:2px dashed var(--brd);border-radius:12px">
            <i class="fas fa-question-circle" style="font-size:32px;margin-bottom:8px"></i>
            <p>Вопросов пока нет. Нажмите «Добавить вопрос».</p>
          </div>`;
        return;
    }

    el.innerHTML = questions.map((q, qi) => `
      <div class="ct-question-card" data-qid="${q.id}">
        <!-- Заголовок вопроса -->
        <div style="display:flex;align-items:flex-start;gap:10px;margin-bottom:10px">
          <div style="background:var(--acc);color:#fff;width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;flex-shrink:0">
            ${qi + 1}
          </div>
          <div style="flex:1;font-size:15px;font-weight:600;padding-top:2px">${esc(q.question)}</div>
          <div style="display:flex;gap:6px;flex-shrink:0">
            <button class="btn btn-sm" title="Редактировать вопрос" onclick="ctEditQuestion(${q.id}, ${JSON.stringify(q.question)})">
              <i class="fas fa-pencil-alt"></i>
            </button>
            <button class="btn btn-sm btn-danger" title="Удалить вопрос" onclick="ctDeleteQuestion(${q.id})">
              <i class="fas fa-trash"></i>
            </button>
          </div>
        </div>

        <!-- Ответы -->
        <div class="ct-answers" data-qid="${q.id}" style="margin-left:38px;display:flex;flex-direction:column;gap:6px">
          ${(q.answers || []).map(a => `
            <div class="ct-answer-row" data-aid="${a.id}" style="display:flex;align-items:center;gap:8px;background:var(--bg3);border-radius:8px;padding:8px 12px">
              <div style="flex:1">
                <div style="font-size:14px">${esc(a.text)}</div>
                ${a.specialty_ids && a.specialty_ids.length
                  ? `<div style="font-size:11px;color:var(--txt2);margin-top:2px">
                       <i class="fas fa-tag"></i> ${a.specialty_ids.map(s => esc(s)).join(', ')}
                     </div>`
                  : `<div style="font-size:11px;color:var(--txt3);margin-top:2px"><i class="fas fa-exclamation"></i> Специальности не указаны</div>`}
              </div>
              <button class="btn btn-sm" title="Редактировать ответ" onclick="ctEditAnswer(${a.id}, ${q.id})">
                <i class="fas fa-pencil-alt"></i>
              </button>
              <button class="btn btn-sm btn-danger" title="Удалить ответ" onclick="ctDeleteAnswer(${a.id}, ${q.id})">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          `).join('')}
        </div>

        <!-- Добавить ответ -->
        <div style="margin-left:38px;margin-top:8px">
          <button class="btn btn-sm" onclick="ctOpenAddAnswer(${q.id})">
            <i class="fas fa-plus"></i> Добавить ответ
          </button>
        </div>
      </div>
    `).join('');
}

// ═══════════════════════════════════════════════════════
// ВОПРОСЫ — создание / редактирование
// ═══════════════════════════════════════════════════════

function ctAddQuestion() {
    if (!ctCurrentTestId) return;
    ctEditingQid     = null;
    ctEditingQTestId = ctCurrentTestId;
    document.getElementById('mdCtQTitle').innerHTML = '<i class="fas fa-plus-circle"></i> Новый вопрос';
    document.getElementById('mdCtQText').value = '';
    om('mdCtQuestion');
}

function ctEditQuestion(qid, text) {
    ctEditingQid     = qid;
    ctEditingQTestId = ctCurrentTestId;
    document.getElementById('mdCtQTitle').innerHTML = '<i class="fas fa-edit"></i> Редактировать вопрос';
    document.getElementById('mdCtQText').value = text;
    om('mdCtQuestion');
}

function closeMdCtQuestion() { cm('mdCtQuestion'); }

async function ctSaveQuestion() {
    const text = document.getElementById('mdCtQText').value.trim();
    if (!text) { toast('Введите текст вопроса', 'warning'); return; }

    let r;
    if (ctEditingQid) {
        // Обновление
        r = await api('PUT', `api/career_test.php?action=question_update&qid=${ctEditingQid}`, { question: text });
        if (!r || r.error) { toast(r ? r.error : 'Ошибка обновления вопроса', 'error'); return; }
        toast('Вопрос обновлён');
    } else {
        // Создание
        r = await api('POST', 'api/career_test.php?action=question_create', {
            test_id: ctEditingQTestId,
            question: text,
        });
        if (!r || r.error) { toast(r ? r.error : 'Ошибка создания вопроса', 'error'); return; }
        toast('Вопрос добавлен');
    }
    cm('mdCtQuestion');
    await ctReloadQuestions();
}

async function ctDeleteQuestion(qid) {
    if (!confirm('Удалить вопрос со всеми ответами?')) return;
    const r = await api('DELETE', `api/career_test.php?action=question_delete&qid=${qid}`);
    if (!r || r.error) { toast(r ? r.error : 'Ошибка удаления вопроса', 'error'); return; }
    toast('Вопрос удалён');
    await ctReloadQuestions();
}

// ═══════════════════════════════════════════════════════
// ОТВЕТЫ — создание / редактирование
// ═══════════════════════════════════════════════════════

async function ctOpenAddAnswer(qid) {
    ctEditingAid = null;
    ctEditingAQid = qid;
    document.getElementById('mdCtATitle').innerHTML = '<i class="fas fa-plus-circle"></i> Новый ответ';
    document.getElementById('mdCtAText').value = '';
    await ctLoadSpecsForModal([]);
    om('mdCtAnswer');
}

async function ctEditAnswer(aid, qid) {
    ctEditingAid  = aid;
    ctEditingAQid = qid;
    document.getElementById('mdCtATitle').innerHTML = '<i class="fas fa-edit"></i> Редактировать ответ';

    // Найти ответ в текущем тесте
    let answer = null;
    if (ctCurrentTest) {
        for (const q of ctCurrentTest.questions || []) {
            for (const a of q.answers || []) {
                if (a.id === aid) { answer = a; break; }
            }
        }
    }
    document.getElementById('mdCtAText').value = answer ? answer.text : '';
    await ctLoadSpecsForModal(answer ? (answer.specialty_ids || []) : []);
    om('mdCtAnswer');
}

function closeMdCtAnswer() { cm('mdCtAnswer'); }

async function ctLoadSpecsForModal(selected) {
    const wrap = document.getElementById('mdCtASpecsWrap');
    wrap.innerHTML = '<div class="ldo"><div class="spin" style="width:20px;height:20px;border-width:2px"></div></div>';

    // Загружаем специальности с кэшированием
    if (!ctSpecialties) {
        const r = await api('GET', 'api/specialties.php?limit=200');
        ctSpecialties = (r && r.data) ? r.data : [];
    }

    if (!ctSpecialties.length) {
        wrap.innerHTML = '<p style="color:var(--txt2);font-size:13px">Специальностей нет. Сначала добавьте специальности в разделе «Специальности».</p>';
        return;
    }

    wrap.innerHTML = `
      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:8px;max-height:240px;overflow-y:auto;padding:4px">
        ${ctSpecialties.map(s => `
          <label style="display:flex;align-items:center;gap:8px;cursor:pointer;padding:6px 8px;border-radius:6px;border:1px solid var(--bdr);background:var(--bg3);transition:background .15s"
                 onmouseover="this.style.background='var(--bg4)'" onmouseout="this.style.background='var(--bg3)'">
            <input type="checkbox" class="ct-spec-cb" value="${esc(s.title)}"
                   ${selected.includes(s.title) ? 'checked' : ''}>
            <div>
              <div style="font-size:13px;font-weight:500">${esc(s.title)}</div>
              ${s.code ? `<div style="font-size:11px;color:var(--txt2)">${esc(s.code)}</div>` : ''}
            </div>
          </label>
        `).join('')}
      </div>
      <div style="font-size:12px;color:var(--txt2);margin-top:4px">
        Отмечено: <span id="ctSpecCount">${selected.length}</span>
      </div>`;

    // Счётчик отмеченных
    wrap.querySelectorAll('.ct-spec-cb').forEach(cb => {
        cb.addEventListener('change', () => {
            const cnt = wrap.querySelectorAll('.ct-spec-cb:checked').length;
            const el = document.getElementById('ctSpecCount');
            if (el) el.textContent = cnt;
        });
    });
}

async function ctSaveAnswer() {
    const text = document.getElementById('mdCtAText').value.trim();
    if (!text) { toast('Введите текст ответа', 'warning'); return; }

    const sids = Array.from(document.querySelectorAll('.ct-spec-cb:checked')).map(c => c.value);

    let r;
    if (ctEditingAid) {
        r = await api('PUT', `api/career_test.php?action=answer_update&aid=${ctEditingAid}`, {
            text,
            specialty_ids: sids,
        });
        if (!r || r.error) { toast(r ? r.error : 'Ошибка обновления ответа', 'error'); return; }
        toast('Ответ обновлён');
    } else {
        r = await api('POST', 'api/career_test.php?action=answer_create', {
            question_id: ctEditingAQid,
            text,
            specialty_ids: sids,
        });
        if (!r || r.error) { toast(r ? r.error : 'Ошибка создания ответа', 'error'); return; }
        toast('Ответ добавлен');
    }
    cm('mdCtAnswer');
    await ctReloadQuestions();
}

async function ctDeleteAnswer(aid, qid) {
    if (!confirm('Удалить этот ответ?')) return;
    const r = await api('DELETE', `api/career_test.php?action=answer_delete&aid=${aid}`);
    if (!r || r.error) { toast(r ? r.error : 'Ошибка удаления ответа', 'error'); return; }
    toast('Ответ удалён');
    await ctReloadQuestions();
}

// ═══════════════════════════════════════════════════════
// ВСПОМОГАТЕЛЬНЫЕ
// ═══════════════════════════════════════════════════════

async function ctReloadQuestions() {
    if (!ctCurrentTestId) return;
    const t = await api('GET', `api/career_test.php?id=${ctCurrentTestId}`);
    if (!t || t.error) { toast('Ошибка перезагрузки вопросов', 'error'); return; }
    ctCurrentTest = t;
    renderCtQuestions(t.questions || []);
}

// ═══════════════════════════════════════════════════════
// СТИЛИ для карточек вопросов (инжектируются в head)
// ═══════════════════════════════════════════════════════
(function injectCtStyles() {
    if (document.getElementById('ct-styles')) return;
    const s = document.createElement('style');
    s.id = 'ct-styles';
    s.textContent = `
      .ct-question-card {
        background: var(--bg2);
        border: 1px solid var(--brd);
        border-radius: 12px;
        padding: 16px;
        transition: box-shadow .2s;
      }
      .ct-question-card:hover {
        box-shadow: 0 2px 8px rgba(0,0,0,.08);
      }
      .ct-answer-row {
        transition: background .15s;
      }
      .ct-answer-row:hover {
        background: var(--bg4) !important;
      }
    `;
    document.head.appendChild(s);
})();
