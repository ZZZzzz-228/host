<?php
/**
 * API: file upload
 * POST multipart/form-data
 *   file     — файл
 *   type     — images|documents|covers (папка назначения, default: uploads)
 *   max_size — переопределить максимум (байты), default 10MB
 *
 * Returns: {url, filename, size, mime}
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    json(['error' => 'Method Not Allowed']);
}

// ── Config ─────────────────────────────────────────────────────────────────
$allowedTypes = [
    'images'    => ['image/jpeg','image/png','image/gif','image/webp','image/svg+xml'],
    'documents' => [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/zip','application/x-rar-compressed',
    ],
    'covers'    => ['image/jpeg','image/png','image/webp'],
];

$typeParam = preg_replace('/[^a-z]/', '', strtolower($_POST['type'] ?? 'images'));
if (!array_key_exists($typeParam, $allowedTypes)) $typeParam = 'images';

$maxSize   = min((int)($_POST['max_size'] ?? 0) ?: 10 * 1024 * 1024, 20 * 1024 * 1024);
$allowed   = $allowedTypes[$typeParam];

// ── Validate upload ─────────────────────────────────────────────────────────
if (empty($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    $err = $_FILES['file']['error'] ?? 'no file';
    http_response_code(400);
    json(['error' => "Ошибка загрузки файла (код: $err)"]);
}

$file     = $_FILES['file'];
$fileSize = $file['size'];
$tmpPath  = $file['tmp_name'];
$origName = $file['name'];

if ($fileSize > $maxSize) {
    http_response_code(413);
    json(['error' => 'Файл слишком большой. Максимум: ' . round($maxSize / 1024 / 1024, 1) . ' МБ']);
}

// MIME check
$finfo    = new finfo(FILEINFO_MIME_TYPE);
$mime     = $finfo->file($tmpPath);
if (!in_array($mime, $allowed)) {
    http_response_code(415);
    json(['error' => "Недопустимый тип файла: $mime"]);
}

// ── Build destination ───────────────────────────────────────────────────────
$uploadDir = dirname(__DIR__) . '/uploads/' . $typeParam . '/' . date('Y/m') . '/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Safe filename
$ext      = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
$baseName = pathinfo($origName, PATHINFO_FILENAME);
$safeName = preg_replace('/[^a-zA-Z0-9_\-а-яёА-ЯЁ]/u', '_', $baseName);
$safeName = mb_substr($safeName, 0, 80);
$unique   = $safeName . '_' . uniqid() . '.' . $ext;
$destPath = $uploadDir . $unique;

if (!move_uploaded_file($tmpPath, $destPath)) {
    http_response_code(500);
    json(['error' => 'Не удалось сохранить файл']);
}

// ── Public URL ──────────────────────────────────────────────────────────────
$proto    = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host     = $_SERVER['HTTP_HOST'];
$basePath = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'])), '/');
$relPath  = '/uploads/' . $typeParam . '/' . date('Y/m') . '/' . $unique;
$publicUrl = $proto . '://' . $host . $basePath . $relPath;

// ── Log to DB ───────────────────────────────────────────────────────────────
try {
    $pdo = getDB();
    $pdo->prepare(
        "INSERT INTO uploaded_files (original_name, stored_name, mime_type, file_size, file_path, url, uploaded_by)
         VALUES (?,?,?,?,?,?,?)"
    )->execute([
        $origName, $unique, $mime, $fileSize,
        $relPath, $publicUrl,
        $_SESSION['admin_id'] ?? 0
    ]);
    adminLog($pdo, 'upload', 'uploaded_files', (int)$pdo->lastInsertId(), "Загружен файл: $origName");
} catch (Exception $e) {
    // non-fatal
}

json([
    'url'      => $publicUrl,
    'path'     => $relPath,
    'filename' => $unique,
    'original' => $origName,
    'size'     => $fileSize,
    'mime'     => $mime,
]);