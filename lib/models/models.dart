class Fandub {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? telegramChannel;
  final bool isVerified;
  final int animeCount;

  Fandub({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.telegramChannel,
    this.isVerified = false,
    this.animeCount = 0,
  });

  factory Fandub.fromJson(Map<String, dynamic> json) {
    return Fandub(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      telegramChannel: json['telegram_channel'],
      isVerified: json['is_verified'] == 1,
      animeCount: json['anime_count'] ?? 0,
    );
  }
}

class FandubRelease {
  final int id;
  final int episodeId;
  final int fandubId;
  final String fandubName;
  final String? fandubSlug;
  final String? fandubLogo;
  final String streamUrl;
  final String? telegramFileId;
  final String resolution;
  final String? voiceActors;
  final int viewsCount;

  FandubRelease({
    required this.id,
    required this.episodeId,
    required this.fandubId,
    required this.fandubName,
    this.fandubSlug,
    this.fandubLogo,
    required this.streamUrl,
    this.telegramFileId,
    this.resolution = '1080p',
    this.voiceActors,
    this.viewsCount = 0,
  });

  factory FandubRelease.fromJson(Map<String, dynamic> json) {
    return FandubRelease(
      id: json['id'] ?? 0,
      episodeId: json['episode_id'] ?? 0,
      fandubId: json['fandub_id'] ?? 0,
      fandubName: json['fandub_name'] ?? 'Fandub',
      fandubSlug: json['fandub_slug'],
      fandubLogo: json['fandub_logo'],
      streamUrl: json['stream_url'] ?? '',
      telegramFileId: json['telegram_file_id'],
      resolution: json['resolution'] ?? '1080p',
      voiceActors: json['voice_actors'],
      viewsCount: json['views_count'] ?? 0,
    );
  }
}

class Episode {
  final int id;
  final int episodeNumber;
  final String title;
  final int durationSeconds;
  final List<FandubRelease> releases;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    this.durationSeconds = 0,
    this.releases = const [],
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 1,
      title: json['title'] ?? '${json['episode_number']}-qism',
      durationSeconds: json['duration_seconds'] ?? 0,
      releases: (json['releases'] as List<dynamic>?)
              ?.map((e) => FandubRelease.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Anime {
  final int id;
  final String title;
  final String? originalTitle;
  final String slug;
  final String? description;
  final String? posterUrl;
  final String? bannerUrl;
  final int? releaseYear;
  final String? genres;
  final String status;
  final int totalEpisodes;
  final List<Fandub> availableFandubs;

  Anime({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.slug,
    this.description,
    this.posterUrl,
    this.bannerUrl,
    this.releaseYear,
    this.genres,
    this.status = 'ongoing',
    this.totalEpisodes = 0,
    this.availableFandubs = const [],
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      originalTitle: json['original_title'],
      slug: json['slug'] ?? '',
      description: json['description'],
      posterUrl: json['poster_url'],
      bannerUrl: json['banner_url'],
      releaseYear: json['release_year'],
      genres: json['genres'],
      status: json['status'] ?? 'ongoing',
      totalEpisodes: json['total_episodes'] ?? 0,
      availableFandubs: (json['available_fandubs'] as List<dynamic>?)
              ?.map((e) => Fandub.fromJson(e))
              .toList() ??
          [],
    );
  }
}
