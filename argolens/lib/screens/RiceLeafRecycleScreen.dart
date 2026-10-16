import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:argolens/providers/language_provider.dart';
import 'RiceLeafRecycleDetailScreen.dart';

class RiceLeafRecycleScreen extends StatefulWidget {
  const RiceLeafRecycleScreen({super.key});

  @override
  State<RiceLeafRecycleScreen> createState() => _RiceLeafRecycleScreenState();
}

class _RiceLeafRecycleScreenState extends State<RiceLeafRecycleScreen> {
  Map<String, dynamic> categoryData = {};
  List<dynamic> methods = [];
  bool isLoading = true;
  double _fontScale = 1.0;

  static const Color _primaryColor = Color(0xFF00695C);
  static const Color _lightTint = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    fetchRecycleData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
      });
    }
  }

  Future<void> fetchRecycleData() async {
    final url = Uri.parse('https://rice-json-api.vercel.app/riceLeafRecycle.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            categoryData = data ?? {};
            methods = data['utilization_methods'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => isLoading = true);
    await _loadSettings();
    await fetchRecycleData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = langProvider.isMyanmar;

    final categoryName = isMyanmar
        ? (categoryData['category_name_mm'] ?? 'Recycle စနစ်များ')
        : (categoryData['category_name_en'] ?? 'Recycle Systems');

    final description = isMyanmar
        ? (categoryData['description_mm'] ?? '')
        : (categoryData['description_en'] ?? '');

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF090C09) : const Color(0xFFF2F5F2),
        appBar: AppBar(
          title: Text(
            categoryName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          actions: [
            if (!isLoading && methods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isMyanmar ? "${methods.length} မျိုး" : "${methods.length} items",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: isDark ? _lightTint : _primaryColor,
          backgroundColor: isDark ? const Color(0xFF101410) : Colors.white,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: _primaryColor))
              : ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              // Top Banner Hero Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/forsmallicon.jpg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Utilization Methods List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: methods.length,
                itemBuilder: (context, index) {
                  final item = methods[index];
                  final title = isMyanmar
                      ? (item['title_mm'] ?? '')
                      : (item['title_en'] ?? '');
                  final useCase = isMyanmar
                      ? (item['use_case_type_mm'] ?? '')
                      : (item['use_case_type_en'] ?? '');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101410) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : _primaryColor.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.4)
                              : _primaryColor.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiceLeafRecycleDetailScreen(
                                methodData: item,
                                isMyanmar: isMyanmar,
                              ),
                            ),
                          );
                          _loadSettings();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 52,
                                margin: const EdgeInsets.only(right: 16, top: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? _lightTint : _primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        height: 1.3,
                                        color: isDark ? Colors.white : const Color(0xFF0F1C10),
                                      ),
                                    ),
                                    if (useCase.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(isDark ? 0.25 : 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _primaryColor.withOpacity(isDark ? 0.4 : 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          useCase,
                                          style: TextStyle(
                                            color: isDark ? _lightTint : _primaryColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white54 : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}