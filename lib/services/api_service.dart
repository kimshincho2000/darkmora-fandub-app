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

  // --- Comments ---
  Future<List<Map<String, dynamic>>> getComments(int animeId) async {
    try {
      final response = await _dio.get('/animes/$animeId/comments');
      return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addComment(int animeId, String text, int rating, {int? fandubId}) async {
    try {
      await _dio.post('/animes/$animeId/comments', data: {
        'text': text,
        'rating': rating,
        if (fandubId != null) 'fandub_id': fandubId,
      });
      return true;
    } catch (_) {
      return false;
    }
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

  Future<bool> createFandub(String name, String slug, String description, String? telegramChannel) async {
    try {
      await _dio.post('/fandubs', data: {
        'name': name,
        'slug': slug,
        'description': description,
        'telegram_channel': telegramChannel,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Streaming Resolver ---
  Future<Map<String, dynamic>> resolveStream(int releaseId) async {
    final response = await _dio.get('/releases/$releaseId/stream');
    return response.data;
  }

  // --- User & Auth ---
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      if (response.data['requires_2fa'] == true) {
        return response.data;
      }
      final token = response.data['access_token'];
      final user = response.data['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('username', username);
      await prefs.setString('role', user['role'] ?? 'user');
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<bool> verify2FA(String sessionToken, String code) async {
    try {
      final response = await _dio.post('/auth/verify-2fa', data: {
        'session_token': sessionToken,
        'code': code,
      });
      final token = response.data['access_token'];
      final user = response.data['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('username', user['username']);
      await prefs.setString('role', user['role'] ?? 'user');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> register(String username, String password, {String? email}) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      final token = response.data['access_token'];
      final user = response.data['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('username', username);
      await prefs.setString('role', user['role'] ?? 'user');
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile({
    String? avatarUrl,
    int? preferredFandubId,
    String? defaultQuality,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      await _dio.patch('/auth/profile', data: {
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (preferredFandubId != null) 'preferred_fandub_id': preferredFandubId,
        if (defaultQuality != null) 'default_quality': defaultQuality,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(int animeId) async {
    final response = await _dio.post('/user/favorites/toggle', data: {
      'anime_id': animeId,
    });
    return response.data['status'] == 'added';
  }

  Future<List<Anime>> getFavorites() async {
    try {
      final response = await _dio.get('/user/favorites');
      return (response.data as List).map((json) => Anime.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _dio.get('/user/history');
      return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(int releaseId, int progressSeconds) async {
    try {
      await _dio.post('/user/history', data: {
        'release_id': releaseId,
        'progress_seconds': progressSeconds,
      });
    } catch (_) {}
  }

  // --- Studio & Collaboration Pipeline ---
  Future<List<DubberMember>> getStudioMembers(int fandubId) async {
    try {
      final res = await _dio.get('/studio/$fandubId/members');
      return (res.data as List).map((e) => DubberMember.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addStudioMember(int fandubId, String stageName, String role, {String? bio, String? sampleAudioUrl, String? username}) async {
    try {
      await _dio.post('/studio/$fandubId/members', data: {
        'stage_name': stageName,
        'role': role,
        if (bio != null) 'bio': bio,
        if (sampleAudioUrl != null) 'sample_audio_url': sampleAudioUrl,
        if (username != null) 'username': username,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ProductionTask>> getPipeline(int fandubId) async {
    try {
      final res = await _dio.get('/studio/$fandubId/pipeline');
      return (res.data as List).map((e) => ProductionTask.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createPipelineTask(int fandubId, int animeId, int episodeNumber, {String? notes, String? scriptText, String? stage}) async {
    try {
      await _dio.post('/studio/$fandubId/pipeline', data: {
        'anime_id': animeId,
        'episode_number': episodeNumber,
        if (stage != null) 'stage': stage,
        if (notes != null) 'notes': notes,
        if (scriptText != null) 'script_text': scriptText,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTaskStage(int taskId, String stage, {String? notes, String? scriptText, String? audioDraftUrl}) async {
    try {
      await _dio.patch('/studio/pipeline/$taskId/stage', data: {
        'stage': stage,
        if (notes != null) 'notes': notes,
        if (scriptText != null) 'script_text': scriptText,
        if (audioDraftUrl != null) 'audio_draft_url': audioDraftUrl,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<StudioMessage>> getStudioChat(int fandubId) async {
    try {
      final res = await _dio.get('/studio/$fandubId/chat');
      return (res.data as List).map((e) => StudioMessage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendStudioChat(int fandubId, String text, {int? taskId}) async {
    try {
      await _dio.post('/studio/$fandubId/chat', data: {
        'text': text,
        if (taskId != null) 'task_id': taskId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<DubberMember>> getDubbers({String? role}) async {
    try {
      final res = await _dio.get('/studio/dubbers/all', queryParameters: {
        if (role != null) 'role': role,
      });
      return (res.data as List).map((e) => DubberMember.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
