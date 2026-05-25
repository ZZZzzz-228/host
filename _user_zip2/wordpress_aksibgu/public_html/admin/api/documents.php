<?php
/**
 * API: documents
 * GET    ?page=&limit=&search=&category=&file_type=
 * GET    ?id=
 * POST   create
 * PUT    ?id=
 * PATCH  ?id=  {is_public, sort_order}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function docFields(array $d): array {
    return [
        'name'        => trim($d['name']        ?? ''),
        'description' => trim($d['description'] ?? ''),
        'file_url'    => trim($d['file_url']    ?? ''),
        'file_type'   => trim($d['file_type']   ?? 'other'),
        'category'    => trim($d['category']    ?? 'other'),
        'file_size'   => isset($d['file_size'])  ? (int)$d['file_size']   : null,
        'is_public'   => isset($d['is_public'])  ? (int)(bool)$d['is_public']  : 1,
        'sort_order'  => isset($d['sort_order']) ? (int)$d['sort_order']   : 0,
        'uploaded_by' => (int)($_SESSION['admin_id'] ?? 0),
    ];
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM documents WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
        json($row);
    }

    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 25)));
    $offset = ($page - 1) * $limit;

    $where = ['1=1']; $params = [];
    if (!empty($_GET['search'])) {
        $s = '%'.$_GET['search'].'%';
        $where[] = "(name LIKE ? OR description LIKE ?)";
        $params  = array_merge($params, [$s, $s]);
    }
    if (!empty($_GET['category']))  { $where[] = "category=?";  $params[] = $_GET['category'];  }
    if (!empty($_GET['file_type'])) { $where[] = "file_type=?"; $params[] = $_GET['file_type']; }
    if (isset($_GET['is_public']) && $_GET['is_public'] !== '') {
        $where[] = "is_public=?"; $params[] = (int)$_GET['is_public'];
    }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM documents WHERE $ws");
    $tcnt->execute($params); $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare("SELECT * FROM documents WHERE $ws ORDER BY sort_order ASC, created_at DESC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    // Distinct categories
    $cats = [];
    try {
        $cats = $pdo->query("SELECT DISTINCT category FROM documents ORDER BY category")->fetchAll(PDO::FETCH_COLUMN);
    } catch (Exception $e) {}

    json(['data' => $rows, 'total' => $total, 'page' => $page, 'limit' => $limit, 'pages' => ceil($total / $limit), 'categories' => $cats]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();
    $f = docFields($d);
    if (!$f['name']) { http_response_code(422); json(['error' => 'Название обязательно']); }

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare("INSERT INTO documents (".implode(',', $cols).") VALUES (".implode(',', $ph).")");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'documents', $newId, "Добавлен документ: {$f['name']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM documents WHERE id=? LIMIT 1");
    $row->execute([$newId]); json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody(); $f = docFields($d);
    if (!$f['name']) { http_response_code(422); json(['error' => 'Название обязательно']); }

    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE documents SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id); $st->execute();

    adminLog($pdo, 'update', 'documents', $id, "Обновлён документ: {$f['name']}");
    $row = $pdo->prepare("SELECT * FROM documents WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $allowed = ['is_public', 'sort_order', 'category']; $set = []; $params = [':id' => $id];
    foreach ($allowed as $f) {
        if (array_key_exists($f, $d)) { $set[] = "$f=:$f"; $params[":$f"] = $d[$f]; }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }
    $pdo->prepare("UPDATE documents SET ".implode(', ', $set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row = $pdo->prepare("SELECT * FROM documents WHERE id=? LIMIT 1");
    $row->execute([$id]); json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $check = $pdo->prepare("SELECT name FROM documents WHERE id=? LIMIT 1");
    $check->execute([$id]); $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
    $pdo->prepare("DELETE FROM documents WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'documents', $id, "Удалён документ: {$row['name']}");
    http_response_code(204); exit;
}

http_response_code(405); json(['error' => 'Method Not Allowed']);