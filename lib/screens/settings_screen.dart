import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();

  String _selectedQuality = "1080p";
  int? _preferredFandubId;
  String _preferredFandubName = "Avtomatik";
  bool _autoPlayNext = true;
  bool _skipIntro = true;
  bool _backgroundAudio = false;
  String _language = "O'zbekcha (Lotin)";
  String _themeMode = "Cyber Dark";
  String _cacheSize = "24.6 MB";

  List<Fandub> _fandubs = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fandubs = await _apiService.getFandubs();

    setState(() {
      _selectedQuality = prefs.getString('pref_quality') ?? "1080p";
      _preferredFandubId = prefs.getInt('pref_fandub_id');
      _autoPlayNext = prefs.getBool('pref_autoplay') ?? true;
      _skipIntro = prefs.getBool('pref_skip_intro') ?? true;
      _backgroundAudio = prefs.getBool('pref_bg_audio') ?? false;
      _language = prefs.getString('pref_lang') ?? "O'zbekcha (Lotin)";
      _themeMode = prefs.getString('pref_theme') ?? "Cyber Dark";
      _fandubs = fandubs;

      if (_preferredFandubId != null) {
        final match = fandubs.where((f) => f.id == _preferredFandubId).toList();
        if (match.isNotEmpty) {
          _preferredFandubName = match.first.name;
        }
      }
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  void _showQualityPicker() {
    final qualities = ["Avto", "1080p Full HD", "720p HD", "480p SD"];
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
              const Text("Standart Video Sifati", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...qualities.map((q) {
                final isSel = _selectedQuality == q.split(" ")[0];
                return ListTile(
                  title: Text(q, style: TextStyle(color: isSel ? AppTheme.primary : AppTheme.text, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    final cleanQ = q.split(" ")[0];
                    setState(() => _selectedQuality = cleanQ);
                    _saveSetting('pref_quality', cleanQ);
                    _apiService.updateProfile(defaultQuality: cleanQ);
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

  void _showFandubPreferencePicker() {
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
              const Text("Sevimli Fandub (Standart Ovoz)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Barcha animelar birinchi navbatda shu jamoa ovozida ochiladi", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
              const SizedBox(height: 14),
              ListTile(
                title: const Text("Avtomatik (Har qanday mavjudi)"),
                trailing: _preferredFandubId == null ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  setState(() {
                    _preferredFandubId = null;
                    _preferredFandubName = "Avtomatik";
                  });
                  _saveSetting('pref_fandub_id', 0);
                  Navigator.pop(ctx);
                },
              ),
              ..._fandubs.map((f) {
                final isSel = _preferredFandubId == f.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: f.logoUrl != null ? NetworkImage(f.logoUrl!) : null,
                    child: f.logoUrl == null ? const Icon(Icons.mic, color: AppTheme.primary) : null,
                  ),
                  title: Text(f.name, style: TextStyle(color: isSel ? AppTheme.primary : AppTheme.text, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _preferredFandubId = f.id;
                      _preferredFandubName = f.name;
                    });
                    _saveSetting('pref_fandub_id', f.id);
                    _apiService.updateProfile(preferredFandubId: f.id);
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

  void _showFandubApplicationDialog() {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text("Fandub Jamoasini Ro'yxatdan O'tkazish"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("DarkMora platformasida o'z fandubingizni oching va relizlaringizni bot orqali joylang.", style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Fandub nomi (masalan: AniVoice)")),
                const SizedBox(height: 8),
                TextField(controller: slugCtrl, decoration: const InputDecoration(labelText: "Slug (masalan: anivoice)")),
                const SizedBox(height: 8),
                TextField(controller: tgCtrl, decoration: const InputDecoration(labelText: "Telegram kanal (@kanal)")),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Tavsif")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || slugCtrl.text.isEmpty) return;
                final ok = await _apiService.createFandub(nameCtrl.text, slugCtrl.text, descCtrl.text, tgCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? "Fandub arizasi muvaffaqiyatli topshirildi!" : "Xatolik yuz berdi")),
                );
              },
              child: const Text("YUBORISH"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sozlamalar"),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Section 1: Video Playback
          _buildSectionHeader("🎬 VIDEO VA PLEER SOZLAMALARI"),
          _buildTile(
            icon: Icons.high_quality,
            title: "Standart Video Sifati",
            subtitle: _selectedQuality,
            onTap: _showQualityPicker,
          ),
          _buildTile(
            icon: Icons.record_voice_over,
            title: "Sevimli Fandub (Standart Ovoz)",
            subtitle: _preferredFandubName,
            onTap: _showFandubPreferencePicker,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.skip_next, color: AppTheme.primary),
            title: const Text("Keyingi qismga avtomatik o'tish"),
            subtitle: const Text("Qism tugagach avtomatik keyingisiga o'tadi", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            value: _autoPlayNext,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _autoPlayNext = val);
              _saveSetting('pref_autoplay', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fast_forward, color: AppTheme.primary),
            title: const Text("Intro o'tkazish tugmasi (+85s)"),
            subtitle: const Text("Pleerda boshlanish intro qo'shig'ini o'tkazish", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            value: _skipIntro,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _skipIntro = val);
              _saveSetting('pref_skip_intro', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.headphones, color: AppTheme.primary),
            title: const Text("Orqa fonda audio eshitish"),
            subtitle: const Text("Ekran o'chganda ham ovoz davom etadi", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            value: _backgroundAudio,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _backgroundAudio = val);
              _saveSetting('pref_bg_audio', val);
            },
          ),

          const Divider(color: AppTheme.line, height: 32),

          // Section 2: Tashqi ko'rinish
          _buildSectionHeader("🎨 INTERFEYS VA TILLAR"),
          _buildTile(
            icon: Icons.palette,
            title: "Mavzu (Theme)",
            subtitle: _themeMode,
            onTap: () {
              setState(() => _themeMode = _themeMode == "Cyber Dark" ? "AMOLED Black" : "Cyber Dark");
              _saveSetting('pref_theme', _themeMode);
            },
          ),
          _buildTile(
            icon: Icons.language,
            title: "Ilova Tili",
            subtitle: _language,
            onTap: () {},
          ),

          const Divider(color: AppTheme.line, height: 32),

          // Section 3: Xotira & Kesh
          _buildSectionHeader("💾 KESH VA XOTIRA"),
          ListTile(
            leading: const Icon(Icons.cleaning_services, color: AppTheme.accent),
            title: const Text("Keshni Tozalash"),
            subtitle: Text("Rasm va oqim keshlari: $_cacheSize", style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            trailing: OutlinedButton(
              child: const Text("Tozalash"),
              onPressed: () {
                setState(() => _cacheSize = "0 MB");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Barcha keshlangan ma'lumotlar tozalandi")),
                );
              },
            ),
          ),

          const Divider(color: AppTheme.line, height: 32),

          // Section 4: Fandub Jamoalari uchun
          _buildSectionHeader("🎙 FANDUB JAMOLARI UCHUN"),
          ListTile(
            leading: const Icon(Icons.group_add, color: AppTheme.primary),
            title: const Text("Fandub Jamoangizni Qo'shing"),
            subtitle: const Text("O'z jamoangiz nomidan reliz yuklash uchun ariza bering", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.muted),
            onTap: _showFandubApplicationDialog,
          ),

          const Divider(color: AppTheme.line, height: 32),

          // Section 5: Ilova haqida
          _buildSectionHeader("ℹ️ ILOVA HAQIDA"),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.muted),
            title: Text("DarkMora Fandub"),
            subtitle: Text("Versiya 1.0.0 (Release) • O'zbekiston", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.muted),
      onTap: onTap,
    );
  }
}
