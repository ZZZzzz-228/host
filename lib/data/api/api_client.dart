import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kServerBase = 'http://kucersta.beget.tech';

String _fixUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('/')) return '$_kServerBase$url';
  return url;
}

/// Собираем реальный http.Client.
/// На mobile используем свой dart:io HttpClient с короткими таймаутами
/// и принудительным IPv4 — это избавляет от зависаний IPv6 dual-stack DNS
/// и от багов keep-alive Beget.
http.Client _buildHttpClient() {
  if (kIsWeb) {
    return http.Client();
  }
  final ioc = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 5)
    ..autoUncompress = true
    ..userAgent = 'AKSIBGU/1.0 (Dart)';
  // Принудительно берём только IPv4 — избегаем IPv6 dual-stack зависаний
  // на мобильных сетях.
  ioc.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
    return Socket.startConnect(
      url.host,
      url.hasPort ? url.port : (url.scheme == 'https' ? 443 : 80),
      sourceAddress: InternetAddress.anyIPv4,
    );
  };
  return io_client.IOClient(ioc);
}

class ApiClient {
  ApiClient({required this.baseUrl}) : _http = _buildHttpClient();

  final String baseUrl;
  final http.Client _http;
  String? _token;
  String? _challengeCookie;
  bool _challengeLoaded = false;

  static const _challengeCookieKey = 'aksibgu_challenge_cookie_v1';
  final Duration _timeout = const Duration(seconds: 12);
  static const int _maxRetries = 2;

  String? get token => _token;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

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
      // Connection: close — лечит зависания keep-alive с Beget
      'Connection': 'close',
      'Referer': '$baseUrl/',
      'User-Agent':
      'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36',
      'X-Requested-With': 'XMLHttpRequest',
      if (_challengeCookie != null && _challengeCookie!.isNotEmpty)
        'Cookie': '__test=$_challengeCookie',
      ...?headers,
    };
  }

  Future<http.Response> _executeRequest(
      Future<http.Response> Function(http.Client client, Map<String, String> headers) requestBuilder,
      ) async {
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

        // Если вернулся HTML вместо JSON — это bot challenge, который мы не распознали. Ретраим.
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
        _u(path),
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
        _u(path),
        headers: {...effectiveHeaders, ...?headers},
        body: body,
      ),
    );
  }

  Future<http.Response> _delete(String path, {Map<String, String>? headers}) {
    return _executeRequest(
          (client, effectiveHeaders) => client.delete(
        _u(path),
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
      _token = json['token']?.toString();
      return json;
    }
    throw ApiException(json['message']?.toString() ?? 'Login failed');
  }

  Future<List<ContactItem>> fetchContacts() async {
    try {
      final response = await _get('/contacts');
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

  Future<List<VacancyItem>> fetchVacancies({String? query}) async {
    try {
      final uri = _u('/vacancies').replace(
        queryParameters: (query != null && query.trim().isNotEmpty)
            ? {'q': query.trim()}
            : null,
      );

      final response = await _executeRequest(
            (headers) => http.get(uri, headers: headers),
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

  Future<List<StaffMemberItem>> fetchStaff() async {
    try {
      final response = await _get('/staff');
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
      final response = await _get('/public/pages/$slug');
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
      final response = await _get('/public/specialties');
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
      final response = await _get('/public/education-programs');
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
      final response = await _get('/public/partners');
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

  Future<CareerTestPayload> fetchCareerTest() async {
    try {
      final response = await _get('/public/career-test');
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

  Future<StudentProfileItem?> fetchStudentProfile() async {
    final response =
    await _get('/student/profile', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to load student profile');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) return null;
    return StudentProfileItem.fromJson(data);
  }

  Future<List<StudentResumeItem>> fetchStudentResumes() async {
    final response =
    await _get('/student/resumes', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to load resumes');
    }
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentResumeItem.fromJson)
        .toList(growable: false);
  }

  Future<void> createStudentResume({
    required String title,
    String? summary,
  }) async {
    final response = await _post(
      '/student/resumes',
      headers: _authHeaders(contentTypeJson: true),
      body: jsonEncode({'title': title, 'summary': summary}),
    );
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to create resume');
    }
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

  Future<List<StudentPortfolioItem>> fetchStudentPortfolio() async {
    final response =
    await _get('/student/portfolio', headers: _authHeaders());
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to load portfolio');
    }
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentPortfolioItem.fromJson)
        .toList(growable: false);
  }

  Future<void> createStudentPortfolioItem({
    required String title,
    String? description,
    String? projectUrl,
  }) async {
    final response = await _post(
      '/student/portfolio',
      headers: _authHeaders(contentTypeJson: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'project_url': projectUrl,
      }),
    );
    final json = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          json['message']?.toString() ?? 'Failed to create portfolio item');
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
        '/public/applications',
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
      http.MultipartRequest('POST', _u('/public/applications'));
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
    }
    return headers;
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
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final int sortOrder;

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: _fixUrl((json['image_url'] ?? '').toString()),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'image_url': imageUrl,
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
        final m = Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
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
        final m = Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
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
      achievementsHeading:
      (contentMap['achievements_heading'] ?? '').toString(),
      infrastructureHeading:
      (contentMap['infrastructure_heading'] ?? '').toString(),
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
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'website_url': websiteUrl,
    'logo_url': logoUrl,
  };
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
    final rawAnswers = json['answers'];
    final answers = rawAnswers is List
        ? rawAnswers
        .whereType<Map<String, dynamic>>()
        .map(CareerTestAnswer.fromJson)
        .toList(growable: false)
        : <CareerTestAnswer>[];
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
  StudentResumeItem(
      {required this.id, required this.title, required this.summary});
  final int id;
  final String title;
  final String summary;
  factory StudentResumeItem.fromJson(Map<String, dynamic> json) {
    return StudentResumeItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
    );
  }
}

class StudentPortfolioItem {
  StudentPortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.projectUrl,
  });
  final int id;
  final String title;
  final String description;
  final String projectUrl;
  factory StudentPortfolioItem.fromJson(Map<String, dynamic> json) {
    return StudentPortfolioItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      projectUrl: (json['project_url'] ?? '').toString(),
    );
  }
}