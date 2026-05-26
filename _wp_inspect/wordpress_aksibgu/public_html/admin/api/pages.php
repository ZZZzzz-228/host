<?php
/**
 * API: pages (CMS)
 * GET    ?page=&limit=&search=&is_published=&template=
 * GET    ?id=
 * GET    ?slug=
 * POST   create
 * PUT    ?id=
 * PATCH  ?id=  {is_published}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function pageFields(array $d): array {
    return [
        'title'        => trim($d['title']        ?? ''),
        'slug'         => trim($d['slug']          ?? ''),
        'content'      => $d['content']            ?? '',
        'excerpt'      => trim($d['excerpt']       ?? ''),
        'template'     => trim($d['template']      ?? 'default'),
        'meta_title'   => trim($d['meta_title']    ?? ''),
        'meta_desc'    => trim($d['meta_desc']     ?? ''),
        'cover_image'  => trim($d['cover_image']   ?? ''),
        'parent_id'    => !empty($d['parent_id'])  ? (int)$d['parent_id'] : null,
        'sort_order'   => isset($d['sort_order'])  ? (int)$d['sort_order'] : 0,
        'is_published' => isset($d['is_published']) ? (int)(bool)$d['is_published'] : 0,
        'show_in_menu' => isset($d['show_in_menu']) ? (int)(bool)$d['show_in_menu'] : 0,
    ];
}

function autoPageSlug(string $title, PDO $pdo, ?int $excludeId = null): string {
    $cyr = ['а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'];
    $lat = ['a','b','v','g','d','e','yo','zh','z','i','y','k','l','m','n','o','p','r','s','t','u','f','h','ts','ch','sh','shch','','y','','e','yu','ya'];
    $slug = mb_strtolower(str_replace($cyr, $lat, trim($title)));
    $slug = preg_replace('/[^a-z0-9\-]/', '-', $slug);
    $slug = preg_replace('/-+/', '-', trim($slug, '-')) ?: 'page-'.time();
    $base = $slug; $i = 1;
    while (true) {
        $q = $pdo->prepare("SELECT id FROM pages WHERE slug=? AND id!=? LIMIT 1");
        $q->execute([$slug, $excludeId ?? 0]);
        if (!$q->fetch()) break;
        $slug = $base . '-' . $i++;
    }
    return $slug;
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error'=>'Not found']); }
        json($row);
    }
    if (!empty($_GET['slug'])) {
        $st = $pdo->prepare("SELECT * FROM pages WHERE slug=? LIMIT 1");
        $st->execute([$_GET['slug']]);
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
        $where[] = "(title LIKE ? OR slug LIKE ?)";
        $params  = array_merge($params, [$s, $s]);
    }
    if (isset($_GET['is_published']) && $_GET['is_published'] !== '') {
        $where[] = "is_published=?"; $params[] = (int)$_GET['is_published'];
    }
    if (!empty($_GET['template'])) {
        $where[] = "template=?"; $params[] = $_GET['template'];
    }
    if (!empty($_GET['parent_id'])) {
        $where[] = "parent_id=?"; $params[] = (int)$_GET['parent_id'];
    }

    $ws = implode(' AND ', $where);
    $tcnt = $pdo->prepare("SELECT COUNT(*) FROM pages WHERE $ws");
    $tcnt->execute($params);
    $total = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare("SELECT * FROM pages WHERE $ws ORDER BY sort_order ASC, title ASC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    json(['data' => $rows, 'total' => $total, 'page' => $page, 'limit' => $limit, 'pages' => ceil($total / $limit)]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();
    $f = pageFields($d);
    if (!$f['title']) { http_response_code(422); json(['error' => 'Заголовок обязателен']); }
    if (!$f['slug']) $f['slug'] = autoPageSlug($f['title'], $pdo);

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare("INSERT INTO pages (".implode(',', $cols).") VALUES (".implode(',', $ph).")");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'pages', $newId, "Создана страница: {$f['title']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $f = pageFields($d);
    if (!$f['title']) { http_response_code(422); json(['error' => 'Заголовок обязателен']); }
    if (!$f['slug']) $f['slug'] = autoPageSlug($f['title'], $pdo, $id);

    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE pages SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();

    adminLog($pdo, 'update', 'pages', $id, "Обновлена страница: {$f['title']}");
    $row = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $allowed = ['is_published', 'show_in_menu', 'sort_order'];
    $set = []; $params = [':id' => $id];
    foreach ($allowed as $f) {
        if (array_key_exists($f, $d)) {
            $set[] = "$f=:$f"; $params[":$f"] = $d[$f];
        }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }
    $pdo->prepare("UPDATE pages SET ".implode(', ', $set).", updated_at=NOW() WHERE id=:id")->execute($params);
    adminLog($pdo, 'patch', 'pages', $id, 'Частичное обновление страницы');
    $row = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $check = $pdo->prepare("SELECT title FROM pages WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
    $pdo->prepare("DELETE FROM pages WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'pages', $id, "Удалена страница: {$row['title']}");
    http_response_code(204); exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);