import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'fandub_detail_screen.dart';

class FandubsScreen extends StatefulWidget {
  const FandubsScreen({Key? key}) : super(key: key);

  @override
  State<FandubsScreen> createState() => _FandubsScreenState();
}

class _FandubsScreenState extends State<FandubsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Fandub> _fandubs = [];

  @override
  void initState() {
    super.initState();
    _loadFandubs();
  }

  Future<void> _loadFandubs() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getFandubs();
      setState(() {
        _fandubs = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fandub Jamoalari"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadFandubs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _fandubs.length,
                itemBuilder: (context, index) {
                  final fandub = _fandubs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.surface,
                        backgroundImage: fandub.logoUrl != null
                            ? CachedNetworkImageProvider(fandub.logoUrl!)
                            : null,
                        child: fandub.logoUrl == null
                            ? const Icon(Icons.mic, color: AppTheme.primary)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              fandub.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (fandub.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (fandub.description != null)
                            Text(
                              fandub.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            "🎙 ${fandub.animeCount} ta reliz",
                            style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.muted, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FandubDetailScreen(slug: fandub.slug),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
