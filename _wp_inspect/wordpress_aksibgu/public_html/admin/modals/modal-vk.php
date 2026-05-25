<!-- ═══ MODAL: VK APPROVE ═══ -->
<div class="mo" id="mVkApp"><div class="modal mlg">
  <div class="mh"><div class="mt">Одобрить пост ВК</div><button class="mc" onclick="cm('mVkApp')"><i class="fas fa-times"></i></button></div>
  <div class="mb">
    <input type="hidden" id="vkAId">
    <div class="fr"><label>Заголовок *</label><input class="fc" id="vkATit" placeholder="Заголовок истории"></div>
    <div class="fr"><label>Текст</label><textarea class="ft" id="vkACnt" style="min-height:110px"></textarea></div>
    <div class="fr"><label>Выберите фото (можно несколько)</label><div id="vkAPhotos" class="vk-photos"></div></div>
    <div class="fchk"><input type="checkbox" id="vkAPubNow" checked><label for="vkAPubNow">Опубликовать сразу</label></div>
  </div>
  <div class="mf">
    <button class="btn btn-sec" onclick="cm('mVkApp')">Отмена</button>
    <button class="btn btn-danger" onclick="vkReject(document.getElementById('vkAId').value)"><i class="fas fa-ban"></i>Отклонить</button>
    <button class="btn btn-primary" onclick="vkApprove()"><i class="fas fa-check"></i>Одобрить</button>
  </div>
</div></div>
