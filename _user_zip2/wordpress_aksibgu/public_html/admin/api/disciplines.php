<?php
/**
 * API: disciplines
 * GET    ?page=&limit=&search=&department_id=&is_active=
 * GET    ?id=
 * GET    ?all=1  (для select-опций)
 * POST / PUT ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function discFields(array $d): array {
    return [
        'name'          => trim($d['name']         ?? ''),
        'short_name'    => trim($d['short_name']   ?? ''),
        'code'          => trim($d['code']         ?? ''),
        'description'   => $d['description']       ?? '',
        'department_id' => !empty($d['department_id']) ? (int)$d['department_id'] : null,
        'hours_total'   => isset($d['hours_total']) ? (int)$d['hours_total'] : null,
        'hours_lecture' => isset($d['hours_lecture'])? (int)$d['hours_lecture'] : null,
        'hours_practice'=> isset($d['hours_practice'])?(int)$d['hours_practice']: null,
        'form_control'  => trim($d['form_control'] ?? 'exam'),
        'is_active'     => isset($d['is_active'])  ? (int)(bool)$d['is_active'] : 1,
        'sort_order'    => isset($d['sort_order']) ? (int)$d['sort_order'] : 0,
    ];
}

if ($method === 'GET') {
    if (!empty($_GET['all'])) {
        $rows = $pdo->query(
            "SELECT id, name, short_name, code FROM disciplines WHERE is_active=1 ORDER BY name ASC"
        )->fetchAll(PDO::FETCH_ASSOC);
        json($rows);
    }

    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT d.*, dep.name as department_name FROM disciplines d
             LEFT JOIN departments dep ON dep.id=d.department_id
             WHERE d.id=? LIMIT 1"
        );
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
        $where[]="(d.name LIKE ? OR d.code LIKE ?)";
        $params=array_merge($params,[$s,$s]);
    }
    if(!empty($_GET['department_id'])) { $where[]="d.department_id=?"; $params[]=(int)$_GET['department_id']; }
    if(isset($_GET['is_active'])&&$_GET['is_active']!=='') { $where[]="d.is_active=?"; $params[]=(int)$_GET['is_active']; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM disciplines d WHERE $ws");
    $tcnt->execute($params);
    $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT d.*, dep.name as department_name FROM disciplines d
         LEFT JOIN departments dep ON dep.id=d.department_id
         WHERE $ws ORDER BY d.sort_order ASC, d.name ASC LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d=jsonBody(); $f=discFields($d);
    if(!$f['name']) { http_response_code(422); json(['error'=>'Название дисциплины обязательно']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO disciplines (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->execute();
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','disciplines',$newId,"Создана дисциплина: {$f['name']}");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM disciplines WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=discFields($d);
    if(!$f['name']) { http_response_code(422); json(['error'=>'Название дисциплины обязательно']); }
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE disciplines SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();
    adminLog($pdo,'update','disciplines',$id,"Обновлена дисциплина: {$f['name']}");
    $row=$pdo->prepare("SELECT * FROM disciplines WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT name FROM disciplines WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM disciplines WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','disciplines',$id,"Удалена дисциплина: {$row['name']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);