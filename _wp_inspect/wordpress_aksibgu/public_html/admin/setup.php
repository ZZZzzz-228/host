<?php
/**
 * АКСИБГУУ — Первоначальная установка (Setup)
 *
 * Этот скрипт:
 * 1. Проверяет подключение к БД
 * 2. Создаёт ВСЕ 28 таблиц
 * 3. Создаёт администратора с правильным bcrypt-хэшем
 * 4. Показывает статус каждого шага
 *
 * ПОСЛЕ УСПЕШНОЙ УСТАНОВКИ — УДАЛИТЕ ЭТОТ ФАЙЛ!
 */

// ── Настройки подключения ──────────────────────────────────────────────────
$DB_HOST    = 'localhost';
$DB_NAME    = 'cf990597_aksibgu';
$DB_USER    = 'cf990597_aksibgu';
$DB_PASS    = 'aen5fNt8';
$DB_CHARSET = 'utf8mb4';

// ── Данные нового администратора ───────────────────────────────────────────
$ADMIN_LOGIN    = 'admin';
$ADMIN_PASSWORD = 'Admin1234';
$ADMIN_NAME     = 'Администратор';
$ADMIN_EMAIL    = 'admin@aksibguu.ru';
$ADMIN_ROLE     = 'superadmin';

// ──────────────────────────────────────────────────────────────────────────
session_start();
$log = [];
$errors = 0;

function logOk(string $msg) { global $log; $log[] = ['ok', $msg]; }
function logErr(string $msg) { global $log, $errors; $log[] = ['err', $msg]; $errors++; }
function logInfo(string $msg) { global $log; $log[] = ['info', $msg]; }

// ── Диагностика окружения ─────────────────────────────────────────────────
$phpVersion = PHP_VERSION;
$phpOk      = version_compare($phpVersion, '7.4.0', '>=');
logInfo("PHP версия: <b>{$phpVersion}</b>" . ($phpOk ? " ✅ (7.4+)" : " ❌ (нужна 7.4+)"));
logInfo("PDO MySQL: " . (extension_loaded('pdo_mysql') ? "✅ доступен" : "❌ не установлен!"));
logInfo("JSON ext: "  . (extension_loaded('json')      ? "✅ доступен" : "❌ не установлен!"));
logInfo("mbstring: "  . (extension_loaded('mbstring')  ? "✅ доступен" : "⚠️ отсутствует"));

// ── Шаг 1: Подключение к БД ───────────────────────────────────────────────
$pdo = null;
try {
    $dsn = "mysql:host={$DB_HOST};dbname={$DB_NAME};charset={$DB_CHARSET}";
    $pdo = new PDO($dsn, $DB_USER, $DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    // Проверяем версию MySQL
    $mysqlVer = $pdo->query("SELECT VERSION()")->fetchColumn();
    logOk("Подключение к БД «{$DB_NAME}» успешно — MySQL {$mysqlVer}");
} catch (PDOException $e) {
    $errMsg = $e->getMessage();
    logErr("Не удалось подключиться к БД: <b>" . htmlspecialchars($errMsg) . "</b>");
    // Попытка без имени БД (для диагностики)
    try {
        $pdo2 = new PDO("mysql:host={$DB_HOST};charset={$DB_CHARSET}", $DB_USER, $DB_PASS);
        logInfo("Подключение к серверу MySQL OK, но БД «{$DB_NAME}» недоступна");
        logInfo("Убедитесь, что БД создана в панели управления хостингом");
        $pdo2 = null;
    } catch (PDOException $e2) {
        logErr("Нет доступа к MySQL серверу: " . htmlspecialchars($e2->getMessage()));
    }
}

// ── Шаг 2: Создание таблиц ────────────────────────────────────────────────
$tables = [];

if ($pdo) {

// ── admins ────────────────────────────────────────────────────────────────
$tables['admins'] = "CREATE TABLE IF NOT EXISTS `admins` (
  `id`            INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  `login`         VARCHAR(64)     NOT NULL UNIQUE,
  `password_hash` VARCHAR(255)    NOT NULL,
  `full_name`     VARCHAR(255)    NOT NULL DEFAULT '',
  `email`         VARCHAR(255)    NOT NULL DEFAULT '',
  `phone`         VARCHAR(32)     NOT NULL DEFAULT '',
  `role`          ENUM('superadmin','admin','editor','moderator','career_manager') NOT NULL DEFAULT 'admin',
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
  `last_login`    DATETIME        NULL,
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── admin_logs ────────────────────────────────────────────────────────────
$tables['admin_logs'] = "CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `admin_id`    INT UNSIGNED NULL,
  `action`      VARCHAR(128) NOT NULL DEFAULT '',
  `table_name`  VARCHAR(128) NOT NULL DEFAULT '',
  `record_id`   INT UNSIGNED NOT NULL DEFAULT 0,
  `message`     VARCHAR(500) NOT NULL DEFAULT '',
  `ip_address`  VARCHAR(45)  NOT NULL DEFAULT '',
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (`admin_id`),
  INDEX (`action`),
  INDEX (`table_name`),
  INDEX (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── news_items ────────────────────────────────────────────────────────────
$tables['news_items'] = "CREATE TABLE IF NOT EXISTS `news_items` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`        VARCHAR(512)  NOT NULL DEFAULT '',
  `slug`         VARCHAR(512)  NOT NULL DEFAULT '',
  `excerpt`      TEXT          NULL,
  `content`      LONGTEXT      NULL,
  `category`     VARCHAR(64)   NOT NULL DEFAULT 'news',
  `cover_image`  VARCHAR(512)  NOT NULL DEFAULT '',
  `author_name`  VARCHAR(255)  NOT NULL DEFAULT '',
  `is_published` TINYINT(1)    NOT NULL DEFAULT 0,
  `is_pinned`    TINYINT(1)    NOT NULL DEFAULT 0,
  `views`        INT UNSIGNED  NOT NULL DEFAULT 0,
  `published_at` DATETIME      NULL,
  `tags`         VARCHAR(512)  NOT NULL DEFAULT '',
  `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (`is_published`),
  INDEX (`category`),
  INDEX (`published_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── stories ───────────────────────────────────────────────────────────────
$tables['stories'] = "CREATE TABLE IF NOT EXISTS `stories` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`        VARCHAR(512) NOT NULL DEFAULT '',
  `description`  TEXT         NULL,
  `cover_image`  VARCHAR(512) NOT NULL DEFAULT '',
  `images_json`  JSON         NULL,
  `vk_post_id`   INT UNSIGNED NULL,
  `vk_post_url`  VARCHAR(512) NOT NULL DEFAULT '',
  `is_published` TINYINT(1)   NOT NULL DEFAULT 0,
  `is_featured`  TINYINT(1)   NOT NULL DEFAULT 0,
  `sort_order`   INT          NOT NULL DEFAULT 0,
  `published_at` DATETIME     NULL,
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── vk_pending_stories ────────────────────────────────────────────────────
$tables['vk_pending_stories'] = "CREATE TABLE IF NOT EXISTS `vk_pending_stories` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `vk_post_id`   INT UNSIGNED NULL UNIQUE,
  `vk_post_url`  VARCHAR(512) NOT NULL DEFAULT '',
  `vk_text`      TEXT         NULL,
  `images_json`  JSON         NULL,
  `vk_date`      DATETIME     NULL,
  `status`       ENUM('pending','approved','rejected','skipped') NOT NULL DEFAULT 'pending',
  `story_id`     INT UNSIGNED NULL,
  `reject_reason` VARCHAR(500) NOT NULL DEFAULT '',
  `moderated_at` DATETIME     NULL,
  `moderated_by` INT UNSIGNED NULL,
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (`status`),
  INDEX (`vk_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── pages ─────────────────────────────────────────────────────────────────
$tables['pages'] = "CREATE TABLE IF NOT EXISTS `pages` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`        VARCHAR(512) NOT NULL DEFAULT '',
  `slug`         VARCHAR(512) NOT NULL DEFAULT '' UNIQUE,
  `content`      LONGTEXT     NULL,
  `excerpt`      TEXT         NULL,
  `template`     VARCHAR(64)  NOT NULL DEFAULT 'default',
  `meta_title`   VARCHAR(512) NOT NULL DEFAULT '',
  `meta_desc`    VARCHAR(512) NOT NULL DEFAULT '',
  `cover_image`  VARCHAR(512) NOT NULL DEFAULT '',
  `parent_id`    INT UNSIGNED NULL,
  `sort_order`   INT          NOT NULL DEFAULT 0,
  `is_published` TINYINT(1)   NOT NULL DEFAULT 0,
  `show_in_menu` TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── contacts ──────────────────────────────────────────────────────────────
$tables['contacts'] = "CREATE TABLE IF NOT EXISTS `contacts` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `category`    VARCHAR(64)  NOT NULL DEFAULT 'general',
  `label`       VARCHAR(255) NOT NULL DEFAULT '',
  `name`        VARCHAR(255) NOT NULL DEFAULT '',
  `position`    VARCHAR(255) NOT NULL DEFAULT '',
  `department`  VARCHAR(255) NOT NULL DEFAULT '',
  `phone`       VARCHAR(64)  NOT NULL DEFAULT '',
  `email`       VARCHAR(255) NOT NULL DEFAULT '',
  `address`     VARCHAR(512) NOT NULL DEFAULT '',
  `room`        VARCHAR(64)  NOT NULL DEFAULT '',
  `schedule`    VARCHAR(255) NOT NULL DEFAULT '',
  `vk_url`      VARCHAR(512) NOT NULL DEFAULT '',
  `photo_url`   VARCHAR(512) NOT NULL DEFAULT '',
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `sort_order`  INT          NOT NULL DEFAULT 0,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── departments ───────────────────────────────────────────────────────────
$tables['departments'] = "CREATE TABLE IF NOT EXISTS `departments` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(255) NOT NULL DEFAULT '',
  `short_name`  VARCHAR(64)  NOT NULL DEFAULT '',
  `code`        VARCHAR(32)  NOT NULL DEFAULT '',
  `description` TEXT         NULL,
  `head_name`   VARCHAR(255) NOT NULL DEFAULT '',
  `head_title`  VARCHAR(255) NOT NULL DEFAULT '',
  `email`       VARCHAR(255) NOT NULL DEFAULT '',
  `phone`       VARCHAR(64)  NOT NULL DEFAULT '',
  `room`        VARCHAR(64)  NOT NULL DEFAULT '',
  `schedule`    VARCHAR(255) NOT NULL DEFAULT '',
  `photo_url`   VARCHAR(512) NOT NULL DEFAULT '',
  `sort_order`  INT          NOT NULL DEFAULT 0,
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── specialties ───────────────────────────────────────────────────────────
$tables['specialties'] = "CREATE TABLE IF NOT EXISTS `specialties` (
  `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code`               VARCHAR(32)  NOT NULL DEFAULT '',
  `title`              VARCHAR(512) NOT NULL DEFAULT '',
  `short_title`        VARCHAR(255) NOT NULL DEFAULT '',
  `description`        TEXT         NULL,
  `duration_label`     VARCHAR(128) NOT NULL DEFAULT '',
  `study_form_label`   VARCHAR(128) NOT NULL DEFAULT '',
  `qualification_text` VARCHAR(512) NOT NULL DEFAULT '',
  `career_text`        TEXT         NULL,
  `skills_text`        TEXT         NULL,
  `salary_text`        VARCHAR(255) NOT NULL DEFAULT '',
  `color_hex`          VARCHAR(16)  NOT NULL DEFAULT '#6c63ff',
  `icon_name`          VARCHAR(64)  NOT NULL DEFAULT '',
  `image_url`          VARCHAR(512) NOT NULL DEFAULT '',
  `department_id`      INT UNSIGNED NULL,
  `sort_order`         INT          NOT NULL DEFAULT 0,
  `is_published`       TINYINT(1)   NOT NULL DEFAULT 0,
  `publish_from`       DATE         NULL,
  `publish_to`         DATE         NULL,
  `created_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── education_programs ────────────────────────────────────────────────────
$tables['education_programs'] = "CREATE TABLE IF NOT EXISTS `education_programs` (
  `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `specialty_id`   INT UNSIGNED NULL,
  `title`          VARCHAR(512) NOT NULL DEFAULT '',
  `code`           VARCHAR(32)  NOT NULL DEFAULT '',
  `form`           VARCHAR(32)  NOT NULL DEFAULT 'full-time',
  `duration_years` DECIMAL(4,1) NULL,
  `description`    TEXT         NULL,
  `admission_info` TEXT         NULL,
  `budget_places`  INT UNSIGNED NULL,
  `paid_places`    INT UNSIGNED NULL,
  `tuition_cost`   DECIMAL(12,2) NULL,
  `is_active`      TINYINT(1)   NOT NULL DEFAULT 1,
  `sort_order`     INT          NOT NULL DEFAULT 0,
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── curriculum ────────────────────────────────────────────────────────────
$tables['curriculum'] = "CREATE TABLE IF NOT EXISTS `curriculum` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `program_id`   INT UNSIGNED NULL,
  `discipline`   VARCHAR(512) NOT NULL DEFAULT '',
  `semester`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `hours`        INT UNSIGNED NULL,
  `form_control` VARCHAR(32) NOT NULL DEFAULT 'exam',
  `sort_order`   INT         NOT NULL DEFAULT 0,
  `created_at`   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── groups_ref ────────────────────────────────────────────────────────────
$tables['groups_ref'] = "CREATE TABLE IF NOT EXISTS `groups_ref` (
  `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`           VARCHAR(64)  NOT NULL DEFAULT '',
  `short_name`     VARCHAR(32)  NOT NULL DEFAULT '',
  `specialty_id`   INT UNSIGNED NULL,
  `study_year`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `education_form` VARCHAR(32)  NOT NULL DEFAULT 'full-time',
  `curator_id`     INT UNSIGNED NULL,
  `students_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `is_active`      TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── disciplines ───────────────────────────────────────────────────────────
$tables['disciplines'] = "CREATE TABLE IF NOT EXISTS `disciplines` (
  `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`           VARCHAR(512) NOT NULL DEFAULT '',
  `short_name`     VARCHAR(128) NOT NULL DEFAULT '',
  `code`           VARCHAR(32)  NOT NULL DEFAULT '',
  `description`    TEXT         NULL,
  `department_id`  INT UNSIGNED NULL,
  `hours_total`    INT UNSIGNED NULL,
  `hours_lecture`  INT UNSIGNED NULL,
  `hours_practice` INT UNSIGNED NULL,
  `form_control`   VARCHAR(32)  NOT NULL DEFAULT 'exam',
  `is_active`      TINYINT(1)   NOT NULL DEFAULT 1,
  `sort_order`     INT          NOT NULL DEFAULT 0,
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── staff_members ─────────────────────────────────────────────────────────
$tables['staff_members'] = "CREATE TABLE IF NOT EXISTS `staff_members` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `full_name`     VARCHAR(255) NOT NULL DEFAULT '',
  `short_name`    VARCHAR(128) NOT NULL DEFAULT '',
  `position`      VARCHAR(255) NOT NULL DEFAULT '',
  `academic_rank` VARCHAR(128) NOT NULL DEFAULT '',
  `degree`        VARCHAR(128) NOT NULL DEFAULT '',
  `department_id` INT UNSIGNED NULL,
  `email`         VARCHAR(255) NOT NULL DEFAULT '',
  `phone`         VARCHAR(64)  NOT NULL DEFAULT '',
  `room`          VARCHAR(64)  NOT NULL DEFAULT '',
  `schedule`      VARCHAR(255) NOT NULL DEFAULT '',
  `bio`           TEXT         NULL,
  `photo_url`     VARCHAR(512) NOT NULL DEFAULT '',
  `role`          VARCHAR(64)  NOT NULL DEFAULT 'teacher',
  `disciplines`   TEXT         NULL,
  `sort_order`    INT          NOT NULL DEFAULT 0,
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `is_head`       TINYINT(1)   NOT NULL DEFAULT 0,
  `vk_url`        VARCHAR(512) NOT NULL DEFAULT '',
  `personal_page` VARCHAR(512) NOT NULL DEFAULT '',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── users (студенты и пользователи приложения) ────────────────────────────
$tables['users'] = "CREATE TABLE IF NOT EXISTS `users` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `login`         VARCHAR(64)  NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL DEFAULT '',
  `email`         VARCHAR(255) NOT NULL DEFAULT '',
  `phone`         VARCHAR(32)  NOT NULL DEFAULT '',
  `role`          VARCHAR(32)  NOT NULL DEFAULT 'student',
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── student_profiles ──────────────────────────────────────────────────────
$tables['student_profiles'] = "CREATE TABLE IF NOT EXISTS `student_profiles` (
  `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`        INT UNSIGNED NOT NULL UNIQUE,
  `full_name`      VARCHAR(255) NOT NULL DEFAULT '',
  `birth_date`     DATE         NULL,
  `gender`         ENUM('M','F') NULL,
  `group_id`       INT UNSIGNED NULL,
  `study_year`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `education_form` VARCHAR(32)  NOT NULL DEFAULT 'full-time',
  `admission_year` YEAR         NULL,
  `photo_url`      VARCHAR(512) NOT NULL DEFAULT '',
  `address`        TEXT         NULL,
  `vk_url`         VARCHAR(512) NOT NULL DEFAULT '',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── applications ──────────────────────────────────────────────────────────
$tables['applications'] = "CREATE TABLE IF NOT EXISTS `applications` (
  `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `full_name`        VARCHAR(255) NOT NULL DEFAULT '',
  `email`            VARCHAR(255) NOT NULL DEFAULT '',
  `phone`            VARCHAR(64)  NOT NULL DEFAULT '',
  `type`             ENUM('documents','courses','consultation','other') NOT NULL DEFAULT 'documents',
  `specialty_text`   VARCHAR(512) NOT NULL DEFAULT '',
  `education_form`   VARCHAR(64)  NOT NULL DEFAULT '',
  `message`          TEXT         NULL,
  `notes`            TEXT         NULL,
  `status`           ENUM('new','processing','approved','rejected','archived') NOT NULL DEFAULT 'new',
  `rejection_reason` TEXT         NULL,
  `payload_json`     JSON         NULL,
  `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (`status`),
  INDEX (`type`),
  INDEX (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── application_documents ─────────────────────────────────────────────────
$tables['application_documents'] = "CREATE TABLE IF NOT EXISTS `application_documents` (
  `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `application_id` INT UNSIGNED NOT NULL,
  `file_name`      VARCHAR(255) NOT NULL DEFAULT '',
  `file_url`       VARCHAR(512) NOT NULL DEFAULT '',
  `file_type`      VARCHAR(64)  NOT NULL DEFAULT '',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── schedule ──────────────────────────────────────────────────────────────
$tables['schedule'] = "CREATE TABLE IF NOT EXISTS `schedule` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `group_id`      INT UNSIGNED NULL,
  `discipline_id` INT UNSIGNED NULL,
  `staff_id`      INT UNSIGNED NULL,
  `day_of_week`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `lesson_number` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `week_type`     ENUM('all','odd','even') NOT NULL DEFAULT 'all',
  `study_year`    TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `semester`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `time_start`    VARCHAR(8)   NOT NULL DEFAULT '',
  `time_end`      VARCHAR(8)   NOT NULL DEFAULT '',
  `room`          VARCHAR(64)  NOT NULL DEFAULT '',
  `lesson_type`   VARCHAR(32)  NOT NULL DEFAULT 'lecture',
  `subgroup`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `note`          VARCHAR(255) NOT NULL DEFAULT '',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (`group_id`),
  INDEX (`day_of_week`),
  INDEX (`week_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── documents ─────────────────────────────────────────────────────────────
$tables['documents'] = "CREATE TABLE IF NOT EXISTS `documents` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(512) NOT NULL DEFAULT '',
  `description` TEXT         NULL,
  `file_url`    VARCHAR(512) NOT NULL DEFAULT '',
  `file_type`   VARCHAR(32)  NOT NULL DEFAULT 'other',
  `file_size`   INT UNSIGNED NULL,
  `category`    VARCHAR(64)  NOT NULL DEFAULT 'other',
  `is_public`   TINYINT(1)   NOT NULL DEFAULT 1,
  `sort_order`  INT          NOT NULL DEFAULT 0,
  `uploaded_by` INT UNSIGNED NULL,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── partners ──────────────────────────────────────────────────────────────
$tables['partners'] = "CREATE TABLE IF NOT EXISTS `partners` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`          VARCHAR(255) NOT NULL DEFAULT '',
  `category`      VARCHAR(64)  NOT NULL DEFAULT 'general',
  `description`   TEXT         NULL,
  `logo_url`      VARCHAR(512) NOT NULL DEFAULT '',
  `website_url`   VARCHAR(512) NOT NULL DEFAULT '',
  `contact_name`  VARCHAR(255) NOT NULL DEFAULT '',
  `contact_email` VARCHAR(255) NOT NULL DEFAULT '',
  `contact_phone` VARCHAR(64)  NOT NULL DEFAULT '',
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `sort_order`    INT          NOT NULL DEFAULT 0,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── vacancies ─────────────────────────────────────────────────────────────
$tables['vacancies'] = "CREATE TABLE IF NOT EXISTS `vacancies` (
  `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`           VARCHAR(512) NOT NULL DEFAULT '',
  `company_name`    VARCHAR(255) NOT NULL DEFAULT '',
  `partner_id`      INT UNSIGNED NULL,
  `category`        VARCHAR(64)  NOT NULL DEFAULT 'general',
  `description`     TEXT         NULL,
  `requirements`    TEXT         NULL,
  `conditions`      TEXT         NULL,
  `salary_from`     INT UNSIGNED NULL,
  `salary_to`       INT UNSIGNED NULL,
  `salary_currency` VARCHAR(8)   NOT NULL DEFAULT 'RUB',
  `employment_type` VARCHAR(32)  NOT NULL DEFAULT 'full-time',
  `experience`      VARCHAR(128) NOT NULL DEFAULT '',
  `location`        VARCHAR(255) NOT NULL DEFAULT '',
  `contact_name`    VARCHAR(255) NOT NULL DEFAULT '',
  `contact_email`   VARCHAR(255) NOT NULL DEFAULT '',
  `contact_phone`   VARCHAR(64)  NOT NULL DEFAULT '',
  `apply_url`       VARCHAR(512) NOT NULL DEFAULT '',
  `is_active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `is_featured`     TINYINT(1)   NOT NULL DEFAULT 0,
  `expires_at`      DATE         NULL,
  `sort_order`      INT          NOT NULL DEFAULT 0,
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── career_events ─────────────────────────────────────────────────────────
$tables['career_events'] = "CREATE TABLE IF NOT EXISTS `career_events` (
  `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`              VARCHAR(512) NOT NULL DEFAULT '',
  `description`        TEXT         NULL,
  `event_type`         VARCHAR(64)  NOT NULL DEFAULT 'general',
  `location`           VARCHAR(255) NOT NULL DEFAULT '',
  `is_online`          TINYINT(1)   NOT NULL DEFAULT 0,
  `online_url`         VARCHAR(512) NOT NULL DEFAULT '',
  `cover_image`        VARCHAR(512) NOT NULL DEFAULT '',
  `organizer`          VARCHAR(255) NOT NULL DEFAULT '',
  `partner_id`         INT UNSIGNED NULL,
  `starts_at`          DATETIME     NULL,
  `ends_at`            DATETIME     NULL,
  `registration_url`   VARCHAR(512) NOT NULL DEFAULT '',
  `max_participants`   INT UNSIGNED NULL,
  `is_published`       TINYINT(1)   NOT NULL DEFAULT 0,
  `sort_order`         INT          NOT NULL DEFAULT 0,
  `created_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── student_resumes ───────────────────────────────────────────────────────
$tables['student_resumes'] = "CREATE TABLE IF NOT EXISTS `student_resumes` (
  `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`          INT UNSIGNED NOT NULL,
  `desired_position` VARCHAR(255) NOT NULL DEFAULT '',
  `salary_expected`  INT UNSIGNED NULL,
  `skills_json`      JSON         NULL,
  `experience_text`  TEXT         NULL,
  `education_text`   TEXT         NULL,
  `about_text`       TEXT         NULL,
  `is_active`        TINYINT(1)   NOT NULL DEFAULT 1,
  `is_featured`      TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── student_portfolio_items ───────────────────────────────────────────────
$tables['student_portfolio_items'] = "CREATE TABLE IF NOT EXISTS `student_portfolio_items` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`      INT UNSIGNED NOT NULL,
  `title`        VARCHAR(512) NOT NULL DEFAULT '',
  `description`  TEXT         NULL,
  `category`     VARCHAR(64)  NOT NULL DEFAULT 'other',
  `cover_image`  VARCHAR(512) NOT NULL DEFAULT '',
  `images_json`  JSON         NULL,
  `project_url`  VARCHAR(512) NOT NULL DEFAULT '',
  `is_published` TINYINT(1)   NOT NULL DEFAULT 0,
  `is_featured`  TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── site_settings ─────────────────────────────────────────────────────────
$tables['site_settings'] = "CREATE TABLE IF NOT EXISTS `site_settings` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `key`         VARCHAR(128) NOT NULL UNIQUE,
  `value`       TEXT         NULL,
  `type`        VARCHAR(32)  NOT NULL DEFAULT 'text',
  `label`       VARCHAR(255) NOT NULL DEFAULT '',
  `group`       VARCHAR(64)  NOT NULL DEFAULT 'general',
  `sort_order`  INT          NOT NULL DEFAULT 0,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (`group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── uploaded_files ────────────────────────────────────────────────────────
$tables['uploaded_files'] = "CREATE TABLE IF NOT EXISTS `uploaded_files` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `original_name` VARCHAR(512) NOT NULL DEFAULT '',
  `stored_name`   VARCHAR(512) NOT NULL DEFAULT '',
  `mime_type`     VARCHAR(128) NOT NULL DEFAULT '',
  `file_size`     INT UNSIGNED NOT NULL DEFAULT 0,
  `file_path`     VARCHAR(512) NOT NULL DEFAULT '',
  `url`           VARCHAR(512) NOT NULL DEFAULT '',
  `uploaded_by`   INT UNSIGNED NULL,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

// ── Выполнение ────────────────────────────────────────────────────────────
foreach ($tables as $tableName => $sql) {
    try {
        $pdo->exec($sql);
        logOk("Таблица <code>{$tableName}</code> — создана / уже существует");
    } catch (PDOException $e) {
        logErr("Таблица <code>{$tableName}</code> — ОШИБКА: " . $e->getMessage());
    }
}

// ── Шаг 3: Дефолтные настройки сайта ─────────────────────────────────────
$defaultSettings = [
    // Основные
    ['site_name',          'АКСИБГУУ',                         'text',     'Название сайта',                      'general', 1],
    ['site_url',           'https://cf990597-wordpress-yndvp.tw1.ru', 'url', 'URL сайта',                         'general', 2],
    ['site_description',   'Официальный сайт АКСИБГУУ',        'textarea', 'Описание сайта',                      'general', 3],
    ['site_phone',         '',                                  'text',     'Телефон приёмной',                    'general', 4],
    ['site_email',         '',                                  'email',    'E-mail сайта',                        'general', 5],
    ['site_address',       '',                                  'text',     'Адрес',                               'general', 6],
    ['site_logo',          '',                                  'url',      'URL логотипа',                        'general', 7],
    ['site_favicon',       '',                                  'url',      'URL favicon',                         'general', 8],
    ['site_maintenance',   '0',                                 'bool',     'Режим обслуживания',                  'general', 9],
    // ВКонтакте — ID группы media_ak предустановлен
    ['vk_group_id',        'media_ak',                         'text',     'ID группы ВК (числовой или алиас)',   'vk',      1],
    ['vk_token',           '',                                  'text',     'Сервисный ключ VK API',               'vk',      2],
    ['vk_parse_count',     '20',                               'number',   'Кол-во постов за запрос',             'vk',      3],
    ['vk_auto_parse',      '0',                                'bool',     'Автопарсинг при открытии',            'vk',      4],
    ['vk_group_url',       'https://vk.com/media_ak',          'url',      'Ссылка на группу ВК',                'vk',      5],
    // SMTP почта
    ['smtp_host',          '',                                  'text',     'SMTP хост',                          'smtp',    1],
    ['smtp_port',          '465',                               'number',   'SMTP порт',                          'smtp',    2],
    ['smtp_user',          '',                                  'text',     'Логин SMTP',                         'smtp',    3],
    ['smtp_pass',          '',                                  'text',     'Пароль SMTP',                        'smtp',    4],
    ['smtp_from',          '',                                  'email',    'Отправитель (From)',                  'smtp',    5],
    ['smtp_from_name',     'АКСИБГУУ',                         'text',     'Имя отправителя',                    'smtp',    6],
    ['smtp_secure',        '1',                                 'bool',     'Безопасное соединение (SSL/TLS)',     'smtp',    7],
    ['smtp_enabled',       '0',                                 'bool',     'Включить отправку почты',            'smtp',    8],
    // Главная страница
    ['home_hero_title',    'АКСИБГУУ',                         'text',     'Заголовок главной страницы',         'home',    1],
    ['home_hero_subtitle', 'Алтайский краевой индустриально-строительный колледж', 'text', 'Подзаголовок', 'home', 2],
    ['home_hero_image',    '',                                  'url',      'Фоновое изображение hero',           'home',    3],
    ['home_news_count',    '6',                                 'number',   'Кол-во новостей на главной',         'home',    4],
    ['home_stories_count', '8',                                 'number',   'Кол-во историй на главной',          'home',    5],
    ['home_partners_show', '1',                                 'bool',     'Показывать партнёров',               'home',    6],
    ['home_stats_show',    '1',                                 'bool',     'Показывать статистику',              'home',    7],
    ['home_welcome_text',  '',                                  'textarea', 'Приветственный текст',               'home',    8],
    // Карьерный центр
    ['career_enabled',     '1',                                 'bool',     'Включить карьерный раздел',          'career',  1],
    ['career_email',       '',                                  'email',    'Email карьерного центра',            'career',  2],
    ['career_phone',       '',                                  'text',     'Телефон карьерного центра',          'career',  3],
    ['career_schedule',    'Пн–Пт 9:00–17:00',                 'text',     'График работы',                      'career',  4],
    ['career_resume_public','0',                                'bool',     'Резюме открыты для работодателей',   'career',  5],
    ['career_vacancy_count','12',                               'number',   'Вакансий на странице',               'career',  6],
    ['career_events_count', '6',                                'number',   'Мероприятий на странице',            'career',  7],
];
$settingIns = $pdo->prepare("INSERT IGNORE INTO site_settings (`key`,`value`,`type`,`label`,`group`,`sort_order`) VALUES (?,?,?,?,?,?)");
foreach ($defaultSettings as $s) {
    try { $settingIns->execute($s); } catch(Exception $e) {}
}
logOk("Настройки сайта по умолчанию — добавлены");

// ── Шаг 4: Администратор ─────────────────────────────────────────────────
$hash = password_hash($ADMIN_PASSWORD, PASSWORD_BCRYPT, ['cost' => 10]);
try {
    // Удалить старого с неверным хэшем и создать заново
    $pdo->prepare("DELETE FROM admins WHERE login=?")->execute([$ADMIN_LOGIN]);
    $pdo->prepare(
        "INSERT INTO admins (login, password_hash, full_name, email, role, is_active)
         VALUES (?, ?, ?, ?, ?, 1)"
    )->execute([$ADMIN_LOGIN, $hash, $ADMIN_NAME, $ADMIN_EMAIL, $ADMIN_ROLE]);
    logOk("Администратор <b>{$ADMIN_LOGIN}</b> создан с паролем <b>{$ADMIN_PASSWORD}</b>");
} catch (PDOException $e) {
    logErr("Ошибка создания администратора: " . $e->getMessage());
}

} // end if $pdo

?>
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Setup — АКСИБГУУ</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Arial,sans-serif;background:#0f1117;color:#e8eaf6;min-height:100vh;padding:20px}
.wrap{max-width:760px;margin:30px auto}
h1{font-size:22px;color:#6c63ff;margin-bottom:4px}
.sub{color:#9ca3c4;font-size:13px;margin-bottom:24px}
.item{display:flex;align-items:flex-start;gap:12px;padding:10px 14px;border-radius:8px;margin-bottom:6px;font-size:14px;line-height:1.5}
.item.ok  {background:rgba(39,174,96,.1); border:1px solid rgba(39,174,96,.25)}
.item.err {background:rgba(231,76,60,.1); border:1px solid rgba(231,76,60,.25)}
.item.info{background:rgba(108,99,255,.1);border:1px solid rgba(108,99,255,.25)}
.ico{font-size:16px;flex-shrink:0;margin-top:1px}
.ok  .ico{color:#27ae60}
.err .ico{color:#e74c3c}
.info .ico{color:#6c63ff}
.result{margin-top:24px;border-radius:12px;padding:24px;text-align:center}
.result.success{background:rgba(39,174,96,.12);border:1px solid rgba(39,174,96,.3)}
.result.fail   {background:rgba(231,76,60,.12); border:1px solid rgba(231,76,60,.3)}
.result h2{font-size:20px;margin-bottom:10px}
.creds{display:inline-flex;gap:30px;background:rgba(0,0,0,.3);border-radius:8px;padding:12px 24px;margin:14px 0;flex-wrap:wrap;justify-content:center}
.cred-label{font-size:11px;color:#9ca3c4;margin-bottom:2px}
.cred-val{font-size:18px;font-weight:700;color:#6c63ff;font-family:monospace}
.btn{display:inline-block;margin-top:14px;padding:12px 28px;background:#6c63ff;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;font-size:15px}
.btn:hover{background:#5a52d5}
.warn{background:rgba(243,156,18,.1);border:1px solid rgba(243,156,18,.3);border-radius:8px;padding:12px 16px;font-size:13px;color:#fbbf24;margin-top:16px}
code{background:rgba(255,255,255,.08);padding:2px 6px;border-radius:4px;font-family:monospace;font-size:12px}
</style>
</head>
<body>
<?php
$okCount   = count(array_filter($log, fn($l) => $l[0]==='ok'));
$errCount  = count(array_filter($log, fn($l) => $l[0]==='err'));
$infoCount = count(array_filter($log, fn($l) => $l[0]==='info'));
?>
<div class="wrap">
  <h1>🛠️ АКСИБГУУ — Установка базы данных</h1>
  <p class="sub">Версия PHP: <b><?= PHP_VERSION ?></b> | Сервер: <b><?= htmlspecialchars($_SERVER['SERVER_NAME'] ?? 'localhost') ?></b> | Время: <b><?= date('d.m.Y H:i:s') ?></b></p>

  <div style="display:flex;gap:12px;margin-bottom:20px;flex-wrap:wrap">
    <div style="background:rgba(39,174,96,.15);border:1px solid rgba(39,174,96,.3);border-radius:8px;padding:10px 18px;font-size:13px">
      ✅ Успешно: <b style="color:#27ae60"><?= $okCount ?></b>
    </div>
    <div style="background:rgba(231,76,60,.15);border:1px solid rgba(231,76,60,.3);border-radius:8px;padding:10px 18px;font-size:13px">
      ❌ Ошибок: <b style="color:#e74c3c"><?= $errCount ?></b>
    </div>
    <div style="background:rgba(108,99,255,.15);border:1px solid rgba(108,99,255,.3);border-radius:8px;padding:10px 18px;font-size:13px">
      ℹ️ Инфо: <b style="color:#6c63ff"><?= $infoCount ?></b>
    </div>
  </div>

  <?php foreach ($log as [$type, $msg]): ?>
  <div class="item <?= $type ?>">
    <span class="ico"><?= $type==='ok'?'✅':($type==='err'?'❌':'ℹ️') ?></span>
    <span><?= $msg ?></span>
  </div>
  <?php endforeach; ?>

  <?php if (!$pdo): ?>
  <div class="result fail">
    <h2>❌ Не удалось подключиться к базе данных</h2>
    <div style="color:#9ca3c4;font-size:14px;margin-top:12px;text-align:left;max-width:500px;margin-left:auto;margin-right:auto">
      <b>Возможные причины:</b><br>
      1. База данных ещё не создана в панели TimeWeb<br>
      2. Неверные данные подключения (логин/пароль/имя БД)<br>
      3. Файл <code>config.php</code> загружен с неверными данными<br><br>
      <b>Текущие настройки в setup.php:</b><br>
      • Хост: <code><?= htmlspecialchars($DB_HOST) ?></code><br>
      • БД: <code><?= htmlspecialchars($DB_NAME) ?></code><br>
      • Пользователь: <code><?= htmlspecialchars($DB_USER) ?></code><br><br>
      Если данные верны — убедитесь, что БД <code><?= htmlspecialchars($DB_NAME) ?></code> существует в phpMyAdmin.
    </div>
    <br>
    <a href="setup.php" class="btn" style="margin-right:10px">🔄 Повторить</a>
  </div>

  <?php elseif ($errCount === 0): ?>
  <div class="result success">
    <h2>🎉 Установка завершена успешно!</h2>
    <p style="color:#9ca3c4;font-size:14px">Все <?= $okCount ?> операций выполнены. Войдите в панель управления:</p>
    <div class="creds">
      <div><div class="cred-label">Логин</div><div class="cred-val"><?= htmlspecialchars($ADMIN_LOGIN) ?></div></div>
      <div><div class="cred-label">Пароль</div><div class="cred-val"><?= htmlspecialchars($ADMIN_PASSWORD) ?></div></div>
    </div>
    <br>
    <a href="login.php" class="btn">→ Войти в панель</a>
    <div class="warn">⚠️ <b>УДАЛИТЕ этот файл с хостинга сразу после входа!</b><br>
    Путь на сервере: <code>public_html/admin/setup.php</code></div>
  </div>

  <?php else: ?>
  <div class="result fail">
    <h2>⚠️ Установка завершена с ошибками (<?= $errCount ?>)</h2>
    <p style="color:#9ca3c4;font-size:14px">Часть таблиц не создана. Смотрите ❌ выше.</p>
    <br>
    <a href="setup.php" class="btn" style="margin-right:10px">🔄 Повторить установку</a>
    <a href="login.php" class="btn" style="background:#27ae60">→ Попробовать войти</a>
  </div>
  <?php endif; ?>

  <div style="margin-top:30px;padding:16px;background:rgba(255,255,255,.03);border-radius:8px;font-size:12px;color:#475569;text-align:center">
    setup.php — Запущен: <?= date('d.m.Y H:i:s') ?> | 
    IP: <?= htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? '?') ?>
  </div>

</div>
</body>
</html>