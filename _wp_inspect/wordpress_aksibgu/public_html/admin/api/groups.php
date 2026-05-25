<?php
/**
 * API: groups_ref
 * GET    ?page=&limit=&search=&specialty_id=&study_year=&is_active=
 * GET    ?id=
 * GET    ?all=1  (для select-опций)
 * POST / PUT ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function groupFields(array $d): array {
    return [
        'name'           => trim($d['name']          ?? ''),
        'short_name'     => trim($d['short_name']    ?? ''),
        'specialty_id'   => !empty($d['specialty_id'])  ? (int)$d['specialty_id']  : null,
        'study_year'     => isset($d['study_year'])     ? (int)$d['study_year']     : 1,
        'education_form' => trim($d['education_form']   ?? 'full-time'),
        'curator_id'     => !empty($d['curator_id'])    ? (int)$d['curator_id']     : null,
        'students_count' => isset($d['students_count']) ? (int)$d['students_count'] : 0,
        'is_active'      => isset($d['is_active'])      ? (int)(bool)$d['is_active'] : 1,
    ];
}

if ($method === 'GET') {
    // All for dropdowns
    if (!empty($_GET['all'])) {
        $rows = $pdo->query(
            "SELECT g.id, g.name, g.short_name, g.study_year, s.title as specialty_title
             FROM groups_ref g
             LEFT JOIN specialties s ON s.id=g.specialty_id
             WHERE g.is_active=1 ORDER BY g.study_year ASC, g.name ASC"
        )->fetchAll(PDO::FETCH_ASSOC);
        json($rows);
    }

    if (!empty($_GET['id'])) {
        $st = $pdo->prepare(
            "SELECT g.*, s.title as specialty_title, sm.full_name as curator_name
             FROM groups_ref g
             LEFT JOIN specialties s ON s.id=g.specialty_id
             LEFT JOIN staff_members sm ON sm.id=g.curator_id
             WHERE g.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page = max(1,(int)($_GET['page']??1));
    $limit = min(200,max(1,(int)($_GET['limit']??50)));
    $offset = ($page-1)*$limit;

    $where=['1=1']; $params=[];
    if (!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[] = "(g.name LIKE ? OR g.short_name LIKE ?)";
        $params = array_merge($params,[$s,$s]);
    }
    if (!empty($_GET['specialty_id'])) { $where[]="g.specialty_id=?"; $params[]=(int)$_GET['specialty_id']; }
    if (!empty($_GET['study_year']))   { $where[]="g.study_year=?";   $params[]=(int)$_GET['study_year'];   }
    if (isset($_GET['is_active']) && $_GET['is_active']!=='') { $where[]="g.is_active=?"; $params[]=(int)$_GET['is_active']; }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM groups_ref g WHERE $ws");
    $tcnt->execute($params);
    $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare(
        "SELECT g.*, s.title as specialty_title, sm.full_name as curator_name
         FROM groups_ref g
         LEFT JOIN specialties s ON s.id=g.specialty_id
         LEFT JOIN staff_members sm ON sm.id=g.curator_id
         WHERE $ws ORDER BY g.study_year ASC, g.name ASC LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d=jsonBody(); $f=groupFields($d);
    if (!$f['name']) { http_response_code(422); json(['error'=>'Название группы обязательно']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO groups_ref (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->execute();
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','groups_ref',$newId,"Создана группа: {$f['name']}");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM groups_ref WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=groupFields($d);
    if(!$f['name']) { http_response_code(422); json(['error'=>'Название группы обязательно']); }
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE groups_ref SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();
    adminLog($pdo,'update','groups_ref',$id,"Обновлена группа: {$f['name']}");
    $row=$pdo->prepare("SELECT * FROM groups_ref WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_active','study_year','students_count']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE groups_ref SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row=$pdo->prepare("SELECT * FROM groups_ref WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT name FROM groups_ref WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM groups_ref WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','groups_ref',$id,"Удалена группа: {$row['name']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);