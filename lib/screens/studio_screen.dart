import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StudioScreen extends StatefulWidget {
  final int initialFandubId;
  const StudioScreen({Key? key, this.initialFandubId = 1}) : super(key: key);

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  int _selectedFandubId = 1;
  List<Fandub> _fandubs = [];
  List<ProductionTask> _pipeline = [];
  List<DubberMember> _members = [];
  List<StudioMessage> _messages = [];

  bool _isLoading = true;
  String _pipelineFilter = 'all'; // 'all', 'translation', 'voice_recording', 'mixing_sound', 'review', 'published'
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFandubId = widget.initialFandubId;
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final fList = await _apiService.getFandubs();
      final pipe = await _apiService.getPipeline(_selectedFandubId);
      final mem = await _apiService.getStudioMembers(_selectedFandubId);
      final chat = await _apiService.getStudioChat(_selectedFandubId);

      setState(() {
        _fandubs = fList;
        _pipeline = pipe;
        _members = mem;
        _messages = chat;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCurrentTab() async {
    final pipe = await _apiService.getPipeline(_selectedFandubId);
    final mem = await _apiService.getStudioMembers(_selectedFandubId);
    final chat = await _apiService.getStudioChat(_selectedFandubId);
    setState(() {
      _pipeline = pipe;
      _members = mem;
      _messages = chat;
    });
  }

  void _onFandubChanged(int newId) {
    setState(() {
      _selectedFandubId = newId;
    });
    _loadAll();
  }

  // --- Advance / Change Pipeline Stage ---
  void _openChangeStageDialog(ProductionTask task) {
    final stages = [
      {'key': 'translation', 'name': 'Tarjima', 'icon': Icons.translate},
      {'key': 'voice_recording', 'name': 'Ovoz yozish', 'icon': Icons.mic},
      {'key': 'mixing_sound', 'name': 'Montaj & Tayming', 'icon': Icons.tune},
      {'key': 'review', 'name': 'Tekshiruv', 'icon': Icons.fact_check},
      {'key': 'published', 'name': 'Chiqarildi (Tayyor)', 'icon': Icons.check_circle},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${task.animeTitle} - ${task.episodeNumber}-qism",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Ishlab chiqarish bosqichini tanlang:",
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...stages.map((stg) {
                  final isCurrent = task.stage == stg['key'];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? AppTheme.primary : AppTheme.surface,
                      child: Icon(stg['icon'] as IconData, size: 18, color: Colors.white),
                    ),
                    title: Text(
                      stg['name'] as String,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppTheme.primary : AppTheme.text,
                      ),
                    ),
                    trailing: isCurrent ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await _apiService.updateTaskStage(task.id, stg['key'] as String);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Bosqich o'zgartirildi: ${stg['name']}")),
                        );
                        _refreshCurrentTab();
                      }
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Add Task Dialog ---
  void _openAddTaskDialog() {
    final epCtrl = TextEditingController(text: "1");
    final notesCtrl = TextEditingController();
    int? selectedAnimeId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDState) {
          return AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text("Yangi Epizod Qo'shish"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Fandub jamoangiz rejasiga yangi ovoz berish vazifasini kiritish:",
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: epCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Qism raqami (Episode #)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: "Eslatma / Vazifa talabi"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () async {
                  final ep = int.tryParse(epCtrl.text.trim()) ?? 1;
                  Navigator.pop(ctx);
                  final ok = await _apiService.createPipelineTask(
                    _selectedFandubId,
                    1, // demo anime Naruto
                    ep,
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vazifa muvaffaqiyatli qo'shildi")),
                    );
                    _refreshCurrentTab();
                  }
                },
                child: const Text("Qo'shish"),
              ),
            ],
          );
        });
      },
    );
  }

  // --- Add Member Dialog ---
  void _openAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    String selectedRole = 'dubber_male';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDState) {
          return AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text("Jamoaga A'zo Qo'shish"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Taxallus / Ism (Masalan: Malika San)"),
                  ),
                  const SizedBox(height: 12),
                  const Text("Lavozim / Vazifa:", style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                  DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    dropdownColor: AppTheme.surface,
                    items: const [
                      DropdownMenuItem(value: 'dubber_male', child: Text("Dublyor (Erkak ovoz)")),
                      DropdownMenuItem(value: 'dubber_female', child: Text("Dublyorka (Ayol ovoz)")),
                      DropdownMenuItem(value: 'translator', child: Text("Tarjimon")),
                      DropdownMenuItem(value: 'timer', child: Text("Taymer / Montaj ustasi")),
                      DropdownMenuItem(value: 'uploader', child: Text("Uploader")),
                    ],
                    onChanged: (val) {
                      if (val != null) setDState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    decoration: const InputDecoration(labelText: "Qisqa bio / Ijro etadigan qahramonlari"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await _apiService.addStudioMember(
                    _selectedFandubId,
                    nameCtrl.text.trim(),
                    selectedRole,
                    bio: bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : null,
                  );
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Yangi a'zo muvaffaqiyatli qo'shildi")),
                    );
                    _refreshCurrentTab();
                  }
                },
                child: const Text("Saqlash"),
              ),
            ],
          );
        });
      },
    );
  }

  // --- Send Studio Chat Message ---
  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    final ok = await _apiService.sendStudioChat(_selectedFandubId, text);
    if (ok) {
      final updated = await _apiService.getStudioChat(_selectedFandubId);
      setState(() => _messages = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fandub Studio Workspace"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.muted,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard_customize_outlined), text: "Kanban (${_pipeline.length})"),
            Tab(icon: const Icon(Icons.forum_outlined), text: "Chat (${_messages.length})"),
            Tab(icon: const Icon(Icons.group_outlined), text: "A'zolar (${_members.length})"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Fandub Selector Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.card,
                  child: Row(
                    children: [
                      const Icon(Icons.home_work_outlined, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Text("Jamoa:", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedFandubId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppTheme.surface,
                          items: _fandubs.map((f) {
                            return DropdownMenuItem<int>(
                              value: f.id,
                              child: Text(
                                f.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _onFandubChanged(val);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: "Yangilash",
                        onPressed: _refreshCurrentTab,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildKanbanTab(),
                      _buildChatTab(),
                      _buildMembersTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- 1. Kanban Pipeline Tab ---
  Widget _buildKanbanTab() {
    final stages = [
      {'key': 'all', 'label': 'Barchasi'},
      {'key': 'translation', 'label': 'Tarjima'},
      {'key': 'voice_recording', 'label': 'Ovoz yozish'},
      {'key': 'mixing_sound', 'label': 'Montaj & Tayming'},
      {'key': 'review', 'label': 'Tekshiruv'},
      {'key': 'published', 'label': 'Chiqarildi'},
    ];

    final filtered = _pipelineFilter == 'all'
        ? _pipeline
        : _pipeline.where((t) => t.stage == _pipelineFilter).toList();

    return Column(
      children: [
        // Stage Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: stages.map((stg) {
              final isSel = _pipelineFilter == stg['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(stg['label']!),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => _pipelineFilter = stg['key']!);
                  },
                  selectedColor: AppTheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppTheme.muted,
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppTheme.card,
                  side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.line),
                ),
              );
            }).toList(),
          ),
        ),

        // Tasks List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.muted),
                      const SizedBox(height: 12),
                      const Text("Ushbu bosqichda epizodlar yo'q", style: TextStyle(color: AppTheme.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        icon: const Icon(Icons.add),
                        label: const Text("Epizod qo'shish"),
                        onPressed: _openAddTaskDialog,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final t = filtered[idx];
                    return _buildTaskCard(t);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(ProductionTask task) {
    Color stageColor;
    switch (task.stage) {
      case 'translation':
        stageColor = Colors.orangeAccent;
        break;
      case 'voice_recording':
        stageColor = Colors.redAccent;
        break;
      case 'mixing_sound':
        stageColor = Colors.purpleAccent;
        break;
      case 'review':
        stageColor = Colors.amberAccent;
        break;
      case 'published':
        stageColor = Colors.greenAccent;
        break;
      default:
        stageColor = AppTheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: stageColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: task.animePoster != null
                      ? CachedNetworkImage(
                          imageUrl: task.animePoster!,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 64,
                          color: AppTheme.surface,
                          child: const Icon(Icons.movie, color: AppTheme.muted),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.animeTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${task.episodeNumber}-qism",
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: stageColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.stageLabel,
                          style: TextStyle(color: stageColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.muted),
                  tooltip: "Bosqichni o'zgartirish",
                  onPressed: () => _openChangeStageDialog(task),
                ),
              ],
            ),
            const Divider(height: 18, color: AppTheme.line),
            // Assigned team members row
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (task.dubberMaleName != null)
                  _buildMemberChip(Icons.mic, "Dublyor: ${task.dubberMaleName!}"),
                if (task.dubberFemaleName != null)
                  _buildMemberChip(Icons.mic_external_on, "Dublyorka: ${task.dubberFemaleName!}"),
                if (task.translatorName != null)
                  _buildMemberChip(Icons.translate, "Tarjimon: ${task.translatorName!}"),
                if (task.timerName != null)
                  _buildMemberChip(Icons.tune, "Taymer: ${task.timerName!}"),
              ],
            ),
            if (task.notes != null && task.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.notes!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.muted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
        ],
      ),
    );
  }

  // --- 2. Studio Chat Tab ---
  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text("Studiyada hozircha xabarlar yo'q", style: TextStyle(color: AppTheme.muted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = _messages[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primary,
                            backgroundImage: msg.avatarUrl != null ? NetworkImage(msg.avatarUrl!) : null,
                            child: msg.avatarUrl == null
                                ? Text(msg.stageName.isNotEmpty ? msg.stageName[0].toUpperCase() : 'U')
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.stageName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        msg.role,
                                        style: const TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      msg.createdAt.length >= 16 ? msg.createdAt.substring(11, 16) : '',
                                      style: const TextStyle(color: AppTheme.muted, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.line),
                                  ),
                                  child: Text(msg.text, style: const TextStyle(fontSize: 13, height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Chat Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppTheme.card,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Studiyaga xabar yozish...",
                      hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppTheme.surface,
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    onPressed: _handleSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Members Tab ---
  Widget _buildMembersTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add),
        label: const Text("A'zo qo'shish"),
        onPressed: _openAddMemberDialog,
      ),
      body: _members.isEmpty
          ? const Center(child: Text("Jamoada a'zolar ro'yxatga olinmagan", style: TextStyle(color: AppTheme.muted)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _members.length,
              itemBuilder: (ctx, idx) {
                final m = _members[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.line),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.surface,
                      backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                      child: m.avatarUrl == null
                          ? const Icon(Icons.person, color: AppTheme.primary)
                          : null,
                    ),
                    title: Text(m.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.roleLabel,
                            style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (m.bio != null) ...[
                          const SizedBox(height: 4),
                          Text(m.bio!, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                        ],
                      ],
                    ),
                    trailing: m.sampleAudioUrl != null
                        ? IconButton(
                            icon: const Icon(Icons.volume_up, color: AppTheme.accent),
                            tooltip: "Ovoz namunasini eshitish",
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${m.stageName} ovoz namunasi: ${m.sampleAudioUrl!}")),
                              );
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
