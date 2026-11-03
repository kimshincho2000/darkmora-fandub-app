import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({Key? key, required this.onAuthenticated}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Login Controllers
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register Controllers
  final _regUserCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  final _twoFactorCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMessage;
  bool _show2FAStep = false;
  String? _sessionToken;
  String? _emailHint;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _twoFactorCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final u = _loginUserCtrl.text.trim();
    final p = _loginPassCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      setState(() => _errorMessage = "Login va parolni kiriting");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.login(u, p);
      setState(() => _isLoading = false);

      if (res != null) {
        if (res['requires_2fa'] == true) {
          setState(() {
            _show2FAStep = true;
            _sessionToken = res['session_token'];
            _emailHint = res['email_hint'];
          });
        } else {
          widget.onAuthenticated();
          if (mounted) Navigator.pop(context);
        }
      } else {
        setState(() => _errorMessage = "Login yoki parol noto'g'ri");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Xatolik yuz berdi";
      });
    }
  }

  Future<void> _handleVerify2FA() async {
    final code = _twoFactorCtrl.text.trim();
    if (code.length < 6 || _sessionToken == null) {
      setState(() => _errorMessage = "6 xonali tasdiqlash kodini to'liq kiriting");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.verify2FA(_sessionToken!, code);
      setState(() => _isLoading = false);

      if (response) {
        widget.onAuthenticated();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMessage = "Tasdiqlash kodi noto'g'ri yoki muddati tugagan");
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Xatolik yuz berdi";
      });
    }
  }

  Future<void> _handleRegister() async {
    final u = _regUserCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final p = _regPassCtrl.text.trim();
    final cp = _regConfirmPassCtrl.text.trim();

    if (u.length < 3) {
      setState(() => _errorMessage = "Foydalanuvchi nomi kamida 3 ta belgidan iborat bo'lsin");
      return;
    }
    if (p.length < 6) {
      setState(() => _errorMessage = "Parol kamida 6 ta belgidan iborat bo'lsin");
      return;
    }
    if (p != cp) {
      setState(() => _errorMessage = "Parollar bir xil emas");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _apiService.register(u, p, email: email.isNotEmpty ? email : null);
    setState(() => _isLoading = false);

    if (res != null) {
      widget.onAuthenticated();
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _errorMessage = "Bu foydalanuvchi nomi yoki email allaqachon band");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hisobga kirish"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo Branding
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, size: 54, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              "DARKMORA FANDUB",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 4),
            const Text(
              "Barcha O'zbek fandublari yagona ilovada",
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Tab Bar Switcher
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.muted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "KIRISH"),
                  Tab(text: "RO'YXATDAN O'TISH"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Error banner
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab Content or 2FA step
            if (_show2FAStep)
              _build2FAView()
            else ...[
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginTab(),
                    _buildRegisterTab(),
                  ],
                ),
              ),
            ],

            // Telegram Link Hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.send_rounded, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Fandub jamoasi bo'lsangiz: @seromusic_robot orqali hisobingizni ulab, to'g'ridan-to'g'ri yangi relizlar yuklashingiz mumkin.",
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build2FAView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.security, size: 48, color: AppTheme.primary),
          const SizedBox(height: 12),
          const Text(
            "2-Bosqichli Tasdiqlash",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Tasdiqlash kodi ${_emailHint ?? 'emailingiz'} ga yuborildi.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _twoFactorCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.primary),
            decoration: InputDecoration(
              counterText: "",
              hintText: "______",
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleVerify2FA,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("TASDIQLASH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            child: const Text("Bekor qilish", style: TextStyle(color: AppTheme.muted)),
            onPressed: () => setState(() => _show2FAStep = false),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      children: [
        TextField(
          controller: _loginUserCtrl,
          decoration: InputDecoration(
            labelText: "Foydalanuvchi nomi",
            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.muted),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPassCtrl,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: "Parol",
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.muted),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppTheme.muted),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("TIZIMGA KIRISH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _regUserCtrl,
            decoration: InputDecoration(
              labelText: "Foydalanuvchi nomi *",
              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.muted),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email (ixtiyoriy)",
              prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.muted),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPassCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: "Parol (kamida 6 belgi) *",
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.muted),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regConfirmPassCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: "Parolni tasdiqlang *",
              prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.muted),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("RO'YXATDAN O'TISH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
