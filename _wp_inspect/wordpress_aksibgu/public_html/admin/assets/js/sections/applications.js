/* ── APPLICATIONS ─────────────────────────────────────────────── */
let aP = 1;
async function loadApps(){
    const q=v('apSrch'),st=$('apSt').value,tp=$('apTp').value,df=$('apDf').value,dt=$('apDt').value;
    let u=`api/applications.php?page=${aP}&limit=25`;
    if(q)u+='&q='+encodeURIComponent(q);if(st)u+='&status='+st;if(tp)u+='&type='+tp;if(df)u+='&date_from='+df;if(dt)u+='&date_to='+dt;
    const r=await api('GET',u);const d=r&&r.data?r.data:[];const tot=r&&r.total?r.total:0;
    $('apTotal').textContent=`Всего: ${tot}`;
    const sc={new:'bw',processing:'bi',approved:'bs',rejected:'bd',archived:'bm'};
    const sr={new:'Новая',processing:'В работе',approved:'Принята',rejected:'Отклонена',archived:'Архив'};
    $('apTb').innerHTML=d.length?d.map(a=>`<tr>
        <td>${a.status==='new'?`<input class="ap-ck" type="checkbox" value="${a.id}">`:''}</td>
        <td>${a.id}</td><td>${fd(a.created_at)}</td><td><strong>${esc(a.full_name)}</strong></td>
        <td>${esc(a.email)}</td><td>${esc(a.phone||'')}</td>
        <td>${bdg(sr[a.status]||a.status,sc[a.status]||'bm')}</td>
        <td>${a.type==='courses'?'Курсы':'Документы'}</td>
        <td><div class="tbl-act">
            <button class="btn btn-info btn-sm btn-ico" onclick="viewApp(${a.id})" title="Просмотр"><i class="fas fa-eye"></i></button>
            ${a.status==='new'?`<button class="btn btn-warn btn-sm btn-ico" onclick="setAppSt(${a.id},'processing')"><i class="fas fa-play"></i></button>`:''}
            ${a.status!=='archived'?`<button class="btn btn-sec btn-sm btn-ico" onclick="setAppSt(${a.id},'archived')"><i class="fas fa-archive"></i></button>`:''}
            <button class="btn btn-danger btn-sm btn-ico" onclick="delApp(${a.id})"><i class="fas fa-trash"></i></button>
        </div></td></tr>`).join(''):empty('Заявок нет');
    $('apPgn').innerHTML=pgn(tot,aP,25,'goAP');
}
function goAP(p){aP=p;loadApps();}
$('apSrch').addEventListener('input',()=>{aP=1;loadApps();});

async function viewApp(id){
    // Сервер возвращает объект напрямую (без обёртки data)
    const r=await api('GET',`api/applications.php?id=${id}`);
    const a=r&&r.data?r.data:(r&&r.id?r:null);
    if(!a)return;
    const sr={new:'Новая',processing:'В работе',approved:'Принята',rejected:'Отклонена',archived:'Архив'};
    let pl='';
    try{
        const p=typeof a.payload_json==='string'?JSON.parse(a.payload_json):a.payload_json;
        if(p&&Object.keys(p).length){
            const labels={
                program_title:'Программа',
                preferred_messenger:'Предпочтительный мессенджер',
                specialties:'Специальности',
                attached_file_names:'Прикреплённые файлы'
            };
            const messengerLabels={
                whatsapp:'WhatsApp',telegram:'Telegram',vk:'ВКонтакте',
                viber:'Viber',phone:'Телефонный звонок',odfp:'Без мессенджера'
            };
            let rows='';
            for(const[k,val]of Object.entries(p)){
                const label=labels[k]||k;
                let display='';
                if(Array.isArray(val)){
                    display=val.length?val.map(v=>`<span style="display:inline-block;background:var(--bg2);border-radius:6px;padding:2px 10px;margin:2px 4px 2px 0;font-size:13px">${esc(String(v))}</span>`).join(''):'—';
                }else if(k==='preferred_messenger'){
                    display=esc(messengerLabels[val]||val||'—');
                }else{
                    display=esc(String(val||'—'));
                }
                rows+=`<div style="display:flex;gap:8px;align-items:baseline;padding:6px 0;border-bottom:1px solid var(--brd)">
                    <span style="min-width:200px;font-weight:600;color:var(--txt2);font-size:13px">${esc(label)}</span>
                    <span style="font-size:14px;flex:1">${display}</span>
                </div>`;
            }
            pl=`<div style="margin-top:14px;border:1px solid var(--brd);border-radius:10px;padding:4px 14px 2px">${rows}</div>`;
        }
    }catch(e){}
    $('mAppBody').innerHTML=`<div class="fg">
        <div><b>ФИО:</b><br>${esc(a.full_name)}</div><div><b>Email:</b><br>${esc(a.email||'—')}</div>
        <div><b>Телефон:</b><br>${esc(a.phone||'—')}</div>
        <div><b>Статус:</b><br>${sr[a.status]||a.status}</div><div><b>Тип:</b><br>${a.type==='courses'?'Курсы':'Документы'}</div>
        <div><b>Создана:</b><br>${fd(a.created_at)}</div><div><b>Обновлена:</b><br>${fd(a.updated_at)}</div>
    </div>${a.notes?`<div style="margin-top:10px"><b>Заметки:</b><br>${esc(a.notes)}</div>`:''}${pl}`;
    $('mAppFoot').innerHTML=`
        <select class="fs" id="appStSel" style="max-width:150px">
            <option value="new">Новая</option><option value="processing">В работе</option>
            <option value="approved">Принята</option><option value="rejected">Отклонена</option><option value="archived">Архив</option>
        </select>
        <input class="fc" id="appRej" placeholder="Причина отказа" style="max-width:200px">
        <button class="btn btn-sec" onclick="cm('mApp')">Закрыть</button>
        <button class="btn btn-primary" onclick="chgAppSt(${id})"><i class="fas fa-save"></i>Изменить</button>`;
    $('appStSel').value=a.status;
    om('mApp');
}

async function chgAppSt(id){
    // PATCH возвращает обновлённый объект заявки (без success:true)
    const r=await api('PATCH',`api/applications.php?id=${id}`,{status:$('appStSel').value,rejection_reason:v('appRej')||null});
    if(r&&(r.id||r.success)){toast('Статус обновлён');cm('mApp');loadApps();}
    else toast(r&&(r.error||r.message)||'Ошибка','error');
}

async function setAppSt(id,st){
    // PATCH возвращает обновлённый объект заявки (без success:true)
    const r=await api('PATCH',`api/applications.php?id=${id}`,{status:st});
    if(r&&(r.id||r.success)){toast('Обновлено');loadApps();}
    else toast(r&&(r.error||r.message)||'Ошибка','error');
}

async function delApp(id){
    if(!confirm('Удалить?'))return;
    // DELETE возвращает 204 (null)
    const r=await api('DELETE',`api/applications.php?id=${id}`);
    if(r===null||r&&r.success){toast('Удалено');loadApps();}
    else toast(r&&(r.error||r.message)||'Ошибка','error');
}

async function bulkApps(){
    const ids=[...document.querySelectorAll('.ap-ck:checked')].map(e=>+e.value);
    if(!ids.length){toast('Выберите заявки','warning');return;}
    // Сервер ожидает ?action=bulk_status в URL и {ids, status} в теле
    const r=await api('POST','api/applications.php?action=bulk_status',{ids,status:'processing'});
    if(r&&(r.updated||r.success)){toast(`Переведено: ${r.updated||ids.length}`);loadApps();}
    else toast(r&&(r.error||r.message)||'Ошибка','error');
}

function togAllApps(el){document.querySelectorAll('.ap-ck').forEach(c=>c.checked=el.checked);}
function exportApps(){const st=$('apSt').value,tp=$('apTp').value;let u='api/applications.php?export=csv';if(st)u+='&status='+st;if(tp)u+='&type='+tp;window.open(u,'_blank');}