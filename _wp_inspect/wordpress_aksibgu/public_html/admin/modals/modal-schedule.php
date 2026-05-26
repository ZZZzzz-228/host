<!-- ═══ MODAL: SCHEDULE ═══ -->
<div class="mo" id="mSched"><div class="modal">
  <div class="mh"><div class="mt" id="mSchedT">Занятие</div><button class="mc" onclick="cm('mSched')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="scId">
    <div class="fg">
      <div class="fr"><label>Группа *</label><input class="fc" id="scGr" placeholder="ИС-21"></div>
      <div class="fr"><label>День *</label>
        <select class="fs" id="scDay">
          <option value="1">Понедельник</option>
          <option value="2">Вторник</option>
          <option value="3">Среда</option>
          <option value="4">Четверг</option>
          <option value="5">Пятница</option>
          <option value="6">Суббота</option>
        </select>
      </div>
      <div class="fr"><label>Пара</label><input type="number" class="fc" id="scLes" min="1" max="8" value="1"></div>
      <div class="fr"><label>Начало</label><input type="time" class="fc" id="scTS"></div>
      <div class="fr"><label>Конец</label><input type="time" class="fc" id="scTE"></div>
      <div class="fr"><label>Тип недели</label>
        <select class="fs" id="scWk">
          <option value="all">Каждую</option>
          <option value="odd">Нечётная</option>
          <option value="even">Чётная</option>
        </select>
      </div>
    </div>
    <div class="fr"><label>Предмет *</label><input class="fc" id="scSbj" placeholder="Название предмета"></div>
    <div class="fg">
      <div class="fr"><label>Преподаватель</label><input class="fc" id="scTch"></div>
      <div class="fr"><label>Аудитория</label><input class="fc" id="scRm"></div>
    </div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mSched')">Отмена</button>
    <button class="btn btn-primary" onclick="saveSched()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
