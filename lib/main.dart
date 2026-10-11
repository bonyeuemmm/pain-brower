import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PainMusicApp());
}

class PainMusicApp extends StatelessWidget {
  const PainMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pain Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9B59B6),
        scaffoldBackgroundColor: const Color(0xFF0B0715),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _linkController = TextEditingController();
  InAppWebViewController? _webController;
  List<String> _history = [];
  bool _isLoading = false;
  String? _currentEmbedUrl;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('history') ?? [];
    });
  }

  Future<void> _saveHistory(String link) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(link);
    _history.insert(0, link);
    if (_history.length > 15) _history = _history.sublist(0, 15);
    await prefs.setStringList('history', _history);
    setState(() {});
  }

  String? _getVideoId(String url) {
    url = url.trim();

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    if (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1) {
      return uri.pathSegments[1];
    }

    return null;
  }

  void _play(String url) async {
    final videoId = _getVideoId(url);

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link không hợp lệ. Hãy dán đầy đủ link YouTube'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _saveHistory(url);

    final embedUrl =
        'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&playsinline=1';

    setState(() {
      _currentEmbedUrl = embedUrl;
      _isLoading = false;
    });

    // Load lại webview nếu đã có controller
    _webController?.loadUrl(urlRequest: URLRequest(url: WebUri(embedUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF160B28),
              Color(0xFF0B0715),
              Color(0xFF07040F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pain Music',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Nghe nhạc bằng link YouTube',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ô nhập link
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1229),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.4)),
                  ),
                  child: TextField(
                    controller: _linkController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Dán link YouTube đầy đủ...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                      prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFFBB86FC)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) _play(v.trim());
                    },
                  ),
                ),
              ),

              // Nút phát
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final link = _linkController.text.trim();
                            if (link.isNotEmpty) _play(link);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF5E3A7A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 28),
                              SizedBox(width: 8),
                              Text('Phát nhạc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ),

              // Player
              if (_currentEmbedUrl != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 220,
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(_currentEmbedUrl!)),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          useOnLoadResource: true,
                          transparentBackground: true,
                        ),
                        onWebViewCreated: (controller) {
                          _webController = controller;
                        },
                      ),
                    ),
                  ),
                ),

              // Lịch sử
              if (_history.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lịch sử gần đây',
                      style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final link = _history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161022),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.history_rounded, color: Color(0xFFBB86FC)),
                          title: Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF9B59B6)),
                            onPressed: () {
                              _linkController.text = link;
                              _play(link);
                            },
                          ),
                          onTap: () {
                            _linkController.text = link;
                            _play(link);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else
                const Expanded(
                  child: Center(
                    child: Text(
                      'Chưa có lịch sử phát',
                      style: TextStyle(color: Colors.white30),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
