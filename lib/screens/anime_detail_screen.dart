import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final String slugOrId;

  const AnimeDetailScreen({Key? key, required this.slugOrId}) : super(key: key);

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Anime? _anime;
  List<Episode> _episodes = [];
  List<Fandub> _fandubs = [];
  List<Map<String, dynamic>> _comments = [];
  int? _selectedFandubId; // null = all
  bool _isFavorite = false;

  final TextEditingController _commentCtrl = TextEditingController();
  int _commentRating = 5;
  int? _commentFandubId;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAnimeDetail(widget.slugOrId);
      final anime = data['anime'] as Anime;
      final comments = await _apiService.getComments(anime.id);

      setState(() {
        _anime = anime;
        _episodes = data['episodes'];
        _fandubs = data['fandubs'];
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty || _anime == null) return;
    final text = _commentCtrl.text.trim();
    _commentCtrl.clear();

    final ok = await _apiService.addComment(_anime!.id, text, _commentRating, fandubId: _commentFandubId);
    if (ok) {
      final updated = await _apiService.getComments(_anime!.id);
      setState(() => _comments = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fikringiz muvaffaqiyatli qoldirildi!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fikr qoldirish uchun tizimga kirish lozim")),
      );
    }
  }

  void _onEpisodeTap(Episode episode) {
    if (episode.releases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu qism hali biron fandub tomonidan yuklanmagan")),
      );
      return;
    }

    List<FandubRelease> targetReleases = episode.releases;
    if (_selectedFandubId != null) {
      final matching = episode.releases.where((r) => r.fandubId == _selectedFandubId).toList();
      if (matching.isNotEmpty) {
        targetReleases = matching;
      }
    }

    if (targetReleases.length == 1) {
      _launchPlayer(episode, targetReleases.first, episode.releases);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Qaysi fandub ovozida ko'rasiz?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                ),
                const SizedBox(height: 12),
                ...episode.releases.map((rel) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.card,
                      backgroundImage: rel.fandubLogo != null ? NetworkImage(rel.fandubLogo!) : null,
                      child: rel.fandubLogo == null ? const Icon(Icons.mic, color: AppTheme.primary) : null,
                    ),
                    title: Text(rel.fandubName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Sifat: ${rel.resolution}${rel.voiceActors != null ? ' • ${rel.voiceActors}' : ''}"),
                    trailing: const Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 30),
                    onTap: () {
                      Navigator.pop(ctx);
                      _launchPlayer(episode, rel, episode.releases);
                    },
                  );
                }).toList(),
              ],
            ),
          );
        },
      );
    }
  }

  void _launchPlayer(Episode episode, FandubRelease release, List<FandubRelease> allReleases) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          anime: _anime!,
          episode: episode,
          initialRelease: release,
          allReleases: allReleases,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_anime == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Anime topilmadi")),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Poster Image
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _anime!.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, shadows: [
                  Shadow(color: Colors.black, blurRadius: 10),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_anime!.posterUrl != null)
                    CachedNetworkImage(
                      imageUrl: _anime!.posterUrl!,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withOpacity(0.8),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: _isFavorite ? AppTheme.primary : Colors.white,
                ),
                onPressed: () async {
                  final added = await _apiService.toggleFavorite(_anime!.id);
                  setState(() => _isFavorite = added);
                },
              ),
            ],
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_anime!.originalTitle != null)
                    Text(
                      _anime!.originalTitle!,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  const SizedBox(height: 8),

                  // Metadata Badges (Year, Status, Episodes count)
                  Row(
                    children: [
                      if (_anime!.releaseYear != null)
                        _buildBadge("${_anime!.releaseYear}-yil"),
                      const SizedBox(width: 8),
                      _buildBadge(_anime!.status == "ongoing" ? "Davom etmoqda" : "Tugallangan",
                          color: _anime!.status == "ongoing" ? AppTheme.accent : AppTheme.primary),
                      const SizedBox(width: 8),
                      _buildBadge("${_anime!.totalEpisodes} qism"),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  if (_anime!.description != null)
                    Text(
                      _anime!.description!,
                      style: const TextStyle(color: AppTheme.text, height: 1.5, fontSize: 13),
                    ),
                  const SizedBox(height: 20),

                  // Fandub selector horizontal strip
                  Row(
                    children: [
                      const Icon(Icons.mic, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Ovoz bergan Fandublar:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedFandubId == null,
                          label: const Text("Barchasi"),
                          selectedColor: AppTheme.primary,
                          onSelected: (_) => setState(() => _selectedFandubId = null),
                        ),
                        const SizedBox(width: 8),
                        ..._fandubs.map((f) {
                          final isSel = _selectedFandubId == f.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              selected: isSel,
                              avatar: f.logoUrl != null
                                  ? CircleAvatar(backgroundImage: NetworkImage(f.logoUrl!))
                                  : null,
                              label: Text(f.name),
                              selectedColor: AppTheme.primary,
                              onSelected: (_) => setState(() => _selectedFandubId = isSel ? null : f.id),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Episodes Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Qismlar (Seriyalar)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${_episodes.length} ta mavjud",
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Episodes List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ep = _episodes[index];
                final availableReleases = _selectedFandubId == null
                    ? ep.releases
                    : ep.releases.where((r) => r.fandubId == _selectedFandubId).toList();

                final hasRelease = availableReleases.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasRelease ? AppTheme.line : Colors.white10,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasRelease ? AppTheme.primary.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "${ep.episodeNumber}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasRelease ? AppTheme.primary : AppTheme.muted,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      ep.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Wrap(
                      spacing: 4,
                      children: ep.releases.map((r) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${r.fandubName} (${r.resolution})",
                            style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                          ),
                        );
                      }).toList(),
                    ),
                    trailing: Icon(
                      hasRelease ? Icons.play_arrow_rounded : Icons.lock_clock,
                      color: hasRelease ? AppTheme.primary : AppTheme.muted,
                    ),
                    onTap: () => _onEpisodeTap(ep),
                  ),
                );
              },
              childCount: _episodes.length,
            ),
          ),

          // Community Comments & Voiceover Reviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppTheme.line, height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "💬 Fandub Ovozlariga Sharhlar",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text("${_comments.length} ta fikr", style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Add comment input box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: "Ovoz berish sifati va dublyaj haqida fikringizni yozing...",
                            hintStyle: TextStyle(color: AppTheme.muted, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Star rating
                            Row(
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () => setState(() => _commentRating = i + 1),
                                  child: Icon(
                                    i < _commentRating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                );
                              }),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _submitComment,
                              child: const Text("YUBORISH", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment items
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text("Hozircha sharhlar yo'q. Birinchi bo'lib fikr bildiring!", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                      ),
                    )
                  else
                    ..._comments.map((c) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primary,
                                  child: Text(
                                    (c['username'] ?? 'F')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c['username'] ?? 'Foydalanuvchi',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (c['fandub_name'] != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      c['fandub_name'],
                                      style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Row(
                                  children: List.generate(c['rating'] ?? 5, (_) => const Icon(Icons.star, color: Colors.amber, size: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(c['text'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, {Color color = AppTheme.line}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color == AppTheme.line ? AppTheme.muted : color),
      ),
    );
  }
}
