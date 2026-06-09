<?php
/**
 * АКСИБГУУ — API: Преподаватели
 * Файл: api/teachers.php
 * Положить в: public_html/admin/api/teachers.php
 */
require_once dirname(__DIR__) . '/config.php';
requireAuth();

$db     = getDB();
$search = sanitize($_GET['search'] ?? '');

if ($search) {
    $stmt = $db->prepare(
        "SELECT t.*, d.name AS department_name
         FROM teachers t
         LEFT JOIN departments d ON d.id = t.department_id
         WHERE t.full_name LIKE ? OR d.name LIKE ? OR t.position LIKE ?
         ORDER BY t.full_name"
    );
    $stmt->execute(["%$search%", "%$search%", "%$search%"]);
} else {
    $stmt = $db->query(
        "SELECT t.*, d.name AS department_name
         FROM teachers t
         LEFT JOIN departments d ON d.id = t.department_id
         ORDER BY t.full_name"
    );
}

jsonResponse(['success' => true, 'data' => $stmt->fetchAll()]);
