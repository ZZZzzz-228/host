-- АКСИБГУ: замена старых таблиц резюме и портфолио на формат public_api/index.php
-- Выполнить в phpMyAdmin → база cf990597_aksibgu → вкладка SQL → Выполнить

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Старые / несовместимые таблицы (API их не использует или схема другая)
DROP TABLE IF EXISTS `student_resumes`;
DROP TABLE IF EXISTS `student_portfolio`;
DROP TABLE IF EXISTS `student_portfolio_items`;

SET FOREIGN_KEY_CHECKS = 1;

-- ─── Резюме студента (привязка к students.id через student_id) ───
CREATE TABLE `student_resumes` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` int UNSIGNED NOT NULL,
  `specialty_id` int UNSIGNED DEFAULT NULL,
  `specialty_custom` varchar(255) NOT NULL DEFAULT '',
  `last_name` varchar(128) NOT NULL DEFAULT '',
  `first_name` varchar(128) NOT NULL DEFAULT '',
  `middle_name` varchar(128) NOT NULL DEFAULT '',
  `birth_date` date DEFAULT NULL,
  `gender` varchar(16) NOT NULL DEFAULT '',
  `city` varchar(128) NOT NULL DEFAULT '',
  `phone` varchar(32) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT '',
  `telegram` varchar(128) NOT NULL DEFAULT '',
  `vk` varchar(255) NOT NULL DEFAULT '',
  `desired_position` varchar(255) NOT NULL DEFAULT '',
  `desired_salary` int UNSIGNED DEFAULT NULL,
  `employment_type` varchar(128) NOT NULL DEFAULT '',
  `schedule` varchar(128) NOT NULL DEFAULT '',
  `work_experience` text,
  `education` text,
  `skills` text,
  `about` text,
  `languages` varchar(512) NOT NULL DEFAULT '',
  `portfolio_links` text,
  `specialty_answers` text,
  `is_published` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `specialty_id` (`specialty_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Портфолио студента ───
CREATE TABLE `student_portfolio` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` int UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL DEFAULT '',
  `description` text,
  `category` varchar(128) NOT NULL DEFAULT '',
  `project_url` varchar(512) NOT NULL DEFAULT '',
  `image_url` varchar(512) NOT NULL DEFAULT '',
  `tags` varchar(512) NOT NULL DEFAULT '',
  `is_published` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
