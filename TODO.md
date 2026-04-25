# План: Подключение Flutter-приложения к хостингу https://aksibgu.gamer.gd

## Информация
- `api_base_url.dart` уже содержит правильный URL `https://aksibgu.gamer.gd`
- Backend (PHP) не имеет CORS-заголовков
- Backend (PHP) не имеет `.htaccess` для перенаправления запросов на `index.php`
- На хостинге, скорее всего, Apache — без `.htaccess` запросы к `/health`, `/auth/login` вернут 404

## Шаги

1. [ ] Создать `backend/public/.htaccess` — перенаправление всех запросов на `index.php`
2. [ ] Добавить CORS в `backend/public/index.php` — заголовки + обработка OPTIONS (preflight)
3. [ ] Добавить CORS в `backend/src/Response.php` — Access-Control-Allow-Origin/Methods/Headers
4. [ ] (После загрузки на хостинг) Проверить `https://aksibgu.gamer.gd/health`

