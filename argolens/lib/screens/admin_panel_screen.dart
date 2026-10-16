import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// 📌 Currency Input Formatter (Handles Burmese & English Digits + Comma Separator based on language)
class CurrencyInputFormatter extends TextInputFormatter {
  final bool isMyanmar;
  CurrencyInputFormatter({required this.isMyanmar});

  final NumberFormat _formatter = NumberFormat('#,###');

  static const List<String> _burmeseDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];
  static const List<String> _englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  static String convertToEnglishDigits(String input) {
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(_burmeseDigits[i], _englishDigits[i]);
    }
    return result;
  }

  static String convertToBurmeseDigits(String input) {
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(_englishDigits[i], _burmeseDigits[i]);
    }
    return result;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final String convertedInput = convertToEnglishDigits(newValue.text);
    final String cleanText = convertedInput.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) return const TextEditingValue(text: '');

    final int? parsedValue = int.tryParse(cleanText);
    if (parsedValue == null) return newValue;

    final String formattedEnglish = _formatter.format(parsedValue);
    final String formattedText = isMyanmar
        ? convertToBurmeseDigits(formattedEnglish)
        : formattedEnglish;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late final String baseUrl = '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000'}/api/rices';

  bool _isLoading = true;
  List<dynamic> _riceList = [];
  List<Map<String, String>> _dynamicRiceTypes = [];
  String _errorMessage = '';
  double _fontScale = 1.0;

  // 📌 Shimmer Controller for Premium Loading Effect
  late AnimationController _shimmerController;

  // 📌 Selected Region Filter & Category Tab Filter ('rice' or 'byproduct')
  String _selectedRegionFilter = 'Shwebo';
  String _selectedCategoryTab = 'rice';

  // 📌 Predefined Regions
  static const List<Map<String, String>> _predefinedRegions = [
    {'key': 'Shwebo', 'mm': 'ရွှေဘို', 'en': 'Shwebo'},
    {'key': 'Ayeyarwady', 'mm': 'ဧရာဝတီ', 'en': 'Ayeyarwady'},
    {'key': 'Bago', 'mm': 'ပဲခူး', 'en': 'Bago'},
    {'key': 'Yangon', 'mm': 'ရန်ကုန်', 'en': 'Yangon'},
  ];

  // 📌 Predefined Byproducts
  static const List<Map<String, String>> _predefinedByproducts = [
    {'key': 'ဖွဲနု', 'mm': 'ဖွဲနု', 'en': 'Rice Bran'},
    {'key': 'ဖွဲကြမ်း', 'mm': 'ဖွဲကြမ်း', 'en': 'Coarse Bran'},
    {'key': 'ကောက်ရိုးအထုံး', 'mm': 'ကောက်ရိုးအထုံး', 'en': 'Rice Straw (Bundle)'},
    {'key': 'ကောက်ရိုးစင်းပြီးသား', 'mm': 'ကောက်ရိုးစင်းပြီးသား', 'en': 'Processed Rice Straw'},
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _loadFontScale();
    _fetchInitialData();
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

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.wait([
      _fetchRiceVarietiesFromAPI(),
      _fetchRicePrices(),
    ]);
  }

  // 📌 API မှ စပါးအမျိုးအစားများကို ဒိုင်းနမစ်ဖြင့် ရယူခြင်း
  Future<void> _fetchRiceVarietiesFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://rice-json-api.vercel.app/rice_varieties.json'),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        List categories = [];
        if (decoded is Map<String, dynamic>) {
          categories = decoded['categories'] ?? [];
        } else if (decoded is List) {
          categories = decoded;
        }

        List<Map<String, String>> tempVarieties = [];
        for (var cat in categories) {
          final varieties = cat['varieties'] as List? ?? [];
          for (var v in varieties) {
            String nameMm = v['name_mm'] ?? v['name_en'] ?? '';
            String nameEn = v['name_en'] ?? v['name_mm'] ?? '';
            if (nameMm.isNotEmpty) {
              tempVarieties.add({
                'key': nameMm,
                'mm': nameMm,
                'en': nameEn,
              });
            }
          }
        }

        if (tempVarieties.isNotEmpty && mounted) {
          setState(() {
            _dynamicRiceTypes = tempVarieties;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching rice varieties JSON: $e");
    }
  }

  Future<void> _fetchRicePrices() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'ကျေးဇူးပြု၍ Login ထပ်လုပ်ပါ။';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        final fetchedList = decodedData is List ? decodedData : (decodedData['data'] ?? []);

        // 📌 Database ထဲမှာရှိပြီးသား နာမည်တွေထဲက _dynamicRiceTypes ထဲ မပါသေးတာတွေကိုပါ ပေါင်းထည့်ပေးခြင်း (Missing items safeguard)
        for (var item in fetchedList) {
          String rawName = item['name'] ?? '';
          String category = item['category'] ?? 'rice';
          if (rawName.isNotEmpty && category == 'rice') {
            bool exists = _dynamicRiceTypes.any((r) => r['key'] == rawName || r['mm'] == rawName || r['en'] == rawName);
            if (!exists) {
              _dynamicRiceTypes.add({'key': rawName, 'mm': rawName, 'en': rawName});
            }
          }
        }

        setState(() {
          _riceList = fetchedList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'ဒေတာရယူ၍မရပါ (Server Error: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } on TimeoutException catch (_) {
      setState(() {
        _errorMessage = 'ဆာဗာချိတ်ဆက်မှု အချိန်ကုန်သွားပါပြီ (Timeout)။';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ချိတ်ဆက်မှု အမှားအယွင်းရှိသည်: $e';
        _isLoading = false;
      });
    }
  }

  String _normalizeRegionKey(String? rawRegion) {
    if (rawRegion == null || rawRegion.trim().isEmpty) return 'Shwebo';
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
    final list = category == 'byproduct' ? _predefinedByproducts : _dynamicRiceTypes;
    if (list.isEmpty) return nameKey;
    final found = list.firstWhere(
          (r) => r['key'] == nameKey || r['mm'] == nameKey || r['en'] == nameKey,
      orElse: () => {'mm': nameKey, 'en': nameKey},
    );
    return isMm ? found['mm']! : found['en']!;
  }

  Future<void> _submitRiceData({
    String? id,
    required String name,
    required String price,
    required String region,
    required String category,
    required bool isMm,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return;

      final englishPrice = CurrencyInputFormatter.convertToEnglishDigits(price);
      final standardRegionKey = _normalizeRegionKey(region);
      final url = id == null ? baseUrl : '$baseUrl/$id';

      final Map<String, dynamic> requestBody = {
        'name': name,
        'market_value': englishPrice,
        'region': standardRegionKey,
        'category': category,
      };

      final response = id == null
          ? await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode(requestBody),
      )
          : await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSnackBar(
            id == null
                ? (isMm ? '✅ အချက်အလက် အသစ်ထည့်ပြီးပါပြီ' : '✅ New item added successfully')
                : (isMm ? '🔄 ဈေးနှုန်း ပြင်ဆင်ပြီးပါပြီ' : '🔄 Price updated successfully'),
            const Color(0xFF2E7D32),
          );
        }
        _fetchRicePrices();
      } else {
        if (mounted) {
          _showSnackBar(isMm ? '❌ ထည့်သွင်း၍ မရပါ (${response.statusCode})' : '❌ Failed to save (${response.statusCode})', Colors.redAccent);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    }
  }

  Future<void> _deleteRice(String id, bool isMm) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar(
            isMm ? '🗑️ အောင်မြင်စွာ ဖျက်လိုက်ပါပြီ' : '🗑️ Deleted successfully',
            Colors.grey.shade700,
          );
        }
        _fetchRicePrices();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmDelete(String id, String name, bool isMm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Text(isMm ? 'သတိပေးချက်' : 'Warning', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isMm ? '"$name" ကို ဖျက်မှာ သေချာပါသလား?' : 'Are you sure you want to delete "$name"?',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isMm ? 'မလုပ်တော့ပါ' : 'Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteRice(id, isMm);
            },
            child: Text(isMm ? 'ဖျက်မည်' : 'Delete', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({String? id, String? currentName, String? currentPrice, String? currentRegion, String? currentCategory}) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isMm = languageProvider.isMyanmar;
    final primaryColor = Theme.of(context).colorScheme.primary;

    String selectedRegion = currentRegion != null && currentRegion.isNotEmpty
        ? _normalizeRegionKey(currentRegion)
        : _selectedRegionFilter;

    String selectedCategory = currentCategory != null && currentCategory.isNotEmpty
        ? currentCategory
        : _selectedCategoryTab;

    List<Map<String, String>> getCurrentList() => selectedCategory == 'byproduct' ? _predefinedByproducts : (_dynamicRiceTypes.isNotEmpty ? _dynamicRiceTypes : [{'key': currentName ?? '', 'mm': currentName ?? '', 'en': currentName ?? ''}]);

    String selectedItemName = getCurrentList()[0]['key']!;
    if (currentName != null && currentName.isNotEmpty) {
      final list = getCurrentList();
      final found = list.firstWhere(
            (r) => r['key'] == currentName || r['mm'] == currentName || r['en'] == currentName,
        orElse: () => {'key': currentName, 'mm': currentName, 'en': currentName},
      );
      selectedItemName = found['key']!;
      // ထည့်ထားတဲ့နာမည်က list ထဲ လုံးဝမရှိသေးရင် အသစ်ထည့်ပေးခြင်း
      if (!list.any((element) => element['key'] == selectedItemName)) {
        list.add({'key': selectedItemName, 'mm': selectedItemName, 'en': selectedItemName});
      }
    }

    final TextEditingController priceController = TextEditingController(text: currentPrice ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            id == null
                ? (isMm ? 'အသစ်ထည့်ရန်' : 'Add New Item')
                : (isMm ? 'ဈေးနှုန်း ပြင်ဆင်ရန်' : 'Edit Price'),
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _inputDecoration(isMm ? 'အမျိုးအစား (Category)' : 'Category', primaryColor),
                  items: [
                    DropdownMenuItem(value: 'rice', child: Text(isMm ? 'စပါးအမျိုးအစားများ' : 'Rice Types')),
                    DropdownMenuItem(value: 'byproduct', child: Text(isMm ? 'ဖွဲနှင့် ကောက်ရိုး (Byproducts)' : 'Byproducts (Bran/Straw)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedCategory = value;
                        final newList = getCurrentList();
                        selectedItemName = newList.isNotEmpty ? newList[0]['key']! : '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRegion,
                  decoration: _inputDecoration(isMm ? 'ဒေသ/မြို့နယ်' : 'Region', primaryColor),
                  items: _predefinedRegions.map((region) {
                    return DropdownMenuItem<String>(
                      value: region['key']!,
                      child: Text(isMm ? region['mm']! : region['en']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedRegion = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: getCurrentList().any((e) => e['key'] == selectedItemName) ? selectedItemName : null,
                  isExpanded: true,
                  decoration: _inputDecoration(isMm ? 'အမည်' : 'Item Name', primaryColor),
                  items: getCurrentList().map((item) {
                    return DropdownMenuItem<String>(
                      value: item['key']!,
                      child: Text(isMm ? item['mm']! : item['en']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedItemName = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [CurrencyInputFormatter(isMyanmar: isMm)],
                  decoration: _inputDecoration(isMm ? 'ပေါက်ဈေး (ကျပ်)' : 'Price (MMK)', primaryColor),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isMm ? 'ပယ်ဖျက်မည်' : 'Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                if (priceController.text.isNotEmpty && selectedItemName.isNotEmpty) {
                  Navigator.pop(context);
                  _submitRiceData(
                    id: id,
                    name: selectedItemName,
                    price: priceController.text.trim(),
                    region: selectedRegion,
                    category: selectedCategory,
                    isMm: isMm,
                  );
                }
              },
              child: Text(isMm ? 'သိမ်းမည်' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isMm = languageProvider.isMyanmar;

    final filteredRiceList = _riceList.where((rice) {
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
            isMm ? "စပါးနှင့် ဘေးထွက်ပစ္စည်း ဈေးနှုန်းများ စီမံရန်" : "Admin - Price Management",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          backgroundColor: primaryColor,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () => _showFormDialog(currentRegion: _selectedRegionFilter, currentCategory: _selectedCategoryTab),
          icon: const Icon(Icons.add_rounded),
          label: Text(isMm ? 'အသစ်ထည့်ရန်' : 'Add New', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            // 📌 Category Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF161616) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(isMm ? '🌾 စပါးအမျိုးအစားများ' : '🌾 Rice Types')),
                      selected: _selectedCategoryTab == 'rice',
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedCategoryTab == 'rice' ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCategoryTab == 'rice' ? primaryColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
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
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedCategoryTab == 'byproduct' ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCategoryTab == 'byproduct' ? primaryColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
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
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      backgroundColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
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

            // 📌 Content Area
            Expanded(
              child: _isLoading
                  ? AnimatedBuilder(
                animation: _shimmerController,
                builder: (_, __) {
                  final t = _shimmerController.value;
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
              )
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
                        onPressed: _fetchInitialData,
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
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 48, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isMm ? "ဤဒေသတွင် အချက်အလက် မရှိသေးပါ။" : "No data available for this region.",
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: filteredRiceList.length,
                itemBuilder: (context, index) {
                  final rice = filteredRiceList[index];
                  final String id = rice['_id'] ?? '';
                  final String rawName = rice['name'] ?? '';
                  final String price = rice['market_value'] ?? '';
                  final String category = rice['category'] ?? 'rice';
                  final String name = _getLocalizedItemName(rawName, category, isMm);
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
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/forsmallicon.jpg',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.eco_rounded, color: primaryColor, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 13, color: primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    localizedRegionName,
                                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMm ? "ဈေးနှုန်း: $price ကျပ်" : "Price: $price MMK",
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_rounded, color: primaryColor, size: 20),
                              onPressed: () => _showFormDialog(
                                id: id,
                                currentName: rawName,
                                currentPrice: price,
                                currentRegion: _selectedRegionFilter,
                                currentCategory: category,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmDelete(id, name, isMm),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
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