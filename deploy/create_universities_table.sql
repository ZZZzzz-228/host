-- Если в админке «Университеты» падают с ошибкой БД — выполнить в phpMyAdmin

CREATE TABLE IF NOT EXISTS `universities` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `short_name` varchar(64) NOT NULL DEFAULT '',
  `description` text,
  `full_text` mediumtext,
  `url` varchar(512) NOT NULL DEFAULT '',
  `admission_url` varchar(512) NOT NULL DEFAULT '',
  `vk_url` varchar(512) NOT NULL DEFAULT '',
  `telegram_url` varchar(512) NOT NULL DEFAULT '',
  `logo_url` varchar(512) NOT NULL DEFAULT '',
  `cover_url` varchar(512) NOT NULL DEFAULT '',
  `city` varchar(128) NOT NULL DEFAULT '',
  `address` varchar(512) NOT NULL DEFAULT '',
  `phone` varchar(64) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT '',
  `tags` varchar(512) NOT NULL DEFAULT '',
  `specialties_offered` text,
  `sort_order` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `is_active` (`is_active`),
  KEY `sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
