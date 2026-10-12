import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        primaryColor: const Color(0xFFBB86FC),
        scaffoldBackgroundColor: const Color(0xFF0A0614),
        useMaterial3: true,
      ),
      home: const BrowserHome(),
    );
  }
}

class BrowserTab {
  WebViewController? controller;
  String url;
  String title;
  bool isLoading;

  BrowserTab({
    this.controller,
    this.url = "",
    this.title = "Tab mới",
    this.isLoading = false,
  });
}

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _proxyController = TextEditingController();

  List<BrowserTab> _tabs = [];
  int _currentTabIndex = 0;

  bool _isFullscreen = false;
  bool _isIncognito = false;
  bool _isDesktopUA = false;

  bool _enableIncognito = true;
  bool _enableFullscreen = true;
  bool _enableJavaScript = true;
  bool _enableBackButton = true;
  bool _enableProxy = false;
  String _proxyAddress = "";

  List<Map<String, String>> _customTools = [];

  final String _mobileUA =
      "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";
  final String _desktopUA =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  BrowserTab get _currentTab => _tabs[_currentTabIndex];

  @override
  void initState() {
    super.initState();
    _tabs.add(BrowserTab(title: "Trang chủ"));
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableIncognito = prefs.getBool('enableIncognito') ?? true;
      _enableFullscreen = prefs.getBool('enableFullscreen') ?? true;
      _enableJavaScript = prefs.getBool('enableJavaScript') ?? true;
      _enableBackButton = prefs.getBool('enableBackButton') ?? true;
      _enableProxy = prefs.getBool('enableProxy') ?? false;
      _proxyAddress = prefs.getString('proxyAddress') ?? "";
      _proxyController.text = _proxyAddress;
      _isDesktopUA = prefs.getBool('isDesktopUA') ?? false;

      final toolsJson = prefs.getString('customTools');
      if (toolsJson != null) {
        final List list = jsonDecode(toolsJson);
        _customTools = list.map((e) => Map<String, String>.from(e)).toList();
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableIncognito', _enableIncognito);
    await prefs.setBool('enableFullscreen', _enableFullscreen);
    await prefs.setBool('enableJavaScript', _enableJavaScript);
    await prefs.setBool('enableBackButton', _enableBackButton);
    await prefs.setBool('enableProxy', _enableProxy);
    await prefs.setString('proxyAddress', _proxyAddress);
    await prefs.setBool('isDesktopUA', _isDesktopUA);
    await prefs.setString('customTools', jsonEncode(_customTools));
  }

  void _initControllerForTab(BrowserTab tab) {
    tab.controller = WebViewController()
      ..setJavaScriptMode(_enableJavaScript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setUserAgent(_isDesktopUA ? _desktopUA : _mobileUA)
      ..setBackgroundColor(const Color(0xFF0A0614))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              tab.isLoading = true;
              tab.url = url;
              if (_tabs[_currentTabIndex] == tab) {
                _urlController.text = url;
              }
            });
          },
          onPageFinished: (url) async {
            final title = await tab.controller!.getTitle();
            setState(() {
              tab.isLoading = false;
              tab.title = title ?? "Tab";
              tab.url = url;
              if (_tabs[_currentTabIndex] == tab) {
                _urlController.text = url;
              }
            });
          },
          onWebResourceError: (error) {
            setState(() => tab.isLoading = false);
          },
        ),
      );
  }

  void _loadUrl(String input) {
    String url = input.trim();
    if (url.isEmpty) return;

    if (_currentTab.controller == null) {
      _initControllerForTab(_currentTab);
    }

    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      if (url.contains(".") && !url.contains(" ")) {
        url = "https://$url";
      } else {
        url = "https://www.google.com/search?q=${Uri.encodeComponent(url)}";
      }
    }

    setState(() {
      _currentTab.url = url;
    });
    _currentTab.controller!.loadRequest(Uri.parse(url));
  }

  void _createNewTab() {
    setState(() {
      _tabs.add(BrowserTab(title: "Tab mới"));
      _currentTabIndex = _tabs.length - 1;
      _urlController.clear();
    });
  }

  void _closeTab(int index) {
    if (_tabs.length == 1) {
      setState(() {
        _tabs[0] = BrowserTab(title: "Trang chủ");
        _currentTabIndex = 0;
        _urlController.clear();
      });
      return;
    }

    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
      _urlController.text = _tabs[_currentTabIndex].url;
    });
  }

  void _switchTab(int index) {
    setState(() {
      _currentTabIndex = index;
      _urlController.text = _tabs[index].url;
    });
  }

  void _showTabManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161022),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Các tab (${_tabs.length})",
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          _createNewTab();
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.add, color: Color(0xFFBB86FC)),
                        label: const Text("Tab mới", style: TextStyle(color: Color(0xFFBB86FC))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _tabs.length,
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        final isActive = index == _currentTabIndex;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF9B59B6).withOpacity(0.15) : const Color(0xFF1A1229),
                            borderRadius: BorderRadius.circular(12),
                            border: isActive ? Border.all(color: const Color(0xFFBB86FC).withOpacity(0.5)) : null,
                          ),
                          child: ListTile(
                            title: Text(tab.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              tab.url.isEmpty ? "Trang chủ" : tab.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                              onPressed: () {
                                _closeTab(index);
                                setModalState(() {});
                              },
                            ),
                            onTap: () {
                              _switchTab(index);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _goHome() {
    setState(() {
      _currentTab.controller = null;
      _currentTab.url = "";
      _currentTab.title = "Trang chủ";
      _urlController.clear();
    });
  }

  void _goBack() async {
    if (!_enableBackButton) return;
    final controller = _currentTab.controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    } else {
      _goHome();
    }
  }

  void _goForward() async {
    final controller = _currentTab.controller;
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  void _toggleFullscreen() {
    if (!_enableFullscreen) return;
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleIncognito() {
    if (!_enableIncognito) return;
    setState(() => _isIncognito = !_isIncognito);
    if (_isIncognito && _currentTab.controller != null) {
      _currentTab.controller!.clearCache();
      _currentTab.controller!.clearLocalStorage();
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161022),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Text("Cài đặt & Tiện ích", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: const Text("Nút Quay lại", style: TextStyle(color: Colors.white)),
                      value: _enableBackButton,
                      activeColor: const Color(0xFFBB86FC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setModalState(() => _enableBackButton = v);
                        setState(() => _enableBackButton = v);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Chế độ Ẩn danh", style: TextStyle(color: Colors.white)),
                      value: _enableIncognito,
                      activeColor: const Color(0xFFBB86FC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setModalState(() => _enableIncognito = v);
                        setState(() => _enableIncognito = v);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Toàn màn hình", style: TextStyle(color: Colors.white)),
                      value: _enableFullscreen,
                      activeColor: const Color(0xFFBB86FC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setModalState(() => _enableFullscreen = v);
                        setState(() => _enableFullscreen = v);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text("JavaScript", style: TextStyle(color: Colors.white)),
                      value: _enableJavaScript,
                      activeColor: const Color(0xFFBB86FC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setModalState(() => _enableJavaScript = v);
                        setState(() => _enableJavaScript = v);
                        _saveSettings();
                      },
                    ),

                    const Divider(color: Colors.white12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cleaning_services_rounded, color: Color(0xFFBB86FC)),
                      title: const Text("Xóa Cookie & Cache", style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _currentTab.controller?.clearCache();
                        _currentTab.controller?.clearLocalStorage();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.public, color: Color(0xFFBB86FC)),
                      title: const Text("Kiểm tra IP", style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _loadUrl("https://api.ipify.org?format=json");
                      },
                    ),

                    const Divider(color: Colors.white12),

                    SwitchListTile(
                      title: const Text("Sử dụng Proxy", style: TextStyle(color: Colors.white)),
                      value: _enableProxy,
                      activeColor: const Color(0xFFBB86FC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setModalState(() => _enableProxy = v);
                        setState(() => _enableProxy = v);
                        _saveSettings();
                      },
                    ),
                    if (_enableProxy)
                      TextField(
                        controller: _proxyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "IP:Port",
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF1A1229),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (v) {
                          _proxyAddress = v.trim();
                          _saveSettings();
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentTab;
    final hasWebView = current.controller != null && current.url.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0614),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isFullscreen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF9B59B6), Color(0xFF6C3483)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.public_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isIncognito ? "Pain Browser • Ẩn danh" : "Pain Browser",
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            hasWebView ? current.title : "Trang chủ",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: _showTabManager,
                          icon: const Icon(Icons.web_asset_rounded, color: Colors.white60),
                        ),
                        if (_tabs.length > 1)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF9B59B6), shape: BoxShape.circle),
                              child: Text("${_tabs.length}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white60),
                    ),
                  ],
                ),
              ),

            if (!_isFullscreen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161022),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isIncognito ? const Color(0xFFBB86FC).withOpacity(0.6) : const Color(0xFF2A1F3A),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(_isIncognito ? Icons.visibility_off_rounded : Icons.search_rounded, color: const Color(0xFFBB86FC), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Tìm kiếm hoặc nhập địa chỉ...",
                            hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: _loadUrl,
                        ),
                      ),
                      if (current.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFFBB86FC))),
                        ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: hasWebView
                  ? WebViewWidget(controller: current.controller!)
                  : _buildHomePage(),
            ),

            if (!_isFullscreen)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161022),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A1F3A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bottomButton(icon: Icons.arrow_back_ios_new_rounded, enabled: _enableBackButton, onTap: _goBack),
                    _bottomButton(icon: Icons.arrow_forward_ios_rounded, enabled: true, onTap: _goForward),
                    _bottomButton(icon: Icons.add_rounded, enabled: true, onTap: _createNewTab),
                    _bottomButton(icon: _isIncognito ? Icons.visibility_off_rounded : Icons.visibility_rounded, enabled: true, active: _isIncognito, onTap: _toggleIncognito),
                    _bottomButton(icon: Icons.home_rounded, enabled: true, onTap: _goHome),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF9B59B6), Color(0xFF6C3483)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.public_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 24),
            const Text("Pain Browser", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Tab \( {_currentTabIndex + 1}/ \){_tabs.length}", style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 32),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF161022),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search_rounded, color: Color(0xFFBB86FC)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Tìm kiếm Google hoặc nhập link...",
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: _loadUrl,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFBB86FC)),
                    onPressed: () => _loadUrl(_urlController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton({required IconData icon, required bool enabled, bool active = false, required VoidCallback onTap}) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 22, color: active ? const Color(0xFFBB86FC) : enabled ? Colors.white70 : Colors.white24),
    );
  }
}
