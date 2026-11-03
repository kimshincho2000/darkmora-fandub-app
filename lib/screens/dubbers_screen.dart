import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DubbersScreen extends StatefulWidget {
  const DubbersScreen({Key? key}) : super(key: key);

  @override
  State<DubbersScreen> createState() => _DubbersScreenState();
}

class _DubbersScreenState extends State<DubbersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<DubberMember> _dubbers = [];
  String? _selectedRoleFilter; // null = all

  @override
  void initState() {
    super.initState();
    _loadDubbers();
  }

  Future<void> _loadDubbers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getDubbers(role: _selectedRoleFilter);
      setState(() {
        _dubbers = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String? role) {
    setState(() {
      _selectedRoleFilter = role;
    });
    _loadDubbers();
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'Barchasi', 'role': null},
      {'label': '🎙 Dublyor (Erkak)', 'role': 'dubber_male'},
      {'label': '🌸 Dublyorka (Ayol)', 'role': 'dubber_female'},
      {'label': '📖 Tarjimon', 'role': 'translator'},
      {'label': '🎛 Taymer / Montaj', 'role': 'timer'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ovoz ustalari & Dublyorlar"),
      ),
      body: Column(
        children: [
          // Role filters chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: filters.map((f) {
                final isSelected = _selectedRoleFilter == f['role'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label'] as String),
                    selected: isSelected,
                    onSelected: (_) => _onFilterChanged(f['role'] as String?),
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.muted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppTheme.card,
                    side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.line),
                  ),
                );
              }).toList(),
            ),
          ),

          // Dubbers grid / list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _dubbers.isEmpty
                    ? const Center(child: Text("Dublyorlar topilmadi", style: TextStyle(color: AppTheme.muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _dubbers.length,
                        itemBuilder: (ctx, idx) {
                          final d = _dubbers[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppTheme.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppTheme.line),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppTheme.surface,
                                    backgroundImage: d.avatarUrl != null
                                        ? CachedNetworkImageProvider(d.avatarUrl!)
                                        : null,
                                    child: d.avatarUrl == null
                                        ? const Icon(Icons.person, size: 30, color: AppTheme.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                d.stageName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            if (d.fandubName != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surface,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.line),
                                                ),
                                                child: Text(
                                                  d.fandubName!,
                                                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            d.roleLabel,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (d.bio != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            d.bio!,
                                            style: const TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.3),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        // Voice sample button
                                        if (d.sampleAudioUrl != null) ...[
                                          InkWell(
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("${d.stageName} ovoz namunasi tinglanmoqda..."),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surface,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Ovoz namunasini tinglash",
                                                    style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
