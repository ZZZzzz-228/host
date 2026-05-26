<?php
/**
 * Основные параметры WordPress.
 *
 * Скрипт для создания wp-config.php использует этот файл в процессе установки.
 * Необязательно использовать веб-интерфейс, можно скопировать файл в "wp-config.php"
 * и заполнить значения вручную.
 *
 * Этот файл содержит следующие параметры:
 *
 * * Настройки базы данных
 * * Секретные ключи
 * * Префикс таблиц базы данных
 * * ABSPATH
 *
 * @link https://ru.wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Параметры базы данных: Эту информацию можно получить у вашего хостинг-провайдера ** //
/** Имя базы данных для WordPress */
define( 'DB_NAME', 'cf990597_aksibgu' );

/** Имя пользователя базы данных */
define( 'DB_USER', 'cf990597_aksibgu' );

/** Пароль к базе данных */
define( 'DB_PASSWORD', 'aen5fNt8' );

/** Имя сервера базы данных */
define( 'DB_HOST', 'localhost' );

/** Кодировка базы данных для создания таблиц. */
define( 'DB_CHARSET', 'utf8mb4' );

/** Схема сопоставления. Не меняйте, если не уверены. */
define( 'DB_COLLATE', '' );

/**#@+
 * Уникальные ключи и соли для аутентификации.
 *
 * Смените значение каждой константы на уникальную фразу. Можно сгенерировать их с помощью
 * {@link https://api.wordpress.org/secret-key/1.1/salt/ сервиса ключей на WordPress.org}.
 *
 * Можно изменить их, чтобы сделать существующие файлы cookies недействительными.
 * Пользователям потребуется авторизоваться снова.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'Iebh83Pt9F_};vFLmJuF42<-iFI:/,x&.7NAPUww03&wQJRae]+SxS/-Pn7a#=!?' );
define( 'SECURE_AUTH_KEY',  '~P!&{e<9_{6A+?L*@0M71&YNjNx.p(?ZRxlREXH#~S9b0.VBLSRO|+t*Qko`^6<4' );
define( 'LOGGED_IN_KEY',    's3a1Be1V/o@}nxK*Av;4GGbd|ZZG,41fRj*L8{s7Fe?i_=9TIuGXXgtfxzV?V`6B' );
define( 'NONCE_KEY',        ']k,gM~qK8}1L=WG~O{=iVIYjPlr~<)y~`zpnQVp&Zh$`*CmvHc%/fuN(4{TBNE=y' );
define( 'AUTH_SALT',        '~~fCdkem=Q`tMoK]=L-45,@O{c]&L2%&m^Uw FK2KJb51,AS_}=80KlS:?{TpEum' );
define( 'SECURE_AUTH_SALT', 'XA|j*uC~0sA1):G3^EQ?DiYB{r03FBO(I(We%?:AUj/&H|J;luWe#4~zf/WT%42t' );
define( 'LOGGED_IN_SALT',   '7(C/oCkL>@t!`Zg8^J{m[IoyG^Zc[L&BR!#TQS%+9jju$}SH=O2|g:qomW<?`-$!' );
define( 'NONCE_SALT',       'T]W!L$96W9e>AJt$W[|LiQm](.02kU00i]+sVLUQZc*ft-b&S|U$U=8J[NJlGGsX' );

/**#@-*/

/**
 * Префикс таблиц в базе данных WordPress.
 *
 * Можно установить несколько сайтов в одну базу данных, если использовать
 * разные префиксы. Пожалуйста, указывайте только цифры, буквы и знак подчеркивания.
 */
$table_prefix = 'wp_';

/**
 * Для разработчиков: Режим отладки WordPress.
 *
 * Измените это значение на true, чтобы включить отображение уведомлений при разработке.
 * Разработчикам плагинов и тем настоятельно рекомендуется использовать WP_DEBUG
 * в своём рабочем окружении.
 *
 * Информацию о других отладочных константах можно найти в документации.
 *
 * @link https://ru.wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Произвольные значения добавляйте между этой строкой и надписью "дальше не редактируем". */



/* Это всё, дальше не редактируем. Успехов! */

/** Абсолютный путь к директории WordPress. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Инициализирует переменные WordPress и подключает файлы. */
require_once ABSPATH . 'wp-settings.php';
