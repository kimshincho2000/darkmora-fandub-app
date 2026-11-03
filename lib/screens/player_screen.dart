import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Anime anime;
  final Episode episode;
  final FandubRelease initialRelease;
  final List<FandubRelease> allReleases;

  const PlayerScreen({
    Key? key,
    required this.anime,
    required this.episode,
    required this.initialRelease,
    required this.allReleases,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ApiService _apiService = ApiService();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  late FandubRelease _currentRelease;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _historyTimer;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _currentRelease = widget.initialRelease;
    _initializePlayer(_currentRelease);

    _historyTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isPlaying) {
        final positionSec =
            _videoPlayerController!.value.position.inSeconds;
        _apiService.saveHistory(_currentRelease.id, positionSec);
      }
    });
  }

  Future<void> _initializePlayer(FandubRelease release, {Duration? seekTo}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolved = await _apiService.resolveStream(release.id);
      final streamUrl = resolved['stream_url'] ?? release.streamUrl;

      final oldController = _videoPlayerController;
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setPlaybackSpeed(_playbackSpeed);

      if (seekTo != null) {
        await _videoPlayerController!.seekTo(seekTo);
      }

      _chewieController?.dispose();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primary,
          handleColor: AppTheme.primary,
          backgroundColor: AppTheme.line,
          bufferedColor: Colors.white24,
        ),
      );

      await oldController?.dispose();

      setState(() {
        _currentRelease = release;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Videoni yuklashda xatolik yuz berdi: $e";
      });
    }
  }

  void _skipIntro() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      final cur = _videoPlayerController!.value.position;
      _videoPlayerController!.seekTo(cur + const Duration(seconds: 85));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Intro o'tkazib yuborildi (+85s)"), duration: Duration(seconds: 1)),
      );
    }
  }

  void _seekRelative(int seconds) {
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      final cur = _videoPlayerController!.value.position;
      final target = cur + Duration(seconds: seconds);
      _videoPlayerController!.seekTo(target > Duration.zero ? target : Duration.zero);
    }
  }

  void _showSpeedPicker() {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ijro Tezligi (Speed)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...speeds.map((s) {
                final isSel = _playbackSpeed == s;
                return ListTile(
                  title: Text("${s}x", style: TextStyle(color: isSel ? AppTheme.primary : AppTheme.text, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    setState(() => _playbackSpeed = s);
                    _videoPlayerController?.setPlaybackSpeed(s);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showFandubSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.record_voice_over, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text(
                    "Fandub ovozini tanlang",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.muted),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${widget.anime.title} — ${widget.episode.title}",
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...widget.allReleases.map((rel) {
                final isSelected = rel.id == _currentRelease.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.line,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.background,
                      backgroundImage: rel.fandubLogo != null
                          ? NetworkImage(rel.fandubLogo!)
                          : null,
                      child: rel.fandubLogo == null
                          ? const Icon(Icons.mic, color: AppTheme.primary)
                          : null,
                    ),
                    title: Text(
                      rel.fandubName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.primary : AppTheme.text,
                      ),
                    ),
                    subtitle: Text(
                      "Sifat: ${rel.resolution}${rel.voiceActors != null ? ' • Ovozlar: ${rel.voiceActors}' : ''}",
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.primary)
                        : const Icon(Icons.play_arrow_outlined, color: AppTheme.muted),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isSelected) {
                        final currentPos = _videoPlayerController?.value.position;
                        _initializePlayer(rel, seekTo: currentPos);
                      }
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.anime.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "${widget.episode.title} • ${_currentRelease.fandubName}",
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Tezlik",
            icon: Text("${_playbackSpeed}x", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
            onPressed: _showSpeedPicker,
          ),
          IconButton(
            tooltip: "Fandubni almashtirish",
            icon: const Icon(Icons.record_voice_over, color: AppTheme.primary),
            onPressed: _showFandubSwitcher,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video viewport
            Expanded(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppTheme.primary)
                    : _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _chewieController != null &&
                                _chewieController!
                                    .videoPlayerController.value.isInitialized
                            ? Chewie(controller: _chewieController!)
                            : const CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
            // Quick Control Bar (Skip Intro, 10s Rewind/Forward)
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    icon: const Icon(Icons.replay_10, size: 20),
                    label: const Text("-10s"),
                    onPressed: () => _seekRelative(-10),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: AppTheme.line),
                    ),
                    icon: const Icon(Icons.fast_forward, size: 16),
                    label: const Text("Intro o'tkazish (+85s)", style: TextStyle(fontSize: 12)),
                    onPressed: _skipIntro,
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    icon: const Icon(Icons.forward_10, size: 20),
                    label: const Text("+10s"),
                    onPressed: () => _seekRelative(10),
                  ),
                ],
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.background,
                    backgroundImage: _currentRelease.fandubLogo != null
                        ? NetworkImage(_currentRelease.fandubLogo!)
                        : null,
                    child: _currentRelease.fandubLogo == null
                        ? const Icon(Icons.mic, size: 16, color: AppTheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ovoz: ${_currentRelease.fandubName}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.text,
                          ),
                        ),
                        Text(
                          "Mavjud: ${widget.allReleases.length} ta fandub jamoasi",
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.card,
                      foregroundColor: AppTheme.text,
                      side: const BorderSide(color: AppTheme.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 18, color: AppTheme.primary),
                    label: const Text("O'zgartirish"),
                    onPressed: _showFandubSwitcher,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
