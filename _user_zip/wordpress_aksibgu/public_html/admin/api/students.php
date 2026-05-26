<?php
/**
 * API: students (users with role='student' + student_profiles join)
 * GET    ?page=&limit=&search=&group_id=&study_year=&is_active=
 * GET    ?id=
 * POST   create user+profile
 * PUT    ?id=  update user+profile
 * PATCH  ?id=  {is_active, group_id}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare(
            "SELECT u.id, u.login, u.email, u.phone, u.is_active, u.created_at,
                    sp.full_name, sp.birth_date, sp.gender, sp.group_id, sp.study_year,
                    sp.education_form, sp.admission_year, sp.photo_url, sp.address, sp.vk_url,
                    g.name as group_name, s.title as specialty_title
             FROM users u
             LEFT JOIN student_profiles sp ON sp.user_id=u.id
             LEFT JOIN groups_ref g ON g.id=sp.group_id
             LEFT JOIN specialties s ON s.id=g.specialty_id
             WHERE u.id=? AND u.role='student' LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??25)));
    $offset=($page-1)*$limit;

    $where=["u.role='student'"]; $params=[];
    if(!empty($_GET['search'])) {
        $s='%'.$_GET['search'].'%';
        $where[]="(sp.full_name LIKE ? OR u.email LIKE ? OR u.login LIKE ? OR u.phone LIKE ?)";
        $params=array_merge($params,[$s,$s,$s,$s]);
    }
    if(!empty($_GET['group_id']))   { $where[]="sp.group_id=?";   $params[]=(int)$_GET['group_id'];   }
    if(!empty($_GET['study_year'])) { $where[]="sp.study_year=?"; $params[]=(int)$_GET['study_year']; }
    if(isset($_GET['is_active'])&&$_GET['is_active']!=='') { $where[]="u.is_active=?"; $params[]=(int)$_GET['is_active']; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare(
        "SELECT COUNT(*) FROM users u
         LEFT JOIN student_profiles sp ON sp.user_id=u.id
         WHERE $ws"
    );
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare(
        "SELECT u.id, u.login, u.email, u.phone, u.is_active, u.created_at,
                sp.full_name, sp.study_year, sp.education_form,
                g.name as group_name, s.title as specialty_title
         FROM users u
         LEFT JOIN student_profiles sp ON sp.user_id=u.id
         LEFT JOIN groups_ref g ON g.id=sp.group_id
         LEFT JOIN specialties s ON s.id=g.specialty_id
         WHERE $ws ORDER BY sp.full_name ASC, u.created_at DESC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit)]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();

    if (empty($d['login']) || empty($d['password'])) {
        http_response_code(422); json(['error'=>'Логин и пароль обязательны']);
    }

    // check duplicate login
    $exists=$pdo->prepare("SELECT id FROM users WHERE login=? LIMIT 1");
    $exists->execute([$d['login']]);
    if($exists->fetch()) { http_response_code(409); json(['error'=>'Такой логин уже существует']); }

    // check email
    if(!empty($d['email'])) {
        $exists=$pdo->prepare("SELECT id FROM users WHERE email=? LIMIT 1");
        $exists->execute([$d['email']]);
        if($exists->fetch()) { http_response_code(409); json(['error'=>'Email уже занят']); }
    }

    $pdo->beginTransaction();
    try {
        $pdo->prepare(
            "INSERT INTO users (login, password_hash, email, phone, role, is_active)
             VALUES (?, ?, ?, ?, 'student', 1)"
        )->execute([
            $d['login'],
            password_hash($d['password'], PASSWORD_BCRYPT),
            $d['email'] ?? null,
            $d['phone'] ?? null,
        ]);
        $userId = (int)$pdo->lastInsertId();

        $pdo->prepare(
            "INSERT INTO student_profiles
             (user_id, full_name, birth_date, gender, group_id, study_year, education_form, admission_year, photo_url, address, vk_url)
             VALUES (?,?,?,?,?,?,?,?,?,?,?)"
        )->execute([
            $userId,
            $d['full_name']     ?? '',
            $d['birth_date']    ?? null,
            $d['gender']        ?? null,
            !empty($d['group_id'])      ? (int)$d['group_id']      : null,
            !empty($d['study_year'])    ? (int)$d['study_year']    : 1,
            $d['education_form']?? 'full-time',
            !empty($d['admission_year'])? (int)$d['admission_year']: date('Y'),
            $d['photo_url']     ?? '',
            $d['address']       ?? '',
            $d['vk_url']        ?? '',
        ]);

        $pdo->commit();
        adminLog($pdo,'create','users',$userId,"Создан студент: {$d['full_name']} ({$d['login']})");
        http_response_code(201);
        json(['id'=>$userId,'login'=>$d['login'],'full_name'=>$d['full_name']??'']);
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(500); json(['error'=>$e->getMessage()]);
    }
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();

    $pdo->beginTransaction();
    try {
        // update user
        $userFields = [];
        if(!empty($d['email']))  { $userFields['email']  = $d['email'];  }
        if(!empty($d['phone']))  { $userFields['phone']  = $d['phone'];  }
        if(isset($d['is_active'])) { $userFields['is_active'] = (int)(bool)$d['is_active']; }
        if(!empty($d['password'])) {
            $userFields['password_hash'] = password_hash($d['password'], PASSWORD_BCRYPT);
        }
        if($userFields) {
            $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($userFields)));
            $st=$pdo->prepare("UPDATE users SET $set, updated_at=NOW() WHERE id=:id");
            foreach($userFields as $k=>$v) $st->bindValue(":$k",$v);
            $st->bindValue(':id',$id); $st->execute();
        }

        // update profile
        $profFields = [
            'full_name'      => $d['full_name']     ?? '',
            'birth_date'     => $d['birth_date']    ?? null,
            'gender'         => $d['gender']        ?? null,
            'group_id'       => !empty($d['group_id'])      ? (int)$d['group_id']      : null,
            'study_year'     => !empty($d['study_year'])    ? (int)$d['study_year']    : null,
            'education_form' => $d['education_form']?? 'full-time',
            'photo_url'      => $d['photo_url']     ?? '',
            'address'        => $d['address']       ?? '',
            'vk_url'         => $d['vk_url']        ?? '',
        ];
        $set=implode(', ',array_map(fn($c)=>"$c=:$c",array_keys($profFields)));
        $st=$pdo->prepare("UPDATE student_profiles SET $set, updated_at=NOW() WHERE user_id=:id");
        foreach($profFields as $k=>$v) $st->bindValue(":$k",$v);
        $st->bindValue(':id',$id); $st->execute();

        $pdo->commit();
        adminLog($pdo,'update','users',$id,"Обновлён студент: {$d['full_name']}");
        json(['id'=>$id,'updated'=>true]);
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(500); json(['error'=>$e->getMessage()]);
    }
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $d=jsonBody();

    if(isset($d['is_active'])) {
        $pdo->prepare("UPDATE users SET is_active=?, updated_at=NOW() WHERE id=? AND role='student'")
            ->execute([(int)(bool)$d['is_active'],$id]);
    }
    if(isset($d['group_id'])) {
        $pdo->prepare("UPDATE student_profiles SET group_id=?, updated_at=NOW() WHERE user_id=?")
            ->execute([!empty($d['group_id'])?(int)$d['group_id']:null,$id]);
    }
    json(['id'=>$id,'patched'=>true]);
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $check=$pdo->prepare("SELECT login FROM users WHERE id=? AND role='student' LIMIT 1");
    $check->execute([$id]); $row=$check->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); json(['error'=>'Not found']); }

    $pdo->beginTransaction();
    $pdo->prepare("DELETE FROM student_profiles WHERE user_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM student_resumes WHERE user_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM student_portfolio_items WHERE user_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM users WHERE id=?")->execute([$id]);
    $pdo->commit();
    adminLog($pdo,'delete','users',$id,"Удалён студент: {$row['login']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);