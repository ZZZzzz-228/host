<?php
/**
 * API: specialties
 * GET    ?page=&limit=&search=&is_published=
 * GET    ?id=
 * POST   create
 * PUT    ?id=
 * PATCH  ?id=  {is_published, sort_order}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function specFields(array $d): array {
    return [
        'code'               => trim($d['code']              ?? ''),
        'title'              => trim($d['title']             ?? ''),
        'short_title'        => trim($d['short_title']       ?? ''),
        'description'        => $d['description']            ?? '',
        'duration_label'     => trim($d['duration_label']    ?? ''),
        'study_form_label'   => trim($d['study_form_label']  ?? ''),
        'qualification_text' => trim($d['qualification_text']?? ''),
        'career_text'        => $d['career_text']            ?? '',
        'skills_text'        => $d['skills_text']            ?? '',
        'salary_text'        => trim($d['salary_text']       ?? ''),
        'color_hex'          => trim($d['color_hex']         ?? '#6c63ff'),
        'icon_name'          => trim($d['icon_name']         ?? ''),
        'image_url'          => trim($d['image_url']         ?? ''),
        'gosuslugi_url'      => trim($d['gosuslugi_url']     ?? ''),
        'department_id'      => !empty($d['department_id'])  ? (int)$d['department_id'] : null,
        'sort_order'         => isset($d['sort_order'])      ? (int)$d['sort_order']    : 0,
        'is_published'       => isset($d['is_published'])    ? (int)(bool)$d['is_published'] : 0,
        'publish_from'       => !empty($d['publish_from'])   ? $d['publish_from'] : null,
        'publish_to'         => !empty($d['publish_to'])     ? $d['publish_to']   : null,
    ];
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare(
            "SELECT s.*, d.name as department_name
             FROM specialties s
             LEFT JOIN departments d ON d.id=s.department_id
             WHERE s.id=? LIMIT 1"
        );
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 20)));
    $offset = ($page - 1) * $limit;

    $where = ['1=1']; $params = [];
    if (!empty($_GET['search'])) {
        $s = '%'.$_GET['search'].'%';
        $where[] = "(s.title LIKE ? OR s.code LIKE ? OR s.short_title LIKE ?)";
        $params  = array_merge($params, [$s, $s, $s]);
    }
    if (isset($_GET['is_published']) && $_GET['is_published'] !== '') {
        $where[] = "s.is_published=?"; $params[] = (int)$_GET['is_published'];
    }
    if (!empty($_GET['department_id'])) {
        $where[] = "s.department_id=?"; $params[] = (int)$_GET['department_id'];
    }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM specialties s WHERE $ws");
    $tcnt->execute($params);
    $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare(
        "SELECT s.*, d.name as department_name
         FROM specialties s
         LEFT JOIN departments d ON d.id=s.department_id
         WHERE $ws ORDER BY s.sort_order ASC, s.title ASC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    json(['data' => $rows, 'total' => $total, 'page' => $page, 'limit' => $limit, 'pages' => ceil($total / $limit)]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();
    $f = specFields($d);
    if (!$f['title']) { http_response_code(422); json(['error' => 'Название обязательно']); }

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare("INSERT INTO specialties (".implode(',', $cols).") VALUES (".implode(',', $ph).")");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'specialties', $newId, "Создана специальность: {$f['title']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM specialties WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $f = specFields($d);
    if (!$f['title']) { http_response_code(422); json(['error' => 'Название обязательно']); }

    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE specialties SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();

    adminLog($pdo, 'update', 'specialties', $id, "Обновлена специальность: {$f['title']}");
    $row = $pdo->prepare("SELECT * FROM specialties WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $allowed = ['is_published', 'sort_order', 'color_hex'];
    $set = []; $params = [':id' => $id];
    foreach ($allowed as $f) {
        if (array_key_exists($f, $d)) { $set[] = "$f=:$f"; $params[":$f"] = $d[$f]; }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }
    $pdo->prepare("UPDATE specialties SET ".implode(', ', $set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row = $pdo->prepare("SELECT * FROM specialties WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $check = $pdo->prepare("SELECT title FROM specialties WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
    $pdo->prepare("DELETE FROM specialties WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'specialties', $id, "Удалена специальность: {$row['title']}");
    http_response_code(204); exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);