<!-- ═══ VK ═══ -->
<section class="sec" id="s-vk">
  <div class="card" style="margin-bottom:14px;background:rgba(76,117,163,.08);border-color:rgba(76,117,163,.25)">
    <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
      <div style="flex:1;min-width:220px">
        <div style="font-size:13px;font-weight:600;color:var(--txt);margin-bottom:4px">
          <i class="fab fa-vk" style="color:#4c75a3"></i>
           Публикации с группы ВКонтакте.: <a href="https://vk.com/media_ak" target="_blank" style="color:#4c75a3">vk.com/media_ak</a>
        </div>
        <div style="font-size:11.5px;color:var(--txt3)">
          Сбор новых постов и сохранение их в базу для проверки.
        </div>
      </div>
      <div style="display:flex;gap:7px;flex-wrap:wrap">
        <button class="btn btn-info" onclick="runParser()"><i class="fas fa-play"></i>Запустить парсер</button>
        <button class="btn btn-sec" onclick="loadVK()"><i class="fas fa-sync"></i>Обновить</button>
      </div>
    </div>
  </div>
  <div class="card">
    <div class="card-hd">
      <div>
        <div class="card-title"><i class="fab fa-vk" style="color:#4c75a3"></i> ВКонтакте — очередь модерации</div>
        <div class="card-sub">Посты из группы, ожидающие публикации как Истории</div>
      </div>
    </div>
    <div id="vkList"><div class="ldo"><div class="spin"></div></div></div>
  </div>
</section>