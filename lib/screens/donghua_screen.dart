import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/theme.dart';

class DonghuaScreen extends StatefulWidget {
  const DonghuaScreen({super.key});

  @override
  State<DonghuaScreen> createState() => _DonghuaScreenState();
}

class _DonghuaScreenState extends State<DonghuaScreen> {
  bool _isLoading = true;
  bool _isLandscape = false;
  late WebViewController _webViewController;

  static const Color _borderColor = Color(0xFF1A2E45);
  static const String _donghuaUrl = 'https://donghub.vip/';

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_donghuaUrl));
  }

  @override
  void dispose() {
    // Balik ke portrait waktu keluar screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() => _isLandscape = !_isLandscape);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.string(AppSvgIcons.arrowBack, width: 22, height: 22,
              colorFilter: const ColorFilter.mode(AppTheme.textSecondary, BlendMode.srcIn)),
        ),
        title: const Text(
          'Pegasus-X DongHub',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleOrientation,
            tooltip: _isLandscape ? 'Portrait Mode' : 'Landscape Mode',
            icon: SvgPicture.string(
              _isLandscape
                ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="7" y="2" width="10" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>'
                : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="10" rx="2" ry="2"/><line x1="6" y1="12" x2="6.01" y2="12"/></svg>',
              width: 22, height: 22,
              colorFilter: ColorFilter.mode(
                _isLandscape ? AppTheme.primaryBlue : AppTheme.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Container(
      color: AppTheme.darkBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: _borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'LOADING DONGHUA...',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                color: AppTheme.textMuted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
