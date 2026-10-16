import 'package:argolens/screens/RiceVoucherScreen.dart';
import 'package:argolens/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:argolens/providers/language_provider.dart';
import 'package:argolens/screens/note/NotesListScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RiceLeafRecycleScreen.dart'; // 👈 သင့်ဖိုင်အမည်အတိုင်း import လုပ်ထားပါသည်
import 'UserRicePricesScreen.dart';

class PriceAndToolScreen extends StatefulWidget {
  const PriceAndToolScreen({super.key});

  @override
  State<PriceAndToolScreen> createState() => _PriceAndToolScreenState();
}

class _PriceAndToolScreenState extends State<PriceAndToolScreen> {
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
    });
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
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F6F4),
        extendBody: true,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 110),
          physics: const BouncingScrollPhysics(),
          children: [
            // Attractive Top Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFF81C784).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyanmar ? "တောင်သူအတွက် အထူးဝန်ဆောင်မှု" : "Smart Farming Hub",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isMyanmar
                              ? "ဈေးကွက်၊ ဘောက်ချာနှင့် မှတ်တမ်းများကို တစ်နေရာတည်းတွင် စီမံပါ"
                              : "Manage market prices, vouchers & records seamlessly",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),


            _ModernFeatureCard(
              title: isMyanmar ? "စပါးဈေးနှုန်းများနှင့် ဈေးကွက်" : "Rice Prices & Market",
              subtitle: isMyanmar
                  ? "ဒေသအလိုက် လက်ရှိစပါးဈေးနှုန်းများနှင့် ဈေးကွက်အခြေအနေများကို အချိန်နှင့်တပြေးညီ ကြည့်ရှုရန်"
                  : "Track real-time local market prices and historical trends instantly",
              icon: Icons.trending_up_rounded,
              gradientColors: const [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRicePricesScreen()),
                );
              },
            ),


            const SizedBox(height: 16),

            // 🌟 Card 0: Rice Straw & Recycle (Class နာမည်ကို မှန်ကန်စွာ ပြင်ဆင်ထားပါသည်)
            _ModernFeatureCard(
              title: isMyanmar ? "စပါးပင်မှရရှိသော ကောက်ရိုး၊စပါးခွံများကိုပြန်လည်အသုံးပြုခြင်း" : "Recycling rice straw and rice husks from paddy plants",
              subtitle: isMyanmar
                  ? "ကောက်ရိုးနှင့် စပါးခွံစသည့် ပစ္စည်းများကို စီးပွားဖြစ် ပြန်လည်အသုံးပြုပုံ နည်းလမ်းများ"
                  : "Explore smart utilization methods for rice straw and agricultural by-products",
              icon: Icons.recycling_rounded,
              gradientColors: const [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RiceLeafRecycleScreen(
                    ),
                  ),
                );
              },
            ),


            // Card 1: Rice Prices & Market

            const SizedBox(height: 16),

            // Card 2: Farm Notes & Logs
            _ModernFeatureCard(
              title: isMyanmar ? "ကိုယ်ပိုင်မှတ်စုများနှင့် မှတ်တမ်းများ" : "Farm Notes & Logs",
              subtitle: isMyanmar
                  ? "စိုက်ပျိုးရေး လုပ်ငန်းစဉ်များ၊ မြေဩဇာသုံးစွဲမှုနှင့် မှတ်စုများကို စနစ်တကျ သိမ်းဆည်းရန်"
                  : "Keep track of crop logs, fertilizer schedules, and field notes efficiently",
              icon: Icons.edit_note_rounded,
              gradientColors: const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesListScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // Card 3: Rice Vouchers
            _ModernFeatureCard(
              title: isMyanmar ? "စပါးစိုက်ခင်းအတွက်အရှုံးအမြတ်တွက်ချက်မှု့" : "Profit and Loss Calculation for Rice Farming",
              subtitle: isMyanmar
                  ? "စပါးအရောင်းအဝယ် ဘောက်ချာများနှင့် ငွေစာရင်းရှင်းတမ်းများကို စနစ်တကျ ထုတ်ယူရန်"
                  : "Manage and track your rice transaction vouchers and receipts easily",
              icon: Icons.receipt_long_rounded,
              gradientColors: const [Color(0xFFE65100), Color(0xFFEF6C00), Color(0xFFF57C00)],
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiceVoucherScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // Card 4: History
            _ModernFeatureCard(
              title: isMyanmar ? "လုပ်ဆောင်ချက် မှတ်တမ်းဟောင်းများ" : "History & Logs",
              subtitle: isMyanmar
                  ? "ယခင်ပြုလုပ်ခဲ့သော အရောင်းအဝယ်နှင့် ရှာဖွေမှု မှတ်တမ်းဟောင်းများကို ပြန်လည်ကြည့်ရှုရန်"
                  : "View past activities, previous transactions, and historical logs",
              icon: Icons.history_rounded,
              gradientColors: const [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF8E24AA)],
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Modern Feature Card Widget
// ─────────────────────────────────────────────
class _ModernFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMyanmar = Provider.of<LanguageProvider>(context).isMyanmar;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -25,
                bottom: -25,
                child: Icon(
                  icon,
                  size: 140,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          isMyanmar ? "" : "Explore Now",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ],
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