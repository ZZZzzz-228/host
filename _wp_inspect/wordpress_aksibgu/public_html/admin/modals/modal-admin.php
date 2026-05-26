<!-- ═══ MODAL: ADMIN USER ═══ -->
<div class="mo" id="mAdmin"><div class="modal">
  <div class="mh"><div class="mt" id="mAdminT">Администратор</div><button class="mc" onclick="cm('mAdmin')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="adId">
    <div class="fg">
      <div class="fr"><label>Логин *</label><input class="fc" id="adLg" autocomplete="off"></div>
      <div class="fr"><label>Пароль <span id="adPwHint">(обязателен)</span></label><input type="password" class="fc" id="adPw" autocomplete="new-password" placeholder="Мин. 8 символов"></div>
      <div class="fr"><label>ФИО</label><input class="fc" id="adNm"></div>
      <div class="fr"><label>Email</label><input type="email" class="fc" id="adEm"></div>
      <div class="fr"><label>Роль</label>
        <select class="fs" id="adRl">
          <option value="editor">Редактор</option>
          <option value="moderator">Модератор</option>
          <option value="career_manager">Менеджер карьера</option>
          <option value="admin">Администратор</option>
          <option value="superadmin">Суперадмин</option>
        </select>
      </div>
    </div>
    <div class="fchk"><input type="checkbox" id="adAct" checked><label for="adAct">Активен</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mAdmin')">Отмена</button>
    <button class="btn btn-primary" onclick="saveAdmin()"><i class="fas fa-save"></i>Сохранить</button>
  </div>
</div></div>
