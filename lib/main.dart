import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PainBrowserApp());
}

class PainBrowserApp extends StatelessWidget {
  const PainBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pain Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9B59B6),
        scaffoldBackgroundColor: const Color(0xFF0B0715),
        useMaterial3: true,
      ),
      home: const BrowserHome(),
    );
  }
}

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  late WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isFullscreen = false;
  bool _isIncognito = false;
  bool _showBottomBar = true;
  String _currentUrl = "https://www.google.com";
  String _pageTitle = "Pain Browser";

  // Feature toggles
  bool _enableIncognito = true;
  bool _enableFullscreen = true;
  bool _enableJavaScript = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableIncognito = prefs.getBool('enableIncognito') ?? true;
      _enableFullscreen = prefs.getBool('enableFullscreen') ?? true;
      _enableJavaScript = prefs.getBool('enableJavaScript') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableIncognito', _enableIncognito);
    await prefs.setBool('enableFullscreen', _enableFullscreen);
    await prefs.setBool('enableJavaScript', _enableJavaScript);
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0715))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
              _urlController.text = url;
            });
          },
          onPageFinished: (url) async {
            final title = await _controller.getTitle();
            final canBack = await _controller.canGoBack();
            final canForward = await _controller.canGoForward();
            setState(() {
              _isLoading = false;
              _pageTitle = title ?? "Pain Browser";
              _canGoBack = canBack;
              _canGoForward = canForward;
              _currentUrl = url;
              _urlController.text = url;
            });
          },
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _loadUrl(String input) {
    String url = input.trim();
    if (url.isEmpty) return;

    // Nếu không phải link thì tìm Google
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      if (url.contains(".") && !url.contains(" ")) {
        url = "https://$url";
      } else {
        url = "https://www.google.com/search?q=${Uri.encodeComponent(url)}";
      }
    }

    _controller.loadRequest(Uri.parse(url));
  }

  void _toggleFullscreen() {
    if (!_enableFullscreen) return;
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showBottomBar = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleIncognito() {
    if (!_enableIncognito) return;
    setState(() {
      _isIncognito = !_isIncognito;
    });

    if (_isIncognito) {
      // Xóa cookie + cache khi bật ẩn danh
      _controller.clearCache();
      _controller.clearLocalStorage();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã bật chế độ Ẩn danh"),
          backgroundColor: Color(0xFF9B59B6),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã tắt chế độ Ẩn danh"),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack(); // Không load lại trang
    }
  }

  void _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  void _reload() {
    _controller.reload();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1229),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Cài đặt Pain Browser",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Cho phép chế độ Ẩn danh", style: TextStyle(color: Colors.white)),
                    value: _enableIncognito,
                    activeColor: const Color(0xFF9B59B6),
                    onChanged: (v) {
                      setModalState(() => _enableIncognito = v);
                      setState(() => _enableIncognito = v);
                      _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Cho phép Toàn màn hình", style: TextStyle(color: Colors.white)),
                    value: _enableFullscreen,
                    activeColor: const Color(0xFF9B59B6),
                    onChanged: (v) {
                      setModalState(() => _enableFullscreen = v);
                      setState(() => _enableFullscreen = v);
                      _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Bật JavaScript", style: TextStyle(color: Colors.white)),
                    value: _enableJavaScript,
                    activeColor: const Color(0xFF9B59B6),
                    onChanged: (v) {
                      setModalState(() => _enableJavaScript = v);
                      setState(() => _enableJavaScript = v);
                      _controller.setJavaScriptMode(
                        v ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
                      );
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text("Xóa dữ liệu duyệt web", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      _controller.clearCache();
                      _controller.clearLocalStorage();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã xóa cache và dữ liệu")),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF160B28), Color(0xFF0B0715)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar tùy chỉnh
              if (!_isFullscreen)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.public, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isIncognito ? "Ẩn danh - Pain Browser" : "Pain Browser",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isIncognito)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B59B6).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "ẨN DANH",
                            style: TextStyle(color: Color(0xFFBB86FC), fontSize: 11),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                ),

              // Thanh địa chỉ
              if (!_isFullscreen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1229),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Color(0xFFBB86FC), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: "Tìm kiếm Google hoặc nhập địa chỉ...",
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.go,
                            onSubmitted: _loadUrl,
                          ),
                        ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF9B59B6),
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                            onPressed: _reload,
                          ),
                      ],
                    ),
                  ),
                ),

              // WebView
              Expanded(
                child: ClipRRect(
                  borderRadius: _isFullscreen
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(top: Radius.circular(0)),
                  child: WebViewWidget(controller: _controller),
                ),
              ),

              // Thanh điều khiển dưới
              if (_showBottomBar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF140C22),
                    border: Border(top: BorderSide(color: Color(0xFF2A1F3A))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            color: _canGoBack ? Colors.white : Colors.white24, size: 20),
                        onPressed: _canGoBack ? _goBack : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios,
                            color: _canGoForward ? Colors.white : Colors.white24, size: 20),
                        onPressed: _canGoForward ? _goForward : null,
                      ),
                      IconButton(
                        icon: Icon(
                          _isIncognito ? Icons.visibility_off : Icons.visibility,
                          color: _isIncognito ? const Color(0xFFBB86FC) : Colors.white70,
                        ),
                        onPressed: _toggleIncognito,
                        tooltip: "Chế độ Ẩn danh",
                      ),
                      IconButton(
                        icon: Icon(
                          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white70,
                        ),
                        onPressed: _toggleFullscreen,
                        tooltip: "Toàn màn hình",
                      ),
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.white70),
                        onPressed: () => _loadUrl("https://www.google.com"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
