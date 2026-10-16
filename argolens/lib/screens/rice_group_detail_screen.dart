import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:argolens/providers/language_provider.dart';

class RiceGroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> varietyData;

  const RiceGroupDetailScreen({
    super.key,
    required this.varietyData,
  });

  @override
  State<RiceGroupDetailScreen> createState() => _RiceGroupDetailScreenState();
}

class _RiceGroupDetailScreenState extends State<RiceGroupDetailScreen> {
  double _fontScale = 1.0;

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _softGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadFontScale();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
      });
    }
  }

  String _getString(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    if (value is String) return value.trim().isEmpty ? defaultValue : value;
    return value.toString();
  }

  IconData _getSeasonIcon(String season) {
    final s = season.toLowerCase();
    if (s.contains('မိုး') || s.contains('rain') || s.contains('monsoon')) {
      return Icons.water_drop_rounded;
    } else if (s.contains('ဆောင်း') || s.contains('winter') || s.contains('cold')) {
      return Icons.ac_unit_rounded;
    } else if (s.contains('နွေ') || s.contains('summer') || s.contains('hot')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.eco_rounded;
  }

  Color _getSeasonColor(String season, bool isDark) {
    final s = season.toLowerCase();
    if (s.contains('မိုး') || s.contains('rain') || s.contains('monsoon')) {
      return isDark ? const Color(0xFF81D4FA) : const Color(0xFF0288D1);
    } else if (s.contains('ဆောင်း') || s.contains('winter') || s.contains('cold')) {
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
    } else if (s.contains('နွေ') || s.contains('summer') || s.contains('hot')) {
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    }
    return isDark ? _softGreen : _primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final langProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = langProvider.isMyanmar;

    final nameMm = isMyanmar
        ? _getString(widget.varietyData['name_mm'] ?? widget.varietyData['name'], defaultValue: 'အမည်မရှိ')
        : _getString(widget.varietyData['name_en'] ?? widget.varietyData['name'], defaultValue: 'Unnamed');

    final nameEn = isMyanmar
        ? _getString(widget.varietyData['name_en'], defaultValue: '')
        : _getString(widget.varietyData['name_mm'], defaultValue: '');

    final season = isMyanmar
        ? _getString(widget.varietyData['season_mm'] ?? widget.varietyData['season'])
        : _getString(widget.varietyData['season_en'] ?? widget.varietyData['season'], defaultValue: '-');

    final lifeCycleDays = isMyanmar
        ? _getString(widget.varietyData['life_cycle_days_mm'] ?? widget.varietyData['life_cycle_days'] ?? widget.varietyData['duration'] ?? widget.varietyData['days'])
        : _getString(widget.varietyData['life_cycle_days_en'] ?? widget.varietyData['life_cycle_days'] ?? widget.varietyData['duration'] ?? widget.varietyData['days']);

    final yieldPotential = isMyanmar
        ? _getString(widget.varietyData['yield_potential_mm'] ?? widget.varietyData['yield_potential'] ?? widget.varietyData['yield'])
        : _getString(widget.varietyData['yield_potential_en'] ?? widget.varietyData['yield_potential'] ?? widget.varietyData['yield'], defaultValue: '-');

    final grainType = isMyanmar
        ? _getString(widget.varietyData['grain_type_mm'] ?? widget.varietyData['grain_type'])
        : _getString(widget.varietyData['grain_type_en'] ?? widget.varietyData['grain_type'], defaultValue: '-');

    final plantHeight = isMyanmar
        ? _getString(widget.varietyData['plant_height_mm'] ?? widget.varietyData['plant_height'] ?? widget.varietyData['height'])
        : _getString(widget.varietyData['plant_height_en'] ?? widget.varietyData['plant_height'] ?? widget.varietyData['height'], defaultValue: '-');

    final soilType = isMyanmar
        ? _getString(widget.varietyData['soil_type_mm'] ?? widget.varietyData['soil_type'])
        : _getString(widget.varietyData['soil_type_en'] ?? widget.varietyData['soil_type'], defaultValue: '-');

    final sowingTime = isMyanmar
        ? _getString(widget.varietyData['sowing_time_mm'] ?? widget.varietyData['sowing_time'])
        : _getString(widget.varietyData['sowing_time_en'] ?? widget.varietyData['sowing_time'], defaultValue: '-');

    final harvestingTime = isMyanmar
        ? _getString(widget.varietyData['harvesting_time_mm'] ?? widget.varietyData['harvesting_time'])
        : _getString(widget.varietyData['harvesting_time_en'] ?? widget.varietyData['harvesting_time'], defaultValue: '-');

    final description = isMyanmar
        ? _getString(widget.varietyData['description_mm'] ?? widget.varietyData['description'], defaultValue: 'အသေးစိတ် ဖော်ပြချက် မရှိပါ။')
        : _getString(widget.varietyData['description_en'] ?? widget.varietyData['description'], defaultValue: 'No detailed description available.');

    final marketValue = isMyanmar
        ? _getString(widget.varietyData['market_value_mm'] ?? widget.varietyData['market_value'] ?? widget.varietyData['price'])
        : _getString(widget.varietyData['market_value_en'] ?? widget.varietyData['market_value'] ?? widget.varietyData['price'], defaultValue: '-');

    final bestPractices = isMyanmar
        ? _getString(widget.varietyData['best_practices_mm'] ?? widget.varietyData['best_practices'])
        : _getString(widget.varietyData['best_practices_en'] ?? widget.varietyData['best_practices'], defaultValue: '-');

    final String? imageUrl = widget.varietyData['image_url'] ?? widget.varietyData['image'];

    final List resistances = isMyanmar
        ? (widget.varietyData['resistances_mm'] ?? widget.varietyData['resistances'] ?? [])
        : (widget.varietyData['resistances_en'] ?? widget.varietyData['resistances'] ?? []);

    final List diseasesAndPests = isMyanmar
        ? (widget.varietyData['diseases_and_pests_mm'] ?? widget.varietyData['diseases_and_pests'] ?? [])
        : (widget.varietyData['diseases_and_pests_en'] ?? widget.varietyData['diseases_and_pests'] ?? []);

    final cultivationTips = widget.varietyData['cultivation_tips'] ?? {};

    final seasonIcon = _getSeasonIcon(season);
    final seasonColor = _getSeasonColor(season, isDark);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF090C09)
            : const Color(0xFFF2F5F2),
        appBar: AppBar(
          title: Text(
            nameMm,
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
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _imageErrorFallback(),
                    )
                        : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _imageErrorFallback(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101410) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : _primaryGreen.withOpacity(0.08),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _primaryGreen.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/forsmallicon.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameMm,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F1C10),
                                  height: 1.25,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (nameEn.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  nameEn,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : _primaryGreen.withOpacity(0.1),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.65,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (season != '-')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: seasonColor.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: seasonColor.withOpacity(isDark ? 0.4 : 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(seasonIcon, size: 15, color: seasonColor),
                                const SizedBox(width: 6),
                                Text(
                                  season,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: seasonColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (season != '-' && marketValue != '-')
                          const SizedBox(width: 10),
                        if (marketValue != '-')
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withOpacity(isDark ? 0.25 : 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _primaryGreen.withOpacity(isDark ? 0.3 : 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: isDark ? _softGreen : _primaryGreen,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      marketValue,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F1C10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle(isMyanmar ? "စိုက်ပျိုးရေးဆိုင်ရာ အဓိက အချက်အလက်များ" : "Key Cultivation Information"),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildInfoTile(isMyanmar ? "ရာသီဥတု" : "Season", season, seasonIcon, isDark, seasonColor),
                  _buildInfoTile(isMyanmar ? "သက်တမ်း" : "Life Cycle", lifeCycleDays.contains('ရက်') || lifeCycleDays.contains('days') ? lifeCycleDays : (isMyanmar ? "$lifeCycleDays ရက်" : "$lifeCycleDays days"), Icons.timer_rounded, isDark, null),
                  _buildInfoTile(isMyanmar ? "အထွက်နှုန်း" : "Yield Potential", yieldPotential, Icons.trending_up_rounded, isDark, null),
                  _buildInfoTile(isMyanmar ? "စပါးစေ့အမျိုးအစား" : "Grain Type", grainType, Icons.grain_rounded, isDark, null),
                  _buildInfoTile(isMyanmar ? "အပင်အမြင့်" : "Plant Height", plantHeight, Icons.height_rounded, isDark, null),
                  _buildInfoTile(isMyanmar ? "မြေအမျိုးအစား" : "Soil Type", soilType, Icons.layers_rounded, isDark, null),
                  _buildInfoTile(isMyanmar ? "စိုက်ပျိုးချိန်" : "Sowing Time", sowingTime, Icons.calendar_today_rounded, isDark, null),
                  _buildInfoTile(isMyanmar ? "ရိတ်သိမ်းချိန်" : "Harvesting Time", harvestingTime, Icons.event_available_rounded, isDark, null),
                ],
              ),

              if (resistances.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle(isMyanmar ? "ခုခံနိုင်စွမ်းများ" : "Resistances"),
                const SizedBox(height: 14),
                // Overflow မဖြစ်စေရန် Column သုံးပြီး ဘေးတိုက်ပြည့်သွားစေရန် ပြင်ဆင်ထားသည်
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: resistances.map((res) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark
                            ? _softGreen.withOpacity(0.15)
                            : _primaryGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _primaryGreen.withOpacity(isDark ? 0.3 : 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 16,
                            color: isDark ? _softGreen : _primaryGreen,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              res.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? _softGreen : _primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (cultivationTips is Map && cultivationTips.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle(isMyanmar ? "စိုက်ပျိုးရေး နည်းလမ်းညွှန်ချက်များ" : "Cultivation Tips"),
                const SizedBox(height: 14),
                if (cultivationTips['fertilizer_plan_mm'] != null || cultivationTips['fertilizer_plan'] != null || cultivationTips['fertilizer_plan_en'] != null)
                  _buildTipCard(
                    isMyanmar ? "ဓာတ်မြေသြဇာ ကျွေးမည့်အစီအစဉ်" : "Fertilizer Plan",
                    _getString(isMyanmar ? (cultivationTips['fertilizer_plan_mm'] ?? cultivationTips['fertilizer_plan']) : (cultivationTips['fertilizer_plan_en'] ?? cultivationTips['fertilizer_plan'])),
                    Icons.science_rounded,
                    isDark,
                  ),
                if (cultivationTips['optimal_water_level_mm'] != null || cultivationTips['optimal_water_level'] != null || cultivationTips['optimal_water_level_en'] != null) ...[
                  const SizedBox(height: 12),
                  _buildTipCard(
                    isMyanmar ? "ရေသွင်းရေထုတ် ထိန်းသိမ်းရန်" : "Optimal Water Level",
                    _getString(isMyanmar ? (cultivationTips['optimal_water_level_mm'] ?? cultivationTips['optimal_water_level']) : (cultivationTips['optimal_water_level_en'] ?? cultivationTips['optimal_water_level'])),
                    Icons.water_drop_rounded,
                    isDark,
                  ),
                ],
              ],

              if (diseasesAndPests.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle(isMyanmar ? "ဖြစ်ပွားတတ်သော ရောဂါနှင့် ပိုးမွှားများ" : "Diseases and Pests"),
                const SizedBox(height: 14),
                ...diseasesAndPests.map((pest) {
                  final pestMap = pest is Map ? pest : {};

                  final pestName = _getString(
                      isMyanmar
                          ? (pestMap['name_mm'] ?? pestMap['name'])
                          : (pestMap['name_en'] ?? pestMap['name']),
                      defaultValue: isMyanmar ? 'ပိုးမွှား/ရောဂါ အမည်မသိ' : 'Unknown Pest/Disease'
                  );

                  final pestSymptoms = _getString(
                      isMyanmar
                          ? (pestMap['symptoms_mm'] ?? pestMap['symptoms'])
                          : (pestMap['symptoms_en'] ?? pestMap['symptoms']),
                      defaultValue: '-'
                  );

                  final pestTreatment = _getString(
                      isMyanmar
                          ? (pestMap['treatment_mm'] ?? pestMap['treatment'])
                          : (pestMap['treatment_en'] ?? pestMap['treatment']),
                      defaultValue: '-'
                  );

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101410) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(isDark ? 0.3 : 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.4)
                              : Colors.redAccent.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bug_report_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pestName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isMyanmar ? "လက္ခဏာ - $pestSymptoms" : "Symptoms: $pestSymptoms",
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(isDark ? 0.25 : 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryGreen.withOpacity(isDark ? 0.3 : 0.1),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.medical_services_rounded,
                                size: 16,
                                color: isDark ? _softGreen : _primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isMyanmar ? "ကုသ/ကာကွယ်ရန် - $pestTreatment" : "Treatment: $pestTreatment",
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: isDark ? _softGreen : _primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],

              if (bestPractices != '-') ...[
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101410) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withOpacity(isDark ? 0.4 : 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.amber.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isMyanmar ? "အထူးအကြံပြုချက် (Best Practices)" : "Best Practices",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.amber.shade200
                                    : const Color(0xFF795548),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        bestPractices,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageErrorFallback() {
    return Image.asset(
      'assets/images/forsmallicon.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInfoTile(
      String title,
      String value,
      IconData icon,
      bool isDark,
      Color? accentColor,
      ) {
    final color = accentColor ?? (isDark ? _softGreen : _primaryGreen);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101410) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : _primaryGreen.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : _primaryGreen.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.25 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1C10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String content, IconData icon, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101410) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGreen.withOpacity(isDark ? 0.3 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : _primaryGreen.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? _softGreen : _primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? _softGreen : _primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}