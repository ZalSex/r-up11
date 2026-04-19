import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../utils/theme.dart';
import '../../utils/notif_helper.dart';
import '../../utils/app_localizations.dart';
import '../../utils/role_style.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class BugTab extends StatefulWidget {
  const BugTab({super.key});

  @override
  State<BugTab> createState() => _BugTabState();
}

class _BugTabState extends State<BugTab> with WidgetsBindingObserver, TickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedSenderId;
  String? _selectedSenderPhone;
  List<String> _selectedSenderIds = [];
  bool _selectAll = false;
  List<Map<String, dynamic>> _senders = [];
  bool _loadingSenders = false;
  String _username = '';
  String _role = 'member';
  String? _avatarBase64;

  late AnimationController _rotateCtrl;
  late Animation<double> _rotateAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  final _targetCtrl = TextEditingController();
  bool _executing   = false;
  bool _showHeartbeat = false;
  int? _selectedMethod;

  String? _currentJobId;
  Timer? _pollTimer;
  String _jobStatus = '';
  int _jobProgress = 0;
  int _jobTotal = 0;
  String _jobError = '';

  static const String _heartbeatIcon = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>';

  static const String _iconCamera   = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>';
  static const String _iconBolt     = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>';
  static const String _iconWave     = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></svg>';
  static const String _iconContact  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
  static const String _iconSticker  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg>';
  static const String _iconCrashSpam  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/></svg>';
  static const String _iconCrashClick = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 9s-1-1 0-2l2.5-2.5c1-1 2 0 2 0"/><path d="m13 13 3.5 3.5c1 1 1 2 0 2L14 21c-1 1-2 0-2 0"/><path d="M9.5 14.5 3 21"/><path d="m11 11-1.5-1.5"/><path d="M14.5 7 21 3"/><path d="m13 9 1.5 1.5"/></svg>';
  static const String _iconXCrash     = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/><path d="M15 9h-4a2 2 0 0 0 0 4h2a2 2 0 0 1 0 4H9"/></svg>';
  static const String _iconForceClick = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3H14z"/><path d="M7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg>';

  static const List<Map<String, dynamic>> _methods = [
    {'id': 'forclose_invisible', 'title': 'Forclose Invisible', 'desc': 'Force Close WhatsApp Target Dengan Invisible Payload', 'icon': _heartbeatIcon,    'color': Color(0xFFFF2D55)},
    {'id': 'crash_spam',         'title': 'Crash Spam',         'desc': 'Spam Quote Payload Untuk Crash WhatsApp Target',                    'icon': _iconCrashSpam,  'color': Color(0xFFFF6B00)},
    {'id': 'crash_click',        'title': 'Crash Click',        'desc': 'Kirim Quote Payload Sekali Untuk Instant Crash',                    'icon': _iconCrashClick, 'color': Color(0xFFFFB800)},
    {'id': 'invisible',          'title': 'Invisible Delay',    'desc': 'Kirim Pesan Payload Tak Terlihat Untuk Delay', 'icon': AppSvgIcons.eye,   'color': Color(0xFF8B5CF6)},
    {'id': 'stickerpack',        'title': 'Sticker Blank',      'desc': 'Spam Sticker Blank Overflow WhatsApp Target',       'icon': AppSvgIcons.smile, 'color': Color(0xFFF59E0B)},
    {'id': 'trash',              'title': 'Button Invis',       'desc': 'Kirim Button Invisible Untuk Crash UI',        'icon': AppSvgIcons.trash, 'color': Color(0xFFEC4899)},
    {'id': 'bulldozer',          'title': 'Contact Delay',      'desc': 'Spam Contact Message Dengan Payload Besar',    'icon': AppSvgIcons.drain, 'color': Color(0xFF06B6D4)},
    {'id': 'iosinvisible',       'title': 'Invisible iOS',      'desc': 'Invisible Force Khusus Device iOS',            'icon': AppSvgIcons.zap,   'color': Color(0xFF10B981)},
    {'id': 'iphonecursed',       'title': 'iPhone Cursed',      'desc': 'Exploit Khusus iPhone Dengan Pesan Cursed',    'icon': AppSvgIcons.skull, 'color': Color(0xFFEF4444)},
    {'id': 'delay_photo',        'title': 'Delay Photo',        'desc': 'Carousel Photo Dengan Payload Card Besar',  'icon': _iconCamera,       'color': Color(0xFF3B82F6)},
    {'id': 'delay_xforce',       'title': 'Delay X Force',      'desc': 'Kirim Pesan Payload Tak Terlihat Yang Menyebabkan Delay + Forclose',      'icon': _iconBolt,         'color': Color(0xFFE11D48)},
    {'id': 'blank_delay',        'title': 'Blank Delay',        'desc': 'Kirim Button Dengan Corrupt Besar Di Tambah Payload Tak Terlihat Buat Delay',     'icon': _iconWave,         'color': Color(0xFF7C3AED)},
    {'id': 'invis_delay_v2',     'title': 'Invisible Delay V2', 'desc': 'Kirim Kontak Dengan Payload Tak Terlihat',    'icon': _iconContact,      'color': Color(0xFF059669)},
    {'id': 'sticker_delay',      'title': 'Sticker Delay',      'desc': 'Sticker Corrupt Dengan Invisible Payload Delay',   'icon': _iconSticker,      'color': Color(0xFFD97706)},
  ];

  final _groupTargetCtrl = TextEditingController();
  bool _executingGroup   = false;
  bool _showHeartbeatGroup = false;
  int? _selectedGroupMethod;

  String? _currentGroupJobId;
  Timer? _pollGroupTimer;
  String _groupJobStatus = '';
  int _groupJobProgress = 0;
  int _groupJobTotal = 0;
  String _groupJobError = '';

  static const List<Map<String, dynamic>> _groupMethods = [
    {'id': 'group_xcrash_spam',    'title': 'XCrash Spam',   'desc': 'Spam Quote Payload Untuk Crash WhatsApp Grup Target',              'icon': _iconXCrash,     'color': Color(0xFFFF4500)},
    {'id': 'group_force_click',   'title': 'Force Click',   'desc': 'Kirim Quote Payload Untuk Force Crash Grup WhatsApp',                'icon': _iconForceClick, 'color': Color(0xFFFF8C00)},
    {'id': 'group_visible_delay',  'title': 'Visible Delay', 'desc': 'Kirim Payload Visible Untuk Delay WhatsApp Grup Target',      'icon': AppSvgIcons.eye,   'color': Color(0xFF8B5CF6)},
    {'id': 'group_trash_button',   'title': 'Trash Button',  'desc': 'Kirim Button Invisible Untuk Crash UI Grup WhatsApp',         'icon': AppSvgIcons.trash,  'color': Color(0xFFEC4899)},
    {'id': 'group_crash_delay',    'title': 'Forclose Mention',   'desc': 'Spam Payload Besar Untuk Force Close WhatsApp Grup Target',   'icon': AppSvgIcons.zap,    'color': Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadSenders();
    _loadProfile();

    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _rotateAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_rotateCtrl);

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_glowCtrl);
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? '';
        _role = prefs.getString('role') ?? 'member';
        _avatarBase64 = prefs.getString('avatar');
      });
      final res = await ApiService.getProfile();
      if (res['success'] == true && mounted) {
        setState(() {
          _username = res['user']['username'] ?? _username;
          _role = res['user']['role'] ?? _role;
          _avatarBase64 = res['user']['avatar'] ?? _avatarBase64;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _targetCtrl.dispose();
    _groupTargetCtrl.dispose();
    _pollTimer?.cancel();
    _pollGroupTimer?.cancel();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadSenders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSenders();
  }

  Future<void> _loadSenders() async {
    if (_loadingSenders) return;
    if (mounted) setState(() => _loadingSenders = true);
    try {
      final res = await ApiService.getSenders();
      if (res['success'] == true && mounted) {
        final newSenders = List<Map<String, dynamic>>.from(res['senders'] ?? []);
        setState(() {
          _senders = newSenders;
          if (_selectedSenderId != null) {
            final found = newSenders.where((s) => s['id'] == _selectedSenderId).toList();
            if (found.isEmpty) {
              _selectedSenderId = null;
              _selectedSenderPhone = null;
            } else {
              final isOnline = found.first['status'] == 'online' || found.first['status'] == 'connected';
              if (!isOnline) {
                _selectedSenderId = null;
                _selectedSenderPhone = null;
              }
            }
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSenders = false);
  }

  Future<void> _startPolling(String jobId, {bool isGroup = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final timer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted) { t.cancel(); return; }
      try {
        final res = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/bug/job/$jobId'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));

        final json = jsonDecode(res.body);
        if (!mounted) { t.cancel(); return; }

        if (json['success'] == true) {
          final status   = json['status'] as String? ?? 'running';
          final progress = json['progress'] as int? ?? 0;
          final total    = json['total'] as int? ?? 0;
          final error    = json['error'] as String?;
          final done     = json['done'] as bool? ?? false;

          setState(() {
            if (isGroup) {
              _groupJobStatus   = status;
              _groupJobProgress = progress;
              _groupJobTotal    = total;
              _groupJobError    = error ?? '';
            } else {
              _jobStatus   = status;
              _jobProgress = progress;
              _jobTotal    = total;
              _jobError    = error ?? '';
            }
          });

          if (done) {
            t.cancel();
            if (isGroup) {
              _pollGroupTimer = null;
              setState(() { _executingGroup = false; _currentGroupJobId = null; });
            } else {
              _pollTimer = null;
              setState(() { _executing = false; _currentJobId = null; });
            }

            if (error != null && error.isNotEmpty) {
              _showSnack('Error: $error', isError: true);
            } else {
              _showSnack('Bug Selesai Dikirim ($progress/$total Berhasil)', isSuccess: true);
            }
          }
        }
      } catch (_) {}
    });

    if (isGroup) {
      _pollGroupTimer?.cancel();
      _pollGroupTimer = timer;
    } else {
      _pollTimer?.cancel();
      _pollTimer = timer;
    }
  }

  void _showSenderPicker() async {
    await _loadSenders();
    if (!mounted) return;
    // temp selection state inside sheet
    final tempSelected = <String>{..._selectedSenderIds};
    bool tempSelectAll = _selectAll;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final onlineSenders = _senders.where((s) => s['status'] == 'online' || s['status'] == 'connected').toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(width: 3, height: 18,
                            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(2))),
                        SizedBox(width: 10),
                        Text(tr('pick_sender'), style: TextStyle(fontFamily: 'Orbitron', color: Colors.white,
                            fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      ]),
                      GestureDetector(
                        onTap: () async { await _loadSenders(); setSheet(() {}); },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _loadingSenders
                              ? SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryBlue))
                              : const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.only(left: 13),
                    child: Text('Pilih satu atau lebih sender aktif',
                        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppTheme.textMuted)),
                  ),
                  SizedBox(height: 12),
                  // Select All row
                  if (_senders.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setSheet(() {
                          tempSelectAll = !tempSelectAll;
                          if (tempSelectAll) {
                            tempSelected.addAll(onlineSenders.map((s) => s['id'] as String));
                          } else {
                            tempSelected.removeAll(onlineSenders.map((s) => s['id'] as String));
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: tempSelectAll
                              ? LinearGradient(colors: [AppTheme.primaryBlue.withOpacity(0.3), AppTheme.primaryBlue.withOpacity(0.08)])
                              : null,
                          color: tempSelectAll ? null : AppTheme.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: tempSelectAll ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.25),
                            width: tempSelectAll ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tempSelectAll ? AppTheme.primaryBlue : Colors.transparent,
                                border: Border.all(color: tempSelectAll ? AppTheme.primaryBlue : AppTheme.textMuted),
                              ),
                              child: tempSelectAll
                                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(width: 12),
                            Text('Select All (${onlineSenders.length} online)',
                                style: TextStyle(fontFamily: 'Orbitron', fontSize: 11,
                                    color: tempSelectAll ? Colors.white : AppTheme.textSecondary, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  if (_senders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(tr('no_sender_connected'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppTheme.textMuted, height: 1.6)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        shrinkWrap: true,
                        itemCount: _senders.length,
                        itemBuilder: (_, i) {
                          final s = _senders[i];
                          final isOnline = s['status'] == 'online' || s['status'] == 'connected';
                          final isSelected = tempSelected.contains(s['id']);
                          return GestureDetector(
                            onTap: isOnline ? () {
                              setSheet(() {
                                if (isSelected) {
                                  tempSelected.remove(s['id']);
                                } else {
                                  tempSelected.add(s['id'] as String);
                                }
                                tempSelectAll = tempSelected.containsAll(onlineSenders.map((s) => s['id'] as String));
                              });
                            } : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(colors: [AppTheme.primaryBlue.withOpacity(0.25), AppTheme.primaryBlue.withOpacity(0.05)])
                                    : AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.2),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isOnline ? Colors.green.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
                                    ),
                                    child: Center(
                                      child: SvgPicture.string(AppSvgIcons.mobile, width: 20, height: 20,
                                          colorFilter: ColorFilter.mode(isOnline ? Colors.green : Colors.grey, BlendMode.srcIn)),
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('+${s['phone'] ?? s['id']}',
                                            style: TextStyle(fontFamily: 'Orbitron', fontSize: 13,
                                                color: isOnline ? Colors.white : AppTheme.textMuted, letterSpacing: 0.5)),
                                        SizedBox(height: 3),
                                        Row(children: [
                                          Container(width: 6, height: 6,
                                              decoration: BoxDecoration(shape: BoxShape.circle,
                                                  color: isOnline ? Colors.green : Colors.grey)),
                                          SizedBox(width: 6),
                                          Text(isOnline ? tr('sender_terhubung') : 'Terputus',
                                              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10,
                                                  color: isOnline ? Colors.green : Colors.grey, letterSpacing: 1)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                                      border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted.withOpacity(0.4)),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 14),
                  // Confirm button
                  GestureDetector(
                    onTap: tempSelected.isEmpty ? null : () {
                      setState(() {
                        _selectedSenderIds = tempSelected.toList();
                        _selectAll = tempSelectAll;
                        // set _selectedSenderId to first for display
                        _selectedSenderId = _selectedSenderIds.first;
                        final found = _senders.where((s) => s['id'] == _selectedSenderId).toList();
                        _selectedSenderPhone = found.isNotEmpty ? (found.first['phone'] ?? found.first['id']) : _selectedSenderId;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: tempSelected.isEmpty ? null : AppTheme.primaryGradient,
                        color: tempSelected.isEmpty ? AppTheme.primaryBlue.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tempSelected.isEmpty
                            ? AppTheme.primaryBlue.withOpacity(0.2)
                            : AppTheme.primaryBlue),
                      ),
                      child: Center(
                        child: Text(
                          tempSelected.isEmpty
                              ? 'Pilih Sender Dulu'
                              : 'Konfirmasi ${tempSelected.length} Sender',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            letterSpacing: 1.5,
                            color: tempSelected.isEmpty ? AppTheme.textMuted : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBanned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 10),
          Text('AKUN DIBANNED', style: TextStyle(
            fontFamily: 'Orbitron', fontSize: 13, color: Colors.redAccent, letterSpacing: 2)),
        ]),
        content: const Text(
          'Akun kamu telah dibanned karena mencoba bug nomor/grup yang dilindungi oleh owner.\n\nKamu tidak bisa login lagi.',
          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: Color(0xFF64B5F6), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('OK', style: TextStyle(color: Colors.redAccent, fontFamily: 'Orbitron')),
          ),
        ],
      ),
    );
  }

  bool _isValidPhoneNumber(String input) {
    // Tolak jika ada +, spasi, atau -
    if (input.contains('+') || input.contains(' ') || input.contains('-')) return false;
    // Harus semua angka, support semua kode negara
    return RegExp(r'^\d+$').hasMatch(input);
  }

  Future<void> _execute() async {
    final activeSenders = <String>[...(_selectAll
        ? _senders.where((s) => s['status'] == 'online' || s['status'] == 'connected').map((s) => s['id'] as String).toList()
        : _selectedSenderIds.isNotEmpty ? _selectedSenderIds : (_selectedSenderId != null ? [_selectedSenderId!] : []))];

    if (activeSenders.isEmpty) { _showSnack('Pilih Sender Terlebih Dahulu'); return; }
    if (_selectedMethod == null) { _showSnack('Pilih Metode Bug'); return; }
    final rawTarget = _targetCtrl.text.trim();
    if (rawTarget.isEmpty) { _showSnack('Masukkan Nomer Target'); return; }
    if (!_isValidPhoneNumber(rawTarget)) {
      _showSnack('Format Salah! Gunakan Angka Saja Tanpa +/Spasi/-', isError: true);
      return;
    }
    const count = 1;

    setState(() { _executing = true; _showHeartbeat = true; _jobStatus = 'running'; _jobError = ''; });

    try {
      final method = _methods[_selectedMethod!]['id'] as String;
      final res = activeSenders.length > 1
          ? await ApiService.executeBugMulti(
              senderIds: activeSenders, target: rawTarget,
              method: method, count: count,
            )
          : await ApiService.executeBug(
              senderId: activeSenders.first, target: rawTarget,
              method: method, count: count,
            );

      if (res['banned'] == true) {
        setState(() { _executing = false; _showHeartbeat = false; _jobStatus = 'error'; });
        _handleBanned();
        return;
      }

      if (res['success'] != true) {
        setState(() { _executing = false; _showHeartbeat = false; _jobStatus = 'error'; });
        _showSnack(res['message'] ?? 'Gagal Mengirim Bug', isError: true);
        return;
      }

      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() { _executing = false; _showHeartbeat = false; _jobStatus = ''; });
      _showSnack('Bug Berhasil Dikirim Dari ${activeSenders.length} Sender!', isSuccess: true);
    } catch (_) {
      setState(() { _executing = false; _showHeartbeat = false; _jobStatus = 'error'; });
      _showSnack('Koneksi Gagal Ke Server', isError: true);
    }
  }

  Future<void> _executeGroup() async {
    final activeSenders = <String>[...(_selectAll
        ? _senders.where((s) => s['status'] == 'online' || s['status'] == 'connected').map((s) => s['id'] as String).toList()
        : _selectedSenderIds.isNotEmpty ? _selectedSenderIds : (_selectedSenderId != null ? [_selectedSenderId!] : []))];

    if (activeSenders.isEmpty)        { _showSnack('Pilih Sender Terlebih Dahulu'); return; }
    if (_selectedGroupMethod == null) { _showSnack('Pilih Metode Bug Grup'); return; }
    if (_groupTargetCtrl.text.isEmpty){ _showSnack('Masukkan ID Grup Target'); return; }
    const count = 1;

    setState(() { _executingGroup = true; _showHeartbeatGroup = true; _groupJobStatus = 'running'; _groupJobError = ''; });

    try {
      final method = _groupMethods[_selectedGroupMethod!]['id'] as String;
      final res = activeSenders.length > 1
          ? await ApiService.executeBugGroupMulti(
              senderIds: activeSenders, target: _groupTargetCtrl.text.trim(),
              method: method, count: count,
            )
          : await ApiService.executeBugGroup(
              senderId: activeSenders.first, target: _groupTargetCtrl.text.trim(),
              method: method, count: count,
            );

      if (res['banned'] == true) {
        setState(() { _executingGroup = false; _showHeartbeatGroup = false; _groupJobStatus = 'error'; });
        _handleBanned();
        return;
      }

      if (res['success'] != true) {
        setState(() { _executingGroup = false; _showHeartbeatGroup = false; _groupJobStatus = 'error'; });
        _showSnack(res['message'] ?? 'Gagal Mengirim Bug Grup', isError: true);
        return;
      }

      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() { _executingGroup = false; _showHeartbeatGroup = false; _groupJobStatus = ''; });
      _showSnack('Bug Grup Dikirim Dari ${activeSenders.length} Sender!', isSuccess: true);
    } catch (_) {
      setState(() { _executingGroup = false; _showHeartbeatGroup = false; _groupJobStatus = 'error'; });
      _showSnack('Koneksi Gagal Ke Server', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    if (isError) {
      showError(context, msg);
    } else if (isSuccess) {
      showSuccess(context, msg);
    } else {
      showWarning(context, msg);
    }
  }

  void _showSuccessVideo() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => const _SuccessVideoDialog(),
    );
  }

  Widget _buildJobStatus({bool isGroup = false}) => const SizedBox.shrink();

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileBadge(),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.6), width: 1.5),
                boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 14, spreadRadius: 1)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _BannerSlider(),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(width: 3, height: 20,
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(2))),
                  SizedBox(width: 10),
                  Text(tr('bug_wa'), style: TextStyle(fontFamily: 'Orbitron', fontSize: 18,
                      fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                ]),
                GestureDetector(
                  onTap: _loadSenders,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _loadingSenders
                        ? SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryBlue))
                        : const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPurpleLabel(tr('pick_sender')),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _showSenderPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedSenderId != null ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _selectedSenderId != null ? Colors.green.withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedSenderId != null ? Colors.green.withOpacity(0.4) : AppTheme.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: SvgPicture.string(AppSvgIcons.phone, width: 18, height: 18,
                            colorFilter: ColorFilter.mode(
                                _selectedSenderId != null ? Colors.green : AppTheme.textMuted, BlendMode.srcIn)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSenderIds.length > 1
                                ? '${_selectedSenderIds.length} Sender Dipilih'
                                : _selectedSenderId != null
                                    ? '+${_selectedSenderPhone ?? _selectedSenderId}'
                                    : 'Pilih Nomer Sender...',
                            style: TextStyle(
                                fontFamily: _selectedSenderId != null ? 'Orbitron' : 'ShareTechMono',
                                fontSize: _selectedSenderId != null ? 13 : 12,
                                color: _selectedSenderId != null ? Colors.white : AppTheme.textMuted,
                                letterSpacing: _selectedSenderId != null ? 0.5 : 0),
                          ),
                          if (_selectedSenderId != null) ...[
                            SizedBox(height: 2),
                            Row(children: [
                              Container(width: 5, height: 5,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                              SizedBox(width: 5),
                              Text(
                                _selectedSenderIds.length > 1 ? 'Multi Sender Aktif' : tr('sender_terhubung'),
                                style: TextStyle(fontFamily: 'ShareTechMono',
                                    fontSize: 9, color: Colors.green, letterSpacing: 1)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 22),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'BUG NOMER', AppSvgIcons.mobile),
                  _buildTabButton(1, 'BUG GROUP', AppSvgIcons.group),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final isGroup = _tabController.index == 1;
          return isGroup ? _buildGroupScrollView() : _buildNomerScrollView();
        },
      ),
    );
  }

  Widget _buildNomerScrollView() {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPurpleLabel('Nomer Target'),
                SizedBox(height: 8),
                TextFormField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                  decoration: InputDecoration(
                    hintText: '628xxx / 1234xxx / 44xxxx',
                    hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 13),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.string(AppSvgIcons.mobile, width: 18, height: 18,
                          colorFilter: const ColorFilter.mode(AppTheme.textSecondary, BlendMode.srcIn)),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (_showHeartbeat)
          SliverToBoxAdapter(child: _buildHeartbeatLoader())
        else
          SliverToBoxAdapter(child: _buildMethodScrollCards()),
        SliverToBoxAdapter(child: _buildSendButton(_executing, _selectedMethod, _execute, 'SEND BUG NOMER')),
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90)),
      ],
    );
  }

  Widget _buildGroupScrollView() {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPurpleLabel('Link Grup Target'),
                SizedBox(height: 8),
                TextFormField(
                  controller: _groupTargetCtrl,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                  decoration: InputDecoration(
                    hintText: 'https://chat.whatsapp.com/xxxx',
                    hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 12),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.string(AppSvgIcons.group, width: 18, height: 18,
                          colorFilter: const ColorFilter.mode(AppTheme.textSecondary, BlendMode.srcIn)),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (_showHeartbeatGroup)
          SliverToBoxAdapter(child: _buildHeartbeatLoader())
        else
          SliverToBoxAdapter(child: _buildGroupMethodScrollCards()),
        SliverToBoxAdapter(child: _buildSendButton(_executingGroup, _selectedGroupMethod, _executeGroup, 'SEND BUG GROUP')),
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90)),
      ],
    );
  }

  Widget _buildHeartbeatLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFF2D55).withOpacity(0.25), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid lines background
              CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _GridPainter(),
              ),
              // Heartbeat line
              _HeartbeatLine(),
              // Text below
              Positioned(
                bottom: 16,
                child: Text(
                  'MENGIRIM BUG...',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: Color(0xFFFF2D55),
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, String icon) {
    final isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabController.animateTo(index)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 8)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(icon, width: 14, height: 14,
                  colorFilter: ColorFilter.mode(isActive ? Colors.white : AppTheme.textMuted, BlendMode.srcIn)),
              SizedBox(width: 6),
              Text(label, style: TextStyle(fontFamily: 'Orbitron', fontSize: 11,
                  fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppTheme.textMuted, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSendButton(bool executing, int? selected, VoidCallback onTap, String label) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: executing || selected == null ? null : AppTheme.primaryGradient,
          color: executing || selected == null ? AppTheme.primaryBlue.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: executing || selected == null ? [] : [
            BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 4))
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: executing || selected == null ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          icon: executing
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"/><path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/><path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0"/><path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"/></svg>',
                  width: 18, height: 18,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
          label: Text(executing ? 'Mengirim...' : label,
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildProfileBadge() {
    return Container(
      width: double.infinity,
      height: 120,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.6)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: badge.jpg
          Image.asset(
            'assets/icons/badge.jpg',
            fit: BoxFit.cover,
          ),
          // Dark overlay tipis
          Container(
            color: Colors.black.withOpacity(0.30),
          ),
          // Content row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // === Foto user — border biru seperti login, rotating ===
                RoleStyle.instagramPhoto(
                  assetPath: _avatarBase64 == null ? 'assets/icons/revenge.jpg' : null,
                  customImage: _avatarBase64 != null ? Image.memory(base64Decode(_avatarBase64!), fit: BoxFit.cover) : null,
                  colors: RoleStyle.loginBorderColors,
                  rotateAnim: _rotateAnim,
                  glowAnim: _glowAnim,
                  size: 56,
                  borderWidth: 2.5,
                  innerPad: 2,
                  fallback: Container(color: AppTheme.primaryBlue.withOpacity(0.3),
                    child: Center(child: SvgPicture.string(AppSvgIcons.user, width: 26, height: 26,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))),
                ),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_username.isEmpty ? '...' : _username,
                    style: const TextStyle(fontFamily: 'Orbitron', fontSize: 14,
                        fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  SizedBox(height: 6),
                  // === Badge role sesuai warna ===
                  RoleStyle.roleBadge(_role),
                ])),
                Container(width: 9, height: 9,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green,
                    boxShadow: [BoxShadow(color: Colors.green, blurRadius: 6)])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: AppTheme.textMuted, letterSpacing: 2));
  }

  Widget _buildPurpleLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0068b1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0068b1), width: 1.4),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 12,
          color: Colors.white,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMethodCard(int index) {
    final method = _methods[index];
    final isSelected = _selectedMethod == index;
    final color = method['color'] as Color;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = isSelected ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)])
              : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppTheme.primaryBlue.withOpacity(0.25), width: isSelected ? 1.5 : 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Center(child: SvgPicture.string(method['icon'] as String, width: 22, height: 22,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn))),
            ),
            SizedBox(width: 14),
            Expanded(child: Text(method['title'] as String,
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.white, letterSpacing: 0.5))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(color: isSelected ? color : AppTheme.textMuted, width: 1.5),
              ),
              child: isSelected
                  ? Center(child: SvgPicture.string(AppSvgIcons.zap, width: 11, height: 11,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ID bug yang dikunci
  static const _lockedIds = {'forclose_invisible', 'delay_xforce', 'crash_spam'};
  static const _groupLockedIds = {'group_force_click', 'group_crash_delay'};

  static const _svgLockChain = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/><circle cx="12" cy="16" r="1"/><path d="M9 11h6"/></svg>';

  Widget _buildMethodScrollCards() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPurpleLabel('Pilih Metode'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _methods.length,
              itemBuilder: (_, i) {
                final method    = _methods[i];
                final isSelected = _selectedMethod == i;
                final color     = method['color'] as Color;
                final isLocked  = _lockedIds.contains(method['id'] as String);
                return GestureDetector(
                  onTap: isLocked ? null : () => setState(() => _selectedMethod = isSelected ? null : i),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 148,
                        margin: EdgeInsets.only(right: i < _methods.length - 1 ? 12 : 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [color.withOpacity(0.3), color.withOpacity(0.08)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : const LinearGradient(
                                  colors: [Color(0xFF0D1B2A), Color(0xFF0A1628)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLocked ? color.withOpacity(0.15) : (isSelected ? color : color.withOpacity(0.25)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(isLocked ? 0.06 : 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: color.withOpacity(isLocked ? 0.15 : 0.4)),
                                  ),
                                  child: Center(
                                    child: SvgPicture.string(
                                      method['icon'] as String,
                                      width: 20, height: 20,
                                      colorFilter: ColorFilter.mode(
                                        color.withOpacity(isLocked ? 0.3 : 1.0),
                                        BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? color : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? color : AppTheme.textMuted.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(child: SvgPicture.string(AppSvgIcons.zap, width: 10, height: 10,
                                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              method['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? color.withOpacity(0.3) : color,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                method['desc'] as String,
                                style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(isLocked ? 0.2 : 0.55),
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Overlay hitam samar + icon kunci+rantai di tengah
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            margin: EdgeInsets.only(right: i < _methods.length - 1 ? 12 : 0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(
                                    _svgLockChain,
                                    width: 28, height: 28,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.7), BlendMode.srcIn),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'LOCKED',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 8,
                                      color: Colors.white.withOpacity(0.5),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMethodScrollCards() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPurpleLabel('Pilih Metode'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _groupMethods.length,
              itemBuilder: (_, i) {
                final method      = _groupMethods[i];
                final isSelected  = _selectedGroupMethod == i;
                final color       = method['color'] as Color;
                final isLocked    = _groupLockedIds.contains(method['id'] as String);
                return GestureDetector(
                  onTap: isLocked ? null : () => setState(() => _selectedGroupMethod = isSelected ? null : i),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 148,
                        margin: EdgeInsets.only(right: i < _groupMethods.length - 1 ? 12 : 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [color.withOpacity(0.3), color.withOpacity(0.08)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : const LinearGradient(
                                  colors: [Color(0xFF0D1B2A), Color(0xFF0A1628)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLocked ? color.withOpacity(0.15) : (isSelected ? color : color.withOpacity(0.25)),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(isLocked ? 0.06 : 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: color.withOpacity(isLocked ? 0.15 : 0.4)),
                                  ),
                                  child: Center(
                                    child: SvgPicture.string(
                                      method['icon'] as String,
                                      width: 20, height: 20,
                                      colorFilter: ColorFilter.mode(
                                        color.withOpacity(isLocked ? 0.3 : 1.0), BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? color : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? color : AppTheme.textMuted.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: SvgPicture.string(AppSvgIcons.zap, width: 10, height: 10,
                                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              method['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? color.withOpacity(0.3) : color,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                method['desc'] as String,
                                style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(isLocked ? 0.2 : 0.55),
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Overlay locked
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            margin: EdgeInsets.only(right: i < _groupMethods.length - 1 ? 12 : 0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(
                                    _svgLockChain,
                                    width: 28, height: 28,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.7), BlendMode.srcIn),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'LOCKED',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 8,
                                      color: Colors.white.withOpacity(0.5),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMethodCard(int index) {
    final method = _groupMethods[index];
    final isSelected = _selectedGroupMethod == index;
    final color = method['color'] as Color;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroupMethod = isSelected ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)])
              : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppTheme.primaryBlue.withOpacity(0.25), width: isSelected ? 1.5 : 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Center(child: SvgPicture.string(method['icon'] as String, width: 22, height: 22,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn))),
            ),
            SizedBox(width: 14),
            Expanded(child: Text(method['title'] as String,
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.white, letterSpacing: 0.5))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(color: isSelected ? color : AppTheme.textMuted, width: 1.5),
              ),
              child: isSelected
                  ? Center(child: SvgPicture.string(AppSvgIcons.zap, width: 11, height: 11,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Painter ────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF2D55).withOpacity(0.07)
      ..strokeWidth = 0.5;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─── Heartbeat Line ───────────────────────────────────────────────────────────
class _HeartbeatLine extends StatefulWidget {
  const _HeartbeatLine();
  @override
  State<_HeartbeatLine> createState() => _HeartbeatLineState();
}

class _HeartbeatLineState extends State<_HeartbeatLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _HeartbeatPainter(_anim.value),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final double progress;
  _HeartbeatPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF2D55)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFFF2D55).withOpacity(0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final mid = size.height / 2;
    final w = size.width;

    // ECG pattern points (normalized 0..1 x, relative y offset)
    final pattern = <Offset>[
      Offset(0.0,   0),
      Offset(0.15,  0),
      Offset(0.20,  -15),
      Offset(0.22,  5),
      Offset(0.25,  -50),
      Offset(0.28,  30),
      Offset(0.31,  -10),
      Offset(0.35,  0),
      Offset(0.55,  0),
      Offset(0.60,  -15),
      Offset(0.62,  5),
      Offset(0.65,  -50),
      Offset(0.68,  30),
      Offset(0.71,  -10),
      Offset(0.75,  0),
      Offset(1.0,   0),
    ];

    // Scroll offset based on progress
    final offset = progress;

    final path = Path();
    final glowPath = Path();
    bool first = true;

    for (final p in pattern) {
      // shift x by offset, wrap around
      double x = ((p.dx + offset) % 1.0) * w;
      double y = mid + p.dy;
      if (first) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, paint);

    // Moving dot at pulse head
    final headX = ((0.35 + offset) % 1.0) * w;
    canvas.drawCircle(
      Offset(headX, mid),
      4,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset(headX, mid),
      3,
      Paint()..color = const Color(0xFFFF2D55),
    );
  }

  @override
  bool shouldRepaint(_HeartbeatPainter old) => old.progress != progress;
}

// ─── Banner Slider Widget ────────────────────────────────────────────────────
class _BannerSlider extends StatefulWidget {
  const _BannerSlider();

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  final PageController _ctrl = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_current + 1) % 2;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: 2,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => Image.asset(
            'assets/images/banner${i + 1}.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.cardBg,
              child: Center(child: Icon(Icons.image_not_supported, color: AppTheme.textMuted)),
            ),
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),
        // Owner text bottom left
        Positioned(
          bottom: 8, left: 10,
          child: Text(
            'Buy Role? Chat @Zal7Sex',
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Dot indicators bottom right
        Positioned(
          bottom: 8, right: 10,
          child: Row(
            children: List.generate(2, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: _current == i ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i ? AppTheme.accentBlue : Colors.white38,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ),
      ],
    );
  }
}

// ─── Success Video Dialog ────────────────────────────────────────────────────
class _SuccessVideoDialog extends StatefulWidget {
  const _SuccessVideoDialog();

  @override
  State<_SuccessVideoDialog> createState() => _SuccessVideoDialogState();
}

class _SuccessVideoDialogState extends State<_SuccessVideoDialog> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/video/sukses.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _ctrl!.setLooping(false);
          _ctrl!.setVolume(1.0);
          _ctrl!.play();
          // Auto close when done
          _ctrl!.addListener(() {
            if (_ctrl!.value.position >= _ctrl!.value.duration && mounted) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = _initialized ? _ctrl!.value.aspectRatio : 16 / 9;
    final double maxWidth = MediaQuery.of(context).size.width - 40;
    final double videoHeight = maxWidth / aspectRatio;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: maxWidth,
            height: _initialized ? videoHeight : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryBlue, width: 2),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _initialized
                  ? AspectRatio(
                      aspectRatio: aspectRatio,
                      child: VideoPlayer(_ctrl!),
                    )
                  : Container(
                      height: 180,
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 2),
                      ),
                    ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
                border: Border.all(color: Colors.white30),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
