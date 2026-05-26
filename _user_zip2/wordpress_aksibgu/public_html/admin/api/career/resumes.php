<?php
/**
 * API: student_resumes (admin view)
 * GET    ?page=&limit=&search=&is_active=&user_id=
 * GET    ?id=
 * PATCH  ?id=  {is_active, is_featured}
 * DELETE ?id=
 */
require_once __DIR__ . '/../../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT r.*, u.login as user_login, u.email as user_email,
                    sp.full_name, sp.group_id,
                    g.name as group_name
             FROM student_resumes r
             LEFT JOIN users u ON u.id=r.user_id
             LEFT JOIN student_profiles sp ON sp.user_id=r.user_id
             LEFT JOIN groups_ref g ON g.id=sp.group_id
             WHERE r.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        // parse skills JSON
        if(!empty($row['skills_json'])) $row['skills'] = json_decode($row['skills_json'],true);
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??25)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(sp.full_name LIKE ? OR u.email LIKE ? OR r.desired_position LIKE ?)";
        $params=array_merge($params,[$s,$s,$s]);
    }
    if(isset($_GET['is_active'])&&$_GET['is_active']!=='') { $where[]="r.is_active=?"; $params[]=(int)$_GET['is_active']; }
    if(!empty($_GET['user_id'])) { $where[]="r.user_id=?"; $params[]=(int)$_GET['user_id']; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM student_resumes r LEFT JOIN users u ON u.id=r.user_id LEFT JOIN student_profiles sp ON sp.user_id=r.user_id WHERE $ws");
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT r.id, r.user_id, r.desired_position, r.salary_expected, r.is_active, r.created_at,
                sp.full_name, g.name as group_name, u.email as user_email
         FROM student_resumes r
         LEFT JOIN users u ON u.id=r.user_id
         LEFT JOIN student_profiles sp ON sp.user_id=r.user_id
         LEFT JOIN groups_ref g ON g.id=sp.group_id
         WHERE $ws ORDER BY r.created_at DESC LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_active','is_featured']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE student_resumes SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    adminLog($pdo,'patch','student_resumes',$id,'Обновлено резюме');
    $row=$pdo->prepare("SELECT * FROM student_resumes WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT id FROM student_resumes WHERE id=? LIMIT 1");
    $check->execute([$id]);
    if(!$check->fetch()) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM student_resumes WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','student_resumes',$id,'Удалено резюме');
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);