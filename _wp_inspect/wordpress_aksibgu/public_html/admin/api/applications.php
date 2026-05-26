<?php
/**
 * API: applications
 * GET    ?page=&limit=&search=&status=&type=&specialty=&date_from=&date_to=
 * GET    ?id=
 * GET    ?export=csv
 * POST   create
 * PUT    ?id=  full update
 * PATCH  ?id=  {status, rejection_reason}
 * POST   ?action=bulk_status  {ids:[], status}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// ── CSV export ─────────────────────────────────────────────────────────────
if ($method === 'GET' && !empty($_GET['export']) && $_GET['export'] === 'csv') {
    $where = ['1=1']; $params = [];
    if (!empty($_GET['status']))    { $where[] = "status=?"; $params[] = $_GET['status']; }
    if (!empty($_GET['type']))      { $where[] = "type=?";   $params[] = $_GET['type'];   }
    if (!empty($_GET['specialty'])) { $where[] = "specialty_text LIKE ?"; $params[] = '%'.$_GET['specialty'].'%'; }
    if (!empty($_GET['date_from'])) { $where[] = "created_at >= ?"; $params[] = $_GET['date_from']; }
    if (!empty($_GET['date_to']))   { $where[] = "created_at <= ?"; $params[] = $_GET['date_to'].' 23:59:59'; }

    $ws = implode(' AND ', $where);
    $st = $pdo->prepare("SELECT * FROM applications WHERE $ws ORDER BY created_at DESC");
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="applications_' . date('Y-m-d') . '.csv"');
    $out = fopen('php://output', 'w');
    fprintf($out, chr(0xEF).chr(0xBB).chr(0xBF)); // UTF-8 BOM
    if ($rows) {
        fputcsv($out, ['ID','ФИО','Email','Телефон','Тип','Специальность','Статус','Примечание','Дата']);
        foreach ($rows as $r) {
            fputcsv($out, [
                $r['id'], $r['full_name'], $r['email'], $r['phone'],
                $r['type'], $r['specialty_text'], $r['status'],
                $r['notes'] ?? '', $r['created_at']
            ]);
        }
    }
    fclose($out);
    exit;
}

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st = $pdo->prepare("SELECT * FROM applications WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if (!$row) { http_response_code(404); json(['error' => 'Not found']); }
        // decode payload
        if (!empty($row['payload_json'])) {
            $row['payload'] = json_decode($row['payload_json'], true);
        }
        json($row);
    }

    $page   = max(1, (int)($_GET['page']  ?? 1));
    $limit  = min(200, max(1, (int)($_GET['limit'] ?? 25)));
    $offset = ($page - 1) * $limit;

    $where = ['1=1']; $params = [];

    if (!empty($_GET['search'])) {
        $s = '%'.$_GET['search'].'%';
        $where[]  = "(full_name LIKE ? OR email LIKE ? OR phone LIKE ? OR specialty_text LIKE ?)";
        $params   = array_merge($params, [$s, $s, $s, $s]);
    }
    if (!empty($_GET['status']))    { $where[] = "status=?";   $params[] = $_GET['status'];   }
    if (!empty($_GET['type']))      { $where[] = "type=?";     $params[] = $_GET['type'];     }
    if (!empty($_GET['specialty'])) { $where[] = "specialty_text LIKE ?"; $params[] = '%'.$_GET['specialty'].'%'; }
    if (!empty($_GET['date_from'])) { $where[] = "created_at >= ?"; $params[] = $_GET['date_from']; }
    if (!empty($_GET['date_to']))   { $where[] = "created_at <= ?"; $params[] = $_GET['date_to'].' 23:59:59'; }

    $ws = implode(' AND ', $where);

    $total = (int)$pdo->prepare("SELECT COUNT(*) FROM applications WHERE $ws")->execute($params) ? 0 : 0;
    $tcnt  = $pdo->prepare("SELECT COUNT(*) FROM applications WHERE $ws");
    $tcnt->execute($params);
    $totalCount = (int)$tcnt->fetchColumn();

    $st = $pdo->prepare("SELECT * FROM applications WHERE $ws ORDER BY created_at DESC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    // status counts for badge
    $statusCounts = [];
    try {
        $sc = $pdo->query("SELECT status, COUNT(*) as cnt FROM applications GROUP BY status");
        foreach ($sc->fetchAll(PDO::FETCH_ASSOC) as $r) {
            $statusCounts[$r['status']] = (int)$r['cnt'];
        }
    } catch (Exception $e) {}

    json([
        'data'          => $rows,
        'total'         => $totalCount,
        'page'          => $page,
        'limit'         => $limit,
        'pages'         => ceil($totalCount / $limit),
        'status_counts' => $statusCounts,
    ]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();

    // Bulk status action
    if (!empty($_GET['action']) && $_GET['action'] === 'bulk_status') {
        $ids    = array_map('intval', $d['ids']    ?? []);
        $status = $d['status'] ?? '';
        $validStatuses = ['new','processing','approved','rejected','archived'];
        if (!$ids || !in_array($status, $validStatuses)) {
            http_response_code(422);
            json(['error' => 'Invalid ids or status']);
        }
        $ph  = implode(',', array_fill(0, count($ids), '?'));
        $params = $ids;
        $params[] = $status;
        $pdo->prepare("UPDATE applications SET status=?, updated_at=NOW() WHERE id IN ($ph)")
            ->execute(array_merge([$status], $ids));
        adminLog($pdo, 'bulk_status', 'applications', 0, "Bulk: $status для ".count($ids)." заявок");
        json(['updated' => count($ids)]);
    }

    // Create
    $fields = [
        'full_name'        => trim($d['full_name']        ?? ''),
        'email'            => trim($d['email']            ?? ''),
        'phone'            => trim($d['phone']            ?? ''),
        'type'             => $d['type']                  ?? 'documents',
        'specialty_text'   => trim($d['specialty_text']   ?? ''),
        'education_form'   => trim($d['education_form']   ?? ''),
        'message'          => trim($d['message']          ?? ''),
        'notes'            => trim($d['notes']            ?? ''),
        'status'           => $d['status']                ?? 'new',
        'rejection_reason' => trim($d['rejection_reason'] ?? ''),
        'payload_json'     => !empty($d['payload']) ? json_encode($d['payload'], JSON_UNESCAPED_UNICODE) : null,
    ];

    if (!$fields['full_name'] || !$fields['email']) {
        http_response_code(422);
        json(['error' => 'ФИО и Email обязательны']);
    }

    $cols = array_keys($fields);
    $ph   = array_map(fn($c) => ":$c", $cols);
    $st   = $pdo->prepare("INSERT INTO applications (".implode(',', $cols).") VALUES (".implode(',', $ph).")");
    foreach ($fields as $k => $v) $st->bindValue(":$k", $v);
    $st->execute();
    $newId = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'applications', $newId, "Создана заявка: {$fields['full_name']}");
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM applications WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PUT ────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $d = jsonBody();
    $fields = [
        'full_name'        => trim($d['full_name']        ?? ''),
        'email'            => trim($d['email']            ?? ''),
        'phone'            => trim($d['phone']            ?? ''),
        'type'             => $d['type']                  ?? 'documents',
        'specialty_text'   => trim($d['specialty_text']   ?? ''),
        'education_form'   => trim($d['education_form']   ?? ''),
        'message'          => trim($d['message']          ?? ''),
        'notes'            => trim($d['notes']            ?? ''),
        'status'           => $d['status']                ?? 'new',
        'rejection_reason' => trim($d['rejection_reason'] ?? ''),
    ];

    if (!empty($d['payload'])) {
        $fields['payload_json'] = json_encode($d['payload'], JSON_UNESCAPED_UNICODE);
    }

    $set = implode(', ', array_map(fn($c) => "$c=:$c", array_keys($fields)));
    $st  = $pdo->prepare("UPDATE applications SET $set, updated_at=NOW() WHERE id=:id");
    foreach ($fields as $k => $v) $st->bindValue(":$k", $v);
    $st->bindValue(':id', $id);
    $st->execute();

    adminLog($pdo, 'update', 'applications', $id, "Обновлена заявка: {$fields['full_name']}");
    $row = $pdo->prepare("SELECT * FROM applications WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── PATCH ──────────────────────────────────────────────────────────────────
if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $d       = jsonBody();
    $allowed = ['status', 'rejection_reason', 'notes'];
    $set     = []; $params = [':id' => $id];
    foreach ($allowed as $field) {
        if (array_key_exists($field, $d)) {
            $set[]           = "$field=:$field";
            $params[":$field"] = $d[$field];
        }
    }
    if (!$set) { http_response_code(400); json(['error' => 'No fields']); }

    $pdo->prepare("UPDATE applications SET ".implode(', ', $set).", updated_at=NOW() WHERE id=:id")
        ->execute($params);

    if (isset($d['status'])) {
        adminLog($pdo, 'status_change', 'applications', $id, "Статус → {$d['status']}");
    }

    $row = $pdo->prepare("SELECT * FROM applications WHERE id=? LIMIT 1");
    $row->execute([$id]);
    json($row->fetch(PDO::FETCH_ASSOC));
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); json(['error' => 'id required']); }

    $check = $pdo->prepare("SELECT full_name FROM applications WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) { http_response_code(404); json(['error' => 'Not found']); }

    // delete related documents
    $pdo->prepare("DELETE FROM application_documents WHERE application_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM applications WHERE id=?")->execute([$id]);
    adminLog($pdo, 'delete', 'applications', $id, "Удалена заявка: {$row['full_name']}");

    http_response_code(204);
    exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);