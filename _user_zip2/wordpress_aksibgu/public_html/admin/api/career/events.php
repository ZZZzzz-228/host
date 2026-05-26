<?php
/**
 * API: career_events
 * GET    ?page=&limit=&search=&is_published=&event_type=&date_from=&date_to=
 * GET    ?id=
 * POST / PUT ?id= / PATCH ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function ceFields(array $d): array {
    return [
        'title'        => trim($d['title']        ?? ''),
        'description'  => $d['description']       ?? '',
        'event_type'   => trim($d['event_type']   ?? 'general'),
        'location'     => trim($d['location']     ?? ''),
        'is_online'    => isset($d['is_online'])  ? (int)(bool)$d['is_online']    : 0,
        'online_url'   => trim($d['online_url']   ?? ''),
        'cover_image'  => trim($d['cover_image']  ?? ''),
        'organizer'    => trim($d['organizer']    ?? ''),
        'partner_id'   => !empty($d['partner_id']) ? (int)$d['partner_id'] : null,
        'starts_at'    => !empty($d['starts_at']) ? $d['starts_at'] : null,
        'ends_at'      => !empty($d['ends_at'])   ? $d['ends_at']   : null,
        'registration_url' => trim($d['registration_url'] ?? ''),
        'max_participants' => isset($d['max_participants']) ? (int)$d['max_participants'] : null,
        'is_published' => isset($d['is_published']) ? (int)(bool)$d['is_published'] : 0,
        'sort_order'   => isset($d['sort_order'])   ? (int)$d['sort_order']         : 0,
    ];
}

if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT ce.*, p.name as partner_name FROM career_events ce
             LEFT JOIN partners p ON p.id=ce.partner_id
             WHERE ce.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??20)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(ce.title LIKE ? OR ce.description LIKE ? OR ce.organizer LIKE ?)";
        $params=array_merge($params,[$s,$s,$s]);
    }
    if(isset($_GET['is_published'])&&$_GET['is_published']!=='') { $where[]="ce.is_published=?"; $params[]=(int)$_GET['is_published']; }
    if(!empty($_GET['event_type'])) { $where[]="ce.event_type=?"; $params[]=$_GET['event_type']; }
    if(!empty($_GET['date_from'])) { $where[]="ce.starts_at >= ?"; $params[]=$_GET['date_from']; }
    if(!empty($_GET['date_to']))   { $where[]="ce.starts_at <= ?"; $params[]=$_GET['date_to'].' 23:59:59'; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM career_events ce WHERE $ws");
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT ce.*, p.name as partner_name FROM career_events ce
         LEFT JOIN partners p ON p.id=ce.partner_id
         WHERE $ws ORDER BY ce.starts_at DESC, ce.sort_order ASC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d=jsonBody(); $f=ceFields($d);
    if(!$f['title']) { http_response_code(422); json(['error'=>'Название мероприятия обязательно']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO career_events (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->execute();
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','career_events',$newId,"Создано мероприятие: {$f['title']}");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM career_events WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=ceFields($d);
    if(!$f['title']) { http_response_code(422); json(['error'=>'Название мероприятия обязательно']); }
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE career_events SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();
    adminLog($pdo,'update','career_events',$id,"Обновлено мероприятие: {$f['title']}");
    $row=$pdo->prepare("SELECT * FROM career_events WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_published','is_online','sort_order']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE career_events SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row=$pdo->prepare("SELECT * FROM career_events WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT title FROM career_events WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM career_events WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','career_events',$id,"Удалено мероприятие: {$row['title']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);