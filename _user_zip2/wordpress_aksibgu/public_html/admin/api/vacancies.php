<?php
/**
 * API: vacancies
 * GET    ?page=&limit=&search=&partner_id=&is_active=&category=
 * GET    ?id=
 * POST / PUT ?id= / PATCH ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function vacancyFields(array $d): array {
    return [
        'title'           => trim($d['title']           ?? ''),
        'company_name'    => trim($d['company_name']    ?? ''),
        'partner_id'      => !empty($d['partner_id'])   ? (int)$d['partner_id'] : null,
        'category'        => trim($d['category']        ?? 'general'),
        'description'     => $d['description']          ?? '',
        'requirements'    => $d['requirements']         ?? '',
        'conditions'      => $d['conditions']           ?? '',
        'salary_from'     => isset($d['salary_from'])   ? (int)$d['salary_from'] : null,
        'salary_to'       => isset($d['salary_to'])     ? (int)$d['salary_to']   : null,
        'salary_currency' => trim($d['salary_currency'] ?? 'RUB'),
        'employment_type' => trim($d['employment_type'] ?? 'full-time'),
        'experience'      => trim($d['experience']      ?? ''),
        'location'        => trim($d['location']        ?? ''),
        'contact_name'    => trim($d['contact_name']    ?? ''),
        'contact_email'   => trim($d['contact_email']   ?? ''),
        'contact_phone'   => trim($d['contact_phone']   ?? ''),
        'apply_url'       => trim($d['apply_url']       ?? ''),
        'is_active'       => isset($d['is_active'])     ? (int)(bool)$d['is_active'] : 1,
        'is_featured'     => isset($d['is_featured'])   ? (int)(bool)$d['is_featured'] : 0,
        'expires_at'      => !empty($d['expires_at'])   ? $d['expires_at'] : null,
        'sort_order'      => isset($d['sort_order'])    ? (int)$d['sort_order'] : 0,
    ];
}

if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT v.*, p.name as partner_name FROM vacancies v
             LEFT JOIN partners p ON p.id=v.partner_id
             WHERE v.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??25)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(v.title LIKE ? OR v.company_name LIKE ? OR v.location LIKE ?)";
        $params=array_merge($params,[$s,$s,$s]);
    }
    if(!empty($_GET['partner_id'])) { $where[]="v.partner_id=?"; $params[]=(int)$_GET['partner_id']; }
    if(!empty($_GET['category']))   { $where[]="v.category=?";   $params[]=$_GET['category'];       }
    if(isset($_GET['is_active'])&&$_GET['is_active']!=='') { $where[]="v.is_active=?"; $params[]=(int)$_GET['is_active']; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM vacancies v WHERE $ws");
    $tcnt->execute($params);
    $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT v.*, p.name as partner_name FROM vacancies v
         LEFT JOIN partners p ON p.id=v.partner_id
         WHERE $ws ORDER BY v.is_featured DESC, v.sort_order ASC, v.created_at DESC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d=jsonBody(); $f=vacancyFields($d);
    if(!$f['title']) { http_response_code(422); json(['error'=>'Название вакансии обязательно']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO vacancies (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->execute();
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','vacancies',$newId,"Создана вакансия: {$f['title']}");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM vacancies WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=vacancyFields($d);
    if(!$f['title']) { http_response_code(422); json(['error'=>'Название вакансии обязательно']); }
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE vacancies SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();
    adminLog($pdo,'update','vacancies',$id,"Обновлена вакансия: {$f['title']}");
    $row=$pdo->prepare("SELECT * FROM vacancies WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_active','is_featured','sort_order']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE vacancies SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row=$pdo->prepare("SELECT * FROM vacancies WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT title FROM vacancies WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM vacancies WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','vacancies',$id,"Удалена вакансия: {$row['title']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);