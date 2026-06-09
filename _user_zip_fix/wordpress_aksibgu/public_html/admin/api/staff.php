<?php
/**
 * API: staff_members (сотрудники)
 * Файл: public_html/admin/api/staff.php
 *
 * GET    ?limit=&page=&q=&department=   → список сотрудников
 * GET    ?id=N                          → один сотрудник
 * POST                                  → создать
 * PUT    ?id=N                          → обновить
 * PATCH  ?id=N                          → частичное обновление (sort_order, is_active)
 * PATCH  ?reorder=1                     → массовое обновление порядка (drag&drop)
 *        body: { items: [{id:1, sort_order:0}, {id:5, sort_order:1}, ...] }
 * DELETE ?id=N                          → удалить
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

function staffFields(array $d): array
{
    return [
        'full_name'  => trim($d['full_name']      ?? ''),
        'short_name' => trim($d['short_name']     ?? ''),
        'position'   => trim($d['position_title'] ?? $d['position'] ?? ''),
        'email'      => trim($d['email']           ?? ''),
        'phone'      => trim($d['phone']           ?? ''),
        'role'       => trim($d['department']      ?? $d['role'] ?? 'college'),
        'photo_url'  => trim($d['photo_url']       ?? ''),
        'color_hex'  => trim($d['color_hex']       ?? '#1565C0'),
        'sort_order' => isset($d['sort_order'])    ? (int)$d['sort_order']  : 0,
        'schedule'   => trim($d['office_hours']    ?? $d['schedule'] ?? ''),
        'bio'        => trim($d['bio']             ?? ''),
        'is_active'  => isset($d['is_published'])  ? (int)(bool)$d['is_published']
                      : (isset($d['is_active'])    ? (int)(bool)$d['is_active'] : 1),
    ];
}

function staffRow(array $row): array
{
    $row['position_title'] = $row['position']   ?? '';
    $row['office_hours']   = $row['schedule']   ?? '';
    $row['is_published']   = (int)($row['is_active'] ?? 1);
    $row['department']     = $row['role']       ?? 'college';
    $row['color_hex']      = $row['color_hex']  ?? '#1565C0';
    return $row;
}

/* ══════════ GET ══════════════════════════════════════════════════════════ */
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM staff_members WHERE id = ? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            http_response_code(404);
            json(['error' => 'Not found']);
        }
        json(staffRow($row));
    }

    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 100)));
    $offset = ($page - 1) * $limit;

    $where  = ['1=1'];
    $params = [];

    if (!empty($_GET['q'])) {
        $s        = '%' . $_GET['q'] . '%';
        $where[]  = "(full_name LIKE ? OR position LIKE ? OR email LIKE ? OR phone LIKE ?)";
        $params   = array_merge($params, [$s, $s, $s, $s]);
    }
    if (!empty($_GET['department'])) {
        $where[]  = "role = ?";
        $params[] = $_GET['department'];
    }

    $ws = implode(' AND ', $where);

    $cnt = $pdo->prepare("SELECT COUNT(*) FROM staff_members WHERE $ws");
    $cnt->execute($params);
    $total = (int)$cnt->fetchColumn();

    $st = $pdo->prepare(
        "SELECT * FROM staff_members
         WHERE $ws
         ORDER BY sort_order ASC, id ASC
         LIMIT $limit OFFSET $offset"
    );
    $st->execute($params);
    $rows = array_map('staffRow', $st->fetchAll(PDO::FETCH_ASSOC));

    json([
        'data'  => $rows,
        'total' => $total,
        'page'  => $page,
        'limit' => $limit,
        'pages' => $total ? (int)ceil($total / $limit) : 0,
    ]);
}

/* ══════════ POST (создать) ═══════════════════════════════════════════════ */
if ($method === 'POST') {
    $d = jsonBody();
    $f = staffFields($d);

    if ($f['full_name'] === '') {
        http_response_code(422);
        json(['error' => 'ФИО обязательно']);
    }

    $cols = array_keys($f);
    $ph   = array_map(fn($c) => ":$c", $cols);

    $st = $pdo->prepare(
        "INSERT INTO staff_members (" . implode(', ', $cols) . ")
         VALUES (" . implode(', ', $ph) . ")"
    );
    foreach ($f as $k => $v) {
        $st->bindValue(":$k", $v);
    }
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'staff_members', $newId, "Создан сотрудник: {$f['full_name']}");

    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM staff_members WHERE id = ? LIMIT 1");
    $row->execute([$newId]);
    json(staffRow($row->fetch(PDO::FETCH_ASSOC)));
}

/* ══════════ PUT (обновить) ═══════════════════════════════════════════════ */
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) {
        http_response_code(400);
        json(['error' => 'id required']);
    }

    $d = jsonBody();
    $f = staffFields($d);

    if ($f['full_name'] === '') {
        http_response_code(422);
        json(['error' => 'ФИО обязательно']);
    }

    $set = implode(', ', array_map(fn($c) => "$c = :$c", array_keys($f)));
    $st  = $pdo->prepare(
        "UPDATE staff_members SET $set, updated_at = NOW() WHERE id = :id"
    );
    foreach ($f as $k => $v) {
        $st->bindValue(":$k", $v);
    }
    $st->bindValue(':id', $id, PDO::PARAM_INT);
    $st->execute();

    adminLog($pdo, 'update', 'staff_members', $id, "Обновлён сотрудник: {$f['full_name']}");

    $row = $pdo->prepare("SELECT * FROM staff_members WHERE id = ? LIMIT 1");
    $row->execute([$id]);
    json(staffRow($row->fetch(PDO::FETCH_ASSOC)));
}

/* ══════════ PATCH ══════════════════════════════════════════════════════
   Два режима:
   1) ?reorder=1 + body { items:[{id,sort_order},...] } — массовая пересортировка
   2) ?id=N     + body { sort_order|is_active|is_published } — точечная правка
   ════════════════════════════════════════════════════════════════════════ */
if ($method === 'PATCH') {
    $d = jsonBody();

    // ── Режим 1: массовая пересортировка (drag & drop) ──
    if (!empty($_GET['reorder'])) {
        $items = $d['items'] ?? [];
        if (!is_array($items) || !count($items)) {
            http_response_code(400);
            json(['error' => 'items[] required']);
        }
        $pdo->beginTransaction();
        try {
            $upd = $pdo->prepare("UPDATE staff_members SET sort_order = :so, updated_at = NOW() WHERE id = :id");
            foreach ($items as $it) {
                $id = (int)($it['id'] ?? 0);
                $so = (int)($it['sort_order'] ?? 0);
                if (!$id) continue;
                $upd->execute([':so' => $so, ':id' => $id]);
            }
            $pdo->commit();
            adminLog($pdo, 'update', 'staff_members', 0, 'Изменён порядок сотрудников: ' . count($items) . ' шт.');
            json(['success' => true, 'updated' => count($items)]);
        } catch (Exception $e) {
            $pdo->rollBack();
            http_response_code(500);
            json(['error' => 'reorder failed: ' . $e->getMessage()]);
        }
    }

    // ── Режим 2: точечная правка ──
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $allowed = ['sort_order', 'is_active'];
    $set = []; $params = [':id' => $id];

    if (array_key_exists('sort_order', $d))   { $set[] = "sort_order = :sort_order"; $params[':sort_order'] = (int)$d['sort_order']; }
    if (array_key_exists('is_published', $d)) { $set[] = "is_active = :is_active";   $params[':is_active']  = (int)(bool)$d['is_published']; }
    if (array_key_exists('is_active', $d))    { $set[] = "is_active = :is_active";   $params[':is_active']  = (int)(bool)$d['is_active']; }

    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }

    $pdo->prepare("UPDATE staff_members SET " . implode(', ', $set) . ", updated_at = NOW() WHERE id = :id")
        ->execute($params);

    $row = $pdo->prepare("SELECT * FROM staff_members WHERE id = ? LIMIT 1");
    $row->execute([$id]);
    json(staffRow($row->fetch(PDO::FETCH_ASSOC)));
}

/* ══════════ DELETE ═══════════════════════════════════════════════════════ */
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) {
        http_response_code(400);
        json(['error' => 'id required']);
    }

    $check = $pdo->prepare("SELECT full_name FROM staff_members WHERE id = ? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        http_response_code(404);
        json(['error' => 'Not found']);
    }

    $pdo->prepare("DELETE FROM staff_members WHERE id = ?")->execute([$id]);
    adminLog($pdo, 'delete', 'staff_members', $id, "Удалён сотрудник: {$row['full_name']}");

    http_response_code(204);
    exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);
