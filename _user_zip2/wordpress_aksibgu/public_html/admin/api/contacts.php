<?php
/**
 * API: contacts
 * GET    ?page=&limit=&search=&category=&is_active=
 * GET    ?id=
 * POST   create
 * PUT    ?id=
 * PATCH  ?id=  {is_active, sort_order}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function contactFields(array $d): array {
    return [
        'category'    => trim($d['category']    ?? 'general'),
        'label'       => trim($d['label']        ?? ''),
        'name'        => trim($d['name']         ?? ''),
        'position'    => trim($d['position']     ?? ''),
        'department'  => trim($d['department']   ?? ''),
        'phone'       => trim($d['phone']        ?? ''),
        'email'       => trim($d['email']        ?? ''),
        'address'     => trim($d['address']      ?? ''),
        'room'        => trim($d['room']         ?? ''),
        'schedule'    => trim($d['schedule']     ?? ''),
        'vk_url'      => trim($d['vk_url']       ?? ''),
        'photo_url'   => trim($d['photo_url']    ?? ''),
        'is_active'   => isset($d['is_active'])  ? (int)(bool)$d['is_active'] : 1,
        'sort_order'  => isset($d['sort_order']) ? (int)$d['sort_order'] : 0,
    ];
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM contacts WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }

    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 50)));
    $offset = ($page - 1) * $limit;

    $where = ['1=1']; $params = [];
    if (!empty($_GET['search'])) {
        $s = '%'.$_GET['search'].'%';
        $where[] = "(name LIKE ? OR email LIKE ? OR phone LIKE ? OR department LIKE ?)";
        $params  = array_merge($params, [$s, $s, $s, $s]);
    }
    if (!empty($_GET['category'])) { $where[] = "category=?"; $params[] = $_GET['category']; }
    if (isset($_GET['is_active']) && $_GET['is_active'] !== '') {
        $where[] = "is_active=?"; $params[] = (int)$_GET['is_active'];
    }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM contacts WHERE $ws");
    $tcnt->execute($params);
    $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare("SELECT * FROM contacts WHERE $ws ORDER BY category ASC, sort_order ASC, name ASC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    // categories list
    $cats = [];
    try {
        $cats = $pdo->query("SELECT DISTINCT category FROM contacts ORDER BY category")->fetchAll(PDO::FETCH_COLUMN);
    } catch (Exception $e) {}

    json(['data' => $rows, 'total' => $total, 'page' => $page, 'limit' => $limit, 'pages' => ceil($total / $limit), 'categories' => $cats]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();
    $f = contactFields($d);
    if (!$f['name'] && !$f['label']) { http_response_code(422); json(['error' => 'Имя или метка обязательны']); }

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare("INSERT INTO contacts (".implode(',', $cols).") VALUES (".implode(',', $ph).")");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'contacts', $newId, "Создан контакт: {$f['name']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM contacts WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $f = contactFields($d);
    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE contacts SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();
    adminLog($pdo, 'update', 'contacts', $id, "Обновлён контакт: {$f['name']}");
    $row = $pdo->prepare("SELECT * FROM contacts WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $allowed = ['is_active', 'sort_order', 'category'];
    $set = []; $params = [':id' => $id];
    foreach ($allowed as $f) {
        if (array_key_exists($f, $d)) { $set[] = "$f=:$f"; $params[":$f"] = $d[$f]; }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }
    $pdo->prepare("UPDATE contacts SET ".implode(', ', $set).", updated_at=NOW() WHERE id=:id")->execute($params);
    $row = $pdo->prepare("SELECT * FROM contacts WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $check = $pdo->prepare("SELECT name FROM contacts WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
    $pdo->prepare("DELETE FROM contacts WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'contacts', $id, "Удалён контакт: {$row['name']}");
    http_response_code(204); exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);