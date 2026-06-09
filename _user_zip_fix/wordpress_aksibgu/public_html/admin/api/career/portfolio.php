<?php
/**
 * API: student_portfolio (admin) — схема как в public_api (student_id, is_published)
 */
require_once __DIR__ . '/../../config.php';
sessionCheck();

header('Content-Type: application/json; charset=utf-8');

function ensurePortfolioTable(PDO $pdo): void
{
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
}

try {
    $pdo    = getDB();
    $method = $_SERVER['REQUEST_METHOD'];
    ensurePortfolioTable($pdo);

    if ($method === 'GET') {
        if (!empty($_GET['id'])) {
            $st = $pdo->prepare(
                "SELECT pi.*, s.full_name, s.email AS user_email
                 FROM student_portfolio pi
                 LEFT JOIN students s ON s.id = pi.student_id
                 WHERE pi.id = ? LIMIT 1"
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
            $where[] = '(pi.title LIKE ? OR pi.description LIKE ? OR s.full_name LIKE ? OR s.email LIKE ?)';
            $params  = array_merge($params, [$s, $s, $s, $s]);
        }
        if (isset($_GET['is_published']) && $_GET['is_published'] !== '') {
            $where[] = 'pi.is_published = ?';
            $params[] = (int)$_GET['is_published'];
        }
        if (!empty($_GET['student_id'])) {
            $where[] = 'pi.student_id = ?';
            $params[] = (int)$_GET['student_id'];
        }
        if (!empty($_GET['category'])) {
            $where[] = 'pi.category = ?';
            $params[] = $_GET['category'];
        }

        $ws = implode(' AND ', $where);
        $tcnt = $pdo->prepare(
            "SELECT COUNT(*) FROM student_portfolio pi
             LEFT JOIN students s ON s.id = pi.student_id
             WHERE {$ws}"
        );
        $tcnt->execute($params);
        $total = (int)$tcnt->fetchColumn();

        $st = $pdo->prepare(
            "SELECT pi.id, pi.student_id, pi.title, pi.category, pi.project_url,
                    pi.image_url, pi.is_published, pi.created_at,
                    COALESCE(s.full_name, '') AS full_name,
                    s.email AS user_email
             FROM student_portfolio pi
             LEFT JOIN students s ON s.id = pi.student_id
             WHERE {$ws}
             ORDER BY pi.created_at DESC
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
            'UPDATE student_portfolio SET ' . implode(', ', $set) . ', updated_at = NOW() WHERE id = :id'
        )->execute($params);
        adminLog($pdo, 'patch', 'student_portfolio', $id, 'Обновлена работа портфолио');
        $st = $pdo->prepare('SELECT * FROM student_portfolio WHERE id = ? LIMIT 1');
        $st->execute([$id]);
        json($st->fetch(PDO::FETCH_ASSOC));
    }

    if ($method === 'DELETE') {
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) {
            http_response_code(400);
            json(['error' => 'id required']);
        }
        $check = $pdo->prepare('SELECT id FROM student_portfolio WHERE id = ? LIMIT 1');
        $check->execute([$id]);
        if (!$check->fetch()) {
            http_response_code(404);
            json(['error' => 'Not found']);
        }
        $pdo->prepare('DELETE FROM student_portfolio WHERE id = ?')->execute([$id]);
        adminLog($pdo, 'delete', 'student_portfolio', $id, 'Удалена работа портфолио');
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
