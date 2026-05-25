<?php
/**
 * API: news_items
 * GET    ?page=&limit=&search=&category=&is_published=&is_pinned=
 * GET    ?id=
 * POST   create
 * PUT    ?id=  full update
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$method = $_SERVER['REQUEST_METHOD'];
$pdo    = getDB();

// ── helpers ──────────────────────────────────────────────────────────────────
function newsFields(array $d): array {
    return [
        'title'        => trim($d['title']        ?? ''),
        'slug'         => trim($d['slug']          ?? ''),
        'excerpt'      => trim($d['excerpt']       ?? ''),
        'content'      => trim($d['content']       ?? ''),
        'category'     => trim($d['category']      ?? 'news'),
        'cover_image'  => trim($d['cover_image']   ?? ''),
        'author_name'  => trim($d['author_name']   ?? ''),
        'is_published' => isset($d['is_published']) ? (int)(bool)$d['is_published'] : 0,
        'is_pinned'    => isset($d['is_pinned'])    ? (int)(bool)$d['is_pinned']    : 0,
        'views'        => isset($d['views'])        ? (int)$d['views']              : 0,
        'published_at' => !empty($d['published_at']) ? $d['published_at'] : null,
        'tags'         => trim($d['tags']          ?? ''),
    ];
}

function autoSlug(string $title, PDO $pdo, ?int $excludeId = null): string {
    $slug = mb_strtolower(trim($title));
    $slug = preg_replace('/[^a-z0-9а-яёa-z\s]/ui', '', $slug);
    $slug = preg_replace('/\s+/', '-', $slug);
    $slug = preg_replace('/-+/', '-', trim($slug, '-'));
    if (!$slug) $slug = 'news-' . time();
    // transliterate if cyrillic
    $cyr = ['а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'];
    $lat = ['a','b','v','g','d','e','yo','zh','z','i','y','k','l','m','n','o','p','r','s','t','u','f','h','ts','ch','sh','shch','','y','','e','yu','ya'];
    $slug = str_replace($cyr, $lat, $slug);
    // ensure unique
    $base = $slug; $i = 1;
    while (true) {
        $q = $pdo->prepare("SELECT id FROM news_items WHERE slug=? AND id!=? LIMIT 1");
        $q->execute([$slug, $excludeId ?? 0]);
        if (!$q->fetch()) break;
        $slug = $base . '-' . $i++;
    }
    return $slug;
}

// ── GET ───────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    // single record
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM news_items WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
        json($row);
    }

    // list
    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 20)));
    $offset = ($page - 1) * $limit;

    $where  = ['1=1'];
    $params = [];

    if (!empty($_GET['search'])) {
        $where[]  = "(title LIKE ? OR excerpt LIKE ? OR author_name LIKE ?)";
        $s = '%' . $_GET['search'] . '%';
        $params   = array_merge($params, [$s, $s, $s]);
    }
    if (isset($_GET['category']) && $_GET['category'] !== '') {
        $where[]  = "category = ?";
        $params[] = $_GET['category'];
    }
    if (isset($_GET['is_published']) && $_GET['is_published'] !== '') {
        $where[]  = "is_published = ?";
        $params[] = (int)$_GET['is_published'];
    }
    if (isset($_GET['is_pinned']) && $_GET['is_pinned'] !== '') {
        $where[]  = "is_pinned = ?";
        $params[] = (int)$_GET['is_pinned'];
    }

    $whereStr = implode(' AND ', $where);

    $total = $pdo->prepare("SELECT COUNT(*) FROM news_items WHERE $whereStr");
    $total->execute($params);
    $totalCount = (int)$total->fetchColumn();

    $st = $pdo->prepare(
        "SELECT * FROM news_items WHERE $whereStr
         ORDER BY is_pinned DESC, published_at DESC, created_at DESC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    json([
        'data'       => $rows,
        'total'      => $totalCount,
        'page'       => $page,
        'limit'      => $limit,
        'pages'      => ceil($totalCount / $limit),
    ]);
}

// ── POST ──────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();
    $f = newsFields($d);

    if (!$f['title']) { http_response_code(422); json(['error' => 'Заголовок обязателен']); }

    if (!$f['slug']) $f['slug'] = autoSlug($f['title'], $pdo);

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare(
        "INSERT INTO news_items (" . implode(',', $cols) . ") VALUES (" . implode(',', $ph) . ")"
    );
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'news_items', $newId, "Создана новость: {$f['title']}");

    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM news_items WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ───────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $d = jsonBody();
    $f = newsFields($d);

    if (!$f['title']) { http_response_code(422); json(['error' => 'Заголовок обязателен']); }

    if (!$f['slug']) $f['slug'] = autoSlug($f['title'], $pdo, $id);

    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE news_items SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();

    adminLog($pdo, 'update', 'news_items', $id, "Обновлена новость: {$f['title']}");

    $row = $pdo->prepare("SELECT * FROM news_items WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ─────────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $d       = jsonBody();
    $allowed = ['is_published', 'is_pinned', 'views', 'category'];
    $set     = []; $params = [':id' => $id];
    foreach ($allowed as $field) {
        if (array_key_exists($field, $d)) {
            $set[]          = "$field=:$field";
            $params[":$field"] = $d[$field];
        }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields to patch']); }

    $pdo->prepare("UPDATE news_items SET " . implode(', ', $set) . ", updated_at=NOW() WHERE id=:id")
        ->execute($params);

    adminLog($pdo, 'patch', 'news_items', $id, 'Частичное обновление новости');

    $row = $pdo->prepare("SELECT * FROM news_items WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ────────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $check = $pdo->prepare("SELECT title FROM news_items WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }

    $pdo->prepare("DELETE FROM news_items WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'news_items', $id, "Удалена новость: {$row['title']}");

    http_response_code(204);
    exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);