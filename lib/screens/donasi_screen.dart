import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/notif_helper.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class DonasiScreen extends StatefulWidget {
  final String username;
  const DonasiScreen({super.key, required this.username});

  @override
  State<DonasiScreen> createState() => _DonasiScreenState();
}

class _DonasiScreenState extends State<DonasiScreen> {
  int _balance = 0;
  bool _loadingBalance = true;
  bool _loadingKode = false;

  static const int _donasiMin = 5000;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  String _formatRupiah(int val) {
    final s = val.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _fetchBalance() async {
    await ApiService.init();
    setState(() => _loadingBalance = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/donasi/balance?username=${Uri.encodeComponent(widget.username)}'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() => _balance = data['balance'] ?? 0);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingBalance = false);
  }

  Future<void> _dapatkanKode() async {
    if (_balance < _donasiMin) {
      await showWarning(context,
        'Saldo kamu Rp ${_formatRupiah(_balance)}.\nMinimal Rp ${_formatRupiah(_donasiMin)} Untuk Dapatkan Kode.');
      return;
    }
    setState(() => _loadingKode = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/donasi/get-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        final kode = data['code'].toString();
        await _fetchBalance();
        if (mounted) _showKodeDialog(kode);
      } else if (mounted) {
        await showError(context, data['message'] ?? 'Gagal mendapatkan kode');
      }
    } catch (_) {
      if (mounted) await showError(context, 'Koneksi error');
    }
    if (mounted) setState(() => _loadingKode = false);
  }

  void _showKodeDialog(String kode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
                ),
                child: const Icon(Icons.key_rounded, color: Colors.green, size: 28),
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                ).createShader(b),
                child: const Text('KODE AKSES KAMU',
                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 13,
                    fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text('● Simpan Baik-Baik ●',
                style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9,
                  color: const Color(0xFF00E5FF).withOpacity(0.6), letterSpacing: 2),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: kode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kode disalin!'), duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                  ),
                  child: Column(children: [
                    Text(kode,
                      style: const TextStyle(fontFamily: 'Orbitron', fontSize: 28,
                        fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 6),
                    ),
                    const SizedBox(height: 4),
                    Text('Tap untuk salin',
                      style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9,
                        color: const Color(0xFF00E5FF).withOpacity(0.5)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('LOGIN SEKARANG',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Orbitron', fontSize: 12,
                      fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({required String svgPath, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.string(
          svgPath,
          width: 16, height: 16,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontFamily: 'ShareTechMono', fontSize: 10,
          color: color, letterSpacing: 0.5,
        )),
      ]),
    );
  }

  void _openDeposit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepositSheet(
        username: widget.username,
        onSuccess: _fetchBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(delegate: SliverChildListDelegate([
                // ── Header ──
                Row(children: [
                  Container(width: 3, height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                      borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                      ).createShader(b),
                      child: const Text('DONASI',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 20,
                          fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3),
                      ),
                    ),
                    Text('Donasi untuk dapatkan kode akses',
                      style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10,
                        color: const Color(0xFF00E5FF).withOpacity(0.6)),
                    ),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchBalance,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 18),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('👤 ${widget.username}',
                  style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11,
                    color: const Color(0xFF00E5FF).withOpacity(0.5)),
                ),
                const SizedBox(height: 24),

                // ── Saldo Card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1565C0).withOpacity(0.3), AppTheme.cardBg],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E88E5).withOpacity(0.15), blurRadius: 16)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF1E88E5), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('SALDO DONASI',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 11,
                          color: Color(0xFF1E88E5), letterSpacing: 2),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _loadingBalance
                      ? const SizedBox(height: 36,
                          child: Center(child: SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Color(0xFF1E88E5), strokeWidth: 2))))
                      : Text('Rp ${_formatRupiah(_balance)}',
                          style: TextStyle(
                            fontFamily: 'Orbitron', fontSize: 28, fontWeight: FontWeight.bold,
                            color: _balance >= _donasiMin ? const Color(0xFF4CAF50) : Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _balance >= _donasiMin
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _balance >= _donasiMin
                            ? Colors.green.withOpacity(0.4)
                            : const Color(0xFFFF6B35).withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          _balance >= _donasiMin ? Icons.check_circle_outline : Icons.info_outline,
                          color: _balance >= _donasiMin ? Colors.green : const Color(0xFFFF6B35),
                          size: 13),
                        const SizedBox(width: 6),
                        Text(
                          _balance >= _donasiMin
                            ? 'Saldo cukup! Bisa dapatkan kode'
                            : 'Butuh min. Rp ${_formatRupiah(_donasiMin)} untuk dapat kode',
                          style: TextStyle(
                            fontFamily: 'ShareTechMono', fontSize: 10,
                            color: _balance >= _donasiMin ? Colors.green : const Color(0xFFFF6B35),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Info ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF64B5F6), size: 14),
                      const SizedBox(width: 8),
                      const Text('CARA MENDAPATKAN KODE',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 10,
                          color: Color(0xFF64B5F6), letterSpacing: 1),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ...[
                      '1. Tap tombol DEPOSIT di bawah',
                      '2. Pilih metode pembayaran',
                      '3. Transfer mininmal. Rp 5.000',
                      '4. Upload bukti transfer',
                      '5. Tunggu owner setujui',
                      '6. Saldo masuk → tap DAPATKAN KODE',
                    ].map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(width: 4),
                        Text(t, style: TextStyle(
                          fontFamily: 'ShareTechMono', fontSize: 10,
                          color: const Color(0xFF64B5F6).withOpacity(0.8), height: 1.5)),
                      ]),
                    )),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── MOHON BACA Section ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B0000).withOpacity(0.35),
                        const Color(0xFF1A0000).withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF1744).withOpacity(0.15), blurRadius: 20),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Judul MOHON BACA
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.priority_high_rounded,
                          color: Color(0xFFFF1744), size: 20),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
                        ).createShader(b),
                        child: const Text('MOHON BACA!',
                          style: TextStyle(
                            fontFamily: 'Orbitron', fontSize: 22,
                            fontWeight: FontWeight.bold, color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.4)),
                        ),
                        child: const Text('PENTING',
                          style: TextStyle(fontFamily: 'Orbitron', fontSize: 8,
                            color: Color(0xFFFF1744), letterSpacing: 2),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Badge row 1
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _buildInfoBadge(
                        svgPath: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>',
                        label: 'Donasi untuk server Pegasus',
                        color: const Color(0xFFFF4081),
                      ),
                      _buildInfoBadge(
                        svgPath: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96z"/></svg>',
                        label: 'Bantu biaya VPS & Hosting',
                        color: const Color(0xFF40C4FF),
                      ),
                      _buildInfoBadge(
                        svgPath: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-2 16l-4-4 1.41-1.41L10 14.17l6.59-6.59L18 9l-8 8z"/></svg>',
                        label: 'Sistem tetap online 24/7',
                        color: const Color(0xFF69F0AE),
                      ),
                      _buildInfoBadge(
                        svgPath: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M20 6h-2.18c.07-.31.18-.62.18-1 0-2.21-1.79-4-4-4-1.05 0-1.96.41-2.66 1.05L10 3.41 8.66 2.05C7.96 1.41 7.05 1 6 1 3.79 1 2 2.79 2 5c0 .38.11.69.18 1H0v14h20V6zM12 4c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zM6 3c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm14 15H2v-2h18v2zm0-5H2V8h5.08L5 10.83 6.62 12 9 8.43l1-1.43 1 1.43L13.38 12 15 10.83 12.92 8H18v5z"/></svg>',
                        label: 'Donasi bukan bayar fitur',
                        color: const Color(0xFFFFD740),
                      ),
                      _buildInfoBadge(
                        svgPath: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 6v3l4-4-4-4v3c-4.42 0-8 3.58-8 8 0 1.57.46 3.03 1.24 4.26L6.7 14.8c-.45-.83-.7-1.79-.7-2.8 0-3.31 2.69-6 6-6zm6.76 1.74L17.3 9.2c.44.84.7 1.79.7 2.8 0 3.31-2.69 6-6 6v-3l-4 4 4 4v-3c4.42 0 8-3.58 8-8 0-1.57-.46-3.03-1.24-4.26z"/></svg>',
                        label: 'Update terus dikembangkan',
                        color: const Color(0xFFE040FB),
                      ),
                      _buildInfoBadge(
                        svgPath: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>',
                        label: 'Komunitas Pegasus-X',
                        color: const Color(0xFF00E5FF),
                      ),
                    ]),

                    const SizedBox(height: 14),
                    Container(height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFFFF1744).withOpacity(0.4),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Keterangan
                    Text(
                      '⚠️  Donasi ini digunakan untuk membantu membeli & memperpanjang server agar aplikasi Pegasus tetap berjalan. Tanpa donasi, server bisa mati dan semua fitur tidak akan bisa digunakan.',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 10,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.check_circle_rounded, color: const Color(0xFF69F0AE), size: 13),
                      const SizedBox(width: 6),
                      const Expanded(child: Text(
                        'Setiap donasi sekecil apapun sangat berarti bagi kami.',
                        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10,
                          color: Color(0xFF69F0AE)),
                      )),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.check_circle_rounded, color: const Color(0xFF69F0AE), size: 13),
                      const SizedBox(width: 6),
                      const Expanded(child: Text(
                        'Donasi min. Rp 5.000 akan mendapat kode akses eksklusif.',
                        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10,
                          color: Color(0xFF69F0AE)),
                      )),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Tombol DEPOSIT ──
                GestureDetector(
                  onTap: _openDeposit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12)],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.upload_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('DEPOSIT',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 14,
                          fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Tombol DAPATKAN KODE ──
                GestureDetector(
                  onTap: _loadingKode ? null : _dapatkanKode,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _balance >= _donasiMin
                          ? [const Color(0xFF00E5FF), const Color(0xFF2979FF)]
                          : [Colors.grey.shade800, Colors.grey.shade700],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _balance >= _donasiMin
                        ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.25), blurRadius: 12)]
                        : [],
                    ),
                    child: _loadingKode
                      ? const Center(child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                          Icon(Icons.key_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('DAPATKAN KODE',
                            style: TextStyle(fontFamily: 'Orbitron', fontSize: 14,
                              fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
                        ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Tombol LOGIN DASHBOARD ──
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.5),
                      color: const Color(0xFF00E5FF).withOpacity(0.05),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.login_rounded, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 10),
                      Text('LOGIN DASHBOARD',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 13,
                          fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 2)),
                    ]),
                  ),
                ),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEPOSIT SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _DepositSheet extends StatefulWidget {
  final String username;
  final VoidCallback onSuccess;
  const _DepositSheet({required this.username, required this.onSuccess});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  int _step = 0;
  String? _selectedMethod;
  final _nominalCtrl = TextEditingController();
  String? _proofBase64;
  XFile? _proofFile;
  bool _uploadingProof = false;
  bool _loading = false;

  static const _danaNumber   = '+62 895-2413-4626';
  static const _gopayNumber  = '+62 895-2413-4626';
  static const _ownerName    = 'Pr* Har*****';

  @override
  void dispose() {
    _nominalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() { _uploadingProof = true; _proofFile = file; });
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      setState(() => _proofBase64 = 'data:$mime;base64,${base64Encode(bytes)}');
    } catch (_) {
      setState(() { _proofFile = null; _proofBase64 = null; });
    }
    if (mounted) setState(() => _uploadingProof = false);
  }

  void _copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number.replaceAll(RegExp(r'[\s\-]'), '')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nomor disalin!'), duration: Duration(seconds: 1)));
  }

  Future<void> _submitDeposit() async {
    final nominalStr = _nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = int.tryParse(nominalStr) ?? 0;
    if (nominal < 5000) {
      await showWarning(context, 'Minimal deposit Rp 5.000');
      return;
    }
    if (_proofBase64 == null) {
      await showWarning(context, 'Upload bukti transfer dulu ya');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/donasi/deposit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'amount': nominal,
          'proofBase64': _proofBase64,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        await showSuccess(context, 'Deposit dikirim!\nMenunggu konfirmasi owner.');
      } else if (mounted) {
        await showError(context, data['message'] ?? 'Gagal kirim deposit');
      }
    } catch (_) {
      if (mounted) await showError(context, 'Koneksi error');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Row(children: [
                if (_step > 0) ...[
                  GestureDetector(
                    onTap: () => setState(() => _step = 0),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.accentBlue, size: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(width: 3, height: 20,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text(_step == 0 ? 'Metode Pembayaran' : 'Detail Deposit',
                  style: const TextStyle(fontFamily: 'Orbitron', fontSize: 15,
                    fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              ]),
              const SizedBox(height: 14),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: _step == 0 ? _buildMethodStep() : _buildFormStep(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMethodStep() {
    return Column(children: [
      _buildQrisCard(),
      const SizedBox(height: 12),
      _buildEwalletCard('Dana',  Icons.account_balance_wallet_rounded, const Color(0xFF3B82F6), _danaNumber),
      const SizedBox(height: 12),
      _buildEwalletCard('GoPay', Icons.payment_rounded, const Color(0xFF10B981), _gopayNumber),
    ]);
  }

  Widget _buildQrisCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4)),
        color: const Color(0xFF06B6D4).withOpacity(0.05),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.qr_code_rounded,
                color: Color(0xFF06B6D4), size: 22))),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QRIS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14,
                fontWeight: FontWeight.bold, color: Color(0xFF06B6D4))),
              Text('Scan QR untuk transfer', style: TextStyle(
                fontFamily: 'ShareTechMono', fontSize: 11, color: AppTheme.textMuted)),
            ])),
          ]),
        ),
        GestureDetector(
          onTap: _showQrisDialog,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
              color: AppTheme.cardBg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network('${ApiService.baseUrl}/qris.jpg',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.qr_code_2_rounded, size: 56, color: Color(0xFF06B6D4)))),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GestureDetector(
            onTap: () { _selectedMethod = 'QRIS'; setState(() => _step = 1); },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
              ),
              child: const Center(child: Text('SUDAH TRANSFER',
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 11,
                  color: Colors.white, letterSpacing: 1))),
            ),
          ),
        ),
      ]),
    );
  }

  void _showQrisDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF06B6D4).withOpacity(0.4))),
        title: const Text('QRIS', style: TextStyle(
          fontFamily: 'Orbitron', fontSize: 13, color: Color(0xFF06B6D4))),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network('${ApiService.baseUrl}/qris.jpg',
            errorBuilder: (_, __, ___) => const SizedBox(height: 200,
              child: Center(child: Icon(Icons.qr_code_2_rounded,
                size: 80, color: Color(0xFF06B6D4))))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(
              fontFamily: 'Orbitron', color: AppTheme.accentBlue))),
        ],
      ),
    );
  }

  Widget _buildEwalletCard(String name, IconData icon, Color color, String number) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        color: color.withOpacity(0.05),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, color: color, size: 22))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontFamily: 'Orbitron', fontSize: 14,
              fontWeight: FontWeight.bold, color: color)),
            Text('a/n $_ownerName', style: const TextStyle(
              fontFamily: 'ShareTechMono', fontSize: 11, color: AppTheme.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.cardBg,
            border: Border.all(color: color.withOpacity(0.3))),
          child: Row(children: [
            Expanded(child: Text(number, style: TextStyle(
              fontFamily: 'ShareTechMono', fontSize: 14,
              color: color, fontWeight: FontWeight.bold))),
            GestureDetector(
              onTap: () => _copyNumber(number),
              child: Icon(Icons.copy_rounded, color: color.withOpacity(0.7), size: 18)),
          ]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { _selectedMethod = name; setState(() => _step = 1); },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            ),
            child: const Center(child: Text('SUDAH TRANSFER',
              style: TextStyle(fontFamily: 'Orbitron', fontSize: 11,
                color: Colors.white, letterSpacing: 1))),
          ),
        ),
      ]),
    );
  }

  Widget _buildFormStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_selectedMethod != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF10B981).withOpacity(0.1),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3))),
          child: Text('Metode: $_selectedMethod',
            style: const TextStyle(fontFamily: 'ShareTechMono',
              fontSize: 11, color: Color(0xFF10B981))),
        ),
      const SizedBox(height: 16),
      const Text('Nominal Transfer',
        style: TextStyle(fontFamily: 'Orbitron', fontSize: 12,
          color: Colors.white, letterSpacing: 1)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
          color: AppTheme.cardBg),
        child: TextField(
          controller: _nominalCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'ShareTechMono', color: Colors.white),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(fontFamily: 'ShareTechMono', color: AppTheme.textMuted),
            hintText: '5000',
            hintStyle: TextStyle(fontFamily: 'ShareTechMono',
              color: AppTheme.textMuted.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Bukti Transfer',
        style: TextStyle(fontFamily: 'Orbitron', fontSize: 12,
          color: Colors.white, letterSpacing: 1)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _uploadingProof ? null : _pickProof,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _proofBase64 != null
                ? Colors.green.withOpacity(0.6)
                : AppTheme.primaryBlue.withOpacity(0.4),
              width: 1.5),
            color: AppTheme.cardBg,
          ),
          child: _uploadingProof
            ? const Padding(padding: EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)),
                  SizedBox(height: 8),
                  Text('Memuat gambar...',
                    style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: Colors.orange)),
                ]))
            : _proofFile != null
              ? Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(File(_proofFile!.path),
                      width: double.infinity, height: 160, fit: BoxFit.cover),
                  ),
                  Positioned(top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Terpilih', style: TextStyle(
                          fontFamily: 'ShareTechMono', fontSize: 9, color: Colors.white)),
                      ]),
                    )),
                  Positioned(bottom: 8, right: 8,
                    child: GestureDetector(
                      onTap: _pickProof,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Ganti', style: TextStyle(
                            fontFamily: 'ShareTechMono', fontSize: 9, color: Colors.white)),
                        ]),
                      ))),
                ])
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.upload_rounded,
                      color: AppTheme.primaryBlue.withOpacity(0.7), size: 32),
                    const SizedBox(height: 6),
                    const Text('Tap untuk upload bukti transfer',
                      style: TextStyle(fontFamily: 'ShareTechMono',
                        fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('JPG / PNG dari galeri',
                      style: TextStyle(fontFamily: 'ShareTechMono',
                        fontSize: 9, color: AppTheme.textMuted.withOpacity(0.5))),
                  ]),
                ),
        ),
      ),
      const SizedBox(height: 28),
      GestureDetector(
        onTap: _loading ? null : _submitDeposit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          ),
          child: Center(child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('KIRIM DEPOSIT',
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 12,
                  color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold))),
        ),
      ),
    ]);
  }
}