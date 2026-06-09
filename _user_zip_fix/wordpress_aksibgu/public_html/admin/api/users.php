<?php
/**
 * API: admins table (admin user management)
 * GET    ?page=&limit=&search=&role=&is_active=
 * GET    ?id=
 * POST   create admin
 * PUT    ?id=  update (incl. password change)
 * PATCH  ?id=  {is_active, role}
 * DELETE ?id=  (cannot delete self)
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];
$selfId = (int)($_SESSION['admin_id'] ?? 0);

// Only super-admin or root can manage admins
$selfRole = $_SESSION['admin_role'] ?? 'admin';
$canManage = in_array($selfRole, ['superadmin', 'root', 'admin']);

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare("SELECT id, login, email, phone, role, full_name, is_active, last_login, created_at FROM admins WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(100,max(1,(int)($_GET['limit']??25)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(login LIKE ? OR email LIKE ? OR full_name LIKE ?)";
        $params=array_merge($params,[$s,$s,$s]);
    }
    if(!empty($_GET['role']))        { $where[]="role=?"; $params[]=$_GET['role']; }
    if(isset($_GET['is_active'])&&$_GET['is_active']!=='') { $where[]="is_active=?"; $params[]=(int)$_GET['is_active']; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM admins WHERE $ws");
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare("SELECT id, login, email, phone, role, full_name, is_active, last_login, created_at FROM admins WHERE $ws ORDER BY created_at ASC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    if (!$canManage) { http_response_code(403); json(['error'=>'Недостаточно прав']); }
    $d=jsonBody();

    if(empty($d['login'])||empty($d['password'])) {
        http_response_code(422); json(['error'=>'Логин и пароль обязательны']);
    }
    if(mb_strlen($d['password'])<6) { http_response_code(422); json(['error'=>'Пароль минимум 6 символов']); }

    $exists=$pdo->prepare("SELECT id FROM admins WHERE login=? LIMIT 1");
    $exists->execute([$d['login']]);
    if($exists->fetch()) { http_response_code(409); json(['error'=>'Логин уже занят']); }

    $role = in_array($d['role']??'',['admin','editor','superadmin','moderator','career_manager']) ? $d['role'] : 'editor';

    $pdo->prepare(
        "INSERT INTO admins (login, password_hash, email, phone, full_name, role, is_active)
         VALUES (?,?,?,?,?,?,1)"
    )->execute([
        $d['login'],
        password_hash($d['password'], PASSWORD_BCRYPT),
        $d['email']     ?? '',
        $d['phone']     ?? '',
        $d['full_name'] ?? '',
        $role,
    ]);
    $newId=(int)$pdo->lastInsertId();
    adminLog($pdo,'create','admins',$newId,"Создан администратор: {$d['login']} ({$role})");
    http_response_code(201);
    $row=$pdo->prepare("SELECT id, login, email, role, full_name, is_active, created_at FROM admins WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    if(!$canManage && $id !== $selfId) { http_response_code(403); json(['error'=>'Недостаточно прав']); }

    $d=jsonBody();
    $fields = [
        'email'     => $d['email']     ?? '',
        'phone'     => $d['phone']     ?? '',
        'full_name' => $d['full_name'] ?? '',
    ];

    // Allow role change only for superadmin
    if($canManage && !empty($d['role'])) {
        $validRoles = ['admin','editor','superadmin','moderator','career_manager'];
        if(in_array($d['role'],$validRoles)) $fields['role'] = $d['role'];
    }

    // Password change
    if(!empty($d['password'])) {
        if(mb_strlen($d['password'])<6) { http_response_code(422); json(['error'=>'Пароль минимум 6 символов']); }
        $fields['password_hash'] = password_hash($d['password'], PASSWORD_BCRYPT);
    }

    $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($fields)));
    $st=$pdo->prepare("UPDATE admins SET $set, updated_at=NOW() WHERE id=:id");
    foreach($fields as $k=>$v) $st->bindValue(":$k",$v);
    $st->bindValue(':id',$id); $st->execute();

    adminLog($pdo,'update','admins',$id,"Обновлён администратор");
    $row=$pdo->prepare("SELECT id, login, email, role, full_name, is_active, created_at FROM admins WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    if(!$canManage) { http_response_code(403); json(['error'=>'Недостаточно прав']); }
    if($id === $selfId && isset($d['is_active']) && !(bool)$d['is_active']) {
        http_response_code(422); json(['error'=>'Нельзя деактивировать себя']);
    }
    $d=jsonBody();
    $allowed=['is_active','role']; $set=[]; $params=[':id'=>$id];
    foreach($allowed as $f) {
        if(array_key_exists($f,$d)) { $set[]="$f=:$f"; $params[":$f"]=$d[$f]; }
    }
    if(!$set) { http_response_code(400); json(['error'=>'No fields']); }
    $pdo->prepare("UPDATE admins SET ".implode(', ',$set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row=$pdo->prepare("SELECT id, login, email, role, full_name, is_active FROM admins WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    if(!$canManage) { http_response_code(403); json(['error'=>'Недостаточно прав']); }
    if($id === $selfId) { http_response_code(422); json(['error'=>'Нельзя удалить себя']); }
    $check=$pdo->prepare("SELECT login FROM admins WHERE id=? LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
    $pdo->prepare("DELETE FROM admins WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','admins',$id,"Удалён администратор: {$row['login']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);