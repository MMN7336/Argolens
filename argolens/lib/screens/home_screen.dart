import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:argolens/screens/PriceAndToolScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:argolens/providers/language_provider.dart';
import 'package:argolens/screens/settings_page.dart';
import 'package:argolens/screens/chat_with_argolens_screen.dart';
import 'package:argolens/screens/rice_group_screen.dart';
import 'package:argolens/screens/rice_group_detail_screen.dart';
import 'package:argolens/screens/analyze_disease_screen.dart';
import 'package:argolens/screens/user_to_admin_suggest_screen.dart';

import 'GlobalGroupChatScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _fontScale = 1.0;
  late final List<Widget> _pages;

  double? _chatLeft;
  double? _chatTop;
  bool _isDragging = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFontScale();

    _pages = [
      const _HomeView(),
      SettingsPage(
        onNavigateHome: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
    ];
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _fontScale = prefs.getDouble('app_font_scale') ?? 1.0);
    }
  }

  void _checkAuthAndChat() {
    final user = FirebaseAuth.instance.currentUser;
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isMyanmar = langProvider.isMyanmar;

    if (user == null) {
      _showLoginDialog(
        title: isMyanmar ? "Login လိုအပ်ပါသည်" : "Login Required",
        content: isMyanmar
            ? "Argolens နှင့် ဆွေးနွေးရန်အတွက် အရင်ဆုံး Login ဝင်ပေးပါ။"
            : "Please log in first to start a discussion with Argolens.",
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatWithArgolensScreen()),
      );
    }
  }

  void _openCameraOptions() {
    _showImageSourceOptions();
  }

  void _showLoginDialog({required String title, required String content}) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isMyanmar = langProvider.isMyanmar;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          content,
          style: const TextStyle(height: 1.45, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isMyanmar ? "ပယ်ဖျက်မည်" : "Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1;
                _loadFontScale();
              });
            },
            child: Text(isMyanmar ? "Login ဝင်မည်" : "Sign In"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyzeDiseaseScreen(imageFile: File(pickedFile.path)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
    }
  }

  void _showImageSourceOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isMyanmar = langProvider.isMyanmar;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isMyanmar ? "ဓာတ်ပုံ ရွေးချယ်ရန်" : "Select Image Source",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _SheetTile(
                icon: Icons.camera_alt_rounded,
                label: isMyanmar ? "ဓာတ်ပုံရိုက်မည်" : "Take a photo",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _SheetTile(
                icon: Icons.photo_library_rounded,
                label: isMyanmar ? "ဖုန်းထဲမှရွေးမည်" : "Choose from gallery",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = langProvider.isMyanmar;
    final screenSize = MediaQuery.of(context).size;

    _chatLeft ??= screenSize.width - 52 - 20.0;
    _chatTop ??= screenSize.height - 220;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9F8),
        body: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),

            Positioned(
              left: _chatLeft,
              top: _chatTop,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    _chatLeft = (_chatLeft! + details.delta.dx).clamp(0.0, screenSize.width - 52);
                    _chatTop = (_chatTop! + details.delta.dy).clamp(50.0, screenSize.height - 150);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _isDragging = false;
                    if (_chatLeft! < screenSize.width / 2) {
                      _chatLeft = 20.0;
                    } else {
                      _chatLeft = screenSize.width - 52 - 20.0;
                    }
                  });
                },
                onTap: () {
                  if (!_isDragging) {
                    _checkAuthAndChat();
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'camera_fab',
            onPressed: _openCameraOptions,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          height: 72,
          elevation: 0,
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                outline: Icons.home_outlined,
                label: isMyanmar ? "ပင်မ" : "Home",
                selected: _selectedIndex == 0,
                onTap: () => setState(() {
                  _selectedIndex = 0;
                  _loadFontScale();
                }),
              ),
              const SizedBox(width: 48),
              _BottomNavItem(
                icon: Icons.person_rounded,
                outline: Icons.person_outline_rounded,
                label: isMyanmar ? "ကိုယ်ရေး" : "Profile",
                selected: _selectedIndex == 1,
                onTap: () => setState(() {
                  _selectedIndex = 1;
                  _loadFontScale();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData outline;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.outline,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? icon : outline,
                size: 22,
                color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with SingleTickerProviderStateMixin {
  String _location = "Loading...";
  String _weather = "--°C";
  String _condition = "Clear";
  final String _apiKey = "958e98e89cad6ca24c5be232e0424414";

  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;
  int _selectedTab = 0;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWeatherData();
      _loadRiceCategories();
      _preloadRicePrices();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _checkAuthAndGlobalChat() {
    final user = FirebaseAuth.instance.currentUser;
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isMyanmar = langProvider.isMyanmar;

    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isMyanmar ? "Login လိုအပ်ပါသည်" : "Login Required",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text(
            isMyanmar
                ? "တောင်သူများ အထွေထွေ ဆွေးနွေးခန်းသို့ ဝင်ရောက်ရန် အရင်ဆုံး Login ဝင်ပေးပါ။"
                : "Please log in first to join the farmers' general chat room.",
            style: const TextStyle(height: 1.45, fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isMyanmar ? "ပယ်ဖျက်မည်" : "Cancel", style: TextStyle(color: Colors.grey.shade600)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(isMyanmar ? "နားလည်ပါပြီ" : "OK"),
            ),
          ],
        ),
      );
    } else {
      final userName = user.displayName ?? user.email?.split('@')[0] ?? (isMyanmar ? "တောင်သူ" : "Farmer");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GlobalGroupChatScreen(userName: userName),
        ),
      );
    }
  }

  Future<void> _preloadRicePrices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final baseUrl = '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000'}/api/rices';

      await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint("Preload error: $e");
    }
  }

  Future<void> _loadRiceCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://rice-json-api.vercel.app/rice_varieties.json'),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        List temp = [];
        if (decoded is Map<String, dynamic>) {
          temp = decoded['categories'] ?? [];
        } else if (decoded is List) {
          temp = decoded;
        }
        if (mounted) {
          setState(() {
            _categories = temp;
            _isLoadingCategories = false;
          });
        }
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  IconData _weatherIcon(String c) {
    switch (c.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
        return Icons.water_drop_rounded;
      case 'drizzle':
        return Icons.grain_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  Future<void> _fetchWeatherData() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isMyanmar = langProvider.isMyanmar;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _location = isMyanmar ? "Location ပိတ်ထားသည်" : "Location disabled");
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _location = isMyanmar ? "Location ခွင့်ပြုချက် မရှိပါ" : "Location permission denied");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _location = isMyanmar ? "Location ခွင့်ပြုချက် ပိတ်ထားသည်" : "Location permission permanently denied");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final url =
          "https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&appid=$_apiKey&units=metric";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _location = "${data['name']}, ${data['sys']['country']}";
            _weather = "${data['main']['temp'].toInt()}°C";
            _condition = data['weather'][0]['main'];
          });
        }
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
      if (mounted) setState(() => _location = isMyanmar ? "ဒေတာရယူ၍မရပါ" : "Failed to load data");
    }
  }

  void _showLogoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/greatestofalltime.jpg',
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryGreen = Color(0xFF2E7D32);

    final langProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = langProvider.isMyanmar;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showLogoDialog,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/greatestofalltime.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "ARGOLENS",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _PremiumCircleAction(
                        icon: Icons.search_rounded,
                        isDark: isDark,
                        onTap: () {
                          showSearch(
                            context: context,
                            delegate: _RiceSearchDelegate(_categories, isMyanmar),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _SuperPremiumChatButton(
                        onTap: _checkAuthAndGlobalChat,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_weatherIcon(_condition), size: 18, color: primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Text(" • ", style: TextStyle(color: Colors.grey)),
                          Text(
                            _condition,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _weather,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isDark ? const Color(0xFF2E7D32) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (_selectedTab == 0 && !isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            isMyanmar ? "စပါးအမျိုးအစားများ" : "Rice Varieties",
                            style: TextStyle(
                              color: _selectedTab == 0
                                  ? (isDark ? Colors.white : const Color(0xFF2E7D32))
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              fontWeight: _selectedTab == 0 ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isDark ? const Color(0xFF2E7D32) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (_selectedTab == 1 && !isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            isMyanmar ? "ဈေးနှုန်းနှင့် ဝန်ဆောင်မှုများ" : "Price & Services",
                            style: TextStyle(
                              color: _selectedTab == 1
                                  ? (isDark ? Colors.white : const Color(0xFF2E7D32))
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              fontWeight: _selectedTab == 1 ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedTab == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMyanmar ? "စပါးအမျိုးအစားများ" : "Rice Varieties",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoadingCategories)
              SliverToBoxAdapter(child: _SkeletonList(controller: _shimmerController, isDark: isDark))
            else if (_categories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Text(
                      isMyanmar ? "အချက်အလက် မရှိပါ။" : "No data available.",
                      style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final cat = _categories[index];
                      final varieties = cat['varieties'] as List? ?? [];

                      final categoryName = isMyanmar
                          ? (cat['category_name_mm'] ?? '')
                          : (cat['category_name_en'] ?? '');

                      final categoryDesc = isMyanmar
                          ? (cat['description_mm'] ?? '')
                          : (cat['description_en'] ?? '');

                      final rawImage = cat['image_url'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PremiumCategoryCard(
                          name: categoryName,
                          description: categoryDesc,
                          count: varieties.length,
                          imageUrl: rawImage,
                          isDark: isDark,
                          isMyanmar: isMyanmar,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RiceGroupScreen(
                                  categoryId: cat['category_id'] ?? '',
                                  categoryName: categoryName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: _categories.length,
                  ),
                ),
              ),
          ] else ...[
            const SliverFillRemaining(
              child: PriceAndToolScreen(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiceSearchDelegate extends SearchDelegate {
  final List<dynamic> categories;
  final bool isMyanmar;

  _RiceSearchDelegate(this.categories, this.isMyanmar);

  // 📌 Login ဝင်ထားခြင်း ရှိမရှိ စစ်ဆေးပြီး Admin Suggestion Screen သို့ ပို့ပေးမည့် Method
  void _checkAuthAndSuggest(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Login မဝင်ထားပါက Dialog ပြရန်
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isMyanmar ? "Login လိုအပ်ပါသည်" : "Login Required",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text(
            isMyanmar
                ? "Admin ထံ အကြံပြုချက်ပေးပို့ရန်အတွက် အရင်ဆုံး Login ဝင်ပေးပါ။"
                : "Please log in first to send suggestions to the admin.",
            style: const TextStyle(height: 1.45, fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isMyanmar ? "ပယ်ဖျက်မည်" : "Cancel", style: TextStyle(color: Colors.grey.shade600)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context); // Dialog ပိတ်မည်
                close(context, null);   // Search ကို ပိတ်မည်
              },
              child: Text(isMyanmar ? "နားလည်ပါပြီ" : "OK"),
            ),
          ],
        ),
      );
    } else {
      // Login ဝင်ထားပြီးပါက Suggest Screen သို့ သွားမည်
      close(context, null);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UserToAdminSuggestScreen(),
        ),
      );
    }
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final lowerQuery = query.toLowerCase().trim();
    List<Map<String, dynamic>> matchedResults = [];

    for (var cat in categories) {
      final varieties = cat['varieties'] as List? ?? [];
      for (var variety in varieties) {
        final vNameMm = (variety['name_mm'] ?? '').toString().toLowerCase();
        final vNameEn = (variety['name_en'] ?? '').toString().toLowerCase();

        if (lowerQuery.isEmpty || vNameMm.contains(lowerQuery) || vNameEn.contains(lowerQuery)) {
          matchedResults.add({
            'category': cat,
            'variety': variety,
          });
        }
      }
    }

    if (matchedResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isMyanmar
                    ? "ယခု app ထဲမှာတော့ ဒီစပါး name မရှိသေးပါ၊ admin ဘက်ကို အကြံပေးလိုက်ပါမယ်"
                    : "This rice name is not available in the app yet. We will notify the admin.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                query.isNotEmpty ? 'ရှာဖွေမှု: "$query"' : '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _checkAuthAndSuggest(context), // 📌 ဤနေရာတွင် Login စစ်ဆေးပေးမည်
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  isMyanmar ? "Admin ထံ အကြံပေးမည်" : "Suggest to Admin",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: matchedResults.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = matchedResults[index];
        final cat = item['category'];
        final variety = item['variety'];

        final varietyName = isMyanmar
            ? (variety['name_mm'] ?? variety['name_en'] ?? 'အမည်မရှိ')
            : (variety['name_en'] ?? variety['name_mm'] ?? 'Unnamed');

        final categoryName = isMyanmar
            ? (cat['category_name_mm'] ?? '')
            : (cat['category_name_en'] ?? '');

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/forsmallicon.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 20),
                ),
              ),
            ),
            title: Text(
              varietyName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            subtitle: Text(
              "${isMyanmar ? 'အုပ်စု' : 'Category'}: $categoryName",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            onTap: () {
              close(context, null);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiceGroupDetailScreen(varietyData: variety),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PremiumCircleAction extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _PremiumCircleAction({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1.2,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            icon,
            size: 19,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _SuperPremiumChatButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _SuperPremiumChatButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCategoryCard extends StatelessWidget {
  final String name;
  final String description;
  final int count;
  final String? imageUrl;
  final bool isDark;
  final bool isMyanmar;
  final VoidCallback onTap;

  const _PremiumCategoryCard({
    required this.name,
    required this.description,
    required this.count,
    required this.imageUrl,
    required this.isDark,
    required this.isMyanmar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = imageUrl != null && imageUrl!.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 195,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                isNetworkImage
                    ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
                    : Image.asset(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              else
                _fallback(),

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.3, 0.5, 1.0],
                  ),
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.eco_rounded, size: 48, color: Colors.white38),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _SkeletonList({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
        final highlight = Color.lerp(base, isDark ? const Color(0xFF3A3A3A) : Colors.white, t)!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: List.generate(3, (i) {
              return Container(
                height: 195,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(24),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}