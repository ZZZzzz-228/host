<?php
/**
 * АКСИБГУУ — Публичный API для Flutter-приложения
 * Путь на хостинге: public_html/public_api/index.php
 *
 * Роуты (GET):
 *   /news              → новости (is_published=1)
 *   /stories           → истории (is_published=1)
 *   /contacts          → контакты (?category=...)
 *   /specialties       → специальности (is_active=1)
 *   /partners          → партнёры (is_active=1)
 *   /education-programs → программы доп. образования (is_active=1)
 *   /events            → мероприятия (is_published=1)
 *   /staff             → сотрудники (?department=...)
 *   /pages/{slug}      → страница по slug
 *   /vacancies         → вакансии (is_published=1)
 *   /universities      → университеты (is_active=1)
 *   /health            → проверка работоспособности
 *
 * Роуты (POST):
 *   /applications      → подача заявления (public)
 *
 * Авторизованные роуты (Bearer token):
 *   /auth/login              → вход студента
 *   /student/profile         → профиль студента
 *   /student/resumes         → список резюме
 *   /student/resumes/full    → создать полное резюме
 *   /student/portfolio       → портфолио
 *   /student/specialties     → специальности + вопросы для резюме
 */

// ── Конфиг БД ────────────────────────────────────────────────────────────────
define('DB_HOST',    'localhost');
define('DB_NAME',    'cf990597_aksibgu');
define('DB_USER',    'cf990597_aksibgu');
define('DB_PASS',    'aen5fNt8');
define('DB_CHARSET', 'utf8mb4');
define('SITE_URL',   'https://cf990597-wordpress-yndvp.tw1.ru');

// ── CORS ─────────────────────────────────────────────────────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ── PDO singleton ─────────────────────────────────────────────────────────────
function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=' . DB_CHARSET;
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }
    return $pdo;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function json_out(mixed $data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function fix_url(string $url): string {
    if (empty($url)) return '';
    if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) return $url;
    return SITE_URL . '/' . ltrim($url, '/');
}

function json_body(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function get_bearer_token(): ?string {
    $auth = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? $_SERVER['Authorization']
        ?? '';
    if ($auth === '' && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }
    if (str_starts_with($auth, 'Bearer ')) {
        return trim(substr($auth, 7));
    }
    return null;
}

function require_auth(): array {
    $token = get_bearer_token();
    if (!$token) json_out(['error' => 'Unauthorised'], 401);

    $pdo = getDB();
    $st = $pdo->prepare('SELECT * FROM students WHERE api_token = ? AND is_active = 1 LIMIT 1');
    $st->execute([$token]);
    $student = $st->fetch();
    if (!$student) json_out(['error' => 'Unauthorised'], 401);
    return $student;
}

// ── Роутинг ───────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = preg_replace('#^/public_api#', '', $uri);
$uri = preg_replace('#^/index\.php#', '', $uri);
$uri = rtrim($uri, '/') ?: '/';

// ────────────────────────────────────────────────────────────────────────────
// GET /health
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/health') {
    json_out(['status' => 'ok', 'time' => date('c')]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /news
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/news') {
    $pdo = getDB();
    $rows = $pdo->query(
        "SELECT id, title, COALESCE(NULLIF(excerpt,''), content) AS content, cover_image AS image_url, published_at, category, tags
         FROM news_items
         WHERE is_published = 1
         ORDER BY is_pinned DESC, published_at DESC
         LIMIT 100"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['image_url'] = fix_url($r['image_url'] ?? '');
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /stories
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/stories') {
    $pdo = getDB();
    $rows = $pdo->query(
        "SELECT id, title, description AS content, cover_image AS image_url, images_json, sort_order
         FROM stories
         WHERE is_published = 1
         ORDER BY is_featured DESC, sort_order ASC, created_at DESC
         LIMIT 50"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['image_url'] = fix_url($r['image_url'] ?? '');
        if (!empty($r['images_json'])) {
            $imgs = json_decode($r['images_json'], true);
            if (is_array($imgs)) {
                $r['images_json'] = array_values(array_map('fix_url', array_filter($imgs)));
            }
        }
        if (empty($r['images_json'])) {
            $r['images_json'] = $r['image_url'] ? [$r['image_url']] : [];
        }
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /contacts
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/contacts') {
    $pdo = getDB();
    $category = trim($_GET['category'] ?? '');

    if ($category !== '') {
        $st = $pdo->prepare(
            "SELECT id, category, label, name, position, phone, email, address, vk_url
             FROM contacts
             WHERE is_active = 1 AND category = ?
             ORDER BY sort_order ASC, name ASC"
        );
        $st->execute([$category]);
    } else {
        $st = $pdo->query(
            "SELECT id, category, label, name, position, phone, email, address, vk_url
             FROM contacts
             WHERE is_active = 1
             ORDER BY category ASC, sort_order ASC, name ASC"
        );
    }
    $rows = $st->fetchAll();

    $result = [];
    $autoId = 1000;
    foreach ($rows as $r) {
        $lbl = $r['name'] ?: $r['label'] ?: '';
        if (!empty($r['phone'])) {
            $result[] = ['id' => $autoId++, 'type' => 'phone',   'value' => $r['phone'],   'label' => $lbl];
        }
        if (!empty($r['email'])) {
            $result[] = ['id' => $autoId++, 'type' => 'email',   'value' => $r['email'],   'label' => $lbl];
        }
        if (!empty($r['address'])) {
            $result[] = ['id' => $autoId++, 'type' => 'address', 'value' => $r['address'], 'label' => $lbl];
        }
        if (!empty($r['vk_url'])) {
            $result[] = ['id' => $autoId++, 'type' => 'website', 'value' => $r['vk_url'],  'label' => $lbl];
        }
    }
    json_out(['data' => $result]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /career-contacts — сотрудники Центра карьеры (карточки в приложении)
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/career-contacts') {
    $pdo = getDB();
    $st = $pdo->prepare(
        "SELECT id, label, name, position, department, phone, email, address,
                room, schedule, vk_url, photo_url, sort_order
         FROM contacts
         WHERE is_active = 1 AND category = 'career_center'
         ORDER BY sort_order ASC, name ASC, label ASC"
    );
    $st->execute();
    $rows = $st->fetchAll();
    $out = [];
    foreach ($rows as $r) {
        $out[] = [
            'id'         => (int) $r['id'],
            'label'      => (string) ($r['label'] ?? ''),
            'name'       => (string) ($r['name'] ?? ''),
            'position'   => (string) ($r['position'] ?? ''),
            'department' => (string) ($r['department'] ?? ''),
            'phone'      => (string) ($r['phone'] ?? ''),
            'email'      => (string) ($r['email'] ?? ''),
            'address'    => (string) ($r['address'] ?? ''),
            'room'       => (string) ($r['room'] ?? ''),
            'schedule'   => (string) ($r['schedule'] ?? ''),
            'vk_url'     => fix_url((string) ($r['vk_url'] ?? '')),
            'photo_url'  => fix_url((string) ($r['photo_url'] ?? '')),
            'sort_order' => (int) ($r['sort_order'] ?? 0),
        ];
    }
    json_out(['data' => $out]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /specialties
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/specialties') {
    $pdo = getDB();
    $rows = $pdo->query(
        "SELECT id, code, title, short_title, description, duration_label, study_form_label,
                qualification_text, career_text, skills_text, salary_text,
                color_hex, icon_name, image_url, gosuslugi_url
         FROM specialties
         WHERE is_published = 1
         ORDER BY sort_order ASC, title ASC"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['image_url'] = fix_url($r['image_url'] ?? '');
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /partners
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/partners') {
    $pdo = getDB();
    $rows = $pdo->query(
        "SELECT id, name, description, website_url, logo_url
         FROM partners
         WHERE is_active = 1
         ORDER BY sort_order ASC, name ASC"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['logo_url'] = fix_url($r['logo_url'] ?? '');
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /education-programs
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/education-programs') {
    $pdo = getDB();
    $rows = $pdo->query(
        "SELECT id, title, form AS type, description,
                COALESCE(for_whom, '')    AS target_audience,
                COALESCE(what_you_get,'') AS outcome_text,
                COALESCE(format_text, '') AS format_text,
                duration_years, duration_hours,
                COALESCE(duration_type,'years') AS duration_type,
                admission_info AS details,
                '' AS icon_name, '' AS color_hex, image_url
         FROM education_programs
         WHERE is_active = 1
         ORDER BY sort_order ASC, title ASC"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['image_url'] = fix_url($r['image_url'] ?? '');
        $dtype = $r['duration_type'] ?? 'years';
        if ($dtype === 'hours' && !empty($r['duration_hours'])) {
            $r['duration_label'] = $r['duration_hours'] . ' ч';
        } elseif (!empty($r['duration_years'])) {
            $r['duration_label'] = $r['duration_years'] . ' лет';
        } else {
            $r['duration_label'] = '';
        }
        unset($r['duration_years'], $r['duration_hours'], $r['duration_type']);
    }
    unset($r);
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /events
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/events') {
    $pdo = getDB();
    $rows = $pdo->query(
        "SELECT id, title, description, event_type AS category,
                cover_image AS cover_url, registration_url AS external_url,
                starts_at, ends_at, location
         FROM career_events
         WHERE is_published = 1
         ORDER BY starts_at DESC, sort_order ASC
         LIMIT 50"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['cover_url'] = fix_url($r['cover_url'] ?? '');
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /staff
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/staff') {
    $pdo = getDB();
    $department = trim($_GET['department'] ?? '');

    if ($department !== '') {
        $st = $pdo->prepare(
            "SELECT id, full_name, position AS position_title, email, phone,
                    schedule AS office_hours, photo_url, '' AS color_hex
             FROM staff_members
             WHERE is_active = 1 AND role = ?
             ORDER BY sort_order ASC, full_name ASC"
        );
        $st->execute([$department]);
    } else {
        $st = $pdo->query(
            "SELECT id, full_name, position AS position_title, email, phone,
                    schedule AS office_hours, photo_url, '' AS color_hex
             FROM staff_members
             WHERE is_active = 1
             ORDER BY sort_order ASC, full_name ASC"
        );
    }
    $rows = $st->fetchAll();
    foreach ($rows as &$r) {
        $r['photo_url'] = fix_url($r['photo_url'] ?? '');
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /vacancies
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/vacancies') {
    $pdo = getDB();
    $q = trim($_GET['q'] ?? '');

    if ($q !== '') {
        $like = '%' . $q . '%';
        $st = $pdo->prepare(
            "SELECT id, title, company_name AS company, location AS city, employment_type,
                    CONCAT(COALESCE(salary_from,''), IF(salary_to, CONCAT(' - ', salary_to),''), ' ', salary_currency) AS salary,
                    description, created_at AS published_at
             FROM vacancies
             WHERE is_active = 1 AND (title LIKE ? OR company_name LIKE ? OR description LIKE ?)
             ORDER BY created_at DESC LIMIT 50"
        );
        $st->execute([$like, $like, $like]);
    } else {
        $st = $pdo->query(
            "SELECT id, title, company_name AS company, location AS city, employment_type,
                    CONCAT(COALESCE(salary_from,''), IF(salary_to, CONCAT(' - ', salary_to),''), ' ', salary_currency) AS salary,
                    description, created_at AS published_at
             FROM vacancies
             WHERE is_active = 1
             ORDER BY created_at DESC LIMIT 50"
        );
    }
    json_out(['data' => $st->fetchAll()]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /universities  — список университетов для приложения
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/universities') {
    $pdo = getDB();
    // Авто-создание таблицы если ещё нет
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `universities` (
          `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
          `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `short_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `description` text COLLATE utf8mb4_unicode_ci,
          `full_text` mediumtext COLLATE utf8mb4_unicode_ci,
          `url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `admission_url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `vk_url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `telegram_url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `logo_url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `cover_url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `city` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `address` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `phone` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `tags` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `specialties_offered` text COLLATE utf8mb4_unicode_ci,
          `sort_order` int NOT NULL DEFAULT '0',
          `is_active` tinyint(1) NOT NULL DEFAULT '1',
          `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (\Exception $e) {}

    $rows = $pdo->query(
        "SELECT id, name, short_name, description, full_text, url, admission_url,
                vk_url, telegram_url, logo_url, cover_url,
                city, address, phone, email, tags, specialties_offered, sort_order
         FROM universities
         WHERE is_active = 1
         ORDER BY sort_order ASC, name ASC
         LIMIT 100"
    )->fetchAll();

    foreach ($rows as &$r) {
        $r['logo_url']  = fix_url($r['logo_url']  ?? '');
        $r['cover_url'] = fix_url($r['cover_url'] ?? '');
        // Разбираем specialties_offered из JSON
        if (!empty($r['specialties_offered'])) {
            $specs = json_decode($r['specialties_offered'], true);
            $r['specialties_offered'] = is_array($specs) ? $specs : [];
        } else {
            $r['specialties_offered'] = [];
        }
        // Теги в массив
        if (!empty($r['tags'])) {
            $r['tags_list'] = array_map('trim', explode(',', $r['tags']));
        } else {
            $r['tags_list'] = [];
        }
    }
    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /pages/{slug}
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && preg_match('#^/pages/([a-z0-9_-]+)$#i', $uri, $m)) {
    $slug = $m[1];
    $pdo = getDB();
    try {
        $cols = array_column($pdo->query("SHOW COLUMNS FROM `pages`")->fetchAll(PDO::FETCH_ASSOC), 'Field');
        $migs = [
            'content_json'    => "ALTER TABLE `pages` ADD COLUMN `content_json` LONGTEXT NULL AFTER `content`",
            'cover_image_url' => "ALTER TABLE `pages` ADD COLUMN `cover_image_url` VARCHAR(512) NOT NULL DEFAULT '' AFTER `cover_image`",
            'audience'        => "ALTER TABLE `pages` ADD COLUMN `audience` VARCHAR(255) NOT NULL DEFAULT '' AFTER `excerpt`",
        ];
        foreach($migs as $col => $sql) {
            if(!in_array($col, $cols)) { try { $pdo->exec($sql); } catch(\Exception $e) {} }
        }
    } catch(\Exception $e) {}

    $st = $pdo->prepare(
        "SELECT slug, title, audience, content_json, cover_image_url, cover_image, is_published
         FROM pages
         WHERE slug = ? AND is_published = 1 LIMIT 1"
    );
    $st->execute([$slug]);
    $row = $st->fetch();
    if (!$row) json_out(['error' => 'Not found'], 404);
    $coverUrl = $row['cover_image_url'] ?? '';
    if(empty($coverUrl)) $coverUrl = $row['cover_image'] ?? '';
    $row['cover_image_url'] = fix_url($coverUrl);
    unset($row['cover_image']);
    json_out(['data' => $row]);
}

// ────────────────────────────────────────────────────────────────────────────
// POST /applications
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'POST' && $uri === '/applications') {
    $pdo = getDB();
    $body = json_body();

    $type      = trim($body['type'] ?? 'other');
    $full_name = trim($body['full_name'] ?? '');
    $email     = trim($body['email'] ?? '');
    $phone     = trim($body['phone'] ?? '');
    $payload   = $body['payload'] ?? [];

    if (!$full_name) json_out(['error' => 'full_name is required'], 422);

    $st = $pdo->prepare(
        "INSERT INTO applications (type, full_name, email, phone, status, payload_json, created_at)
         VALUES (?, ?, ?, ?, 'new', ?, NOW())"
    );
    $st->execute([$type, $full_name, $email, $phone, json_encode($payload, JSON_UNESCAPED_UNICODE)]);
    $id = (int)$pdo->lastInsertId();
    json_out(['id' => $id, 'status' => 'created'], 201);
}

// ────────────────────────────────────────────────────────────────────────────
// POST /auth/login  (студент)
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'POST' && $uri === '/auth/login') {
    $pdo = getDB();
    $body = json_body();
    $email    = trim($body['email'] ?? '');
    $password = $body['password'] ?? '';

    if (!$email || !$password) json_out(['error' => 'email and password required'], 422);

    $st = $pdo->prepare("SELECT * FROM students WHERE email = ? AND is_active = 1 LIMIT 1");
    $st->execute([$email]);
    $student = $st->fetch();

    if (!$student || !password_verify($password, $student['password_hash'])) {
        json_out(['error' => 'Invalid credentials'], 401);
    }

    $token = bin2hex(random_bytes(32));
    $pdo->prepare("UPDATE students SET api_token = ?, last_login = NOW() WHERE id = ?")
        ->execute([$token, $student['id']]);

    json_out([
        'token' => $token,
        'id'    => $student['id'],
        'user'  => [
            'id'        => $student['id'],
            'full_name' => $student['full_name'] ?? '',
            'email'     => $student['email'] ?? '',
            'roles'     => ['student'],
        ],
    ]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /student/profile
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/student/profile') {
    $student = require_auth();
    $pdo = getDB();

    $group = null;
    if (!empty($student['group_id'])) {
        $g = $pdo->prepare("SELECT name FROM groups_ref WHERE id = ? LIMIT 1");
        $g->execute([$student['group_id']]);
        $group = $g->fetchColumn();
    }

    json_out(['data' => [
        'full_name'    => $student['full_name'] ?? '',
        'email'        => $student['email'] ?? '',
        'group_title'  => $group ?? '',
        'curator_name' => '',
        'bio'          => $student['bio'] ?? '',
    ]]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /student/specialties  — специальности + вопросы для резюме
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/student/specialties') {
    require_auth();
    $pdo = getDB();

    $specialties = $pdo->query(
        "SELECT id, code, title, short_title
         FROM specialties
         WHERE is_published = 1
         ORDER BY sort_order ASC, title ASC"
    )->fetchAll();

    // Авто-создание таблицы вопросов если нет
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `specialty_resume_questions` (
          `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
          `specialty_id` int UNSIGNED NOT NULL,
          `question` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
          `field_type` enum('text','textarea','select','multiselect','number','date') NOT NULL DEFAULT 'text',
          `field_options` text COLLATE utf8mb4_unicode_ci,
          `is_required` tinyint(1) NOT NULL DEFAULT '0',
          `sort_order` int NOT NULL DEFAULT '0',
          PRIMARY KEY (`id`),
          KEY `specialty_id` (`specialty_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (\Exception $e) {}

    $qStmt = $pdo->prepare(
        "SELECT id, question, field_type, field_options, is_required, sort_order
         FROM specialty_resume_questions
         WHERE specialty_id = ?
         ORDER BY sort_order ASC, id ASC"
    );

    foreach ($specialties as &$spec) {
        $qStmt->execute([$spec['id']]);
        $questions = $qStmt->fetchAll();
        foreach ($questions as &$q) {
            if (!empty($q['field_options'])) {
                $opts = json_decode($q['field_options'], true);
                $q['field_options'] = is_array($opts) ? $opts : [];
            } else {
                $q['field_options'] = [];
            }
        }
        $spec['resume_questions'] = $questions;
    }

    json_out(['data' => $specialties]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /student/resumes
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/student/resumes') {
    $student = require_auth();
    $pdo = getDB();

    // Авто-создание таблицы
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `student_resumes` (
          `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
          `student_id` int UNSIGNED NOT NULL,
          `specialty_id` int UNSIGNED DEFAULT NULL,
          `specialty_custom` varchar(255) NOT NULL DEFAULT '',
          `last_name` varchar(128) NOT NULL DEFAULT '',
          `first_name` varchar(128) NOT NULL DEFAULT '',
          `middle_name` varchar(128) NOT NULL DEFAULT '',
          `birth_date` date DEFAULT NULL,
          `gender` varchar(16) NOT NULL DEFAULT '',
          `city` varchar(128) NOT NULL DEFAULT '',
          `phone` varchar(32) NOT NULL DEFAULT '',
          `email` varchar(255) NOT NULL DEFAULT '',
          `telegram` varchar(128) NOT NULL DEFAULT '',
          `vk` varchar(255) NOT NULL DEFAULT '',
          `desired_position` varchar(255) NOT NULL DEFAULT '',
          `desired_salary` int UNSIGNED DEFAULT NULL,
          `employment_type` varchar(128) NOT NULL DEFAULT '',
          `schedule` varchar(128) NOT NULL DEFAULT '',
          `work_experience` text,
          `education` text,
          `skills` text,
          `about` text,
          `languages` varchar(512) NOT NULL DEFAULT '',
          `portfolio_links` text,
          `specialty_answers` text,
          `is_published` tinyint(1) NOT NULL DEFAULT '0',
          `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `student_id` (`student_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (\Exception $e) {}

    $st = $pdo->prepare(
        "SELECT r.id, r.desired_position, r.last_name, r.first_name, r.middle_name,
                r.city, r.phone, r.email, r.desired_salary, r.employment_type,
                r.is_published, r.created_at, r.updated_at,
                s.title AS specialty_title
         FROM student_resumes r
         LEFT JOIN specialties s ON s.id = r.specialty_id
         WHERE r.student_id = ?
         ORDER BY r.created_at DESC"
    );
    $st->execute([$student['id']]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        // Формируем title и summary для совместимости со старым кодом
        $r['title'] = $r['desired_position'] ?: 'Резюме';
        $name_parts = array_filter([$r['last_name'], $r['first_name'], $r['middle_name']]);
        $r['summary'] = implode(' ', $name_parts);
    }

    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /student/resumes/{id}  — полное резюме
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && preg_match('#^/student/resumes/(\d+)$#', $uri, $m)) {
    $student = require_auth();
    $pdo = getDB();
    $st = $pdo->prepare(
        "SELECT r.*, s.title AS specialty_title
         FROM student_resumes r
         LEFT JOIN specialties s ON s.id = r.specialty_id
         WHERE r.id = ? AND r.student_id = ? LIMIT 1"
    );
    $st->execute([(int)$m[1], $student['id']]);
    $row = $st->fetch();
    if (!$row) json_out(['error' => 'Not found'], 404);

    // Декодируем JSON поля
    foreach (['work_experience', 'education', 'skills', 'portfolio_links', 'specialty_answers'] as $field) {
        if (!empty($row[$field])) {
            $decoded = json_decode($row[$field], true);
            $row[$field] = is_array($decoded) ? $decoded : [];
        } else {
            $row[$field] = [];
        }
    }
    if (!empty($row['languages'])) {
        $decoded = json_decode($row['languages'], true);
        $row['languages'] = is_array($decoded) ? $decoded : [];
    } else {
        $row['languages'] = [];
    }
    if (!empty($row['employment_type'])) {
        $decoded = json_decode($row['employment_type'], true);
        $row['employment_type'] = is_array($decoded) ? $decoded : [$row['employment_type']];
    }
    if (!empty($row['schedule'])) {
        $decoded = json_decode($row['schedule'], true);
        $row['schedule'] = is_array($decoded) ? $decoded : [$row['schedule']];
    }

    json_out(['data' => $row]);
}

// ────────────────────────────────────────────────────────────────────────────
// POST /student/resumes  — создать / обновить полное резюме
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'POST' && $uri === '/student/resumes') {
    $student = require_auth();
    $pdo = getDB();
    $body = json_body();

    // Совместимость со старым простым форматом
    $desired_position = trim($body['desired_position'] ?? $body['title'] ?? '');

    $fields = [
        'student_id'        => $student['id'],
        'specialty_id'      => !empty($body['specialty_id']) ? (int)$body['specialty_id'] : null,
        'specialty_custom'  => trim($body['specialty_custom'] ?? ''),
        'last_name'         => trim($body['last_name'] ?? ''),
        'first_name'        => trim($body['first_name'] ?? ''),
        'middle_name'       => trim($body['middle_name'] ?? ''),
        'birth_date'        => !empty($body['birth_date']) ? $body['birth_date'] : null,
        'gender'            => trim($body['gender'] ?? ''),
        'city'              => trim($body['city'] ?? ''),
        'phone'             => trim($body['phone'] ?? ''),
        'email'             => trim($body['email'] ?? ''),
        'telegram'          => trim($body['telegram'] ?? ''),
        'vk'                => trim($body['vk'] ?? ''),
        'desired_position'  => $desired_position,
        'desired_salary'    => !empty($body['desired_salary']) ? (int)$body['desired_salary'] : null,
        'employment_type'   => is_array($body['employment_type'] ?? null)
                               ? json_encode($body['employment_type'], JSON_UNESCAPED_UNICODE)
                               : trim($body['employment_type'] ?? ''),
        'schedule'          => is_array($body['schedule'] ?? null)
                               ? json_encode($body['schedule'], JSON_UNESCAPED_UNICODE)
                               : trim($body['schedule'] ?? ''),
        'work_experience'   => json_encode($body['work_experience'] ?? [], JSON_UNESCAPED_UNICODE),
        'education'         => json_encode($body['education'] ?? [], JSON_UNESCAPED_UNICODE),
        'skills'            => json_encode($body['skills'] ?? [], JSON_UNESCAPED_UNICODE),
        'about'             => trim($body['about'] ?? $body['summary'] ?? ''),
        'languages'         => json_encode($body['languages'] ?? [], JSON_UNESCAPED_UNICODE),
        'portfolio_links'   => json_encode($body['portfolio_links'] ?? [], JSON_UNESCAPED_UNICODE),
        'specialty_answers' => json_encode($body['specialty_answers'] ?? [], JSON_UNESCAPED_UNICODE),
        'is_published'      => isset($body['is_published']) ? (int)(bool)$body['is_published'] : 0,
    ];

    $cols = implode(', ', array_keys($fields));
    $phs  = implode(', ', array_map(fn($k) => ":$k", array_keys($fields)));
    $pdo->prepare("INSERT INTO student_resumes ($cols) VALUES ($phs)")->execute($fields);

    $id = (int)$pdo->lastInsertId();
    json_out(['id' => $id, 'status' => 'created'], 201);
}

// ────────────────────────────────────────────────────────────────────────────
// PUT /student/resumes/{id}  — обновить резюме
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'PUT' && preg_match('#^/student/resumes/(\d+)$#', $uri, $m)) {
    $student = require_auth();
    $pdo = getDB();
    $resumeId = (int)$m[1];
    $body = json_body();

    $check = $pdo->prepare("SELECT id FROM student_resumes WHERE id = ? AND student_id = ? LIMIT 1");
    $check->execute([$resumeId, $student['id']]);
    if (!$check->fetch()) json_out(['error' => 'Not found'], 404);

    $desired_position = trim($body['desired_position'] ?? $body['title'] ?? '');

    $fields = [
        'specialty_id'      => !empty($body['specialty_id']) ? (int)$body['specialty_id'] : null,
        'specialty_custom'  => trim($body['specialty_custom'] ?? ''),
        'last_name'         => trim($body['last_name'] ?? ''),
        'first_name'        => trim($body['first_name'] ?? ''),
        'middle_name'       => trim($body['middle_name'] ?? ''),
        'birth_date'        => !empty($body['birth_date']) ? $body['birth_date'] : null,
        'gender'            => trim($body['gender'] ?? ''),
        'city'              => trim($body['city'] ?? ''),
        'phone'             => trim($body['phone'] ?? ''),
        'email'             => trim($body['email'] ?? ''),
        'telegram'          => trim($body['telegram'] ?? ''),
        'vk'                => trim($body['vk'] ?? ''),
        'desired_position'  => $desired_position,
        'desired_salary'    => !empty($body['desired_salary']) ? (int)$body['desired_salary'] : null,
        'employment_type'   => is_array($body['employment_type'] ?? null)
                               ? json_encode($body['employment_type'], JSON_UNESCAPED_UNICODE)
                               : trim($body['employment_type'] ?? ''),
        'schedule'          => is_array($body['schedule'] ?? null)
                               ? json_encode($body['schedule'], JSON_UNESCAPED_UNICODE)
                               : trim($body['schedule'] ?? ''),
        'work_experience'   => json_encode($body['work_experience'] ?? [], JSON_UNESCAPED_UNICODE),
        'education'         => json_encode($body['education'] ?? [], JSON_UNESCAPED_UNICODE),
        'skills'            => json_encode($body['skills'] ?? [], JSON_UNESCAPED_UNICODE),
        'about'             => trim($body['about'] ?? $body['summary'] ?? ''),
        'languages'         => json_encode($body['languages'] ?? [], JSON_UNESCAPED_UNICODE),
        'portfolio_links'   => json_encode($body['portfolio_links'] ?? [], JSON_UNESCAPED_UNICODE),
        'specialty_answers' => json_encode($body['specialty_answers'] ?? [], JSON_UNESCAPED_UNICODE),
        'is_published'      => isset($body['is_published']) ? (int)(bool)$body['is_published'] : 0,
    ];

    $set = implode(', ', array_map(fn($k) => "$k = :$k", array_keys($fields)));
    $fields[':id'] = $resumeId;
    $pdo->prepare("UPDATE student_resumes SET $set, updated_at = NOW() WHERE id = :id")->execute($fields);

    json_out(['id' => $resumeId, 'status' => 'updated']);
}

// ────────────────────────────────────────────────────────────────────────────
// DELETE /student/resumes/{id}
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'DELETE' && preg_match('#^/student/resumes/(\d+)$#', $uri, $m)) {
    $student = require_auth();
    $pdo = getDB();
    $pdo->prepare("DELETE FROM student_resumes WHERE id = ? AND student_id = ?")
        ->execute([(int)$m[1], $student['id']]);
    json_out(['deleted' => true]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /student/portfolio
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/student/portfolio') {
    $student = require_auth();
    $pdo = getDB();

    // Авто-создание таблицы
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `student_portfolio` (
          `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
          `student_id` int UNSIGNED NOT NULL,
          `title` varchar(255) NOT NULL DEFAULT '',
          `description` text,
          `category` varchar(128) NOT NULL DEFAULT '',
          `project_url` varchar(512) NOT NULL DEFAULT '',
          `image_url` varchar(512) NOT NULL DEFAULT '',
          `tags` varchar(512) NOT NULL DEFAULT '',
          `is_published` tinyint(1) NOT NULL DEFAULT '1',
          `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `student_id` (`student_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (\Exception $e) {}

    $st = $pdo->prepare(
        "SELECT id, title, description, category, project_url, image_url, tags, is_published, created_at
         FROM student_portfolio
         WHERE student_id = ?
         ORDER BY created_at DESC"
    );
    $st->execute([$student['id']]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['image_url'] = fix_url($r['image_url'] ?? '');
        // Теги в массив
        if (!empty($r['tags'])) {
            $decoded = json_decode($r['tags'], true);
            $r['tags_list'] = is_array($decoded) ? $decoded : array_map('trim', explode(',', $r['tags']));
        } else {
            $r['tags_list'] = [];
        }
    }

    json_out(['data' => $rows]);
}

// ────────────────────────────────────────────────────────────────────────────
// POST /student/portfolio
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'POST' && $uri === '/student/portfolio') {
    $student = require_auth();
    $pdo = getDB();
    $body = json_body();

    $title       = trim($body['title'] ?? '');
    $description = trim($body['description'] ?? '');
    $category    = trim($body['category'] ?? '');
    $project_url = trim($body['project_url'] ?? '');
    $image_url   = trim($body['image_url'] ?? '');
    $tags        = is_array($body['tags'] ?? null)
                   ? json_encode($body['tags'], JSON_UNESCAPED_UNICODE)
                   : trim($body['tags'] ?? '');

    if (!$title) json_out(['error' => 'title required'], 422);

    $pdo->prepare(
        "INSERT INTO student_portfolio (student_id, title, description, category, project_url, image_url, tags, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, NOW())"
    )->execute([$student['id'], $title, $description, $category, $project_url, $image_url, $tags]);

    json_out(['id' => (int)$pdo->lastInsertId()], 201);
}

// ────────────────────────────────────────────────────────────────────────────
// PUT /student/portfolio/{id}
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'PUT' && preg_match('#^/student/portfolio/(\d+)$#', $uri, $m)) {
    $student = require_auth();
    $pdo = getDB();
    $itemId = (int)$m[1];
    $body = json_body();

    $check = $pdo->prepare("SELECT id FROM student_portfolio WHERE id = ? AND student_id = ? LIMIT 1");
    $check->execute([$itemId, $student['id']]);
    if (!$check->fetch()) json_out(['error' => 'Not found'], 404);

    $tags = is_array($body['tags'] ?? null)
            ? json_encode($body['tags'], JSON_UNESCAPED_UNICODE)
            : trim($body['tags'] ?? '');

    $pdo->prepare(
        "UPDATE student_portfolio SET title=?, description=?, category=?, project_url=?, image_url=?, tags=?, updated_at=NOW()
         WHERE id=? AND student_id=?"
    )->execute([
        trim($body['title'] ?? ''),
        trim($body['description'] ?? ''),
        trim($body['category'] ?? ''),
        trim($body['project_url'] ?? ''),
        trim($body['image_url'] ?? ''),
        $tags,
        $itemId,
        $student['id'],
    ]);

    json_out(['id' => $itemId, 'status' => 'updated']);
}

// ────────────────────────────────────────────────────────────────────────────
// DELETE /student/portfolio/{id}
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'DELETE' && preg_match('#^/student/portfolio/(\d+)$#', $uri, $m)) {
    $student = require_auth();
    $pdo = getDB();
    $pdo->prepare("DELETE FROM student_portfolio WHERE id = ? AND student_id = ?")
        ->execute([(int)$m[1], $student['id']]);
    json_out(['deleted' => true]);
}

// ────────────────────────────────────────────────────────────────────────────
// GET /career-test
// ────────────────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/career-test') {
    $pdo = getDB();

    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `career_tests` (
          `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `title`        VARCHAR(512) NOT NULL DEFAULT '',
          `description`  TEXT,
          `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
          `sort_order`   INT NOT NULL DEFAULT 0,
          `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
        $pdo->exec("CREATE TABLE IF NOT EXISTS `career_test_questions` (
          `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `test_id`    INT UNSIGNED NOT NULL,
          `question`   TEXT NOT NULL,
          `sort_order` INT NOT NULL DEFAULT 0,
          `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`), KEY `test_id` (`test_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
        $pdo->exec("CREATE TABLE IF NOT EXISTS `career_test_answers` (
          `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `question_id`      INT UNSIGNED NOT NULL,
          `text`             TEXT NOT NULL,
          `specialty_ids`    TEXT,
          `sort_order`       INT NOT NULL DEFAULT 0,
          `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`), KEY `question_id` (`question_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (Exception $e) {}

    $test = $pdo->query(
        "SELECT id, title, description FROM career_tests WHERE is_active=1 ORDER BY sort_order ASC, id ASC LIMIT 1"
    )->fetch(PDO::FETCH_ASSOC);

    if (!$test) {
        json_out(['data' => ['questions' => []]]);
    }

    $qs = $pdo->prepare(
        "SELECT id, question FROM career_test_questions WHERE test_id=? ORDER BY sort_order ASC, id ASC"
    );
    $qs->execute([$test['id']]);
    $questions = $qs->fetchAll(PDO::FETCH_ASSOC);

    $aStmt = $pdo->prepare(
        "SELECT id, text, specialty_ids FROM career_test_answers WHERE question_id=? ORDER BY sort_order ASC, id ASC"
    );

    $result = [];
    foreach ($questions as $q) {
        $aStmt->execute([$q['id']]);
        $rawAnswers = $aStmt->fetchAll(PDO::FETCH_ASSOC);
        $answers = [];
        foreach ($rawAnswers as $a) {
            $sids = json_decode($a['specialty_ids'] ?? '[]', true);
            if (!is_array($sids)) $sids = [];
            $answers[] = [
                'text'          => $a['text'],
                'specialty_ids' => $sids,
            ];
        }
        $result[] = [
            'question' => $q['question'],
            'answers'  => $answers,
        ];
    }

    json_out(['data' => ['questions' => $result]]);
}

// 404
json_out(['error' => 'Not found', 'uri' => $uri], 404);
