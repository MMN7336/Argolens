import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:argolens/providers/language_provider.dart';
import 'package:argolens/screens/rice_group_detail_screen.dart';

class RiceGroupScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const RiceGroupScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<RiceGroupScreen> createState() => _RiceGroupScreenState();
}

class _RiceGroupScreenState extends State<RiceGroupScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _varieties = [];
  bool _isLoading = true;
  double _fontScale = 1.0;
  late AnimationController _shimmerController;

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreenTint = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadFontScale();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadVarieties();
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

  Future<void> _loadVarieties() async {
    try {
      final response = await http.get(
        Uri.parse('https://rice-json-api.vercel.app/rice_varieties.json'),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));

        List categories = [];
        if (decodedData is Map<String, dynamic>) {
          categories = decodedData['categories'] ?? [];
        } else if (decodedData is List) {
          categories = decodedData;
        }

        var selectedCategory = categories.firstWhere(
              (cat) => cat['category_id'] == widget.categoryId,
          orElse: () => null,
        );

        List tempVarieties = [];
        if (selectedCategory != null) {
          tempVarieties =
              selectedCategory['varieties'] ?? selectedCategory['items'] ?? [];
        }

        debugPrint("Loaded Varieties Count: ${tempVarieties.length}");
        if (tempVarieties.isNotEmpty) {
          debugPrint("Sample Variety Data: ${tempVarieties.first}");
        }

        if (mounted) {
          setState(() {
            _varieties = tempVarieties;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load varieties from server');
      }
    } catch (e) {
      debugPrint("Error loading varieties: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _loadFontScale();
    await _loadVarieties();
  }

  IconData _getSeasonIcon(String season) {
    final s = season.toLowerCase();
    if (s.contains('မိုး') || s.contains('rain') || s.contains('monsoon')) {
      return Icons.water_drop_rounded;
    } else if (s.contains('ဆောင်း') || s.contains('winter') || s.contains('cold')) {
      return Icons.ac_unit_rounded;
    } else if (s.contains('နွေ') || s.contains('summer') || s.contains('hot')) {
      return Icons.wb_sunny_rounded;
    } else {
      return Icons.eco_rounded;
    }
  }

  Color _getSeasonColor(String season, bool isDark) {
    final s = season.toLowerCase();
    if (s.contains('မိုး') || s.contains('rain') || s.contains('monsoon')) {
      return isDark ? const Color(0xFF81D4FA) : const Color(0xFF0288D1);
    } else if (s.contains('ဆောင်း') || s.contains('winter') || s.contains('cold')) {
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
    } else if (s.contains('နွေ') || s.contains('summer') || s.contains('hot')) {
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    } else {
      return isDark ? _lightGreenTint : _primaryGreen;
    }
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final t = _shimmerController.value;
        final baseColor =
        isDark ? const Color(0xFF151C15) : const Color(0xFFE2E8E2);
        final highlightColor =
        isDark ? const Color(0xFF222C22) : const Color(0xFFF0F4F0);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101410) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : _primaryGreen.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 160,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color.lerp(baseColor, highlightColor, t),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Color.lerp(baseColor, highlightColor, t),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Color.lerp(baseColor, highlightColor, t),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Color.lerp(baseColor, highlightColor, t),
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmptyState(bool isDark, bool isMyanmar) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _primaryGreen.withOpacity(0.2),
              ),
            ),
            child: Icon(
              Icons.eco_rounded,
              size: 40,
              color: isDark ? _lightGreenTint : _primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            isMyanmar
                ? "ဤအမျိုးအစားအောက်တွင်\nစပါးမျိုးများ မရှိသေးပါ။"
                : "No rice varieties found in this category.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = langProvider.isMyanmar;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF090C09) : const Color(0xFFF2F5F2),
        appBar: AppBar(
          title: Text(
            widget.categoryName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          actions: [
            if (!_isLoading && _varieties.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isMyanmar
                          ? "${_varieties.length} မျိုး"
                          : "${_varieties.length} types",
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
          color: isDark ? _lightGreenTint : _primaryGreen,
          backgroundColor: isDark ? const Color(0xFF101410) : Colors.white,
          child: _isLoading
              ? _buildSkeletonLoader(isDark)
              : _varieties.isEmpty
              ? _buildEmptyState(isDark, isMyanmar)
              : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            itemCount: _varieties.length,
            itemBuilder: (context, index) {
              final variety = _varieties[index];

              final name = isMyanmar
                  ? (variety['name_mm'] ?? variety['name'] ?? 'အမည်မရှိ')
                  : (variety['name_en'] ?? variety['name'] ?? 'Unnamed');

              final season = isMyanmar
                  ? (variety['season_mm'] ?? variety['season'] ?? '')
                  : (variety['season_en'] ?? variety['season'] ?? '');

              final description = isMyanmar
                  ? (variety['description_mm'] ?? variety['description'] ?? '')
                  : (variety['description_en'] ?? variety['description'] ?? '');

              final yieldPotential = isMyanmar
                  ? (variety['yield_potential_mm'] ?? variety['yield'] ?? '')
                  : (variety['yield_potential_en'] ?? variety['yield_potential'] ?? '');

              final rawSeasonForIcon = season;
              final seasonIcon = _getSeasonIcon(rawSeasonForIcon);
              final seasonColor =
              _getSeasonColor(rawSeasonForIcon, isDark);

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101410)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : _primaryGreen.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : _primaryGreen.withOpacity(0.05),
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
                          builder: (context) =>
                              RiceGroupDetailScreen(
                                varietyData: variety,
                              ),
                        ),
                      );
                      _loadFontScale();
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
                            margin: const EdgeInsets.only(
                                right: 16, top: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? _lightGreenTint
                                  : _primaryGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17.5,
                                          letterSpacing: -0.3,
                                          height: 1.3,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(
                                              0xFF0F1C10),
                                        ),
                                      ),
                                    ),
                                    if (season.isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 11,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: seasonColor
                                              .withOpacity(
                                              isDark ? 0.2 : 0.1),
                                          borderRadius:
                                          BorderRadius.circular(
                                              12),
                                          border: Border.all(
                                            color: seasonColor
                                                .withOpacity(isDark
                                                ? 0.4
                                                : 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            Icon(
                                              seasonIcon,
                                              size: 14,
                                              color: seasonColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              season,
                                              style: TextStyle(
                                                color: seasonColor,
                                                fontSize: 11.5,
                                                fontWeight:
                                                FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                                if (yieldPotential.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primaryGreen
                                          .withOpacity(
                                          isDark ? 0.25 : 0.05),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _primaryGreen
                                            .withOpacity(isDark
                                            ? 0.3
                                            : 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.agriculture_rounded,
                                          size: 15,
                                          color: isDark
                                              ? _lightGreenTint
                                              : _primaryGreen,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          isMyanmar
                                              ? "အထွက်နှုန်း  "
                                              : "Yield: ",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontWeight:
                                            FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          yieldPotential,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight:
                                            FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(
                                                0xFF0F1C10),
                                          ),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}