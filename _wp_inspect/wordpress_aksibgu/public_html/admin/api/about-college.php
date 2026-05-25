<?php
/**
 * API: about-college (специальная страница О колледже)
 * GET    ?id=   → получить страницу по id
 * GET    (без параметров) → получить страницу со slug='about-college'
 * POST   → создать страницу О колледже (slug фиксированный: about-college)
 * PUT    ?id=  → обновить страницу
 *
 * Поля payload:
 *   title, slug (='about-college'), content_json (JSON-строка), 
 *   cover_image_url, audience, is_published, template
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

header('Content-Type: application/json; charset=utf-8');

// Убеждаемся что нужные колонки существуют (авто-миграция)
function ensureColumns(PDO $pdo): void {
    $cols = $pdo->query("SHOW COLUMNS FROM `pages`")->fetchAll(PDO::FETCH_COLUMN);
    $need = [
        'content_json'    => "ALTER TABLE `pages` ADD COLUMN `content_json` LONGTEXT NULL AFTER `content`",
        'cover_image_url' => "ALTER TABLE `pages` ADD COLUMN `cover_image_url` VARCHAR(512) NOT NULL DEFAULT '' AFTER `cover_image`",
        'audience'        => "ALTER TABLE `pages` ADD COLUMN `audience` VARCHAR(255) NOT NULL DEFAULT '' AFTER `excerpt`",
    ];
    foreach($need as $col => $sql) {
        if(!in_array($col, $cols)) {
            try { $pdo->exec($sql); } catch(\Exception $e) { /* already exists */ }
        }
    }
}

ensureColumns($pdo);

const ABOUT_SLUG = 'about-college';

function fixUrl(string $url): string {
    if(empty($url)) return '';
    if(str_starts_with($url,'http://') || str_starts_with($url,'https://')) return $url;
    $base = defined('SITE_URL') ? rtrim(SITE_URL, '/') : '';
    return $base . '/' . ltrim($url, '/');
}

// ── GET ─────────────────────────────────────────────────────────
if($method === 'GET') {
    $id = !empty($_GET['id']) ? (int)$_GET['id'] : 0;
    if($id) {
        $st = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
        $st->execute([$id]);
    } else {
        $st = $pdo->prepare("SELECT * FROM pages WHERE slug=? LIMIT 1");
        $st->execute([ABOUT_SLUG]);
    }
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if(!$row) { http_response_code(404); echo json_encode(['error'=>'Not found']); exit; }
    $row['cover_image_url'] = fixUrl($row['cover_image_url'] ?? $row['cover_image'] ?? '');
    echo json_encode($row, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
    exit;
}

// ── POST ─────────────────────────────────────────────────────────
if($method === 'POST') {
    $d = json_decode(file_get_contents('php://input'), true) ?: [];

    $title          = trim($d['title'] ?? 'О колледже');
    $content_json   = is_string($d['content_json'] ?? null) ? $d['content_json'] : json_encode($d['content_json'] ?? []);
    $cover          = trim($d['cover_image_url'] ?? $d['cover_image'] ?? '');
    $audience       = trim($d['audience'] ?? '');
    $is_published   = isset($d['is_published']) ? (int)(bool)$d['is_published'] : 1;

    // Проверяем — может страница уже есть?
    $check = $pdo->prepare("SELECT id FROM pages WHERE slug=? LIMIT 1");
    $check->execute([ABOUT_SLUG]);
    $existing = $check->fetchColumn();
    if($existing) {
        // Переключаемся на PUT
        $id = (int)$existing;
        $st = $pdo->prepare(
            "UPDATE pages SET title=:title, content_json=:cj, cover_image_url=:cover,
             audience=:audience, is_published=:pub, template='about-college',
             updated_at=NOW() WHERE id=:id"
        );
        $st->execute([
            ':title'=>$title, ':cj'=>$content_json, ':cover'=>$cover,
            ':audience'=>$audience, ':pub'=>$is_published, ':id'=>$id
        ]);
        adminLog($pdo,'update','pages',$id,'Обновлена страница О колледже');
        $row = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
        $row->execute([$id]);
        $data = $row->fetch(PDO::FETCH_ASSOC);
        $data['cover_image_url'] = fixUrl($data['cover_image_url'] ?? '');
        echo json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
        exit;
    }

    $st = $pdo->prepare(
        "INSERT INTO pages (title,slug,content_json,cover_image_url,audience,template,is_published,sort_order,created_at,updated_at)
         VALUES (:title,:slug,:cj,:cover,:audience,'about-college',:pub,0,NOW(),NOW())"
    );
    $st->execute([
        ':title'=>$title, ':slug'=>ABOUT_SLUG, ':cj'=>$content_json,
        ':cover'=>$cover, ':audience'=>$audience, ':pub'=>$is_published
    ]);
    $newId = (int)$pdo->lastInsertId();
    adminLog($pdo,'create','pages',$newId,'Создана страница О колледже');
    http_response_code(201);
    $row = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
    $row->execute([$newId]);
    $data = $row->fetch(PDO::FETCH_ASSOC);
    $data['cover_image_url'] = fixUrl($data['cover_image_url'] ?? '');
    echo json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
    exit;
}

// ── PUT ──────────────────────────────────────────────────────────
if($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    if(!$id) { http_response_code(400); echo json_encode(['error'=>'id required']); exit; }

    $d = json_decode(file_get_contents('php://input'), true) ?: [];
    $title        = trim($d['title'] ?? '');
    $content_json = is_string($d['content_json'] ?? null) ? $d['content_json'] : json_encode($d['content_json'] ?? []);
    $cover        = trim($d['cover_image_url'] ?? $d['cover_image'] ?? '');
    $audience     = trim($d['audience'] ?? '');
    $is_published = isset($d['is_published']) ? (int)(bool)$d['is_published'] : 1;

    $st = $pdo->prepare(
        "UPDATE pages SET title=:title, slug=:slug, content_json=:cj, cover_image_url=:cover,
         audience=:audience, is_published=:pub, template='about-college',
         updated_at=NOW() WHERE id=:id"
    );
    $st->execute([
        ':title'=>$title, ':slug'=>ABOUT_SLUG, ':cj'=>$content_json,
        ':cover'=>$cover, ':audience'=>$audience, ':pub'=>$is_published, ':id'=>$id
    ]);
    adminLog($pdo,'update','pages',$id,'Обновлена страница О колледже');
    $row = $pdo->prepare("SELECT * FROM pages WHERE id=? LIMIT 1");
    $row->execute([$id]);
    $data = $row->fetch(PDO::FETCH_ASSOC);
    $data['cover_image_url'] = fixUrl($data['cover_image_url'] ?? '');
    echo json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
    exit;
}

http_response_code(405);
echo json_encode(['error'=>'Method Not Allowed']);
