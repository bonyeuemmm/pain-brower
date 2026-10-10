import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
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
  YoutubePlayerController? _controller;
  List<String> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

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

  String? _extractVideoId(String url) {
    // Làm sạch link
    url = url.trim();

    // Nếu người dùng chỉ dán ID
    if (url.length == 11 && !url.contains('/') && !url.contains('?')) {
      return url;
    }

    return YoutubePlayerController.convertUrlToId(url);
  }

  void _play(String url) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final videoId = _extractVideoId(url);

    if (videoId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Link không hợp lệ. Hãy dán đầy đủ link YouTube';
      });
      return;
    }

    await _saveHistory(url);

    try {
      await _controller?.close();

      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          loop: false,
          strictRelatedVideos: false,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể phát video này';
      });
    }
  }

  @override
  void dispose() {
    _controller?.close();
    _linkController.dispose();
    super.dispose();
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

              // Thông báo lỗi
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),

              // Player
              if (_controller != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: YoutubePlayer(
                      controller: _controller!,
                      aspectRatio: 16 / 9,
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
