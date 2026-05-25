<?php
/**
 * API: site_settings
 * GET           → all settings as {key: value} OR grouped by ?group=
 * POST          → {key, value} single update OR {group, settings:{k:v}} bulk group update
 * GET  ?group=  → filtered by group
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['group'])) {
        $st = $pdo->prepare("SELECT `key`, `value`, `type`, `label`, `group` FROM site_settings WHERE `group`=? ORDER BY sort_order ASC");
        $st->execute([$_GET['group']]);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        // decode JSON-type values
        foreach ($rows as &$r) {
            if ($r['type'] === 'json') {
                $r['value'] = json_decode($r['value'], true);
            }
        }
        json($rows);
    }

    // All settings grouped
    $st = $pdo->query("SELECT `key`, `value`, `type`, `label`, `group` FROM site_settings ORDER BY `group` ASC, sort_order ASC");
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);

    $grouped = [];
    $flat    = [];
    foreach ($rows as $r) {
        $val = ($r['type'] === 'json') ? json_decode($r['value'], true) : $r['value'];
        $flat[$r['key']] = $val;
        $grouped[$r['group']][] = array_merge($r, ['value' => $val]);
    }

    json(['flat' => $flat, 'grouped' => $grouped]);
}

// ── POST ───────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d = jsonBody();

    // Bulk group update: {group: 'general', settings: {key: val, ...}}
    if (!empty($d['group']) && !empty($d['settings']) && is_array($d['settings'])) {
        $updated = 0;
        foreach ($d['settings'] as $key => $val) {
            $key = preg_replace('/[^a-zA-Z0-9_\.\-]/', '', $key);
            if (!$key) continue;
            // encode arrays/objects
            if (is_array($val) || is_object($val)) {
                $val = json_encode($val, JSON_UNESCAPED_UNICODE);
                $type = 'json';
            } else {
                $type = 'text';
            }
            // upsert
            $st = $pdo->prepare(
                "INSERT INTO site_settings (`key`, `value`, `type`, `group`, updated_at)
                 VALUES (:k, :v, :t, :g, NOW())
                 ON DUPLICATE KEY UPDATE `value`=:v2, `type`=:t2, updated_at=NOW()"
            );
            $st->execute([
                ':k' => $key, ':v' => $val, ':t' => $type, ':g' => $d['group'],
                ':v2' => $val, ':t2' => $type,
            ]);
            $updated++;
        }
        adminLog($pdo, 'settings_save', 'site_settings', 0, "Сохранены настройки группы: {$d['group']} ({$updated} ключей)");
        json(['saved' => $updated, 'group' => $d['group']]);
    }

    // Single key update: {key, value}
    if (!empty($d['key'])) {
        $key = preg_replace('/[^a-zA-Z0-9_\.\-]/', '', $d['key']);
        $val = $d['value'] ?? '';
        $grp = $d['group'] ?? 'general';
        if (is_array($val) || is_object($val)) {
            $val  = json_encode($val, JSON_UNESCAPED_UNICODE);
            $type = 'json';
        } else {
            $type = 'text';
        }
        $st = $pdo->prepare(
            "INSERT INTO site_settings (`key`, `value`, `type`, `group`, updated_at)
             VALUES (:k, :v, :t, :g, NOW())
             ON DUPLICATE KEY UPDATE `value`=:v2, `type`=:t2, updated_at=NOW()"
        );
        $st->execute([':k'=>$key,':v'=>$val,':t'=>$type,':g'=>$grp,':v2'=>$val,':t2'=>$type]);
        adminLog($pdo, 'settings_save', 'site_settings', 0, "Обновлена настройка: $key");
        json(['key' => $key, 'value' => $d['value']]);
    }

    http_response_code(422);
    json(['error' => 'Нужно передать group+settings или key+value']);
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $key = $_GET['key'] ?? '';
    if (!$key) { http_response_code(400); json(['error' => 'key required']); }
    $pdo->prepare("DELETE FROM site_settings WHERE `key`=?")->execute([$key]);
    adminLog($pdo, 'delete', 'site_settings', 0, "Удалена настройка: $key");
    http_response_code(204); exit;
}

http_response_code(405);
json(['error' => 'Method Not Allowed']);