<!-- ═══ MODAL: EDU PROGRAM ═══ -->
<div class="mo" id="mEprog"><div class="modal">
  <div class="mh"><div class="mt" id="mEprogT">Программа обучения</div><button class="mc" onclick="cm('mEprog')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="epId">
    <div class="fr"><label>Название *</label><input class="fc" id="epTit"></div>
    <!-- Тип программы — определяет фильтр «Доп. образование» / «Курсы» в приложении -->
    <div class="fr">
      <label>Тип *</label>
      <select class="fc" id="epForm">
        <option value="additional">Доп. образование</option>
        <option value="courses">Курсы</option>
      </select>
    </div>
    <div class="fr"><label>Описание</label><textarea class="ft" id="epDesc"></textarea></div>

    <!-- Новые поля: Для кого / Что получите / Формат -->
    <div class="fr"><label>Для кого</label><textarea class="ft" id="epForWhom" placeholder="Опишите целевую аудиторию программы"></textarea></div>
    <div class="fr"><label>Что вы получите</label><textarea class="ft" id="epWhatGet" placeholder="Опишите результат обучения"></textarea></div>
    <div class="fr"><label>Формат занятий</label><textarea class="ft" id="epFormatTxt" placeholder="Например: онлайн, очно, смешанный формат"></textarea></div>

    <div class="fg">
      <!-- Срок обучения: тип (годы / часы) + значение -->
      <div class="fr">
        <label>Тип срока</label>
        <select class="fc" id="epDurType" onchange="epToggleDurType()">
          <option value="years">Лет</option>
          <option value="hours">Часов</option>
        </select>
      </div>
      <div class="fr" id="epDurYearsRow"><label>Срок (лет)</label><input class="fc" id="epDurYears" type="number" step="0.5" min="0" placeholder="1"></div>
      <div class="fr" id="epDurHoursRow" style="display:none"><label>Срок (часов)</label><input class="fc" id="epDurHours" type="number" step="1" min="0" placeholder="72"></div>

      <div class="fr"><label>Стоимость</label><input class="fc" id="epPrc" placeholder="5 000 ₽"></div>
      <!-- Изображение с кроппером -->
      <div class="fr">
        <label>Изображение</label>
        <div style="display:flex;gap:6px;align-items:center">
          <input class="fc" id="epImg" placeholder="https://... или загрузите файл" style="flex:1">
          <button type="button" class="btn btn-sec btn-sm" title="Загрузить с диска"
                  onclick="openCropper('epImg',{title:'Изображение программы',ratio:4/3})">
            <i class="fas fa-upload"></i>
          </button>
        </div>
      </div>
      <div class="fr"><label>Порядок</label><input type="number" class="fc" id="epOrd" value="0"></div>
    </div>
    <div class="fchk"><input type="checkbox" id="epPub" checked><label for="epPub">Опубликовано</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mEprog')">Отмена</button>
    <button class="btn btn-primary" onclick="saveEduProg()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>