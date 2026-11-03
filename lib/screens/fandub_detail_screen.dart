import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'anime_detail_screen.dart';
import 'studio_screen.dart';

class FandubDetailScreen extends StatefulWidget {
  final String slug;

  const FandubDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  State<FandubDetailScreen> createState() => _FandubDetailScreenState();
}

class _FandubDetailScreenState extends State<FandubDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Fandub? _fandub;
  List<Anime> _animes = [];
  List<DubberMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getFandubDetail(widget.slug);
      final fandub = res['fandub'] as Fandub;
      final mem = await _apiService.getStudioMembers(fandub.id);
      setState(() {
        _fandub = fandub;
        _animes = res['animes'];
        _members = mem;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_fandub == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Fandub jamoasi topilmadi")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_fandub!.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fandub Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.surface,
                    backgroundImage: _fandub!.logoUrl != null
                        ? CachedNetworkImageProvider(_fandub!.logoUrl!)
                        : null,
                    child: _fandub!.logoUrl == null
                        ? const Icon(Icons.mic, size: 36, color: AppTheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _fandub!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            if (_fandub!.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_fandub!.description != null)
                          Text(
                            _fandub!.description!,
                            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Released Animes Header
            // Studio Workspace Action
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudioScreen(initialFandubId: _fandub!.id)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard_customize_outlined, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fandub Studio Workspace", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Ishlab chiqarish jarayoni va ichki chat", style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Members / Dubbers Section
            if (_members.isNotEmpty) ...[
              const Text(
                "Ovoz ustalari & Jamoa a'zolari",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _members.length,
                  itemBuilder: (ctx, idx) {
                    final m = _members[idx];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.card,
                            backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                            child: m.avatarUrl == null ? const Icon(Icons.person, color: AppTheme.primary) : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.stageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          Text(
                            m.roleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.muted, fontSize: 9),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ovoz berilgan animelar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${_animes.length} ta",
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Anime Grid
            _animes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "Hozircha animelar yuklanmagan",
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _animes.length,
                    itemBuilder: (context, index) {
                      final anime = _animes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnimeDetailScreen(slugOrId: anime.slug),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: anime.posterUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: anime.posterUrl!,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(color: AppTheme.surface),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anime.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      anime.genres ?? "Anime",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
