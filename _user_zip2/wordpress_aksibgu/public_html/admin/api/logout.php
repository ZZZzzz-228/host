<?php
/**
 * АКСИБГУУ — API: Выход из системы
 * Файл: api/logout.php
 * Положить в: public_html/admin/api/logout.php
 */
require_once dirname(__DIR__) . '/config.php';

if (!empty($_SESSION['admin_logged_in'])) {
    logAction('LOGOUT', 'Выход из системы');
}

session_destroy();
jsonResponse(['success' => true, 'message' => 'Выход выполнен']);