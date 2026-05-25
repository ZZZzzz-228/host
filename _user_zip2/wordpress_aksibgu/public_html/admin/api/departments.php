<?php
/**
 * API: departments
 * GET    ?page=&limit=&search=&is_active=
 * GET    ?id=
 * GET    ?all=1  (для select-опций)
 * POST / PUT ?id= / PATCH ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function deptFields(array $d): array {
    return [
        'name'        => trim($d['name']       ?? ''),
        'short_name'  => trim($d['short_name'] ?? ''),
        'code'        => trim($d['code']       ?? ''),
        'description' => $d['description']     ?? '',
        'head_name'   => trim($d['head_name']  ?? ''),
        'head_title'  => trim($d['head_title'] ?? ''),
        'email'       => trim($d['email']      ?? ''),
        'phone'       => trim($d['phone']      ?? ''),
        'room'        => trim($d['room']       ?? ''),
        'schedule'    => trim($d['schedule']   ?? ''),
        'photo_url'   => trim($d['photo_url']  ?? ''),
        'sort_order'  => isset($d['sort_order']) ? (int)$d['sort_order'] : 0,
        'is_active'   => isset($d['is_active'])  ? (int)(bool)$d['is_active'] : 1,
    ];
}

if ($method === 'GET') {
    if (!empty($_GET['all'])) {
        $rows=$pdo->query("SELECT id, name, short_name FROM departments WHERE is_active=1 ORDER BY sort_order ASC, name ASC")->fetchAll(PDO::FETCH_ASSOC);
        json($rows);
    }

    if (!empty($_GET['id'])) {
        $st=$pdo->prepare("SELECT * FROM departments WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??50)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(name LIKE ? OR head_name LIKE ? OR email LIKE ?)";
        $params=array_merge($params,[$s,$s,$s]);
    }
    if(isset($_GET['is_active'])&&$_GET['is_active']!=='') { $where[]="is_active=?"; $params[]=(int)$_GET['is_active']; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM departments WHERE $ws");
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare("SELECT * FROM departments WHERE $ws ORDER BY sort_order ASC, name ASC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d=jsonBody(); $f=deptFields($d);
    if(!$f['name']) { http_response_code(422); json(['error'=>'Название кафедры обязательно']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO departments (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->execute();
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','departments',$newId,"Создана кафедра: {$f['name']}");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM departments WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=deptFields($d);
    if(!$f['name']) { http_response_code(422); json(['error'=>'Название кафедры обязательно']); }
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE departments SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();
    adminLog($pdo,'update','departments',$id,"Обновлена кафедра: {$f['name']}");
    $row=$pdo->prepare("SELECT * FROM departments WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_active','sort_order']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE departments SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row=$pdo->prepare("SELECT * FROM departments WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT name FROM departments WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM departments WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','departments',$id,"Удалена кафедра: {$row['name']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);