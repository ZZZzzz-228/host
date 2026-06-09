<?php
/**
 * АКСИБГУУ — Конфигурация
 * config.php → public_html/admin/config.php
 */

// ── Настройки БД ───────────────────────────────────────────────────────────
define('DB_HOST',    'localhost');
define('DB_NAME',    'cf990597_aksibgu');
define('DB_USER',    'cf990597_aksibgu');
define('DB_PASS',    'aen5fNt8');
define('DB_CHARSET', 'utf8mb4');

// ── Настройки безопасности ─────────────────────────────────────────────────
define('SESSION_LIFETIME', 7200); // 2 часа
define('SITE_URL',   'https://cf990597-wordpress-yndvp.tw1.ru');
define('ADMIN_URL',  SITE_URL . '/admin');

// ── Старт сессии ────────────────────────────────────────────────────────────
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_httponly', 1);
    ini_set('session.use_strict_mode', 1);
    ini_set('session.cookie_samesite', 'Lax');
    session_start();
}

// ── PDO singleton ───────────────────────────────────────────────────────────
function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }
    return $pdo;
}

// ── JSON response ────────────────────────────────────────────────────────────
/**
 * Отправить JSON и завершить скрипт
 */
function json($data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    header('X-Content-Type-Options: nosniff');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

// ── Read JSON body ───────────────────────────────────────────────────────────
/**
 * Прочитать тело запроса как JSON
 */
function jsonBody(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

// ── Session check ────────────────────────────────────────────────────────────
/**
 * Проверить авторизацию — для API. При неудаче возвращает 401 JSON.
 */
function sessionCheck(): void {
    if (empty($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
        json(['error' => 'Unauthorised', 'redirect' => '../login.php'], 401);
    }
    // Проверка TTL сессии
    if (!empty($_SESSION['admin_login_time']) && (time() - $_SESSION['admin_login_time']) > SESSION_LIFETIME) {
        session_destroy();
        json(['error' => 'Session expired', 'redirect' => '../login.php'], 401);
    }
    // Обновляем время активности
    $_SESSION['admin_login_time'] = time();
}

// ── Admin log ────────────────────────────────────────────────────────────────
/**
 * Записать действие в журнал admin_logs
 */
function adminLog(PDO $pdo, string $action, string $tableName, int $recordId, string $message): void {
    try {
        $pdo->prepare(
            "INSERT INTO admin_logs (admin_id, action, table_name, record_id, message, ip_address, created_at)
             VALUES (?, ?, ?, ?, ?, ?, NOW())"
        )->execute([
            (int)($_SESSION['admin_id'] ?? 0),
            $action,
            $tableName,
            $recordId,
            mb_substr($message, 0, 500),
            $_SERVER['REMOTE_ADDR'] ?? '',
        ]);
    } catch (Exception $e) {}
}

// ── Legacy aliases ────────────────────────────────────────────────────────────
// Для совместимости со старым кодом login.php
function requireAuth(): void {
    sessionCheck();
}

function jsonResponse(array $data, int $code = 200): void {
    json($data, $code);
}

function sanitize(string $str): string {
    return htmlspecialchars(strip_tags(trim($str)), ENT_QUOTES, 'utf8');
}

function logAction(string $action, string $details = ''): void {
    try {
        adminLog(getDB(), $action, '', 0, $details);
    } catch (Exception $e) {}
}