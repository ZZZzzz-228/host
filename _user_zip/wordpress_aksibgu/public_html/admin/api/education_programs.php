<?php
/**
 * API: education_programs
 * GET    ?page=&limit=&search=&specialty_id=&is_active=
 * GET    ?id=
 * POST / PUT ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function epFields(array $d): array {
    return [
        'specialty_id'   => !empty($d['specialty_id'])  ? (int)$d['specialty_id']  : null,
        'title'          => trim($d['title']             ?? ''),
        'code'           => trim($d['code']              ?? ''),
        'form'           => trim($d['form']              ?? 'full-time'),
        'duration_years' => isset($d['duration_years']) && $d['duration_years'] !== null && $d['duration_years'] !== '' ? (float)$d['duration_years'] : null,
        'duration_hours' => isset($d['duration_hours']) && $d['duration_hours'] !== null && $d['duration_hours'] !== '' ? (int)$d['duration_hours'] : null,
        'duration_type'  => in_array($d['duration_type'] ?? '', ['years','hours']) ? $d['duration_type'] : 'years',
        'description'    => $d['description']            ?? '',
        'for_whom'       => $d['for_whom']               ?? '',
        'what_you_get'   => $d['what_you_get']           ?? '',
        'format_text'    => $d['format_text']            ?? '',
        'admission_info' => $d['admission_info']         ?? '',
        'budget_places'  => isset($d['budget_places'])   ? (int)$d['budget_places']  : null,
        'paid_places'    => isset($d['paid_places'])     ? (int)$d['paid_places']    : null,
        'tuition_cost'   => isset($d['tuition_cost'])    ? (float)$d['tuition_cost'] : null,
        // image_url добавляется динамически ниже
        'is_active'      => isset($d['is_active'])       ? (int)(bool)$d['is_active'] : 1,
        'sort_order'     => isset($d['sort_order'])      ? (int)$d['sort_order']      : 0,
    ];
}

if ($method === 'GET') {
    // Авто-миграция: добавляем новые колонки если их нет
    try {
        $cols = array_column($pdo->query("SHOW COLUMNS FROM `education_programs`")->fetchAll(PDO::FETCH_ASSOC), 'Field');
        $migs = [
            'for_whom'      => "ALTER TABLE `education_programs` ADD COLUMN `for_whom` TEXT COLLATE utf8mb4_unicode_ci NULL AFTER `description`",
            'what_you_get'  => "ALTER TABLE `education_programs` ADD COLUMN `what_you_get` TEXT COLLATE utf8mb4_unicode_ci NULL AFTER `for_whom`",
            'format_text'   => "ALTER TABLE `education_programs` ADD COLUMN `format_text` TEXT COLLATE utf8mb4_unicode_ci NULL AFTER `what_you_get`",
            'duration_hours'=> "ALTER TABLE `education_programs` ADD COLUMN `duration_hours` INT NULL AFTER `duration_years`",
            'duration_type' => "ALTER TABLE `education_programs` ADD COLUMN `duration_type` ENUM('years','hours') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'years' AFTER `duration_hours`",
        ];
        foreach ($migs as $col => $sql) {
            if (!in_array($col, $cols)) { try { $pdo->exec($sql); } catch (\Exception $e) {} }
        }
    } catch (\Exception $e) {}

    if (!empty($_GET['id'])) {
        $st = $pdo->prepare(
            "SELECT ep.*, s.title as specialty_title, s.code as specialty_code
             FROM education_programs ep
             LEFT JOIN specialties s ON s.id=ep.specialty_id
             WHERE ep.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page = max(1,(int)($_GET['page'] ?? 1));
    $limit = min(200,max(1,(int)($_GET['limit'] ?? 20)));
    $offset = ($page-1)*$limit;

    $where=['1=1']; $params=[];
    if (!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[] = "(ep.title LIKE ? OR ep.code LIKE ?)";
        $params = array_merge($params,[$s,$s]);
    }
    if (!empty($_GET['specialty_id'])) { $where[] = "ep.specialty_id=?"; $params[] = (int)$_GET['specialty_id']; }
    if (isset($_GET['is_active']) && $_GET['is_active']!=='') { $where[] = "ep.is_active=?"; $params[] = (int)$_GET['is_active']; }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM education_programs ep WHERE $ws");
    $tcnt->execute($params);
    $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare(
        "SELECT ep.*, s.title as specialty_title FROM education_programs ep
         LEFT JOIN specialties s ON s.id=ep.specialty_id
         WHERE $ws ORDER BY ep.sort_order ASC, ep.title ASC LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d = jsonBody(); $f = epFields($d);
    // Убираем комментарий-заглушку
    unset($f['// image_url добавляется динамически ниже']);
    // Добавляем image_url если передан
    $imgUrl = trim($d['image_url'] ?? '');
    if ($imgUrl) $f['image_url'] = $imgUrl;
    if (!$f['title']) { http_response_code(422); json(['error'=>'Название обязательно']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO education_programs (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    try {
        $st->execute();
    } catch(PDOException $e) {
        // Если колонка image_url отсутствует — повторяем без неё
        if (str_contains($e->getMessage(), 'image_url') || str_contains($e->getMessage(), 'Unknown column')) {
            unset($f['image_url']);
            $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
            $st2=$pdo->prepare("INSERT INTO education_programs (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
            foreach($f as $k=>$v) $st2->bindValue(":$k",$v);
            $st2->execute();
        } else {
            http_response_code(500); json(['error'=>$e->getMessage()]);
        }
    }
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','education_programs',$newId,"Создана программа: {$f['title']}");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM education_programs WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if (!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=epFields($d);
    unset($f['// image_url добавляется динамически ниже']);
    $imgUrl = trim($d['image_url'] ?? '');
    if ($imgUrl) $f['image_url'] = $imgUrl;
    if (!$f['title']) { http_response_code(422); json(['error'=>'Название обязательно']); }
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE education_programs SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id);
    try {
        $st->execute();
    } catch(PDOException $e) {
        if (str_contains($e->getMessage(), 'image_url') || str_contains($e->getMessage(), 'Unknown column')) {
            unset($f['image_url']);
            $set2=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
            $st2=$pdo->prepare("UPDATE education_programs SET $set2, updated_at=NOW() WHERE id=:id");
            foreach($f as $k=>$v) $st2->bindValue(":$k",$v);
            $st2->bindValue(':id',$id); $st2->execute();
        } else {
            http_response_code(500); json(['error'=>$e->getMessage()]);
        }
    }
    adminLog($pdo,'update','education_programs',$id,"Обновлена программа: {$f['title']}");
    $row=$pdo->prepare("SELECT * FROM education_programs WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if (!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_active','sort_order']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE education_programs SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row=$pdo->prepare("SELECT * FROM education_programs WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if (!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT title FROM education_programs WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM education_programs WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','education_programs',$id,"Удалена программа: {$row['title']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);