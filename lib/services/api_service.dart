import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = "https://app.darkmora.uz/api";
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // --- Anime Catalog ---
  Future<List<Anime>> getAnimes({String? q, String? genre, int? fandubId}) async {
    final response = await _dio.get('/animes', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (genre != null) 'genre': genre,
      if (fandubId != null) 'fandub_id': fandubId,
    });
    return (response.data as List).map((json) => Anime.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getAnimeDetail(String slugOrId) async {
    final response = await _dio.get('/animes/$slugOrId');
    final anime = Anime.fromJson(response.data['anime']);
    final episodes = (response.data['episodes'] as List)
        .map((e) => Episode.fromJson(e))
        .toList();
    final fandubs = (response.data['available_fandubs'] as List)
        .map((f) => Fandub.fromJson(f))
        .toList();
    return {
      'anime': anime,
      'episodes': episodes,
      'fandubs': fandubs,
    };
  }

  // --- Fandubs ---
  Future<List<Fandub>> getFandubs() async {
    final response = await _dio.get('/fandubs');
    return (response.data as List).map((json) => Fandub.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getFandubDetail(String slug) async {
    final response = await _dio.get('/fandubs/$slug');
    return {
      'fandub': Fandub.fromJson(response.data['fandub']),
      'animes': (response.data['animes'] as List).map((a) => Anime.fromJson(a)).toList(),
    };
  }

  // --- Streaming Resolver ---
  Future<Map<String, dynamic>> resolveStream(int releaseId) async {
    final response = await _dio.get('/releases/$releaseId/stream');
    return response.data;
  }

  // --- User & Auth ---
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('username', username);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
      });
      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('username', username);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(int animeId) async {
    final response = await _dio.post('/user/favorites/toggle', data: {
      'anime_id': animeId,
    });
    return response.data['status'] == 'added';
  }

  Future<void> saveHistory(int releaseId, int progressSeconds) async {
    try {
      await _dio.post('/user/history', data: {
        'release_id': releaseId,
        'progress_seconds': progressSeconds,
      });
    } catch (_) {}
  }
}
