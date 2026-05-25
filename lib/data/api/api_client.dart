import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kServerBase = 'https://cf990597-wordpress-yndvp.tw1.ru';

/// Превращает относительный путь, который пришёл с бэкенда, в абсолютный URL.
String _fixUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/api/')) return '$_kServerBase$url';
  if (url.startsWith('/')) return '$_kServerBase/api/public$url';
  return '$_kServerBase/api/public/$url';
}

http.Client _buildHttpClient() {
  if (kIsWeb) {
    return http.Client();
  }
  final ioc = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 5)
    ..autoUncompress = true
    ..userAgent = 'AKSIBGU/1.0 (Dart)';
  return io_client.IOClient(ioc);
}

class ApiClient {
  ApiClient({required this.baseUrl}) : _http = _buildHttpClient();

  final String baseUrl;
  final http.Client _http;
  String? _token;
  String? _challengeCookie;
  bool _challengeLoaded = false;
  bool _tokenLoaded = false;

  static const _challengeCookieKey = 'aksibgu_challenge_cookie_v1';
  static const _tokenKey = 'aksibgu_bearer_token_v1';
  final Duration _timeout = const Duration(seconds: 12);
  static const int _maxRetries = 2;

  String? get token => _token;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// Для /student/* дублируем токен в query — на Timeweb часто не доходит Authorization.
  Uri _uriForRequest(String path) {
    final uri = _u(path);
    if (!path.startsWith('/student')) return uri;
    final t = _token;
    if (t == null || t.isEmpty) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'access_token': t},
    );
  }

  Future<void> _ensureTokenLoaded() async {
    if (_tokenLoaded) return;
    _tokenLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_tokenKey);
      if (saved != null && saved.isNotEmpty) {
        _token = saved;
      }
    } catch (_) {}
  }

  Future<void> _persistToken(String? value) async {
    _token = (value != null && value.isNotEmpty) ? value : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, _token!);
      }
    } catch (_) {}
  }

  Future<void> _ensureChallengeLoaded() async {
    if (_challengeLoaded) return;
    _challengeLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_challengeCookieKey);
      if (saved != null && saved.isNotEmpty) {
        _challengeCookie = saved;
      }
    } catch (_) {}
  }

  Future<void> _persistChallengeCookie(String value) async {
    _challengeCookie = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_challengeCookieKey, value);
    } catch (_) {}
  }

  Map<String, String> _defaultHeaders([Map<String, String>? headers]) {
    return <String, String>{
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'Connection': 'close',
      'Referer': '$baseUrl/',
      'User-Agent':
      'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36',
      'X-Requested-With': 'XMLHttpRequest',
      if (_challengeCookie != null && _challengeCookie!.isNotEmpty)
        'Cookie': '__test=$_challengeCookie',
      if (_token != null && _token!.isNotEmpty) ...{
        'Authorization': 'Bearer $_token',
        'X-Auth-Token': _token!,
      },
      ...?headers,
    };
  }

  Future<http.Response> _executeRequest(
      Future<http.Response> Function(http.Client client, Map<String, String> headers) requestBuilder,
      ) async {
    await _ensureTokenLoaded();
    await _ensureChallengeLoaded();

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        var response =
        await requestBuilder(_http, _defaultHeaders()).timeout(_timeout);

        final solvedCookie = _solveChallengeCookie(response);
        if (solvedCookie != null) {
          await _persistChallengeCookie(solvedCookie);
          response = await requestBuilder(_http, _defaultHeaders()).timeout(_timeout);

          if (_solveChallengeCookie(response) != null) {
            lastError = ApiException('Challenge re-issued');
            debugPrint('[ApiClient] challenge re-issued, retry');
            continue;
          }
        }

        final ct = (response.headers['content-type'] ?? '').toLowerCase();
        if (response.statusCode == 200 && ct.contains('text/html')) {
          debugPrint('[ApiClient] HTML response on attempt ${attempt + 1}, retry');
          lastError = ApiException('Server returned HTML instead of JSON');
          await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          continue;
        }

        return response;
      } on TimeoutException {
        lastError = ApiException('API timeout ($_timeout) at $baseUrl');
        debugPrint('[ApiClient] timeout #${attempt + 1} on $baseUrl');
      } on HandshakeException {
        lastError = ApiException(
          'SSL error while connecting to $baseUrl. Check the HTTPS certificate.',
        );
        debugPrint('[ApiClient] SSL handshake error');
      } on SocketException catch (e) {
        lastError = ApiException('Cannot connect to $baseUrl: ${e.message}');
        debugPrint('[ApiClient] socket error: ${e.message}');
      } on http.ClientException catch (e) {
        lastError =
            ApiException('Network client error at $baseUrl: ${e.message}');
        debugPrint('[ApiClient] http client error: ${e.message}');
      } catch (e) {
        lastError = ApiException('Unexpected error: $e');
        debugPrint('[ApiClient] unexpected: $e');
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }

    if (lastError is ApiException) throw lastError;
    throw ApiException('Network error');
  }

  Future<http.Response> _get(String path, {Map<String, String>? headers}) {
    return _executeRequest(
          (client, effectiveHeaders) => client.get(
        _uriForRequest(path),
        headers: {...effectiveHeaders, ...?headers},
      ),
    );
  }

  Future<http.Response> _post(
      String path, {
        Map<String, String>? headers,
        Object? body,
      }) {
    return _executeRequest(
          (client, effectiveHeaders) => client.post(
        _uriForRequest(path),
        headers: {...effectiveHeaders, ...?headers},
        body: body,
      ),
    );
  }

  Future<http.Response> _put(
      String path, {
        Map<String, String>? headers,
        Object? body,
      }) {
    return _executeRequest(
          (client, effectiveHeaders) => client.put(
        _uriForRequest(path),
        headers: {...effectiveHeaders, ...?headers},
        body: body,
      ),
    );
  }

  Future<http.Response> _delete(String path, {Map<String, String>? headers}) {
    return _executeRequest(
          (client, effectiveHeaders) => client.delete(
        _uriForRequest(path),
        headers: {...effectiveHeaders, ...?headers},
      ),
    );
  }

  String? _solveChallengeCookie(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final body = response.body;
    if (!contentType.contains('text/html') &&
        !body.contains('document.cookie="__test=')) {
      return null;
    }

    final match = RegExp(
      r'var a=toNumbers\("([0-9a-fA-F]+)"\),b=toNumbers\("([0-9a-fA-F]+)"\),c=toNumbers\("([0-9a-fA-F]+)"\)',
    ).firstMatch(body);
    if (match == null) return null;

    try {
      return _decryptAesChallenge(
        keyHex: match.group(1)!,
        ivHex: match.group(2)!,
        cipherHex: match.group(3)!,
      );
    } catch (_) {
      return null;
    }
  }

  String _decryptAesChallenge({
    required String keyHex,
    required String ivHex,
    required String cipherHex,
  }) {
    final key = Uint8List.fromList(_hexToBytes(keyHex));
    final iv = Uint8List.fromList(_hexToBytes(ivHex));
    final cipherBytes = Uint8List.fromList(_hexToBytes(cipherHex));
    final output = Uint8List(cipherBytes.length);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV<KeyParameter>(KeyParameter(key), iv));

    for (var offset = 0;
    offset < cipherBytes.length;
    offset += cipher.blockSize) {
      cipher.processBlock(cipherBytes, offset, output, offset);
    }

    return _bytesToHex(output);
  }

  List<int> _hexToBytes(String hex) {
    final normalized = hex.trim();
    return List<int>.generate(
      normalized.length ~/ 2,
          (index) => int.parse(
        normalized.substring(index * 2, index * 2 + 2),
        radix: 16,
      ),
      growable: false,
    );
  }

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final value in bytes) {
      buffer.write(value.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Future<void> warmup() async {
    try {
      await _get('/health');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/login',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final json = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _persistToken(json['token']?.toString());
      return json;
    }
    throw ApiException(_apiErrorMessage(json, 'Ошибка входа'));
  }

  Future<void> logout() async {
    await _persistToken(null);
  }

  Future<List<ContactItem>> fetchContacts({String? category}) async {
    try {
      final uri = _u('/contacts').replace(
        queryParameters: (category != null && category.trim().isNotEmpty)
            ? {'category': category.trim()}
            : null,
      );
      final response = await _executeRequest(
            (client, headers) => client.get(uri, headers: headers),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load contacts');
      }
      final data = json['data'];
      if (data is! List) throw ApiException('Invalid contacts response');
      return data
          .whereType<Map<String, dynamic>>()
          .map(ContactItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchContacts failed: $e');
      return _fallbackContacts();
    }
  }

  Future<List<ContactItem>> fetchCareerCenterContacts() =>
      fetchContacts(category: 'career_center');

  Future<List<VacancyItem>> fetchVacancies({String? query}) async {
    try {
      final uri = _u('/vacancies').replace(
        queryParameters: (query != null && query.trim().isNotEmpty)
            ? {'q': query.trim()}
            : null,
      );

      final response = await _executeRequest(
            (client, headers) => client.get(uri, headers: headers),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load vacancies');
      }
      final data = json['data'];
      if (data is! List) throw ApiException('Invalid vacancies response');
      return data
          .whereType<Map<String, dynamic>>()
          .map(VacancyItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchVacancies failed: $e');
      return _fallbackVacancies(query);
    }
  }

  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await _get('/news');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load news');
      }
      final data = json['data'];
      if (data is! List) throw ApiException('Invalid news response');
      return data
          .whereType<Map<String, dynamic>>()
          .map(NewsItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchNews failed: $e');
      return _fallbackNews();
    }
  }

  Future<List<StaffMemberItem>> fetchStaff({String? department}) async {
    try {
      final uri = _u('/staff').replace(
        queryParameters: (department != null && department.trim().isNotEmpty)
            ? {'department': department.trim()}
            : null,
      );
      final response = await _executeRequest(
            (client, headers) => client.get(uri, headers: headers),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load staff');
      }
      final data = json['data'];
      if (data is! List) throw ApiException('Invalid staff response');
      return data
          .whereType<Map<String, dynamic>>()
          .map(StaffMemberItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchStaff failed: $e');
      return _fallbackStaff();
    }
  }

  Future<List<StaffMemberItem>> fetchCareerCenterStaff() =>
      fetchStaff(department: 'career_center');

  Future<List<StoryItem>> fetchStories() async {
    try {
      final response = await _get('/stories');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load stories');
      }
      final data = json['data'];
      if (data is! List) throw ApiException('Invalid stories response');
      return data
          .whereType<Map<String, dynamic>>()
          .map(StoryItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchStories failed: $e');
      return _fallbackStories();
    }
  }

  Future<PageContentItem?> fetchPageBySlug(String slug) async {
    try {
      final response = await _get('/pages/$slug');
      final json = _decodeJson(response.body);
      if (response.statusCode == 404) return _fallbackPageBySlug(slug);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load page');
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) return _fallbackPageBySlug(slug);
      return PageContentItem.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchPageBySlug failed: $e');
      return _fallbackPageBySlug(slug);
    }
  }

  Future<List<SpecialtyItem>> fetchSpecialties() async {
    try {
      final response = await _get('/specialties');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load specialties');
      }
      final data = json['data'];
      if (data is! List) return _fallbackSpecialties();
      return data
          .whereType<Map<String, dynamic>>()
          .map(SpecialtyItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchSpecialties failed: $e');
      return _fallbackSpecialties();
    }
  }

  Future<List<EducationProgramItem>> fetchEducationPrograms() async {
    try {
      final response = await _get('/education-programs');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(json['message']?.toString() ??
            'Failed to load education programs');
      }
      final data = json['data'];
      if (data is! List) return _fallbackEducationPrograms();
      return data
          .whereType<Map<String, dynamic>>()
          .map(EducationProgramItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchEducationPrograms failed: $e');
      return _fallbackEducationPrograms();
    }
  }

  Future<List<PartnerItem>> fetchPartners() async {
    try {
      final response = await _get('/partners');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load partners');
      }
      final data = json['data'];
      if (data is! List) return _fallbackPartners();
      return data
          .whereType<Map<String, dynamic>>()
          .map(PartnerItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchPartners failed: $e');
      return _fallbackPartners();
    }
  }

  Future<List<EventItem>> fetchEvents() async {
    try {
      final response = await _get('/events');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load events');
      }
      final data = json['data'];
      if (data is! List) return _fallbackEvents();
      return data
          .whereType<Map<String, dynamic>>()
          .map(EventItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchEvents failed: $e');
      try {
        final stories = await fetchStories();
        return stories
            .map((story) => EventItem(
          id: story.id,
          title: story.title,
          description: story.content,
          category: 'meetup',
          coverUrl: story.imageUrl,
          externalUrl: '',
          startsAt: null,
          endsAt: null,
          location: '',
        ))
            .toList(growable: false);
      } catch (_) {
        return _fallbackEvents();
      }
    }
  }

  Future<CareerTestPayload> fetchCareerTest() async {
    try {
      final response = await _get('/career-test');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load career test');
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) return _fallbackCareerTest();
      final raw = data['questions'];
      if (raw is! List) return _fallbackCareerTest();
      final questions = raw
          .whereType<Map<String, dynamic>>()
          .map(CareerTestQuestion.fromJson)
          .toList(growable: false);
      return CareerTestPayload(questions: questions);
    } catch (e) {
      debugPrint('[ApiClient] fetchCareerTest failed: $e');
      return _fallbackCareerTest();
    }
  }

  // ─── UNIVERSITIES ────────────────────────────────────────────────────────────

  Future<List<UniversityItem>> fetchUniversities() async {
    try {
      final response = await _get('/universities');
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to load universities');
      }
      final data = json['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(UniversityItem.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchUniversities failed: $e');
      return const [];
    }
  }

  // ─── STUDENT PROFILE ─────────────────────────────────────────────────────────

  Future<StudentProfileItem?> fetchStudentProfile() async {
    final response =
    await _get('/student/profile', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response, json, 'Не удалось загрузить профиль');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) return null;
    return StudentProfileItem.fromJson(data);
  }

  // ─── SPECIALTIES FOR RESUME ──────────────────────────────────────────────────

  Future<List<SpecialtyWithQuestions>> fetchSpecialtiesForResume() async {
    try {
      final response =
      await _get('/student/specialties', headers: _authHeaders());
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(json['message']?.toString() ?? 'Failed');
      }
      final data = json['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(SpecialtyWithQuestions.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ApiClient] fetchSpecialtiesForResume failed: $e');
      return const [];
    }
  }

  // ─── RESUMES ─────────────────────────────────────────────────────────────────

  Future<List<StudentResumeItem>> fetchStudentResumes() async {
    final response =
    await _get('/student/resumes', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response, json, 'Не удалось загрузить резюме');
    }
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentResumeItem.fromJson)
        .toList(growable: false);
  }

  Future<StudentResumeFullItem?> fetchStudentResumeById(int id) async {
    try {
      final response =
      await _get('/student/resumes/$id', headers: _authHeaders());
      final json = _decodeJson(response.body);
      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(json['message']?.toString() ?? 'Failed');
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) return null;
      return StudentResumeFullItem.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchStudentResumeById failed: $e');
      return null;
    }
  }

  Future<int> createStudentResumeFull(Map<String, dynamic> resumeData) async {
    final response = await _post(
      '/student/resumes',
      headers: _authHeaders(contentTypeJson: true),
      body: jsonEncode(resumeData),
    );
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response, json, 'Не удалось сохранить резюме');
    }
    return (json['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> updateStudentResumeFull(
      int id, Map<String, dynamic> resumeData) async {
    final response = await _put(
      '/student/resumes/$id',
      headers: _authHeaders(contentTypeJson: true),
      body: jsonEncode(resumeData),
    );
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to update resume');
    }
  }

  /// Совместимость со старым кодом
  Future<void> createStudentResume({
    required String title,
    String? summary,
  }) async {
    await createStudentResumeFull({
      'desired_position': title,
      'about': summary ?? '',
    });
  }

  Future<void> deleteStudentResume(int id) async {
    final response =
    await _delete('/student/resumes/$id', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to delete resume');
    }
  }

  // ─── PORTFOLIO ───────────────────────────────────────────────────────────────

  Future<List<StudentPortfolioItem>> fetchStudentPortfolio() async {
    final response =
    await _get('/student/portfolio', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response, json, 'Не удалось загрузить портфолио');
    }
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentPortfolioItem.fromJson)
        .toList(growable: false);
  }

  Future<int> createStudentPortfolioItem({
    required String title,
    String? description,
    String? projectUrl,
    String? imageUrl,
    String? category,
    List<String>? tags,
  }) async {
    final response = await _post(
      '/student/portfolio',
      headers: _authHeaders(contentTypeJson: true),
      body: jsonEncode({
        'title': title,
        'description': description ?? '',
        'project_url': projectUrl ?? '',
        'image_url': imageUrl ?? '',
        'category': category ?? '',
        'tags': tags ?? [],
      }),
    );
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response, json, 'Не удалось сохранить проект');
    }
    return (json['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> updateStudentPortfolioItem(
      int id, {
        required String title,
        String? description,
        String? projectUrl,
        String? imageUrl,
        String? category,
        List<String>? tags,
      }) async {
    final response = await _put(
      '/student/portfolio/$id',
      headers: _authHeaders(contentTypeJson: true),
      body: jsonEncode({
        'title': title,
        'description': description ?? '',
        'project_url': projectUrl ?? '',
        'image_url': imageUrl ?? '',
        'category': category ?? '',
        'tags': tags ?? [],
      }),
    );
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to update portfolio item');
    }
  }

  Future<void> deleteStudentPortfolioItem(int id) async {
    final response =
    await _delete('/student/portfolio/$id', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to delete portfolio item');
    }
  }

  // ─── APPLICATIONS ─────────────────────────────────────────────────────────────

  Future<int> submitPublicApplication({
    required String type,
    required String fullName,
    String? email,
    String? phone,
    required Map<String, dynamic> payload,
    List<PlatformFile> files = const [],
  }) async {
    if (files.isEmpty) {
      final response = await _post(
        '/applications',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'payload': payload,
        }),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            json['message']?.toString() ?? 'Failed to submit application');
      }
      return (json['id'] as num?)?.toInt() ?? 0;
    }

    Future<http.Response> sendMultipart(http.Client client, Map<String, String> headers) async {
      final request =
      http.MultipartRequest('POST', _u('/applications'));
      request.headers.addAll(headers);
      request.fields['type'] = type;
      request.fields['full_name'] = fullName;
      if (email != null && email.isNotEmpty) request.fields['email'] = email;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      request.fields['payload_json'] = jsonEncode(payload);

      for (final f in files) {
        final p = f.path;
        if (p != null && p.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath('files[]', p, filename: f.name),
          );
        }
      }

      final streamed = await client.send(request);
      return http.Response.fromStream(streamed);
    }

    final response = await _executeRequest(sendMultipart);
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to submit application');
    }
    return (json['id'] as num?)?.toInt() ?? 0;
  }

  Map<String, String> _authHeaders({bool contentTypeJson = false}) {
    final headers = <String, String>{};
    if (contentTypeJson) headers['Content-Type'] = 'application/json';
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
      headers['X-Auth-Token'] = _token!;
    }
    return headers;
  }

  String _apiErrorMessage(Map<String, dynamic> json, String fallback) {
    final message = json['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
    final error = json['error']?.toString();
    if (error != null && error.isNotEmpty) return error;
    return fallback;
  }

  Never _throwApiError(http.Response response, Map<String, dynamic> json, String fallback) {
    if (response.statusCode == 401) {
      throw ApiException(
        'Сессия не принята сервером. Выйдите из кабинета и войдите снова.',
      );
    }
    throw ApiException(_apiErrorMessage(json, fallback));
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Invalid API response shape');
    } on FormatException {
      final preview =
      body.length > 200 ? '${body.substring(0, 200)}...' : body;
      throw ApiException('API returned non-JSON response: $preview');
    }
  }

  List<ContactItem> _fallbackContacts() => const [];
  List<VacancyItem> _fallbackVacancies(String? query) => const [];
  List<NewsItem> _fallbackNews() => const [];
  List<StaffMemberItem> _fallbackStaff() => const [];
  List<StoryItem> _fallbackStories() => const [];
  PageContentItem? _fallbackPageBySlug(String slug) => null;
  List<SpecialtyItem> _fallbackSpecialties() => const [];
  List<EducationProgramItem> _fallbackEducationPrograms() => const [];
  List<PartnerItem> _fallbackPartners() => const [];
  List<EventItem> _fallbackEvents() => const [];
  CareerTestPayload _fallbackCareerTest() =>
      const CareerTestPayload(questions: []);
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ContactItem {
  ContactItem({
    required this.id,
    required this.type,
    required this.value,
    required this.label,
  });

  final int id;
  final String type;
  final String value;
  final String? label;

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      label: json['label']?.toString(),
    );
  }
}

class VacancyItem {
  VacancyItem({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.employmentType,
    required this.salary,
    required this.description,
    required this.publishedAt,
  });

  final int id;
  final String title;
  final String company;
  final String city;
  final String employmentType;
  final String salary;
  final String description;
  final DateTime? publishedAt;

  factory VacancyItem.fromJson(Map<String, dynamic> json) {
    DateTime? published;
    final publishedRaw = json['published_at']?.toString();
    if (publishedRaw != null && publishedRaw.isNotEmpty) {
      published = DateTime.tryParse(publishedRaw);
    }
    return VacancyItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      employmentType: (json['employment_type'] ?? '').toString(),
      salary: (json['salary'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      publishedAt: published,
    );
  }
}

class NewsItem {
  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
  });

  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final DateTime? publishedAt;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    DateTime? published;
    final publishedRaw = json['published_at']?.toString();
    if (publishedRaw != null && publishedRaw.isNotEmpty) {
      published = DateTime.tryParse(publishedRaw);
    }
    return NewsItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: _fixUrl((json['image_url'] ?? '').toString()),
      publishedAt: published,
    );
  }
}

class StaffMemberItem {
  StaffMemberItem({
    required this.id,
    required this.fullName,
    required this.positionTitle,
    required this.email,
    required this.phone,
    required this.officeHours,
    required this.photoUrl,
    required this.colorHex,
  });

  final int id;
  final String fullName;
  final String positionTitle;
  final String email;
  final String phone;
  final String officeHours;
  final String photoUrl;
  final String colorHex;

  factory StaffMemberItem.fromJson(Map<String, dynamic> json) {
    return StaffMemberItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      positionTitle: (json['position_title'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      officeHours: (json['office_hours'] ?? '').toString(),
      photoUrl: _fixUrl((json['photo_url'] ?? '').toString()),
      colorHex: (json['color_hex'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'position_title': positionTitle,
    'email': email,
    'phone': phone,
    'office_hours': officeHours,
    'photo_url': photoUrl,
    'color_hex': colorHex,
  };
}

class StoryItem {
  StoryItem({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.imageUrls,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final List<String> imageUrls;
  final int sortOrder;

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    final raw = json['images_json'];
    final parsed = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.isNotEmpty) {
          parsed.add(_fixUrl(item));
        }
      }
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is String && item.isNotEmpty) {
              parsed.add(_fixUrl(item));
            }
          }
        }
      } catch (_) {}
    }

    final cover = _fixUrl((json['image_url'] ?? '').toString());
    final urls = parsed.isNotEmpty
        ? parsed
        : (cover.isNotEmpty ? [cover] : const <String>[]);

    return StoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: cover.isNotEmpty ? cover : (urls.isNotEmpty ? urls.first : ''),
      imageUrls: urls,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'image_url': imageUrl,
    'images_json': imageUrls,
    'sort_order': sortOrder,
  };
}

class PageStatCms {
  const PageStatCms({
    required this.iconName,
    required this.value,
    required this.label,
    required this.colorHex,
  });
  final String iconName;
  final String value;
  final String label;
  final String colorHex;
}

class PageCmsCard {
  const PageCmsCard({
    required this.iconName,
    required this.title,
    required this.text,
    required this.colorHex,
  });
  final String iconName;
  final String title;
  final String text;
  final String colorHex;
}

class PageContentItem {
  PageContentItem({
    required this.slug,
    required this.title,
    required this.audience,
    required this.lead,
    required this.body,
    required this.coverImageUrl,
    this.missionTitle = '',
    this.aboutTitle = '',
    this.statsHeading = '',
    this.advantagesHeading = '',
    this.achievementsHeading = '',
    this.infrastructureHeading = '',
    this.infrastructureText = '',
    this.stats = const [],
    this.advantages = const [],
    this.achievements = const [],
  });

  final String slug;
  final String title;
  final String audience;
  final String lead;
  final String body;
  final String coverImageUrl;
  final String missionTitle;
  final String aboutTitle;
  final String statsHeading;
  final String advantagesHeading;
  final String achievementsHeading;
  final String infrastructureHeading;
  final String infrastructureText;
  final List<PageStatCms> stats;
  final List<PageCmsCard> advantages;
  final List<PageCmsCard> achievements;

  static Map<String, dynamic> _parseContentMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return {};
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {};
  }

  static List<PageStatCms> _parseStats(dynamic raw) {
    if (raw is! List) return const [];
    final out = <PageStatCms>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        out.add(PageStatCms(
          iconName: (m['icon'] ?? '').toString(),
          value: (m['value'] ?? '').toString(),
          label: (m['label'] ?? '').toString(),
          colorHex: (m['color'] ?? '').toString(),
        ));
      }
    }
    return out;
  }

  static List<PageCmsCard> _parseCmsCards(dynamic raw) {
    if (raw is! List) return const [];
    final out = <PageCmsCard>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        out.add(PageCmsCard(
          iconName: (m['icon'] ?? '').toString(),
          title: (m['title'] ?? '').toString(),
          text: (m['text'] ?? '').toString(),
          colorHex: (m['color'] ?? '').toString(),
        ));
      }
    }
    return out;
  }

  factory PageContentItem.fromJson(Map<String, dynamic> json) {
    final contentMap = _parseContentMap(json['content_json']);
    return PageContentItem(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      audience: (json['audience'] ?? '').toString(),
      lead: (contentMap['lead'] ?? '').toString(),
      body: (contentMap['body'] ?? '').toString(),
      coverImageUrl: _fixUrl((json['cover_image_url'] ?? '').toString()),
      missionTitle: (contentMap['mission_title'] ?? '').toString(),
      aboutTitle: (contentMap['about_title'] ?? '').toString(),
      statsHeading: (contentMap['stats_heading'] ?? '').toString(),
      advantagesHeading: (contentMap['advantages_heading'] ?? '').toString(),
      achievementsHeading: (contentMap['achievements_heading'] ?? '').toString(),
      infrastructureHeading: (contentMap['infrastructure_heading'] ?? '').toString(),
      infrastructureText: (contentMap['infrastructure_text'] ?? '').toString(),
      stats: _parseStats(contentMap['stats']),
      advantages: _parseCmsCards(contentMap['advantages']),
      achievements: _parseCmsCards(contentMap['achievements']),
    );
  }
}

class SpecialtyItem {
  SpecialtyItem({
    required this.id,
    required this.code,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.durationLabel,
    required this.studyFormLabel,
    required this.qualificationText,
    required this.careerText,
    required this.skillsText,
    required this.salaryText,
    required this.colorHex,
    required this.iconName,
    required this.imageUrl,
    this.gosuslugiUrl = '',
  });
  final int id;
  final String code;
  final String title;
  final String shortTitle;
  final String description;
  final String durationLabel;
  final String studyFormLabel;
  final String qualificationText;
  final String careerText;
  final String skillsText;
  final String salaryText;
  final String colorHex;
  final String iconName;
  final String imageUrl;
  final String gosuslugiUrl;

  factory SpecialtyItem.fromJson(Map<String, dynamic> json) {
    return SpecialtyItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      shortTitle: (json['short_title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      durationLabel: (json['duration_label'] ?? '').toString(),
      studyFormLabel: (json['study_form_label'] ?? '').toString(),
      qualificationText: (json['qualification_text'] ?? '').toString(),
      careerText: (json['career_text'] ?? '').toString(),
      skillsText: (json['skills_text'] ?? '').toString(),
      salaryText: (json['salary_text'] ?? '').toString(),
      colorHex: (json['color_hex'] ?? '').toString(),
      iconName: (json['icon_name'] ?? '').toString(),
      imageUrl: _fixUrl((json['image_url'] ?? '').toString()),
      gosuslugiUrl: (json['gosuslugi_url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'short_title': shortTitle,
    'description': description,
    'duration_label': durationLabel,
    'study_form_label': studyFormLabel,
    'qualification_text': qualificationText,
    'career_text': careerText,
    'skills_text': skillsText,
    'salary_text': salaryText,
    'color_hex': colorHex,
    'icon_name': iconName,
    'image_url': imageUrl,
    'gosuslugi_url': gosuslugiUrl,
  };
}

class SpecialtyWithQuestions {
  SpecialtyWithQuestions({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.code,
    required this.questions,
  });
  final int id;
  final String title;
  final String shortTitle;
  final String code;
  final List<ResumeQuestion> questions;

  factory SpecialtyWithQuestions.fromJson(Map<String, dynamic> json) {
    List<ResumeQuestion> qs = [];
    final rawQ = json['resume_questions'];
    if (rawQ is List) {
      qs = rawQ
          .whereType<Map<String, dynamic>>()
          .map(ResumeQuestion.fromJson)
          .toList();
    }
    return SpecialtyWithQuestions(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      shortTitle: (json['short_title'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      questions: qs,
    );
  }
}

class ResumeQuestion {
  ResumeQuestion({
    required this.id,
    required this.question,
    required this.fieldType,
    required this.fieldOptions,
    required this.isRequired,
  });
  final int id;
  final String question;
  final String fieldType; // text, textarea, select, multiselect, number, date
  final List<String> fieldOptions;
  final bool isRequired;

  factory ResumeQuestion.fromJson(Map<String, dynamic> json) {
    List<String> opts = [];
    final rawOpts = json['field_options'];
    if (rawOpts is List) {
      opts = rawOpts.map((e) => e.toString()).toList();
    }
    return ResumeQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: (json['question'] ?? '').toString(),
      fieldType: (json['field_type'] ?? 'text').toString(),
      fieldOptions: opts,
      isRequired: (json['is_required'] as num?)?.toInt() == 1,
    );
  }
}

class EducationProgramItem {
  EducationProgramItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.details,
    required this.targetAudience,
    required this.outcomeText,
    required this.formatText,
    required this.iconName,
    required this.colorHex,
    required this.imageUrl,
  });

  final int id;
  final String type;
  final String title;
  final String description;
  final String durationLabel;
  final String details;
  final String targetAudience;
  final String outcomeText;
  final String formatText;
  final String iconName;
  final String colorHex;
  final String imageUrl;

  factory EducationProgramItem.fromJson(Map<String, dynamic> json) {
    return EducationProgramItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      durationLabel: (json['duration_label'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      targetAudience: (json['target_audience'] ?? '').toString(),
      outcomeText: (json['outcome_text'] ?? '').toString(),
      formatText: (json['format_text'] ?? '').toString(),
      iconName: (json['icon_name'] ?? '').toString(),
      colorHex: (json['color_hex'] ?? '').toString(),
      imageUrl: _fixUrl((json['image_url'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'duration_label': durationLabel,
    'details': details,
    'target_audience': targetAudience,
    'outcome_text': outcomeText,
    'format_text': formatText,
    'icon_name': iconName,
    'color_hex': colorHex,
    'image_url': imageUrl,
  };
}

class PartnerItem {
  PartnerItem({
    required this.id,
    required this.name,
    required this.description,
    required this.websiteUrl,
    required this.logoUrl,
  });

  final int id;
  final String name;
  final String description;
  final String websiteUrl;
  final String logoUrl;

  factory PartnerItem.fromJson(Map<String, dynamic> json) {
    return PartnerItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      websiteUrl: (json['website_url'] ?? '').toString(),
      logoUrl: _fixUrl((json['logo_url'] ?? '').toString()),
    );
  }
}

class EventItem {
  EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.coverUrl,
    required this.externalUrl,
    required this.startsAt,
    required this.endsAt,
    required this.location,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String coverUrl;
  final String externalUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String location;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    DateTime? starts;
    DateTime? ends;
    final s = json['starts_at']?.toString();
    final e = json['ends_at']?.toString();
    if (s != null && s.isNotEmpty) starts = DateTime.tryParse(s);
    if (e != null && e.isNotEmpty) ends = DateTime.tryParse(e);
    return EventItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      coverUrl: _fixUrl((json['cover_url'] ?? '').toString()),
      externalUrl: (json['external_url'] ?? '').toString(),
      startsAt: starts,
      endsAt: ends,
      location: (json['location'] ?? '').toString(),
    );
  }
}

class CareerTestPayload {
  const CareerTestPayload({required this.questions});
  final List<CareerTestQuestion> questions;
}

class CareerTestQuestion {
  CareerTestQuestion({required this.question, required this.answers});
  final String question;
  final List<CareerTestAnswer> answers;

  factory CareerTestQuestion.fromJson(Map<String, dynamic> json) {
    final raw = json['answers'];
    List<CareerTestAnswer> answers = [];
    if (raw is List) {
      answers = raw
          .whereType<Map<String, dynamic>>()
          .map(CareerTestAnswer.fromJson)
          .toList();
    }
    return CareerTestQuestion(
      question: (json['question'] ?? '').toString(),
      answers: answers,
    );
  }
}

class CareerTestAnswer {
  CareerTestAnswer({required this.text, required this.specialtyTitles});
  final String text;
  final List<String> specialtyTitles;

  factory CareerTestAnswer.fromJson(Map<String, dynamic> json) {
    final raw = json['specialty_ids'];
    final titles = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    return CareerTestAnswer(
      text: (json['text'] ?? '').toString(),
      specialtyTitles: titles,
    );
  }
}

class StudentProfileItem {
  StudentProfileItem({
    required this.fullName,
    required this.email,
    required this.groupTitle,
    required this.curatorName,
    required this.bio,
  });
  final String fullName;
  final String email;
  final String groupTitle;
  final String curatorName;
  final String bio;

  factory StudentProfileItem.fromJson(Map<String, dynamic> json) {
    return StudentProfileItem(
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      groupTitle: (json['group_title'] ?? '').toString(),
      curatorName: (json['curator_name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
    );
  }
}

class StudentResumeItem {
  StudentResumeItem({
    required this.id,
    required this.title,
    required this.summary,
    this.desiredPosition = '',
    this.city = '',
    this.desiredSalary,
    this.specialtyTitle = '',
    this.isPublished = false,
    this.createdAt,
  });
  final int id;
  final String title;
  final String summary;
  final String desiredPosition;
  final String city;
  final int? desiredSalary;
  final String specialtyTitle;
  final bool isPublished;
  final DateTime? createdAt;

  factory StudentResumeItem.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final cRaw = json['created_at']?.toString();
    if (cRaw != null && cRaw.isNotEmpty) created = DateTime.tryParse(cRaw);
    final pos = (json['desired_position'] ?? '').toString();
    final ln = (json['last_name'] ?? '').toString();
    final fn = (json['first_name'] ?? '').toString();
    final mn = (json['middle_name'] ?? '').toString();
    final nameParts = [ln, fn, mn].where((s) => s.isNotEmpty).join(' ');
    return StudentResumeItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: pos.isNotEmpty ? pos : (json['title'] ?? 'Резюме').toString(),
      summary: nameParts.isNotEmpty ? nameParts : (json['summary'] ?? '').toString(),
      desiredPosition: pos,
      city: (json['city'] ?? '').toString(),
      desiredSalary: (json['desired_salary'] as num?)?.toInt(),
      specialtyTitle: (json['specialty_title'] ?? '').toString(),
      isPublished: (json['is_published'] as num?)?.toInt() == 1,
      createdAt: created,
    );
  }
}

class StudentResumeFullItem {
  StudentResumeFullItem({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.desiredPosition,
    required this.city,
    required this.phone,
    required this.email,
    required this.telegram,
    required this.vk,
    required this.about,
    required this.gender,
    required this.birthDate,
    required this.desiredSalary,
    required this.employmentType,
    required this.schedule,
    required this.workExperience,
    required this.education,
    required this.skills,
    required this.languages,
    required this.portfolioLinks,
    required this.specialtyAnswers,
    this.specialtyId,
    this.specialtyTitle = '',
    this.isPublished = false,
  });

  final int id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String desiredPosition;
  final String city;
  final String phone;
  final String email;
  final String telegram;
  final String vk;
  final String about;
  final String gender;
  final String? birthDate;
  final int? desiredSalary;
  final List<String> employmentType;
  final List<String> schedule;
  final List<Map<String, dynamic>> workExperience;
  final List<Map<String, dynamic>> education;
  final List<String> skills;
  final List<Map<String, dynamic>> languages;
  final List<String> portfolioLinks;
  final Map<String, dynamic> specialtyAnswers;
  final int? specialtyId;
  final String specialtyTitle;
  final bool isPublished;

  String get fullName {
    return [lastName, firstName, middleName].where((s) => s.isNotEmpty).join(' ');
  }

  factory StudentResumeFullItem.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    List<Map<String, dynamic>> parseMapList(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    }

    Map<String, dynamic> parseMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      return {};
    }

    return StudentResumeFullItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lastName: (json['last_name'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      middleName: (json['middle_name'] ?? '').toString(),
      desiredPosition: (json['desired_position'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      telegram: (json['telegram'] ?? '').toString(),
      vk: (json['vk'] ?? '').toString(),
      about: (json['about'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      birthDate: json['birth_date']?.toString(),
      desiredSalary: (json['desired_salary'] as num?)?.toInt(),
      employmentType: parseStringList(json['employment_type']),
      schedule: parseStringList(json['schedule']),
      workExperience: parseMapList(json['work_experience']),
      education: parseMapList(json['education']),
      skills: parseStringList(json['skills']),
      languages: parseMapList(json['languages']),
      portfolioLinks: parseStringList(json['portfolio_links']),
      specialtyAnswers: parseMap(json['specialty_answers']),
      specialtyId: (json['specialty_id'] as num?)?.toInt(),
      specialtyTitle: (json['specialty_title'] ?? '').toString(),
      isPublished: (json['is_published'] as num?)?.toInt() == 1,
    );
  }
}

class StudentPortfolioItem {
  StudentPortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.projectUrl,
    this.imageUrl = '',
    this.category = '',
    this.tagsList = const [],
    this.isPublished = true,
    this.createdAt,
  });
  final int id;
  final String title;
  final String description;
  final String projectUrl;
  final String imageUrl;
  final String category;
  final List<String> tagsList;
  final bool isPublished;
  final DateTime? createdAt;

  factory StudentPortfolioItem.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    final rawTags = json['tags_list'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }
    DateTime? created;
    final cRaw = json['created_at']?.toString();
    if (cRaw != null && cRaw.isNotEmpty) created = DateTime.tryParse(cRaw);
    return StudentPortfolioItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      projectUrl: (json['project_url'] ?? '').toString(),
      imageUrl: _fixUrl((json['image_url'] ?? '').toString()),
      category: (json['category'] ?? '').toString(),
      tagsList: tags,
      isPublished: (json['is_published'] as num?)?.toInt() != 0,
      createdAt: created,
    );
  }
}

class UniversityItem {
  UniversityItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.fullText,
    required this.url,
    required this.admissionUrl,
    required this.vkUrl,
    required this.telegramUrl,
    required this.logoUrl,
    required this.coverUrl,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.tagsList,
  });

  final int id;
  final String name;
  final String shortName;
  final String description;
  final String fullText;
  final String url;
  final String admissionUrl;
  final String vkUrl;
  final String telegramUrl;
  final String logoUrl;
  final String coverUrl;
  final String city;
  final String address;
  final String phone;
  final String email;
  final List<String> tagsList;

  factory UniversityItem.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    final rawTags = json['tags_list'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }
    return UniversityItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      shortName: (json['short_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fullText: (json['full_text'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      admissionUrl: (json['admission_url'] ?? '').toString(),
      vkUrl: (json['vk_url'] ?? '').toString(),
      telegramUrl: (json['telegram_url'] ?? '').toString(),
      logoUrl: _fixUrl((json['logo_url'] ?? '').toString()),
      coverUrl: _fixUrl((json['cover_url'] ?? '').toString()),
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      tagsList: tags,
    );
  }
}
