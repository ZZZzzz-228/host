<?php
/**
 * API: universities (Университеты)
 * ====================================
 * GET    ?page=&limit=&search=&is_active=  → список с пагинацией
 * GET    ?id=                              → один объект напрямую
 * POST                                    → создать (тело JSON)
 * PUT    ?id=                             → полное обновление
 * PATCH  ?id=  {is_active, sort_order}    → частичное обновление
 * DELETE ?id=                             → HTTP 204
 *
 * Путь на хостинге: public_html/admin/api/career/universities.php
 */
require_once __DIR__ . '/../../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

/* Таблица universities — создать, если ещё нет (после частичного импорта БД) */
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS `universities` (
      `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` varchar(255) NOT NULL DEFAULT '',
      `short_name` varchar(64) NOT NULL DEFAULT '',
      `description` text,
      `full_text` mediumtext,
      `url` varchar(512) NOT NULL DEFAULT '',
      `admission_url` varchar(512) NOT NULL DEFAULT '',
      `vk_url` varchar(512) NOT NULL DEFAULT '',
      `telegram_url` varchar(512) NOT NULL DEFAULT '',
      `logo_url` varchar(512) NOT NULL DEFAULT '',
      `cover_url` varchar(512) NOT NULL DEFAULT '',
      `city` varchar(128) NOT NULL DEFAULT '',
      `address` varchar(512) NOT NULL DEFAULT '',
      `phone` varchar(64) NOT NULL DEFAULT '',
      `email` varchar(255) NOT NULL DEFAULT '',
      `tags` varchar(512) NOT NULL DEFAULT '',
      `specialties_offered` text,
      `sort_order` int NOT NULL DEFAULT 0,
      `is_active` tinyint(1) NOT NULL DEFAULT 1,
      `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `is_active` (`is_active`),
      KEY `sort_order` (`sort_order`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
} catch (Exception $e) {}

/* ── Извлечение и валидация полей ─────────────────────────────── */
function uniFields(array $d): array {
    $spec = $d['specialties_offered'] ?? '';
    if (is_array($spec)) {
        $spec = json_encode($spec, JSON_UNESCAPED_UNICODE);
    } else {
        $spec = trim((string)$spec);
    }
    return [
        'name'               => trim($d['name']               ?? ''),
        'short_name'         => trim($d['short_name']         ?? ''),
        'description'        => trim($d['description']        ?? ''),
        'full_text'          => $d['full_text']               ?? '',
        'url'                => trim($d['url']                ?? ''),
        'admission_url'      => trim($d['admission_url']      ?? ''),
        'vk_url'             => trim($d['vk_url']             ?? ''),
        'telegram_url'       => trim($d['telegram_url']       ?? ''),
        'logo_url'           => trim($d['logo_url']           ?? ''),
        'cover_url'          => trim($d['cover_url']          ?? ''),
        'city'               => trim($d['city']               ?? ''),
        'address'            => trim($d['address']            ?? ''),
        'phone'              => trim($d['phone']              ?? ''),
        'email'              => trim($d['email']              ?? ''),
        'tags'               => trim($d['tags']               ?? ''),
        'specialties_offered'=> $spec,
        'sort_order'         => isset($d['sort_order'])       ? (int)$d['sort_order'] : 0,
        'is_active'          => isset($d['is_active'])        ? (int)(bool)$d['is_active'] : 1,
    ];
}

/* ── GET ──────────────────────────────────────────────────────── */
if ($method === 'GET') {

    /* GET ?id= → возвращаем объект напрямую (без обёртки data) */
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM universities WHERE id = ? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
        json($row);
    }

    $page  = max(1, (int)($_GET['page']  ?? 1));
    $limit = min(200, max(1, (int)($_GET['limit'] ?? 50)));
    $offset = ($page - 1) * $limit;

    $where  = ['1=1'];
    $params = [];

    if (!empty($_GET['search'])) {
        $s = '%' . $_GET['search'] . '%';
        $where[]  = "(name LIKE ? OR short_name LIKE ? OR city LIKE ?)";
        $params   = array_merge($params, [$s, $s, $s]);
    }
    if (isset($_GET['is_active']) && $_GET['is_active'] !== '') {
        $where[]  = "is_active = ?";
        $params[] = (int)$_GET['is_active'];
    }

    $ws   = implode(' AND ', $where);
    $cnt  = $pdo->prepare("SELECT COUNT(*) FROM universities WHERE $ws");
    $cnt->execute($params);
    $total = (int)$cnt->fetchColumn();

    $st = $pdo->prepare(
        "SELECT * FROM universities WHERE $ws
         ORDER BY sort_order ASC, name ASC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    json([
        'data'  => $rows,
        'total' => $total,
        'page'  => $page,
        'limit' => $limit,
        'pages' => $total > 0 ? (int)ceil($total / $limit) : 1,
    ]);
}

/* ── POST ─────────────────────────────────────────────────────── */
if ($method === 'POST') {
    $d = jsonBody();
    $f = uniFields($d);
    if (!$f['name']) { http_response_code(422); json(['error' => 'Название университета обязательно']); }

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare(
        "INSERT INTO universities (" . implode(',', $cols) . ") VALUES (" . implode(',', $ph) . ")"
    );
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();
    adminLog($pdo, 'create', 'universities', $newId, "Создан университет: {$f['name']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM universities WHERE id = ? LIMIT 1");
    $row->execute([$newId]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

/* ── PUT ──────────────────────────────────────────────────────── */
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d = jsonBody();
    $f = uniFields($d);
    if (!$f['name']) { http_response_code(422); json(['error' => 'Название университета обязательно']); }

    $set = implode(', ', array_map(fn($c) => "$c = :$c", array_keys($f)));
    $st  = $pdo->prepare("UPDATE universities SET $set, updated_at = NOW() WHERE id = :id");
    foreach ($f as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();
    adminLog($pdo, 'update', 'universities', $id, "Обновлён университет: {$f['name']}");
    $row = $pdo->prepare("SELECT * FROM universities WHERE id = ? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

/* ── PATCH ────────────────────────────────────────────────────── */
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $d       = jsonBody();
    $allowed = ['is_active', 'sort_order'];
    $set     = [];
    $params  = [':id' => $id];
    foreach ($allowed as $f) {
        if (array_key_exists($f, $d)) { $set[] = "$f = :$f"; $params[":$f"] = $d[$f]; }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields to update']); }
    $pdo->prepare("UPDATE universities SET " . implode(', ', $set) . ", updated_at = NOW() WHERE id = :id")
        ->execute($params);
    $row = $pdo->prepare("SELECT * FROM universities WHERE id = ? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

/* ── DELETE ───────────────────────────────────────────────────── */
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }
    $check = $pdo->prepare("SELECT name FROM universities WHERE id = ? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
    $pdo->prepare("DELETE FROM universities WHERE id = ?")->execute([$id]);
    adminLog($pdo, 'delete', 'universities', $id, "Удалён университет: {$row['name']}");
    http_response_code(204);
    exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);
