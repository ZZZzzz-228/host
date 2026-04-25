import '../api/api_client.dart';
import '../api/api_base_url.dart';

/// Глобальный синглтон ApiClient.
/// Используй ВЕЗДЕ только AppSession.apiClient — не создавай свой ApiClient
/// в экранах, иначе теряются куки и кэш.
class AppSession {
  AppSession._();

  static final ApiClient apiClient = ApiClient(
    baseUrl: resolveApiBaseUrl(),
  );
}
