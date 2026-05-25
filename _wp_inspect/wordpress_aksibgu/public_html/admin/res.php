<?php

define('SECRET_KEY', 'я даун забыл пароль');

require_once __DIR__ . '/config.php';

$message = '';
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $secret   = $_POST['secret']   ?? '';
    $login    = trim($_POST['login']    ?? 'admin');
    $password = $_POST['password'] ?? '';

    if ($secret !== SECRET_KEY) {
        $message = '❌ Неверный секретный ключ';
    } elseif (mb_strlen($password) < 6) {
        $message = '❌ Пароль минимум 6 символов';
    } else {
        try {
            $pdo  = getDB();
            $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);

            // Попробуем обновить существующего, если нет — создать
            $check = $pdo->prepare("SELECT id FROM admins WHERE login=? LIMIT 1");
            $check->execute([$login]);
            $existing = $check->fetch();

            if ($existing) {
                $pdo->prepare("UPDATE admins SET password_hash=?, is_active=1 WHERE login=?")
                    ->execute([$hash, $login]);
                $message = "✅ Пароль для администратора «{$login}» успешно обновлён!";
            } else {
                $pdo->prepare(
                    "INSERT INTO admins (login, password_hash, full_name, email, role, is_active)
                     VALUES (?, ?, 'Администратор', 'admin@aksibguu.ru', 'superadmin', 1)"
                )->execute([$login, $hash]);
                $message = "✅ Администратор «{$login}» создан с новым паролем!";
            }
            $success = true;
        } catch (Exception $e) {
            $message = '❌ Ошибка БД: ' . $e->getMessage();
        }
    }
}

// Тест подключения к БД
$dbStatus = '';
$dbOk = false;
try {
    $pdo = getDB();
    $cnt = $pdo->query("SELECT COUNT(*) FROM admins")->fetchColumn();
    $dbOk = true;
    $dbStatus = "✅ БД подключена. Администраторов в таблице: <strong>{$cnt}</strong>";
} catch (Exception $e) {
    $dbStatus = "❌ Ошибка подключения к БД: " . htmlspecialchars($e->getMessage());
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Сброс пароля — АКСИБГУУ</title>
<style>
  body { font-family: Arial, sans-serif; background: #0f1117; color: #e8eaf6; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; }
  .box { background: #1a1d27; border: 1px solid rgba(255,255,255,.1); border-radius: 16px; padding: 36px; max-width: 480px; width: 100%; }
  h1 { font-size: 20px; margin-bottom: 6px; color: #6c63ff; }
  .subtitle { color: #9ca3c4; font-size: 13px; margin-bottom: 24px; }
  .db-status { background: rgba(255,255,255,.05); border-radius: 8px; padding: 12px 16px; font-size: 13px; margin-bottom: 20px; }
  label { display: block; color: #9ca3c4; font-size: 12px; margin-bottom: 6px; margin-top: 16px; }
  input[type=text], input[type=password] {
    width: 100%; padding: 11px 14px; background: rgba(255,255,255,.07);
    border: 1px solid rgba(255,255,255,.12); border-radius: 8px; color: #e8eaf6;
    font-size: 14px; box-sizing: border-box; outline: none;
  }
  input:focus { border-color: #6c63ff; }
  .btn { width: 100%; margin-top: 20px; padding: 13px; background: #6c63ff; color: #fff; border: none; border-radius: 8px; font-size: 15px; font-weight: 600; cursor: pointer; }
  .btn:hover { background: #5a52d5; }
  .msg { margin-top: 16px; padding: 12px 16px; border-radius: 8px; font-size: 14px; }
  .msg.ok  { background: rgba(39,174,96,.15); border: 1px solid rgba(39,174,96,.3); color: #86efac; }
  .msg.err { background: rgba(231,76,60,.15);  border: 1px solid rgba(231,76,60,.3);  color: #fca5a5; }
  .warn { background: rgba(243,156,18,.12); border: 1px solid rgba(243,156,18,.3); border-radius: 8px; padding: 12px 16px; font-size: 13px; color: #fbbf24; margin-top: 20px; }
  .login-link { display: block; text-align: center; margin-top: 20px; color: #6c63ff; font-size: 14px; }
</style>
</head>
<body>
<div class="box">
  <h1>🔑 Сброс пароля администратора</h1>
  <p class="subtitle">Инструмент экстренного доступа — АКСИБГУУ Админ-панель</p>

  <div class="db-status"><?= $dbStatus ?></div>

  <?php if ($message): ?>
    <div class="msg <?= $success ? 'ok' : 'err' ?>"><?= $message ?></div>
  <?php endif; ?>

  <?php if ($success): ?>
    <a href="login.php" class="btn" style="display:block;text-align:center;text-decoration:none;box-sizing:border-box">
      → Перейти ко входу
    </a>
    
  <?php else: ?>
  <form method="POST">
    <label>СЕКРЕТНЫЙ КЛЮЧ (по умолчанию: я даун забыл пароль)</label>
    <input type="text" name="secret" placeholder="Введите секретный ключ" autocomplete="off">

    <label>ЛОГИН АДМИНИСТРАТОРА</label>
    <input type="text" name="login" value="admin" placeholder="admin">

    <label>НОВЫЙ ПАРОЛЬ (минимум 6 символов)</label>
    <input type="password" name="password" placeholder="Введите новый пароль">

    <button type="submit" class="btn">Сбросить пароль</button>
  </form>
  
  <?php endif; ?>
</div>
</body>
</html>