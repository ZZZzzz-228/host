<?php
/**
 * Диагностика api/users.php — загрузить в public_html/admin/api/
 * Открыть когда ЗАЛОГИНЕНЫ в админке:
 * https://cf990597-wordpress-yndvp.tw1.ru/admin/api/check_users_api.php
 * УДАЛИТЬ после проверки!
 */
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Буферизация вывода чтобы перехватить любые warnings
ob_start();
require_once __DIR__ . '/../config.php';
$configOutput = ob_get_clean();

header('Content-Type: text/plain; charset=utf-8');
echo "=== ДИАГНОСТИКА ===\n";
echo "PHP: " . phpversion() . "\n";

if ($configOutput) {
    echo "\n⚠ ВЫВОД config.php (предупреждения):\n" . strip_tags($configOutput) . "\n";
} else {
    echo "config.php: OK (нет вывода)\n";
}

echo "\nСессия:\n";
echo "  admin_logged_in = " . var_export($_SESSION['admin_logged_in'] ?? 'нет', true) . "\n";
echo "  admin_id = " . var_export($_SESSION['admin_id'] ?? 'нет', true) . "\n";
echo "  admin_role = " . var_export($_SESSION['admin_role'] ?? 'нет', true) . "\n";

echo "\nBD тест...\n";
try {
    $pdo = getDB();
    echo "Подключение: OK\n";
    
    echo "\nТестовый INSERT (с откатом)...\n";
    ob_start();
    $pdo->beginTransaction();
    $pdo->prepare(
        "INSERT INTO admins (login, password_hash, email, phone, full_name, role, is_active) VALUES (?,?,?,?,?,?,1)"
    )->execute(['_test_' . time(), password_hash('pass123', PASSWORD_BCRYPT), null, null, 'Test', 'editor']);
    $newId = $pdo->lastInsertId();
    $insertWarnings = ob_get_clean();
    echo "INSERT OK, id=$newId\n";
    if ($insertWarnings) echo "Предупреждения: $insertWarnings\n";
    
    // Test adminLog
    ob_start();
    adminLog($pdo, 'test', 'admins', (int)$newId, 'Тест диагностики');
    $logWarnings = ob_get_clean();
    echo "adminLog: OK\n";
    if ($logWarnings) echo "Предупреждения adminLog: $logWarnings\n";
    
    $pdo->rollBack();
    echo "Откат транзакции: OK\n";
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    echo "ОШИБКА: " . get_class($e) . ": " . $e->getMessage() . "\n";
    echo "Файл: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "Трассировка:\n" . $e->getTraceAsString() . "\n";
}

echo "\nПроверка функции sessionCheck при активной сессии...\n";
if (!empty($_SESSION['admin_logged_in'])) {
    echo "Сессия активна - sessionCheck() должен пройти\n";
    
    // Тест полного потока users.php POST
    echo "\nСимуляция POST /api/users.php...\n";
    try {
        $pdo2 = getDB();
        $d = ['login' => '_test2_' . time(), 'password' => 'test12345'];
        
        if(empty($d['login']) || empty($d['password'])) {
            echo "FAIL: пустой логин/пароль\n";
        } elseif(mb_strlen($d['password']) < 6) {
            echo "FAIL: пароль < 6 символов\n";
        } else {
            $exists = $pdo2->prepare("SELECT id FROM admins WHERE login=? LIMIT 1");
            $exists->execute([$d['login']]);
            if($exists->fetch()) {
                echo "FAIL: логин занят\n";
            } else {
                $role = 'editor';
                ob_start();
                $pdo2->beginTransaction();
                $pdo2->prepare(
                    "INSERT INTO admins (login, password_hash, email, phone, full_name, role, is_active) VALUES (?,?,?,?,?,?,1)"
                )->execute([$d['login'], password_hash($d['password'], PASSWORD_BCRYPT), null, null, '', $role]);
                $newId2 = (int)$pdo2->lastInsertId();
                $w = ob_get_clean();
                echo "POST симуляция: OK, id=$newId2\n";
                if ($w) echo "Предупреждения: $w\n";
                $pdo2->rollBack();
            }
        }
    } catch (Throwable $e) {
        if (isset($pdo2) && $pdo2->inTransaction()) $pdo2->rollBack();
        echo "ОШИБКА симуляции: " . $e->getMessage() . "\n";
    }
} else {
    echo "⚠ Сессия НЕ активна - откройте этот файл будучи залогиненным в админке!\n";
    echo "  URL: https://cf990597-wordpress-yndvp.tw1.ru/admin/api/check_users_api.php\n";
}

echo "\n=== КОНЕЦ === УДАЛИТЕ ФАЙЛ! ===\n";
