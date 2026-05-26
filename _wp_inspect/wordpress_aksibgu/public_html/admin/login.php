<?php
/**
 * АКСИБГУУ — Страница входа в админ-панель
 * Файл: login.php
 */
require_once __DIR__ . '/config.php';

if (!empty($_SESSION['admin_logged_in'])) {
    header('Location: index.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_SERVER['HTTP_X_REQUESTED_WITH'])) {
    $input    = json_decode(file_get_contents('php://input'), true) ?? [];
    $username = sanitize($input['username'] ?? '');
    $password = $input['password'] ?? '';

    if (empty($username) || empty($password)) {
        jsonResponse(['success' => false, 'message' => 'Введите логин и пароль']);
    }

    try {
        $db   = getDB();
        $stmt = $db->prepare("SELECT id, login, password_hash, full_name, role FROM admins WHERE login = ? AND is_active = 1 LIMIT 1");
        $stmt->execute([$username]);
        $admin = $stmt->fetch();

        if ($admin && password_verify($password, $admin['password_hash'])) {
            $_SESSION['admin_logged_in']  = true;
            $_SESSION['admin_id']         = $admin['id'];
            $_SESSION['admin_username']   = $admin['login'];
            $_SESSION['admin_name']       = $admin['full_name'];
            $_SESSION['admin_role']       = $admin['role'];
            $_SESSION['admin_login_time'] = time();

            $db->prepare("UPDATE admins SET last_login = NOW() WHERE id = ?")->execute([$admin['id']]);
            logAction('LOGIN', 'Вход в систему');

            jsonResponse(['success' => true, 'redirect' => 'index.php']);
        } else {
            sleep(1);
            jsonResponse(['success' => false, 'message' => 'Неверный логин или пароль'], 401);
        }
    } catch (PDOException $e) {
        jsonResponse(['success' => false, 'message' => 'Ошибка базы данных: ' . $e->getMessage()], 500);
    }
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>АКСИБГУУ — Вход в админ-панель</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.4.0/css/all.min.css">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 50%, #0f172a 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .login-wrapper {
            width: 100%;
            max-width: 420px;
        }

        .login-logo {
            text-align: center;
            margin-bottom: 32px;
        }

        .login-logo .logo-wrap {
            width: 120px;
            height: 120px;
            margin: 0 auto 20px auto;
            color: #3b82f6;
        }

        .login-logo svg {
            width: 100%;
            height: 100%;
            filter: drop-shadow(0 10px 25px rgba(59, 130, 246, 0.5));
        }

        .login-logo h1 {
            color: #fff;
            font-size: 24px;
            font-weight: 700;
            letter-spacing: 1.5px;
            margin-bottom: 6px;
        }

        .login-logo p {
            color: #94a3b8;
            font-size: 13.5px;
        }

        .login-card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            color: #94a3b8;
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 8px;
            letter-spacing: 0.5px;
        }

        .input-wrap {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-wrap .icon-left {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #475569;
            font-size: 15px;
            pointer-events: none;
            transition: color 0.2s;
            z-index: 2;
        }

        .input-wrap input {
            width: 100%;
            padding: 13px 14px 13px 42px;
            background: rgba(255, 255, 255, 0.07);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            color: #f1f5f9;
            font-size: 15px;
            font-family: 'Inter', sans-serif;
            outline: none;
            transition: border-color 0.2s, background 0.2s;
        }

        .input-wrap input.has-toggle {
            padding-right: 44px;
        }

        .input-wrap input:focus {
            border-color: #3b82f6;
            background: rgba(59, 130, 246, 0.08);
        }

        .input-wrap input:focus ~ .icon-left { color: #3b82f6; }

        .toggle-pass {
            position: absolute;
            right: 0;
            top: 0;
            bottom: 0;
            width: 44px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #475569;
            cursor: pointer;
            background: none;
            border: none;
            padding: 0;
            transition: color 0.2s;
            z-index: 2;
            border-radius: 0 12px 12px 0;
        }

        .toggle-pass:hover { color: #94a3b8; }
        .toggle-pass i { font-size: 15px; pointer-events: none; }

        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 600;
            font-family: 'Inter', sans-serif;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s, opacity 0.2s;
            box-shadow: 0 4px 20px rgba(59, 130, 246, 0.4);
            margin-top: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .btn-login:hover:not(:disabled) {
            transform: translateY(-1px);
            box-shadow: 0 6px 28px rgba(59, 130, 246, 0.5);
        }

        .btn-login:disabled {
            opacity: 0.7;
            cursor: not-allowed;
        }

        .btn-login .spinner {
            width: 18px;
            height: 18px;
            border: 2px solid rgba(255,255,255,0.3);
            border-top-color: white;
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
            display: none;
        }

        .btn-login.loading .spinner  { display: block; }
        .btn-login.loading .btn-text { display: none; }

        @keyframes spin { to { transform: rotate(360deg); } }

        .alert {
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 14px;
            margin-bottom: 20px;
            display: none;
            align-items: center;
            gap: 10px;
        }

        .alert.error {
            background: rgba(239, 68, 68, 0.15);
            border: 1px solid rgba(239, 68, 68, 0.3);
            color: #fca5a5;
        }

        .alert.success {
            background: rgba(34, 197, 94, 0.15);
            border: 1px solid rgba(34, 197, 94, 0.3);
            color: #86efac;
        }

        .alert.show { display: flex; }

        .footer-note {
            text-align: center;
            margin-top: 24px;
            color: #334155;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="login-wrapper">
        <div class="login-logo">
          
            <div class="logo-wrap" aria-hidden="true">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 550 550" preserveAspectRatio="xMidYMid meet">
                    <g transform="translate(0,550) scale(0.1,-0.1)" fill="currentColor" stroke="none">
                        <path d="M2667 4674 c-4 -4 -7 -76 -7 -160 0 -84 -3 -155 -7 -157 -5 -3 -60 -12 -123 -21 -201 -29 -381 -86 -561 -176 -82 -42 -254 -160 -323 -221 l-59 -53 -86 92 c-47 51 -92 92 -99 92 -18 0 -112 -82 -112 -97 0 -7 39 -53 88 -104 48 -50 88 -95 90 -100 2 -5 -18 -37 -45 -71 -78 -102 -169 -261 -214 -376 -62 -158 -92 -290 -112 -492 l-2 -25 -170 -5 -170 -5 0 -75 0 -75 171 -3 171 -2 7 -73 c28 -291 156 -594 353 -841 l56 -68 -112 -112 c-61 -61 -111 -116 -111 -122 0 -12 94 -104 106 -104 4 0 58 50 119 111 l113 110 110 -83 c183 -139 423 -250 642 -298 72 -15 186 -32 290 -43 l25 -2 5 -145 5 -145 225 0 225 0 0 75 0 75 -147 3 -148 3 0 68 0 68 98 12 c309 40 583 148 815 322 58 43 109 79 112 79 4 0 48 -38 97 -85 50 -47 96 -85 102 -85 14 0 106 92 106 105 0 6 -43 50 -95 98 l-94 88 66 82 c199 246 306 497 348 816 19 137 19 233 0 374 -51 387 -211 700 -497 971 -264 252 -606 409 -976 447 l-122 13 -2 161 -3 160 -70 3 c-39 1 -74 0 -78 -4z m388 -496 c426 -83 795 -340 1020 -710 268 -443 267 -1025 -2 -1470 -50 -84 -168 -238 -181 -238 -4 0 -54 44 -111 98 l-104 97 64 85 c121 161 204 359 233 561 20 134 20 214 0 348 -37 256 -147 481 -326 667 -204 212 -445 335 -737 377 l-86 12 -3 89 c-2 49 -1 95 2 103 7 16 87 10 231 -19z m-405 -77 l0 -98 -72 -7 c-244 -22 -517 -146 -702 -316 l-42 -39 -69 69 -70 70 30 30 c89 88 293 218 442 280 128 54 341 106 441 109 l42 1 0 -99z m221 -261 c168 -19 367 -94 510 -191 303 -205 485 -566 466 -924 -14 -274 -125 -514 -327 -709 -337 -325 -825 -408 -1260 -214 -83 37 -211 120 -208 134 2 6 42 48 90 93 l87 82 67 -40 c179 -108 415 -146 630 -102 442 91 735 501 670 937 -51 339 -285 597 -632 696 -66 19 -102 22 -224 22 -128 -1 -156 -4 -234 -28 -127 -38 -252 -106 -332 -179 l-67 -62 -78 85 c-44 47 -79 88 -79 92 0 20 178 145 275 193 211 105 414 142 646 115z m-1213 -259 l62 -69 -47 -69 c-103 -152 -193 -409 -193 -553 0 -80 0 -80 -121 -80 l-109 0 0 39 c0 56 25 192 55 296 46 161 236 505 278 505 7 0 41 -31 75 -69z m1082 -119 c0 -5 -9 -17 -21 -28 -29 -27 -102 -130 -135 -194 l-29 -55 -3 -235 -3 -234 -76 -100 c-42 -55 -80 -116 -84 -136 -5 -19 -9 -75 -9 -125 -1 -49 -4 -107 -8 -128 l-7 -38 -60 44 c-114 83 -203 200 -253 335 -19 50 -26 93 -30 175 -6 138 8 208 65 327 39 82 58 107 137 185 102 102 201 159 336 194 77 20 180 27 180 13z m189 -8 c215 -53 402 -200 493 -389 194 -406 -56 -866 -522 -961 -154 -31 -362 -4 -487 64 l-32 17 80 105 c44 58 84 106 89 108 5 2 19 -19 31 -47 l21 -51 149 0 148 0 22 60 c12 33 27 60 33 59 6 0 49 -46 96 -101 l85 -101 3 132 3 132 -55 78 c-30 43 -73 100 -95 127 l-41 49 0 203 c0 177 -3 210 -20 259 -21 61 -70 140 -131 214 -22 26 -39 50 -39 53 0 12 105 6 169 -10z m-960 -302 c-42 -83 -79 -212 -79 -273 0 -70 2 -69 -141 -69 l-129 0 0 24 c0 49 31 194 58 276 34 100 60 154 115 234 l39 58 88 -87 87 -86 -38 -77z m810 -37 c32 -16 41 -33 41 -78 0 -87 -112 -106 -139 -24 -14 41 -2 78 31 101 28 20 32 20 67 1z m-1288 -552 c45 -225 125 -398 263 -567 l48 -58 -83 -84 c-46 -47 -91 -83 -98 -82 -30 6 -152 185 -221 323 -72 144 -110 258 -135 404 -20 111 -19 138 3 144 9 3 60 4 112 4 l95 -2 16 -82z m426 -2 c27 -95 75 -191 131 -265 20 -27 41 -55 46 -62 7 -9 -15 -36 -78 -96 -49 -46 -92 -84 -96 -86 -9 -3 -83 83 -129 151 -53 78 -111 210 -137 314 -37 146 -46 134 107 131 l131 -3 25 -84z m1777 -848 l79 -74 -34 -29 c-142 -122 -383 -245 -584 -298 -287 -76 -594 -66 -876 28 -178 59 -378 169 -508 278 l-33 28 95 87 95 88 82 -56 c143 -97 288 -159 461 -196 134 -29 370 -32 497 -6 185 37 375 119 515 222 l72 53 30 -26 c16 -13 66 -58 109 -99z"/>
                    </g>
                </svg>
            </div>

            <h1>АК СИБГУ</h1>
            <p>Административная панель управления</p>
        </div>

        <div class="login-card">
            <div class="alert error" id="alertError">
                <i class="fas fa-exclamation-circle"></i>
                <span id="alertErrorText">Ошибка входа</span>
            </div>

            <form id="loginForm" novalidate>
                <!-- Логин -->
                <div class="form-group">
                    <label for="username">ЛОГИН</label>
                    <div class="input-wrap">
                        <input type="text" id="username" name="username"
                               placeholder="Введите логин"
                               autocomplete="username" required>
                        <i class="fas fa-user icon-left"></i>
                    </div>
                </div>

                <!-- Пароль -->
                <div class="form-group">
                    <label for="password">ПАРОЛЬ</label>
                    <div class="input-wrap">
                        <input type="password" id="password" name="password"
                               placeholder="Введите пароль"
                               autocomplete="current-password"
                               class="has-toggle" required>
                        <i class="fas fa-lock icon-left"></i>
                        <button type="button" class="toggle-pass" id="togglePass" tabindex="-1">
                            <i class="fas fa-eye" id="togglePassIcon"></i>
                        </button>
                    </div>
                </div>

                <button type="submit" class="btn-login" id="btnLogin">
                    <div class="spinner"></div>
                    <span class="btn-text"><i class="fas fa-sign-in-alt"></i> Войти в систему</span>
                </button>
            </form>
        </div>

        <p class="footer-note">© 2026 АКСИБГУУ — Только для авторизованных сотрудников</p>
    </div>

    <script>
        // Показать / скрыть пароль
        document.getElementById('togglePass').addEventListener('click', function () {
            const inp  = document.getElementById('password');
            const icon = document.getElementById('togglePassIcon');
            if (inp.type === 'password') {
                inp.type       = 'text';
                icon.className = 'fas fa-eye-slash';
            } else {
                inp.type       = 'password';
                icon.className = 'fas fa-eye';
            }
        });

        // Показать ошибку
        function showError(msg) {
            const el = document.getElementById('alertError');
            document.getElementById('alertErrorText').textContent = msg;
            el.classList.add('show');
            setTimeout(() => el.classList.remove('show'), 5000);
        }

        // Отправка формы
        document.getElementById('loginForm').addEventListener('submit', async function (e) {
            e.preventDefault();

            const btn      = document.getElementById('btnLogin');
            const username = document.getElementById('username').value.trim();
            const password = document.getElementById('password').value;

            if (!username || !password) {
                showError('Заполните все поля');
                return;
            }

            btn.classList.add('loading');
            btn.disabled = true;
            document.getElementById('alertError').classList.remove('show');

            try {
                const response = await fetch('login.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: JSON.stringify({ username, password })
                });

                const data = await response.json();

                if (data.success) {
                    btn.innerHTML        = '<i class="fas fa-check"></i> Успешно!';
                    btn.style.background = 'linear-gradient(135deg, #22c55e, #16a34a)';
                    setTimeout(() => window.location.href = data.redirect || 'index.php', 600);
                } else {
                    showError(data.message || 'Неверный логин или пароль');
                    btn.classList.remove('loading');
                    btn.disabled = false;
                }
            } catch (err) {
                showError('Ошибка соединения с сервером');
                btn.classList.remove('loading');
                btn.disabled = false;
            }
        });

        // Скрыть ошибку при вводе
        document.querySelectorAll('input').forEach(inp => {
            inp.addEventListener('input', () => {
                document.getElementById('alertError').classList.remove('show');
            });
        });
    </script>
</body>
</html>