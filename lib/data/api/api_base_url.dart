String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  return 'https://cf990597-wordpress-yndvp.tw1.ru/public_api/index.php';
}