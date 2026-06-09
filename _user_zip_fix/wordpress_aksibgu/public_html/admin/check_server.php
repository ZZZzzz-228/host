<?php
/**
 * Диагностический скрипт - загрузить в public_html/admin/
 * Открыть в браузере: https://cf990597-wordpress-yndvp.tw1.ru/admin/check_server.php
 * После проверки УДАЛИТЬ с сервера!
 */
header('Content-Type: text/plain; charset=utf-8');

echo "=== ДИАГНОСТИКА СЕРВЕРА ===\n\n";
echo "PHP версия: " . phpversion() . "\n";
echo "Макс. размер памяти: " . ini_get('memory_limit') . "\n";
echo "Режим ошибок: " . ini_get('display_errors') . "\n\n";

// Проверка config.php
$configPath = __DIR__ . '/config.php';
echo "config.php: " . ($configPath && file_exists($configPath) ? 'НАЙДЕН' : 'НЕ НАЙДЕН') . "\n";

// Проверка PHP 8.0+ syntax в config.php
if (file_exists($configPath)) {
    $content = file_get_contents($configPath);
    if (strpos($content, 'mixed ') !== false) {
        echo "ПРОБЛЕМА: config.php использует тип 'mixed' (PHP 8.0+) - несовместимо с PHP 7.4!\n";
    } else {
        echo "config.php: тип 'mixed' не найден - OK\n";
    }
}

// Попытка включить config.php
echo "\nПопытка подключить config.php...\n";
try {
    // Временно включаем вывод ошибок
    ini_set('display_errors', 1);
    error_reporting(E_ALL);
    ob_start();
    require_once __DIR__ . '/config.php';
    $output = ob_get_clean();
    if ($output) {
        echo "ВЫВОД ПРИ ПОДКЛЮЧЕНИИ config.php:\n" . $output . "\n";
    } else {
        echo "config.php подключён без вывода: OK\n";
    }
} catch (Throwable $e) {
    ob_end_clean();
    echo "ОШИБКА: " . $e->getMessage() . " в " . $e->getFile() . ":" . $e->getLine() . "\n";
}

// Проверка подключения к БД
echo "\nПроверка подключения к БД...\n";
if (function_exists('getDB')) {
    try {
        $pdo = getDB();
        echo "Подключение к БД: OK\n";
        $stmt = $pdo->query("SELECT COUNT(*) FROM admins");
        echo "Записей в таблице admins: " . $stmt->fetchColumn() . "\n";
    } catch (Throwable $e) {
        echo "ОШИБКА БД: " . $e->getMessage() . "\n";
    }
} else {
    echo "Функция getDB() не найдена\n";
}

echo "\n=== КОНЕЦ ДИАГНОСТИКИ ===\n";
echo "ВАЖНО: удалите этот файл после проверки!\n";
