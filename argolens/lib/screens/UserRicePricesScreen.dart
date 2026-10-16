import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class UserRicePricesScreen extends StatefulWidget {
  const UserRicePricesScreen({super.key});

  @override
  State<UserRicePricesScreen> createState() => _UserRicePricesScreenState();
}

class _UserRicePricesScreenState extends State<UserRicePricesScreen> with SingleTickerProviderStateMixin {
  late final String baseUrl = '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000'}/api/rices';
  bool isLoading = true;
  List<dynamic> riceList = [];
  String _errorMessage = '';
  double _fontScale = 1.0;

  // 📌 Selected Region Filter Tag & Category Tab Filter ('rice' or 'byproduct')
  String _selectedRegionFilter = 'Yangon';
  String _selectedCategoryTab = 'rice';

  // 📌 Predefined Regions (Updated to 5 key regions: Yangon, Mandalay, Shwebo, Ayeyarwady, Bago)
  static const List<Map<String, String>> _predefinedRegions = [
    {'key': 'Yangon', 'mm': 'ရန်ကုန်', 'en': 'Yangon'},
    {'key': 'Mandalay', 'mm': 'မန္တလေး', 'en': 'Mandalay'},
    {'key': 'Shwebo', 'mm': 'ရွှေဘို', 'en': 'Shwebo'},
    {'key': 'Ayeyarwady', 'mm': 'ဧရာဝတီ', 'en': 'Ayeyarwady'},
    {'key': 'Bago', 'mm': 'ပဲခူး', 'en': 'Bago'},
  ];

  // 📌 Predefined Rice Types (Bilingual mapping matching admin panel)
  static const List<Map<String, String>> _predefinedRiceTypes = [
    {'key': 'ရွှေဘိုပေါ်ဆန်း', 'mm': 'ရွှေဘိုပေါ်ဆန်း', 'en': 'Shwebo Paw San'},
    {'key': 'ပေါ်ဆန်းမွှေး', 'mm': 'ပေါ်ဆန်းမွှေး', 'en': 'Paw San Hmwe'},
    {'key': 'ပေါ်ဆန်းရင်', 'mm': 'ပေါ်ဆန်းရင်', 'en': 'Paw San Yin'},
    {'key': 'ပုသိမ်ပေါ်ဆန်း', 'mm': 'ပုသိမ်ပေါ်ဆန်း', 'en': 'Pathein Paw San'},
    {'key': 'မြင်းကွင်း', 'mm': 'မြင်းကွင်း', 'en': 'Myin Kwin'},
    {'key': 'ဧရာမင်း', 'mm': 'ဧရာမင်း', 'en': 'Ayeyar Min'},
    {'key': 'ဆင်းသုခ', 'mm': 'ဆင်းသုခ', 'en': 'Sinn Thukha'},
    {'key': 'မနောသုခ', 'mm': 'မနောသုခ', 'en': 'Manaw Thukha'},
    {'key': 'ဇီယာ', 'mm': 'ဇီယာ', 'en': 'Ziyar'},
    {'key': 'ရွှေဝါထွန်း', 'mm': 'ရွှေဝါထွန်း', 'en': 'Shwe War Tun'},
    {'key': 'မှော်ဘီ - ၂', 'mm': 'မှော်ဘီ - ၂', 'en': 'Hmawbi - 2'},
    {'key': 'မှော်ဘီ - ၃', 'mm': 'မှော်ဘီ - ၃', 'en': 'Hmawbi - 3'},
    {'key': 'သီးထပ်ရင်', 'mm': 'သီးထပ်ရင်', 'en': 'Thee Htat Yin'},
    {'key': 'ရတနာတိုး', 'mm': 'ရတနာတိုး', 'en': 'Yadana Toe'},
    {'key': 'ဆင်းရွှေကြာ', 'mm': 'ဆင်းရွှေကြာ', 'en': 'Sinn Shwe Kyar'},
    {'key': 'ရွှေသွယ်ရင်', 'mm': 'ရွှေသွယ်ရင်', 'en': 'Shwe Thwe Yin'},
    {'key': 'ပုလဲသွယ် (စပ်မျိုး)', 'mm': 'ပုလဲသွယ် (စပ်မျိုး)', 'en': 'Palwe Thwe (Hybrid)'},
    {'key': 'ဧည့်မထ', 'mm': 'ဧည့်မထ', 'en': 'Emata'},
    {'key': 'ငစိန်', 'mm': 'ငစိန်', 'en': 'Nga Sein'},
    {'key': 'မက်စ်မတီ', 'mm': 'မက်စ်မတီ', 'en': 'Basmati'},
    {'key': 'ကောက်ညှင်းမွှေး', 'mm': 'ကောက်ညှင်းမွှေး', 'en': 'Fragrant Sticky Rice'},
    {'key': 'ခေါံတ် (ကောက်ညှင်းမဲ)', 'mm': 'ခေါံတ် (ကောက်ညှင်းမဲ)', 'en': 'Khaung (Black Sticky Rice)'},
    {'key': 'ခွန်နီ', 'mm': 'ခွန်နီ', 'en': 'Khun Ni'},
    {'key': 'တောင်ယာစပါးအမျိုးမျိုး', 'mm': 'တောင်ယာစပါးအမျိုးမျိုး', 'en': 'Various Upland Rice Types'},
    {'key': 'ရေနက်ကွင်းစပါးများ', 'mm': 'ရေနက်ကွင်းစပါးများ', 'en': 'Deep Water Rice Types'},
  ];

  // 📌 Predefined Byproducts (ဖွဲနှင့် ကောက်ရိုးအမျိုးအစားများ)
  static const List<Map<String, String>> _predefinedByproducts = [
    {'key': 'ဖွဲနု', 'mm': 'ဖွဲနု', 'en': 'Rice Bran'},
    {'key': 'ဖွဲကြမ်း', 'mm': 'ဖွဲကြမ်း', 'en': 'Coarse Bran'},
    {'key': 'ကောက်ရိုးအထုံး', 'mm': 'ကောက်ရိုးအထုံး', 'en': 'Rice Straw (Bundle)'},
    {'key': 'ကောက်ရိုးစင်းပြီးသား', 'mm': 'ကောက်ရိုးစင်းပြီးသား', 'en': 'Processed Rice Straw'},
  ];

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _loadFontScale();
    fetchRicePrices();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
      });
    }
  }

  // ✅ Auto-Retry Logic
  Future<void> fetchRicePrices({int retryCount = 3}) async {
    setState(() {
      isLoading = true;
      _errorMessage = '';
    });

    for (int i = 0; i < retryCount; i++) {
      try {
        final response = await http.get(
          Uri.parse(baseUrl),
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final decodedData = json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            riceList = decodedData is List ? decodedData : (decodedData['data'] ?? []);
            isLoading = false;
          });
          return;
        } else {
          if (i == retryCount - 1) {
            setState(() {
              _errorMessage = 'ဒေတာရယူ၍မရပါ (Server Error: ${response.statusCode})';
              isLoading = false;
            });
          }
        }
      } catch (e) {
        if (i == retryCount - 1) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'ဆာဗာနိုးထရန် အချိန်ပိုကြာနေပါသည် (Timeout)။ ထပ်ကြိုးစားပါ။';
            isLoading = false;
          });
        } else {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
  }

  String _normalizeRegionKey(String? rawRegion) {
    if (rawRegion == null || rawRegion.trim().isEmpty) return 'Yangon';
    final trimmed = rawRegion.trim();
    final found = _predefinedRegions.firstWhere(
          (r) => r['key'] == trimmed || r['mm'] == trimmed || r['en'] == trimmed,
      orElse: () => _predefinedRegions[0],
    );
    return found['key']!;
  }

  String _getLocalizedRegion(String? regionKey, bool isMm) {
    final normalizedKey = _normalizeRegionKey(regionKey);
    final found = _predefinedRegions.firstWhere(
          (r) => r['key'] == normalizedKey,
      orElse: () => _predefinedRegions[0],
    );
    return isMm ? found['mm']! : found['en']!;
  }

  String _getLocalizedItemName(String nameKey, String category, bool isMm) {
    final list = category == 'byproduct' ? _predefinedByproducts : _predefinedRiceTypes;
    final found = list.firstWhere(
          (r) => r['key'] == nameKey || r['mm'] == nameKey || r['en'] == nameKey,
      orElse: () => {'mm': nameKey, 'en': nameKey},
    );
    return isMm ? found['mm']! : found['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryGreen = Color(0xFF2E7D32);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isMm = languageProvider.isMyanmar;

    // 📌 Filter list strictly based on selected region and category tab
    final filteredRiceList = riceList.where((rice) {
      final String rawRegion = rice['region'] ?? '';
      final String rawCategory = rice['category'] ?? 'rice';
      return _normalizeRegionKey(rawRegion) == _selectedRegionFilter &&
          rawCategory == _selectedCategoryTab;
    }).toList();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9F8),
        appBar: AppBar(
          title: Text(
            isMm ? "စပါးနှင့် ဘေးထွက်ပစ္စည်း ဈေးနှုန်းများ" : "Prices per Basket & Byproducts",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // 📌 Category Tabs (စပါး / ဖွဲနှင့် ကောက်ရိုး Switcher)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF161616) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(isMm ? '🌾 စပါးအမျိုးအစားများ' : '🌾 Rice Types')),
                      selected: _selectedCategoryTab == 'rice',
                      selectedColor: primaryGreen,
                      labelStyle: TextStyle(
                        color: _selectedCategoryTab == 'rice' ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCategoryTab == 'rice' ? primaryGreen : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          width: 1,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategoryTab = 'rice');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(isMm ? '📦 ဖွဲနှင့် ကောက်ရိုး' : '📦 Byproducts')),
                      selected: _selectedCategoryTab == 'byproduct',
                      selectedColor: primaryGreen,
                      labelStyle: TextStyle(
                        color: _selectedCategoryTab == 'byproduct' ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCategoryTab == 'byproduct' ? primaryGreen : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          width: 1,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategoryTab = 'byproduct');
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // 📌 Horizontal Region Filter Tags Bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: isDark ? const Color(0xFF161616) : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _predefinedRegions.length,
                itemBuilder: (context, index) {
                  final region = _predefinedRegions[index];
                  final String regionKey = region['key']!;
                  final String regionName = isMm ? region['mm']! : region['en']!;
                  final bool isSelected = _selectedRegionFilter == regionKey;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(regionName),
                      selected: isSelected,
                      selectedColor: primaryGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryGreen : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          width: 1,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRegionFilter = regionKey;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // 📌 List / Skeleton / Empty State
            Expanded(
              child: isLoading
                  ? _SkeletonList(controller: _shimmerController, isDark: isDark)
                  : _errorMessage.isNotEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchRicePrices,
                        child: Text(isMm ? 'ပြန်ကြိုးစားမည်' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              )
                  : filteredRiceList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 48, color: primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isMm ? "ဤဒေသတွင် အချက်အလက် မရှိသေးပါ။" : "No price data available for this region.",
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredRiceList.length,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemBuilder: (context, index) {
                  final rice = filteredRiceList[index];
                  final String rawName = rice['name'] ?? '';
                  final String category = rice['category'] ?? 'rice';
                  final String itemName = _getLocalizedItemName(rawName, category, isMm);
                  final String price = rice['market_value'] ?? '--';
                  final String localizedRegionName = _getLocalizedRegion(_selectedRegionFilter, isMm);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/forsmallicon.jpg',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.eco_rounded, color: primaryGreen, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 13, color: primaryGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    localizedRegionName,
                                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isMm ? "ဈေးနှုန်း: " : "Price: ",
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: isMm ? "$price ကျပ်" : "$price MMK",
                                      style: const TextStyle(
                                        color: primaryGreen,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
        final base = isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
        final highlight = Color.lerp(base, isDark ? const Color(0xFF333333) : Colors.white, t)!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}