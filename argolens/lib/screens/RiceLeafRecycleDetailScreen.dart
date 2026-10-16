import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiceLeafRecycleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> methodData;
  final bool isMyanmar;

  const RiceLeafRecycleDetailScreen({
    super.key,
    required this.methodData,
    required this.isMyanmar,
  });

  @override
  State<RiceLeafRecycleDetailScreen> createState() => _RiceLeafRecycleDetailScreenState();
}

class _RiceLeafRecycleDetailScreenState extends State<RiceLeafRecycleDetailScreen> {
  double _fontScale = 1.0;

  static const Color _primaryColor = Color(0xFF00695C);
  static const Color _lightTint = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final item = widget.methodData;
    final isMyanmar = widget.isMyanmar;

    final title = isMyanmar ? (item['title_mm'] ?? '') : (item['title_en'] ?? '');
    final useCase = isMyanmar ? (item['use_case_type_mm'] ?? '') : (item['use_case_type_en'] ?? '');
    final id = item['id'] ?? '';

    final processSummary = isMyanmar ? item['process_summary_mm'] : item['process_summary_en'];
    final yieldIncome = isMyanmar ? item['estimated_yield_and_income_mm'] : item['estimated_yield_and_income_en'];
    final pricingGuide = isMyanmar ? item['pricing_guide_mm'] : item['pricing_guide_en'];
    final unitType = isMyanmar ? item['unit_type_mm'] : item['unit_type_en'];
    final targetMarket = isMyanmar ? item['target_market_mm'] : item['target_market_en'];

    final materials = isMyanmar ? (item['required_materials_mm'] as List?) : (item['required_materials_en'] as List?);
    final steps = isMyanmar ? (item['processing_steps_mm'] as List?) : (item['processing_steps_en'] as List?);
    final crops = isMyanmar ? (item['suitable_crops_mm'] as List?) : (item['suitable_crops_en'] as List?);
    final benefits = isMyanmar ? (item['benefits_mm'] as List?) : (item['benefits_en'] as List?);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF090C09) : const Color(0xFFF2F5F2),
        appBar: AppBar(
          title: Text(
            title,
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
        ),
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            // Header Hero Card
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: _primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                height: 1.3,
                                color: isDark ? Colors.white : const Color(0xFF0F1C10),
                              ),
                            ),
                            if (useCase.isNotEmpty) ...[
                              const SizedBox(height: 8),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Detailed Content Container
            Container(
              padding: const EdgeInsets.all(22),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (processSummary != null) ...[
                    _buildSectionTitle(isMyanmar ? "လုပ်ဆောင်ပုံ အကျဉ်း" : "Process Summary"),
                    const SizedBox(height: 8),
                    Text(processSummary, style: _contentStyle(isDark)),
                    const SizedBox(height: 20),
                  ],

                  if (materials != null) ...[
                    _buildSectionTitle(isMyanmar ? "လိုအပ်သော ပစ္စည်းများ" : "Required Materials"),
                    const SizedBox(height: 8),
                    ...materials.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                          Expanded(child: Text(m, style: _contentStyle(isDark))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],

                  if (steps != null) ...[
                    _buildSectionTitle(isMyanmar ? "ပြုလုပ်ပုံ အဆင့်ဆင့်" : "Processing Steps"),
                    const SizedBox(height: 8),
                    ...steps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${entry.key + 1}. ", style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(entry.value, style: _contentStyle(isDark))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],

                  if (yieldIncome != null) ...[
                    _buildSectionTitle(isMyanmar ? "ထွက်ရှိမှုနှင့် ဝင်ငွေခန့်မှန်းချက်" : "Estimated Yield & Income"),
                    const SizedBox(height: 8),
                    Text(yieldIncome, style: _contentStyle(isDark)),
                    const SizedBox(height: 20),
                  ],

                  if (targetMarket != null) ...[
                    _buildSectionTitle(isMyanmar ? "ပစ်မှတ်ဈေးကွက်" : "Target Market"),
                    const SizedBox(height: 8),
                    Text(targetMarket, style: _contentStyle(isDark)),
                    const SizedBox(height: 20),
                  ],

                  if (pricingGuide != null) ...[
                    _buildSectionTitle(isMyanmar ? "ဈေးနှုန်းသတ်မှတ်ချက် လမ်းညွှန်" : "Pricing Guide"),
                    const SizedBox(height: 8),
                    Text(pricingGuide, style: _contentStyle(isDark)),
                    const SizedBox(height: 20),
                  ],

                  if (unitType != null) ...[
                    _buildSectionTitle(isMyanmar ? "ရောင်းချသည့် ယူနစ်ပုံစံ" : "Unit Type"),
                    const SizedBox(height: 8),
                    Text(unitType, style: _contentStyle(isDark)),
                    const SizedBox(height: 20),
                  ],

                  if (crops != null) ...[
                    _buildSectionTitle(isMyanmar ? "သင့်လျော်သော သီးနှံများ" : "Suitable Crops"),
                    const SizedBox(height: 8),
                    ...crops.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(c, style: _contentStyle(isDark))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],

                  if (benefits != null) ...[
                    _buildSectionTitle(isMyanmar ? "ရရှိမည့် အကျိုးကျေးဇူးများ" : "Benefits"),
                    const SizedBox(height: 8),
                    ...benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("✔ ", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(b, style: _contentStyle(isDark))),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: _primaryColor,
        letterSpacing: -0.2,
      ),
    );
  }

  TextStyle _contentStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white70 : Colors.black87,
      height: 1.55,
    );
  }
}