import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
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
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();

  List<String> _history = [];
  bool _isLoading = false;
  String? _currentTitle;
  String? _errorMessage;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
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
    try {
      return VideoId.parseVideoId(url);
    } catch (e) {
      return null;
    }
  }

  Future<void> _play(String url) async {
    final videoId = _getVideoId(url);

    if (videoId == null) {
      setState(() {
        _errorMessage = 'Link không hợp lệ';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTitle = null;
    });

    try {
      await _saveHistory(url);

      // Lấy thông tin video
      final video = await _yt.videos.get(videoId);
      
      // Lấy stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // Ưu tiên lấy audio only chất lượng tốt nhất
      final audioStream = manifest.audioOnly.withHighestBitrate();

      if (audioStream == null) {
        throw Exception('Không tìm thấy audio stream');
      }

      // Phát bằng just_audio
      await _player.setUrl(audioStream.url.toString());
      await _player.play();

      setState(() {
        _currentTitle = video.title;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không lấy được nhạc.\nBạn có thể thử link khác hoặc đợi sau.';
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
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
                      hintText: 'Dán link YouTube...',
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

              // Thông tin đang phát
              if (_currentTitle != null || _errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1229),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        if (_currentTitle != null) ...[
                          const Text(
                            'Đang phát',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentTitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            onPressed: () {
                              if (_isPlaying) {
                                _player.pause();
                              } else {
                                _player.play();
                              }
                            },
                            icon: Icon(
                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              size: 48,
                              color: const Color(0xFF9B59B6),
                            ),
                          ),
                        ],
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                      ],
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
