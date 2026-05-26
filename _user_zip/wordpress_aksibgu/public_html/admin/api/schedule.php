<?php
/**
 * API: schedule
 * GET    ?page=&limit=&search=&group_id=&staff_id=&day_of_week=&week_type=&study_year=
 * GET    ?id=
 * POST / PUT ?id= / DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function schedFields(array $d): array {
    return [
        'group_id'       => !empty($d['group_id'])       ? (int)$d['group_id']       : null,
        'discipline_id'  => !empty($d['discipline_id'])  ? (int)$d['discipline_id']  : null,
        'staff_id'       => !empty($d['staff_id'])       ? (int)$d['staff_id']       : null,
        'day_of_week'    => isset($d['day_of_week'])     ? (int)$d['day_of_week']     : 1,
        'lesson_number'  => isset($d['lesson_number'])  ? (int)$d['lesson_number']   : 1,
        'week_type'      => trim($d['week_type']         ?? 'all'),   // all|odd|even
        'study_year'     => isset($d['study_year'])     ? (int)$d['study_year']       : 1,
        'semester'       => isset($d['semester'])       ? (int)$d['semester']         : 1,
        'time_start'     => trim($d['time_start']        ?? ''),
        'time_end'       => trim($d['time_end']          ?? ''),
        'room'           => trim($d['room']              ?? ''),
        'lesson_type'    => trim($d['lesson_type']       ?? 'lecture'), // lecture|practice|lab|elective
        'subgroup'       => isset($d['subgroup'])       ? (int)$d['subgroup']         : 0,
        'note'           => trim($d['note']              ?? ''),
    ];
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT s.*, g.name as group_name, d.name as discipline_name,
                    sm.full_name as staff_name
             FROM schedule s
             LEFT JOIN groups_ref g ON g.id=s.group_id
             LEFT JOIN disciplines d ON d.id=s.discipline_id
             LEFT JOIN staff_members sm ON sm.id=s.staff_id
             WHERE s.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(500,max(1,(int)($_GET['limit']??100)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(d.name LIKE ? OR sm.full_name LIKE ? OR s.room LIKE ? OR g.name LIKE ?)";
        $params=array_merge($params,[$s,$s,$s,$s]);
    }
    if(!empty($_GET['group_id']))    { $where[]="s.group_id=?";    $params[]=(int)$_GET['group_id'];    }
    if(!empty($_GET['staff_id']))    { $where[]="s.staff_id=?";    $params[]=(int)$_GET['staff_id'];    }
    if(!empty($_GET['day_of_week'])) { $where[]="s.day_of_week=?"; $params[]=(int)$_GET['day_of_week']; }
    if(!empty($_GET['week_type'])&&$_GET['week_type']!=='all') {
        $where[]="(s.week_type=? OR s.week_type='all')"; $params[]=$_GET['week_type'];
    }
    if(!empty($_GET['study_year'])) { $where[]="s.study_year=?"; $params[]=(int)$_GET['study_year']; }
    if(!empty($_GET['semester']))   { $where[]="s.semester=?";   $params[]=(int)$_GET['semester'];   }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare(
        "SELECT COUNT(*) FROM schedule s
         LEFT JOIN groups_ref g ON g.id=s.group_id
         LEFT JOIN disciplines d ON d.id=s.discipline_id
         LEFT JOIN staff_members sm ON sm.id=s.staff_id
         WHERE $ws"
    );
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT s.*, g.name as group_name, d.name as discipline_name, sm.full_name as staff_name
         FROM schedule s
         LEFT JOIN groups_ref g ON g.id=s.group_id
         LEFT JOIN disciplines d ON d.id=s.discipline_id
         LEFT JOIN staff_members sm ON sm.id=s.staff_id
         WHERE $ws ORDER BY s.day_of_week ASC, s.lesson_number ASC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'POST') {
    $d=jsonBody(); $f=schedFields($d);
    if(!$f['group_id']) { http_response_code(422); json(['error'=>'Группа обязательна']); }
    $cols=array_keys($f); $ph=array_map(fn($c)=>":$c",$cols);
    $st=$pdo->prepare("INSERT INTO schedule (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->execute();
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','schedule',$newId,"Создана запись расписания");
    http_response_code(201);
    $row=$pdo->prepare("SELECT * FROM schedule WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody(); $f=schedFields($d);
    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($f)));
    $st=$pdo->prepare("UPDATE schedule SET $set, updated_at=NOW() WHERE id=:id");
    foreach($f as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();
    adminLog($pdo,'update','schedule',$id,"Обновлена запись расписания");
    $row=$pdo->prepare("SELECT * FROM schedule WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT id FROM schedule WHERE id=? LIMIT 1");
    $check->execute([$id]);
    if(!$check->fetch()) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM schedule WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','schedule',$id,"Удалена запись расписания");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);