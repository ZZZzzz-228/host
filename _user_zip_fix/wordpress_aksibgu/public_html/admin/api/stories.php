<?php
/**
 * API: stories
 * GET    ?page=&limit=&search=&is_published=
 * GET    ?id=
 * POST   create
 * PUT    ?id=
 * PATCH  ?id=  {is_published, is_featured}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function storyFields(array $d): array {
    return [
        'title'        => trim($d['title']        ?? ''),
        'description'  => trim($d['description']  ?? ''),
        'cover_image'  => trim($d['cover_image']  ?? ''),
        'images_json'  => !empty($d['images'])
                          ? json_encode(array_values((array)$d['images']), JSON_UNESCAPED_UNICODE)
                          : (!empty($d['images_json']) ? $d['images_json'] : null),
        'vk_post_id'   => !empty($d['vk_post_id'])   ? (int)$d['vk_post_id']   : null,
        'vk_post_url'  => trim($d['vk_post_url']  ?? ''),
        'is_published' => isset($d['is_published']) ? (int)(bool)$d['is_published'] : 0,
        'is_featured'  => isset($d['is_featured'])  ? (int)(bool)$d['is_featured']  : 0,
        'sort_order'   => isset($d['sort_order'])   ? (int)$d['sort_order']          : 0,
        'published_at' => !empty($d['published_at']) ? $d['published_at'] : null,
    ];
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM stories WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
        if (!empty($row['images_json'])) {
            $row['images'] = json_decode($row['images_json'], true) ?: [];
        }
        json($row);
    }

    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 20)));
    $offset = ($page - 1) * $limit;

    $where = ['1=1']; $params = [];
    if (!empty($_GET['search'])) {
        $s = '%'.$_GET['search'].'%';
        $where[] = "(title LIKE ? OR description LIKE ?)";
        $params  = array_merge($params, [$s, $s]);
    }
    if (isset($_GET['is_published']) && $_GET['is_published'] !== '') {
        $where[] = "is_published=?"; $params[] = (int)$_GET['is_published'];
    }
    if (isset($_GET['is_featured']) && $_GET['is_featured'] !== '') {
        $where[] = "is_featured=?"; $params[] = (int)$_GET['is_featured'];
    }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM stories WHERE $ws");
    $tcnt->execute($params);
    $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare(
        "SELECT * FROM stories WHERE $ws ORDER BY is_featured DESC, sort_order ASC, created_at DESC LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as &$r) {
        if (!empty($r['images_json'])) {
            $r['images'] = json_decode($r['images_json'], true) ?: [];
        }
    }

    json(['data' => $rows, 'total' => $total, 'page' => $page, 'limit' => $limit, 'pages' => ceil($total / $limit)]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();
    $f = storyFields($d);

    if (!$f['title']) { http_response_code(422); json(['error' => 'Заголовок обязателен']); }

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare("INSERT INTO stories (".implode(',', $cols).") VALUES (".implode(',', $ph).")");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'stories', $newId, "Создана история: {$f['title']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM stories WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    $r = $row->fetch(PDO::FETCH_ASSOC);
    if (!empty($r['images_json'])) $r['images'] = json_decode($r['images_json'], true) ?: [];
    json($r);
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $d = jsonBody();
    $f = storyFields($d);

    if (!$f['title']) { http_response_code(422); json(['error' => 'Заголовок обязателен']); }

    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE stories SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();

    adminLog($pdo, 'update', 'stories', $id, "Обновлена история: {$f['title']}");
    $row = $pdo->prepare("SELECT * FROM stories WHERE id=? LIMIT 1");
    $row->execute([$id]);
    $r = $row->fetch(PDO::FETCH_ASSOC);
    if (!empty($r['images_json'])) $r['images'] = json_decode($r['images_json'], true) ?: [];
    json($r);
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $d       = jsonBody();
    $allowed = ['is_published', 'is_featured', 'sort_order'];
    $set     = []; $params = [':id' => $id];
    foreach ($allowed as $field) {
        if (array_key_exists($field, $d)) {
            $set[]           = "$field=:$field";
            $params[":$field"] = $d[$field];
        }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }
    $pdo->prepare("UPDATE stories SET ".implode(', ', $set).", updated_at=NOW() WHERE id=:id")->execute($params);
    adminLog($pdo, 'patch', 'stories', $id, 'Частичное обновление истории');
    $row = $pdo->prepare("SELECT * FROM stories WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $check = $pdo->prepare("SELECT title FROM stories WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }

    $pdo->prepare("DELETE FROM stories WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'stories', $id, "Удалена история: {$row['title']}");
    http_response_code(204); exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);