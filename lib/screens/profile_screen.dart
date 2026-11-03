import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'anime_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  List<Anime> _favorites = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAuth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    final me = await _apiService.getMe();
    if (me != null) {
      final favs = await _apiService.getFavorites();
      final hist = await _apiService.getHistory();
      setState(() {
        _isLoggedIn = true;
        _user = me;
        _favorites = favs;
        _history = hist;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _user = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('username');
    await prefs.remove('role');
    _checkAuth();
  }

  void _openAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(onAuthenticated: _checkAuth),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kabinet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Sozlamalar",
            onPressed: _openSettings,
          ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Chiqish",
              onPressed: _handleLogout,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _isLoggedIn
              ? _buildLoggedInView()
              : _buildGuestView(),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line),
              ),
              child: const Icon(Icons.person_pin, size: 64, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              "Profilga xush kelibsiz!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sevimlilar ro'yxatini tuzish, ko'rish tarixini saqlash va fandub imkoniyatlaridan foydalanish uchun tizimga kiring.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login),
                label: const Text("KIRISH / RO'YXATDAN O'TISH", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _openAuth,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.settings, color: AppTheme.muted),
              label: const Text("Ilova Sozlamalari", style: TextStyle(color: AppTheme.text)),
              onPressed: _openSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView() {
    final username = _user?['username'] ?? 'Foydalanuvchi';
    final role = _user?['role'] ?? 'user';
    final fandubName = _user?['fandub_name'];
    final avatarUrl = _user?['avatar_url'];

    return Column(
      children: [
        // Profile Info Header Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primary,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, size: 36, color: Colors.white) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role == 'superadmin' ? 'SuperAdmin' : role == 'fandub_admin' ? 'Fandub Rahbari' : 'Foydalanuvchi',
                            style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (fandubName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fandubName,
                              style: const TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.muted),
                onPressed: _openSettings,
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.primary,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.muted,
            tabs: [
              Tab(text: "Sevimlilar (${_favorites.length})"),
              Tab(text: "Tarix (${_history.length})"),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return const Center(
        child: Text("Hozircha sevimli animelar yo'q", style: TextStyle(color: AppTheme.muted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final anime = _favorites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: anime.posterUrl != null
                  ? CachedNetworkImage(imageUrl: anime.posterUrl!, width: 45, height: 65, fit: BoxFit.cover)
                  : Container(width: 45, height: 65, color: AppTheme.surface),
            ),
            title: Text(anime.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(anime.genres ?? "Anime", style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            trailing: const Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 28),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AnimeDetailScreen(slugOrId: anime.slug)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Text("Ko'rish tarixi bo'sh", style: TextStyle(color: AppTheme.muted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final animeTitle = item['anime_title'] ?? 'Anime';
        final epNum = item['episode_number'] ?? 1;
        final fandub = item['fandub_name'] ?? 'Fandub';
        final poster = item['poster_url'];
        final seconds = item['progress_seconds'] ?? 0;
        final minutes = (seconds / 60).floor();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: poster != null
                  ? CachedNetworkImage(imageUrl: poster, width: 45, height: 65, fit: BoxFit.cover)
                  : Container(width: 45, height: 65, color: AppTheme.surface),
            ),
            title: Text(animeTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("$epNum-qism • $fandub ovozi\nTo'xtatilgan vaqt: $minutes daqiqa", style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            trailing: const Icon(Icons.play_arrow, color: AppTheme.primary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AnimeDetailScreen(slugOrId: "${item['anime_id']}")),
              );
            },
          ),
        );
      },
    );
  }
}
