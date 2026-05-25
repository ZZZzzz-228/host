<?php
/**
 * API: career_tests (Тесты профориентации)
 * ─────────────────────────────────────────
 * GET    /admin/api/career_test.php                 → список тестов
 * GET    /admin/api/career_test.php?id=             → один тест с вопросами/ответами
 * POST   /admin/api/career_test.php                 → создать тест
 * PUT    /admin/api/career_test.php?id=             → обновить тест
 * DELETE /admin/api/career_test.php?id=             → удалить тест
 *
 * Вопросы:
 * POST   /admin/api/career_test.php?action=question_create  → создать вопрос
 * PUT    /admin/api/career_test.php?action=question_update&qid= → обновить вопрос
 * DELETE /admin/api/career_test.php?action=question_delete&qid= → удалить вопрос
 *
 * Ответы:
 * POST   /admin/api/career_test.php?action=answer_create   → создать ответ
 * PUT    /admin/api/career_test.php?action=answer_update&aid= → обновить ответ
 * DELETE /admin/api/career_test.php?action=answer_delete&aid= → удалить ответ
 * POST   /admin/api/career_test.php?action=answers_reorder → изменить порядок ответов
 * POST   /admin/api/career_test.php?action=questions_reorder → изменить порядок вопросов
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';
$pdo    = getDB();

// ── Автомиграция: создаём таблицы если нет ───────────────────────────────────
$pdo->exec("
CREATE TABLE IF NOT EXISTS `career_tests` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`        VARCHAR(512) NOT NULL DEFAULT '',
  `description`  TEXT,
  `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order`   INT NOT NULL DEFAULT 0,
  `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

$pdo->exec("
CREATE TABLE IF NOT EXISTS `career_test_questions` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `test_id`    INT UNSIGNED NOT NULL,
  `question`   TEXT NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `test_id` (`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

$pdo->exec("
CREATE TABLE IF NOT EXISTS `career_test_answers` (
  `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id`      INT UNSIGNED NOT NULL,
  `text`             TEXT NOT NULL,
  `specialty_ids`    TEXT COMMENT 'JSON-массив title специальностей',
  `sort_order`       INT NOT NULL DEFAULT 0,
  `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `question_id` (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ── Helpers ───────────────────────────────────────────────────────────────────
function testWithQuestions(PDO $pdo, int $testId): array {
    $test = $pdo->prepare("SELECT * FROM career_tests WHERE id = ? LIMIT 1");
    $test->execute([$testId]);
    $t = $test->fetch(PDO::FETCH_ASSOC);
    if (!$t) return [];

    $qs = $pdo->prepare(
        "SELECT * FROM career_test_questions WHERE test_id = ? ORDER BY sort_order ASC, id ASC"
    );
    $qs->execute([$testId]);
    $questions = $qs->fetchAll(PDO::FETCH_ASSOC);

    foreach ($questions as &$q) {
        $as = $pdo->prepare(
            "SELECT * FROM career_test_answers WHERE question_id = ? ORDER BY sort_order ASC, id ASC"
        );
        $as->execute([$q['id']]);
        $answers = $as->fetchAll(PDO::FETCH_ASSOC);
        foreach ($answers as &$a) {
            $a['specialty_ids'] = json_decode($a['specialty_ids'] ?? '[]', true) ?: [];
        }
        $q['answers'] = $answers;
    }
    $t['questions'] = $questions;
    return $t;
}

// ════════════════════════════════════════════════════════════════
// ВОПРОСЫ
// ════════════════════════════════════════════════════════════════

// POST ?action=question_create
if ($method === 'POST' && $action === 'question_create') {
    $d = jsonBody();
    $testId   = (int)($d['test_id'] ?? 0);
    $question = trim($d['question'] ?? '');
    if (!$testId || !$question) json(['error' => 'test_id и question обязательны'], 422);

    // sort_order = max + 1
    $maxOrder = $pdo->prepare("SELECT COALESCE(MAX(sort_order),0) FROM career_test_questions WHERE test_id=?");
    $maxOrder->execute([$testId]);
    $nextOrder = (int)$maxOrder->fetchColumn() + 1;

    $st = $pdo->prepare(
        "INSERT INTO career_test_questions (test_id, question, sort_order) VALUES (?,?,?)"
    );
    $st->execute([$testId, $question, $nextOrder]);
    $qid = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'career_test_questions', $qid, "Добавлен вопрос к тесту #{$testId}");
    json(['id' => $qid, 'test_id' => $testId, 'question' => $question, 'sort_order' => $nextOrder, 'answers' => []]);
}

// PUT ?action=question_update&qid=
if ($method === 'PUT' && $action === 'question_update') {
    $qid = (int)($_GET['qid'] ?? 0);
    $d = jsonBody();
    $question = trim($d['question'] ?? '');
    if (!$qid || !$question) json(['error' => 'qid и question обязательны'], 422);

    $pdo->prepare("UPDATE career_test_questions SET question=? WHERE id=?")->execute([$question, $qid]);
    adminLog($pdo, 'update', 'career_test_questions', $qid, "Обновлён вопрос #{$qid}");
    json(['ok' => true]);
}

// DELETE ?action=question_delete&qid=
if ($method === 'DELETE' && $action === 'question_delete') {
    $qid = (int)($_GET['qid'] ?? 0);
    if (!$qid) json(['error' => 'qid обязателен'], 422);

    $pdo->prepare("DELETE FROM career_test_answers WHERE question_id=?")->execute([$qid]);
    $pdo->prepare("DELETE FROM career_test_questions WHERE id=?")->execute([$qid]);
    adminLog($pdo, 'delete', 'career_test_questions', $qid, "Удалён вопрос #{$qid}");
    json(['ok' => true]);
}

// POST ?action=questions_reorder
if ($method === 'POST' && $action === 'questions_reorder') {
    $d = jsonBody();
    $ids = $d['ids'] ?? [];
    if (!is_array($ids)) json(['error' => 'ids must be array'], 422);
    $st = $pdo->prepare("UPDATE career_test_questions SET sort_order=? WHERE id=?");
    foreach ($ids as $order => $id) {
        $st->execute([(int)$order, (int)$id]);
    }
    json(['ok' => true]);
}

// ════════════════════════════════════════════════════════════════
// ОТВЕТЫ
// ════════════════════════════════════════════════════════════════

// POST ?action=answer_create
if ($method === 'POST' && $action === 'answer_create') {
    $d = jsonBody();
    $qid  = (int)($d['question_id'] ?? 0);
    $text = trim($d['text'] ?? '');
    $sids = $d['specialty_ids'] ?? [];
    if (!$qid || !$text) json(['error' => 'question_id и text обязательны'], 422);
    if (!is_array($sids)) $sids = [];

    $maxOrder = $pdo->prepare("SELECT COALESCE(MAX(sort_order),0) FROM career_test_answers WHERE question_id=?");
    $maxOrder->execute([$qid]);
    $nextOrder = (int)$maxOrder->fetchColumn() + 1;

    $st = $pdo->prepare(
        "INSERT INTO career_test_answers (question_id, text, specialty_ids, sort_order) VALUES (?,?,?,?)"
    );
    $st->execute([$qid, $text, json_encode($sids, JSON_UNESCAPED_UNICODE), $nextOrder]);
    $aid = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'career_test_answers', $aid, "Добавлен ответ к вопросу #{$qid}");
    json(['id' => $aid, 'question_id' => $qid, 'text' => $text, 'specialty_ids' => $sids, 'sort_order' => $nextOrder]);
}

// PUT ?action=answer_update&aid=
if ($method === 'PUT' && $action === 'answer_update') {
    $aid = (int)($_GET['aid'] ?? 0);
    $d = jsonBody();
    $text = trim($d['text'] ?? '');
    $sids = $d['specialty_ids'] ?? [];
    if (!$aid || !$text) json(['error' => 'aid и text обязательны'], 422);
    if (!is_array($sids)) $sids = [];

    $pdo->prepare("UPDATE career_test_answers SET text=?, specialty_ids=? WHERE id=?")
        ->execute([$text, json_encode($sids, JSON_UNESCAPED_UNICODE), $aid]);
    adminLog($pdo, 'update', 'career_test_answers', $aid, "Обновлён ответ #{$aid}");
    json(['ok' => true]);
}

// DELETE ?action=answer_delete&aid=
if ($method === 'DELETE' && $action === 'answer_delete') {
    $aid = (int)($_GET['aid'] ?? 0);
    if (!$aid) json(['error' => 'aid обязателен'], 422);
    $pdo->prepare("DELETE FROM career_test_answers WHERE id=?")->execute([$aid]);
    adminLog($pdo, 'delete', 'career_test_answers', $aid, "Удалён ответ #{$aid}");
    json(['ok' => true]);
}

// POST ?action=answers_reorder
if ($method === 'POST' && $action === 'answers_reorder') {
    $d = jsonBody();
    $ids = $d['ids'] ?? [];
    if (!is_array($ids)) json(['error' => 'ids must be array'], 422);
    $st = $pdo->prepare("UPDATE career_test_answers SET sort_order=? WHERE id=?");
    foreach ($ids as $order => $id) {
        $st->execute([(int)$order, (int)$id]);
    }
    json(['ok' => true]);
}

// ════════════════════════════════════════════════════════════════
// ТЕСТЫ
// ════════════════════════════════════════════════════════════════

// GET — один тест с вопросами
if ($method === 'GET' && !empty($_GET['id'])) {
    $t = testWithQuestions($pdo, (int)$_GET['id']);
    if (!$t) { http_response_code(404); json(['error' => 'Not found']); }
    json($t);
}

// GET — список тестов
if ($method === 'GET') {
    $rows = $pdo->query(
        "SELECT t.*, 
                (SELECT COUNT(*) FROM career_test_questions WHERE test_id=t.id) AS questions_count
         FROM career_tests t
         ORDER BY t.sort_order ASC, t.created_at DESC"
    )->fetchAll(PDO::FETCH_ASSOC);
    json(['data' => $rows]);
}

// POST — создать тест
if ($method === 'POST') {
    $d = jsonBody();
    $title       = trim($d['title'] ?? '');
    $description = trim($d['description'] ?? '');
    $is_active   = isset($d['is_active']) ? (int)(bool)$d['is_active'] : 1;
    if (!$title) json(['error' => 'title обязателен'], 422);

    $maxOrder = (int)$pdo->query("SELECT COALESCE(MAX(sort_order),0) FROM career_tests")->fetchColumn();
    $st = $pdo->prepare(
        "INSERT INTO career_tests (title, description, is_active, sort_order) VALUES (?,?,?,?)"
    );
    $st->execute([$title, $description, $is_active, $maxOrder + 1]);
    $id = (int)$pdo->lastInsertId();

    adminLog($pdo, 'create', 'career_tests', $id, "Создан тест: {$title}");
    json(testWithQuestions($pdo, $id));
}

// PUT — обновить тест
if ($method === 'PUT' && !empty($_GET['id'])) {
    $id = (int)$_GET['id'];
    $d = jsonBody();
    $title       = trim($d['title'] ?? '');
    $description = trim($d['description'] ?? '');
    $is_active   = isset($d['is_active']) ? (int)(bool)$d['is_active'] : 1;
    if (!$title) json(['error' => 'title обязателен'], 422);

    $pdo->prepare(
        "UPDATE career_tests SET title=?, description=?, is_active=?, updated_at=NOW() WHERE id=?"
    )->execute([$title, $description, $is_active, $id]);

    adminLog($pdo, 'update', 'career_tests', $id, "Обновлён тест: {$title}");
    json(testWithQuestions($pdo, $id));
}

// DELETE — удалить тест
if ($method === 'DELETE' && !empty($_GET['id'])) {
    $id = (int)$_GET['id'];

    // Удаляем всё каскадно
    $qids = $pdo->prepare("SELECT id FROM career_test_questions WHERE test_id=?");
    $qids->execute([$id]);
    $qidList = array_column($qids->fetchAll(PDO::FETCH_ASSOC), 'id');
    if ($qidList) {
        $in = implode(',', array_map('intval', $qidList));
        $pdo->exec("DELETE FROM career_test_answers WHERE question_id IN ($in)");
    }
    $pdo->prepare("DELETE FROM career_test_questions WHERE test_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM career_tests WHERE id=?")->execute([$id]);

    adminLog($pdo, 'delete', 'career_tests', $id, "Удалён тест #{$id}");
    json(['ok' => true]);
}

json(['error' => 'Method not allowed'], 405);
