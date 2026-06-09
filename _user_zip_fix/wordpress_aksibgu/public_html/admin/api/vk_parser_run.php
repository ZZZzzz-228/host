<?php
/**
 * API: Запуск Scrapy-парсера VK
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    json(['error' => 'Method Not Allowed']);
}

// Проверяем что exec() доступен
if (!function_exists('exec')) {
    json([
        'status'  => 'error',
        'message' => 'Функция exec() отключена на хостинге. Обратитесь в поддержку Timeweb.',
    ]);
}

$script = '/home/c/cf990597/vk_scrapy_parser/bin/run_parser.sh';
$log    = '/home/c/cf990597/vk_scrapy_parser/parser.log';

// Проверяем что скрипт существует
if (!file_exists($script)) {
    json([
        'status'  => 'error',
        'message' => 'Скрипт парсера не найден. Убедитесь что папка vk_scrapy_parser загружена на хостинг.',
    ]);
}

// Запускаем в фоне
exec("bash {$script} >> {$log} 2>&1 &");

// Логируем запуск
try {
    $pdo = getDB();
    adminLog($pdo, 'vk_parse', 'vk_pending_stories', 0, 'Scrapy-парсер запущен вручную через админку');
} catch (Exception $e) {}

json([
    'status'  => 'started',
    'message' => 'Парсер запущен в фоне. Результат появится через 30–60 секунд. Нажмите «Обновить» чуть позже.',
]);