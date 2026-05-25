<?php
/**
 * API: admin_logs (журнал действий)
 * GET  ?page=&limit=&search=&action=&table_name=&admin_id=&date_from=&date_to=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'GET') { http_response_code(405); json(['error' => 'Method Not Allowed']); }

$page   = max(1, (int)($_GET['page']  ?? 1));
$limit  = min(500, max(1, (int)($_GET['limit'] ?? 50)));
$offset = ($page - 1) * $limit;

$where = ['1=1']; $params = [];

if (!empty($_GET['search'])) {
    $s = '%'.$_GET['search'].'%';
    $where[] = "(l.message LIKE ? OR l.table_name LIKE ? OR a.login LIKE ?)";
    $params  = array_merge($params, [$s, $s, $s]);
}
if (!empty($_GET['action']))     { $where[] = "l.action=?";      $params[] = $_GET['action'];      }
if (!empty($_GET['table_name'])) { $where[] = "l.table_name=?";  $params[] = $_GET['table_name'];  }
if (!empty($_GET['admin_id']))   { $where[] = "l.admin_id=?";    $params[] = (int)$_GET['admin_id']; }
if (!empty($_GET['date_from']))  { $where[] = "l.created_at >= ?"; $params[] = $_GET['date_from'];  }
if (!empty($_GET['date_to']))    { $where[] = "l.created_at <= ?"; $params[] = $_GET['date_to'].' 23:59:59'; }

$ws = implode(' AND ', $where);

$tcnt = $pdo->prepare("SELECT COUNT(*) FROM admin_logs l LEFT JOIN admins a ON a.id=l.admin_id WHERE $ws");
$tcnt->execute($params); $total = (int)$tcnt->fetchColumn();

$st = $pdo->prepare(
    "SELECT l.*, a.login as admin_login, a.full_name as admin_name
     FROM admin_logs l
     LEFT JOIN admins a ON a.id=l.admin_id
     WHERE $ws ORDER BY l.created_at DESC
     LIMIT $limit OFFSET $offset"
);
$st->execute($params);
$rows = $st->fetchAll(PDO::FETCH_ASSOC);

// distinct actions and tables for filters
$actions = []; $tables = [];
try {
    $actions = $pdo->query("SELECT DISTINCT action FROM admin_logs ORDER BY action")->fetchAll(PDO::FETCH_COLUMN);
    $tables  = $pdo->query("SELECT DISTINCT table_name FROM admin_logs ORDER BY table_name")->fetchAll(PDO::FETCH_COLUMN);
} catch (Exception $e) {}

json([
    'data'    => $rows,
    'total'   => $total,
    'page'    => $page,
    'limit'   => $limit,
    'pages'   => ceil($total / $limit),
    'actions' => $actions,
    'tables'  => $tables,
]);