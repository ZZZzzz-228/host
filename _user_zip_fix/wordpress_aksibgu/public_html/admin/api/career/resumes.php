<?php
/**
 * API: student_resumes (admin) — схема как в public_api (student_id, is_published)
 */
require_once __DIR__ . '/../../config.php';
sessionCheck();

header('Content-Type: application/json; charset=utf-8');

function ensureResumeTables(PDO $pdo): void
{
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
      KEY `student_id` (`student_id`),
      KEY `specialty_id` (`specialty_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
}

try {
    $pdo    = getDB();
    $method = $_SERVER['REQUEST_METHOD'];
    ensureResumeTables($pdo);

    $nameExpr = "COALESCE(NULLIF(TRIM(CONCAT_WS(' ', r.last_name, r.first_name, r.middle_name)), ''), s.full_name, '')";

    if ($method === 'GET') {
        if (!empty($_GET['id'])) {
            $st = $pdo->prepare(
                "SELECT r.*, {$nameExpr} AS full_name, s.email AS user_email,
                        sp.title AS specialty_title
                 FROM student_resumes r
                 LEFT JOIN students s ON s.id = r.student_id
                 LEFT JOIN specialties sp ON sp.id = r.specialty_id
                 WHERE r.id = ? LIMIT 1"
            );
            $st->execute([(int)$_GET['id']]);
            $row = $st->fetch(PDO::FETCH_ASSOC);
            if (!$row) {
                http_response_code(404);
                json(['error' => 'Not found']);
            }
            json($row);
        }

        $page   = max(1, (int)($_GET['page'] ?? 1));
        $limit  = min(200, max(1, (int)($_GET['limit'] ?? 25)));
        $offset = ($page - 1) * $limit;

        $where  = ['1=1'];
        $params = [];
        if (!empty($_GET['search'])) {
            $s = '%' . $_GET['search'] . '%';
            $where[] = "({$nameExpr} LIKE ? OR r.email LIKE ? OR s.email LIKE ? OR r.desired_position LIKE ?)";
            $params  = array_merge($params, [$s, $s, $s, $s]);
        }
        if (isset($_GET['is_published']) && $_GET['is_published'] !== '') {
            $where[] = 'r.is_published = ?';
            $params[] = (int)$_GET['is_published'];
        }
        if (!empty($_GET['student_id'])) {
            $where[] = 'r.student_id = ?';
            $params[] = (int)$_GET['student_id'];
        }

        $ws = implode(' AND ', $where);
        $tcnt = $pdo->prepare(
            "SELECT COUNT(*) FROM student_resumes r
             LEFT JOIN students s ON s.id = r.student_id
             WHERE {$ws}"
        );
        $tcnt->execute($params);
        $total = (int)$tcnt->fetchColumn();

        $st = $pdo->prepare(
            "SELECT r.id, r.student_id, r.desired_position, r.city, r.desired_salary,
                    r.is_published, r.created_at, r.last_name, r.first_name, r.middle_name,
                    {$nameExpr} AS full_name, s.email AS user_email,
                    sp.title AS specialty_title
             FROM student_resumes r
             LEFT JOIN students s ON s.id = r.student_id
             LEFT JOIN specialties sp ON sp.id = r.specialty_id
             WHERE {$ws}
             ORDER BY r.created_at DESC
             LIMIT {$limit} OFFSET {$offset}"
        );
        $st->execute($params);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        json([
            'data'  => $rows,
            'total' => $total,
            'page'  => $page,
            'limit' => $limit,
            'pages' => (int)ceil($total / $limit),
        ]);
    }

    if ($method === 'PATCH') {
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) {
            http_response_code(400);
            json(['error' => 'id required']);
        }
        $d = jsonBody();
        $allowed = ['is_published'];
        $set = [];
        $params = [':id' => $id];
        foreach ($allowed as $f) {
            if (array_key_exists($f, $d)) {
                $set[] = "{$f} = :{$f}";
                $params[":{$f}"] = (int)(bool)$d[$f];
            }
        }
        if (!$set) {
            http_response_code(400);
            json(['error' => 'No fields']);
        }
        $pdo->prepare(
            'UPDATE student_resumes SET ' . implode(', ', $set) . ', updated_at = NOW() WHERE id = :id'
        )->execute($params);
        adminLog($pdo, 'patch', 'student_resumes', $id, 'Обновлено резюме');
        $st = $pdo->prepare('SELECT * FROM student_resumes WHERE id = ? LIMIT 1');
        $st->execute([$id]);
        json($st->fetch(PDO::FETCH_ASSOC));
    }

    if ($method === 'DELETE') {
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) {
            http_response_code(400);
            json(['error' => 'id required']);
        }
        $check = $pdo->prepare('SELECT id FROM student_resumes WHERE id = ? LIMIT 1');
        $check->execute([$id]);
        if (!$check->fetch()) {
            http_response_code(404);
            json(['error' => 'Not found']);
        }
        $pdo->prepare('DELETE FROM student_resumes WHERE id = ?')->execute([$id]);
        adminLog($pdo, 'delete', 'student_resumes', $id, 'Удалено резюме');
        http_response_code(204);
        exit;
    }

    http_response_code(405);
    json(['error' => 'Method Not Allowed']);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
    exit;
}
