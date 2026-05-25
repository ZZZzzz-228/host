<?php
/**
 * АКСИБГУУ — Admin Panel (Модульная архитектура)
 * ================================================
 * Каркас: ~60 строк. Все разделы — отдельные файлы:
 *   partials/sidebar.php  — боковое меню
 *   partials/topbar.php   — верхняя панель
 *   sections/*.php        — разделы контента
 *   modals/*.php          — модальные окна
 *   assets/js/sections/   — JS-логика по разделам
 */
session_start();
if (!isset($_SESSION['admin_id'])) {
    header('Location: login.php');
    exit;
}
// Читаем тему из куки, чтобы применить ДО рендера HTML (нет мигания)
$theme = isset($_COOKIE['aksibgu_theme']) ? $_COOKIE['aksibgu_theme'] : 'dark';
$themeClass = ($theme === 'light') ? ' class="light"' : '';
?>
<!DOCTYPE html>
<html lang="ru"<?= $themeClass ?>>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>АКСИБГУУ — Панель управления</title>
<!-- Тема применяется мгновенно из localStorage — до загрузки стилей -->
<script>
(function(){
    var t = localStorage.getItem('aksibgu_theme') || document.cookie.replace(/(?:(?:^|.*;\s*)aksibgu_theme\s*=\s*([^;]*).*$)|^.*$/,'$1') || 'dark';
    if(t === 'light') document.documentElement.classList.add('light');
    // Синхронизируем куку с localStorage
    if(t) document.cookie = 'aksibgu_theme=' + t + ';path=/;max-age=31536000';
})();
</script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.4.0/css/all.min.css">
<link rel="stylesheet" href="assets/css/admin.css">
<link rel="stylesheet" href="assets/css/about-college-v2.css">
<link rel="stylesheet" href="assets/css/dashboard-extra.css">
</head>
<body>

<!-- Toast container -->
<div id="tc"></div>

<!-- Lightbox -->
<div id="lb">
  <span id="lb-x" onclick="closeLB()"><i class="fas fa-times"></i></span>
  <img id="lb-img" src="" alt="">
</div>

<!-- Sidebar overlay (mobile) -->
<div class="sb-overlay" id="sbov" onclick="closeSB()"></div>

<div class="layout">

  <?php include 'partials/sidebar.php'; ?>
  <?php include 'partials/topbar.php'; ?>

  <main class="main"><div class="content">

    <?php include 'sections/dashboard.php'; ?>
    <?php include 'sections/news.php'; ?>
    <?php include 'sections/stories.php'; ?>
    <?php include 'sections/vk.php'; ?>
    <?php include 'sections/about_college.php'; ?>
    <?php include 'sections/contacts.php'; ?>
    <?php include 'sections/applications.php'; ?>
    <?php include 'sections/specialties.php'; ?>
    <?php include 'sections/eduprog.php'; ?>
    <?php include 'sections/departments.php'; ?>
    <?php include 'sections/groups.php'; ?>
    <?php include 'sections/disciplines.php'; ?>
    <?php include 'sections/schedule.php'; ?>
    <?php include 'sections/staff.php'; ?>
    <?php include 'sections/students.php'; ?>
    <?php include 'sections/resumes.php'; ?>
    <?php include 'sections/portfolio.php'; ?>
    <?php include 'sections/universities.php'; ?>
    <?php include 'sections/vacancies.php'; ?>
    <?php include 'sections/cevents.php'; ?>
    <?php include 'sections/career_test.php'; ?>
    <?php include 'sections/partners.php'; ?>
    <?php include 'sections/documents.php'; ?>
    <?php include 'sections/admins.php'; ?>
    <?php include 'sections/settings.php'; ?>
    <?php include 'sections/logs.php'; ?>

  </div></main>

</div><!-- /.layout -->

<!-- ═══════════ MODALS ═══════════ -->
<?php include 'modals/modal-news.php'; ?>
<?php include 'modals/modal-story.php'; ?>
<?php include 'modals/modal-vk.php'; ?>
<?php include 'modals/modal-page.php'; ?>
<?php include 'modals/modal-contact.php'; ?>
<?php include 'modals/modal-app.php'; ?>
<?php include 'modals/modal-specialty.php'; ?>
<?php include 'modals/modal-eduprog.php'; ?>
<?php include 'modals/modal-dept.php'; ?>
<?php include 'modals/modal-group.php'; ?>
<?php include 'modals/modal-discipline.php'; ?>
<?php include 'modals/modal-schedule.php'; ?>
<?php include 'modals/modal-staff.php'; ?>
<?php include 'modals/modal-vacancy.php'; ?>
<?php include 'modals/modal-career-event.php'; ?>
<?php include 'modals/modal-career-test.php'; ?>
<?php include 'modals/modal-partner.php'; ?>
<?php include 'modals/modal-document.php'; ?>
<?php include 'modals/modal-admin.php'; ?>
<?php include 'modals/modal-university.php'; ?>
<!-- Универсальный кроппер фото -->
<?php include 'modals/modal-image-cropper.php'; ?>

<!-- Chart.js для диаграмм дашборда -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

<!-- ═══════════ JS MODULES ═══════════ -->
<script src="assets/js/admin-core.js"></script>
<script src="assets/js/image-cropper.js"></script>
<script src="assets/js/sections/dashboard.js"></script>
<script src="assets/js/sections/news-stories.js"></script>
<script src="assets/js/sections/vk.js"></script>
<script src="assets/js/sections/content.js"></script>
<script src="assets/js/sections/applications.js"></script>
<script src="assets/js/sections/academic.js"></script>
<script src="assets/js/sections/career.js"></script>
<script src="assets/js/sections/universities.js"></script>
<script src="assets/js/sections/career-contacts.js"></script>
<script src="assets/js/sections/career-test.js"></script>
<script src="assets/js/sections/settings-admins-logs.js"></script>
<script src="assets/js/sections/about-college.js"></script>

</body>
</html>
