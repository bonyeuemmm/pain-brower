import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Music Purple',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9B59B6),
        scaffoldBackgroundColor: const Color(0xFF0F0A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9B59B6),
          secondary: Color(0xFF8E44AD),
          surface: Color(0xFF1A1225),
        ),
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
    if (_history.length > 20) _history = _history.sublist(0, 20);
    await prefs.setStringList('history', _history);
    setState(() {});
  }

  void _playVideo(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link YouTube không hợp lệ'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _saveHistory(url);

    setState(() {
      _controller?.dispose();
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          forceHD: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
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
              Color(0xFF1A0B2E),
              Color(0xFF0F0A1A),
              Color(0xFF0A0612),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B59B6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: Color(0xFFBB86FC), size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'YT Music Purple',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Ô nhập link
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1529),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF9B59B6).withOpacity(0.35),
                    ),
                  ),
                  child: TextField(
                    controller: _linkController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Dán link YouTube vào đây...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFFBB86FC)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) _playVideo(value.trim());
                    },
                  ),
                ),
              ),

              // Nút Phát nhạc
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final link = _linkController.text.trim();
                      if (link.isNotEmpty) _playVideo(link);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF9B59B6).withOpacity(0.5),
                    ),
                    child: const Row(
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

              // Player YouTube
              if (_controller != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: YoutubePlayer(
                      controller: _controller!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: const Color(0xFFBB86FC),
                      progressColors: const ProgressBarColors(
                        playedColor: Color(0xFF9B59B6),
                        handleColor: Color(0xFFBB86FC),
                        bufferedColor: Color(0xFF4A3A5C),
                        backgroundColor: Color(0xFF2A1F3A),
                      ),
                    ),
                  ),
                ),

              // Lịch sử
              if (_history.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lịch sử gần đây',
                      style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
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
                          color: const Color(0xFF1A1225),
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
                              _playVideo(link);
                            },
                          ),
                          onTap: () {
                            _linkController.text = link;
                            _playVideo(link);
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
                      'Chưa có lịch sử phát nhạc',
                      style: TextStyle(color: Colors.white38),
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
