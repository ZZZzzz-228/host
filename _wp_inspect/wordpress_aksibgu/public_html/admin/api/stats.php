<?php
/**
 * API: stats (dashboard counters)
 * GET → returns all counters for all 28 tables + recent activity
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo = getDB();

function cnt(PDO $pdo, string $table, string $where = '1=1'): int {
    try {
        return (int)$pdo->query("SELECT COUNT(*) FROM `$table` WHERE $where")->fetchColumn();
    } catch (Exception $e) {
        return 0;
    }
}

// ── Counts ─────────────────────────────────────────────────────────────────
$stats = [
    // Content
    'news_total'         => cnt($pdo, 'news_items'),
    'news_published'     => cnt($pdo, 'news_items', 'is_published=1'),
    'news_pinned'        => cnt($pdo, 'news_items', 'is_pinned=1'),
    'stories_total'      => cnt($pdo, 'stories'),
    'stories_published'  => cnt($pdo, 'stories', 'is_published=1'),
    'pages_total'        => cnt($pdo, 'pages'),
    'pages_published'    => cnt($pdo, 'pages', 'is_published=1'),

    // VK
    'vk_pending'         => cnt($pdo, 'vk_pending_stories', "status='pending'"),
    'vk_approved'        => cnt($pdo, 'vk_pending_stories', "status='approved'"),
    'vk_rejected'        => cnt($pdo, 'vk_pending_stories', "status='rejected'"),

    // Contacts
    'contacts_total'     => cnt($pdo, 'contacts'),

    // Applications
    'apps_total'         => cnt($pdo, 'applications'),
    'apps_new'           => cnt($pdo, 'applications', "status='new'"),
    'apps_processing'    => cnt($pdo, 'applications', "status='processing'"),
    'apps_approved'      => cnt($pdo, 'applications', "status='approved'"),
    'apps_rejected'      => cnt($pdo, 'applications', "status='rejected'"),

    // Education
    'specialties_total'  => cnt($pdo, 'specialties'),
    'specialties_pub'    => cnt($pdo, 'specialties', 'is_published=1'),
    'edu_programs'       => cnt($pdo, 'education_programs'),
    'departments'        => cnt($pdo, 'departments'),
    'groups_total'       => cnt($pdo, 'groups_ref'),
    'disciplines'        => cnt($pdo, 'disciplines'),

    // People
    'staff_total'        => cnt($pdo, 'staff_members'),
    'staff_active'       => cnt($pdo, 'staff_members', 'is_active=1'),
    'students_total'     => cnt($pdo, 'users', "role='student'"),
    'resumes_total'      => cnt($pdo, 'student_resumes'),
    'portfolio_total'    => cnt($pdo, 'student_portfolio_items'),

    // Career
    'vacancies_total'    => cnt($pdo, 'vacancies'),
    'vacancies_active'   => cnt($pdo, 'vacancies', 'is_active=1'),
    'career_events'      => cnt($pdo, 'career_events'),

    // Schedule / Docs
    'schedule_records'   => cnt($pdo, 'schedule'),
    'documents_total'    => cnt($pdo, 'documents'),

    // Partners
    'partners_total'     => cnt($pdo, 'partners'),
    'partners_active'    => cnt($pdo, 'partners', 'is_active=1'),

    // Admin
    'admins_total'       => cnt($pdo, 'admins'),
];

// ── Recent news (5) ────────────────────────────────────────────────────────
try {
    $recentNews = $pdo->query(
        "SELECT id, title, category, is_published, created_at
         FROM news_items ORDER BY created_at DESC LIMIT 5"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) { $recentNews = []; }

// ── Recent applications (5) ────────────────────────────────────────────────
try {
    $recentApps = $pdo->query(
        "SELECT id, full_name, type, status, created_at
         FROM applications ORDER BY created_at DESC LIMIT 5"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) { $recentApps = []; }

// ── Admin logs (10) ────────────────────────────────────────────────────────
try {
    $recentLogs = $pdo->query(
        "SELECT al.*, a.login as admin_login
         FROM admin_logs al
         LEFT JOIN admins a ON a.id=al.admin_id
         ORDER BY al.created_at DESC LIMIT 10"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) { $recentLogs = []; }

// ── Monthly news chart (12 months) ────────────────────────────────────────
try {
    $chartNews = $pdo->query(
        "SELECT DATE_FORMAT(created_at,'%Y-%m') as month, COUNT(*) as cnt
         FROM news_items
         WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
         GROUP BY month ORDER BY month ASC"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) { $chartNews = []; }

// ── Applications by status ──────────────────────────────────────────────────
try {
    $chartApps = $pdo->query(
        "SELECT status, COUNT(*) as cnt FROM applications GROUP BY status"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) { $chartApps = []; }

// ── News by category ──────────────────────────────────────────────────────
try {
    $chartNewsCat = $pdo->query(
        "SELECT category, COUNT(*) as cnt FROM news_items GROUP BY category"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) { $chartNewsCat = []; }

// Добавляем users_total = admins_total (для совместимости с dashboard.js)
$stats['users_total'] = $stats['admins_total'] ?? 0;

json([
    'success'       => true,
    'data'          => $stats,
    'recent_news'   => $recentNews,
    'recent_apps'   => $recentApps,
    'recent_logs'   => $recentLogs,
    'chart_news'    => $chartNews,
    'chart_apps'    => $chartApps,
    'chart_news_cat'=> $chartNewsCat,
]);