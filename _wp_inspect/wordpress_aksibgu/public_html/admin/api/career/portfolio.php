<?php
/**
 * API: student_portfolio_items (admin view)
 * GET    ?page=&limit=&search=&is_published=&user_id=&category=
 * GET    ?id=
 * PATCH  ?id=  {is_published, is_featured}
 * DELETE ?id=
 */
require_once __DIR__ . '/../../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT pi.*, u.login as user_login, u.email as user_email, sp.full_name
             FROM student_portfolio_items pi
             LEFT JOIN users u ON u.id=pi.user_id
             LEFT JOIN student_profiles sp ON sp.user_id=pi.user_id
             WHERE pi.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        if(!empty($row['images_json'])) $row['images'] = json_decode($row['images_json'],true)??[];
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??25)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(pi.title LIKE ? OR pi.description LIKE ? OR sp.full_name LIKE ?)";
        $params=array_merge($params,[$s,$s,$s]);
    }
    if(isset($_GET['is_published'])&&$_GET['is_published']!=='') { $where[]="pi.is_published=?"; $params[]=(int)$_GET['is_published']; }
    if(!empty($_GET['user_id']))  { $where[]="pi.user_id=?";  $params[]=(int)$_GET['user_id'];  }
    if(!empty($_GET['category'])) { $where[]="pi.category=?"; $params[]=$_GET['category'];       }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare(
        "SELECT COUNT(*) FROM student_portfolio_items pi
         LEFT JOIN student_profiles sp ON sp.user_id=pi.user_id
         WHERE $ws"
    );
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT pi.id, pi.user_id, pi.title, pi.category, pi.cover_image, pi.is_published, pi.created_at,
                sp.full_name, u.email as user_email
         FROM student_portfolio_items pi
         LEFT JOIN users u ON u.id=pi.user_id
         LEFT JOIN student_profiles sp ON sp.user_id=pi.user_id
         WHERE $ws ORDER BY pi.created_at DESC LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();
    $allowed=['is_published','is_featured']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE student_portfolio_items SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    adminLog($pdo,'patch','student_portfolio_items',$id,'Обновлена работа портфолио');
    $row=$pdo->prepare("SELECT * FROM student_portfolio_items WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT id FROM student_portfolio_items WHERE id=? LIMIT 1");
    $check->execute([$id]);
    if(!$check->fetch()) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM student_portfolio_items WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','student_portfolio_items',$id,'Удалена работа портфолио');
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);