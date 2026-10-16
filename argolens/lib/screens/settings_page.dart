import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 dotenv import လုပ်ရန်
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart';
import 'admin_suggestions_screen.dart'; // 👈 Admin ဘက်မှ အကြံပြုချက်များကြည့်မည့် Screen ကို import လုပ်ရန်

class SettingsPage extends StatefulWidget {
  final VoidCallback? onNavigateHome;

  const SettingsPage({super.key, this.onNavigateHome});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  double _fontScale = 1.0;

  static const Color _primaryGreen = Color(0xFF2E7D32);

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

  Future<void> _saveFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_font_scale', scale);
    setState(() {
      _fontScale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = languageProvider.isMyanmar;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF1E1E22)
        : Colors.white;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onNavigateHome != null) {
          widget.onNavigateHome!();
        }
      },
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_fontScale),
        ),
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF121215) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              isMyanmar ? "ပြင်ဆင်ချက်များ" : "Settings",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 0.3,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF111111)),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                _buildProfileSection(isDark, surfaceColor, isMyanmar),

                const SizedBox(height: 28),
                _sectionTitle(isMyanmar ? "အထူးပြုပြင်မှုများ" : "PREFERENCES"),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.03),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Dark Mode Tile
                      _settingsTile(
                        title: isMyanmar ? "မှောင်မိုက်သောစနစ်" : "Dark Mode",
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        isDark: isDark,
                        trailing: Switch.adaptive(
                          value: themeProvider.isDarkMode,
                          activeColor: _primaryGreen,
                          onChanged: (value) => themeProvider.toggleTheme(),
                        ),
                      ),
                      _divider(isDark),

                      // Language Selector Tile
                      _settingsTile(
                        title: isMyanmar ? "ဘာသာစကား" : "Language",
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF00B0FF),
                        isDark: isDark,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isMyanmar ? 'မြန်မာ' : 'English',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ],
                        ),
                        onTap: () => _showLanguageBottomSheet(context, languageProvider, isMyanmar),
                      ),
                      _divider(isDark),

                      // Font Size Tile
                      _settingsTile(
                        title: isMyanmar ? "စာသားအရွယ်အစား" : "Font Size",
                        icon: Icons.text_fields_rounded,
                        iconColor: const Color(0xFFFF9100),
                        isDark: isDark,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${(_fontScale * 100).toInt()}%",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ],
                        ),
                        onTap: () => _showFontSizeBottomSheet(context, isMyanmar),
                      ),
                    ],
                  ),
                ),

                // Admin Section (.env ထဲမှ ADMIN_EMAIL ဖြင့် စစ်ဆေးပြီး ပေါ်လာစေရန်)
                _buildAdminSection(isDark, surfaceColor, isMyanmar),

                const SizedBox(height: 28),
                _sectionTitle(isMyanmar ? "အကောင့်" : "ACCOUNT"),
                const SizedBox(height: 10),

                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.03),
                          ),
                        ),
                        child: _settingsTile(
                          title: isMyanmar ? "အကောင့်ထွက်ရန်" : "Sign Out",
                          icon: Icons.logout_rounded,
                          iconColor: Colors.redAccent,
                          isDark: isDark,
                          textColor: Colors.redAccent,
                          onTap: () => _showLogoutDialog(context, isMyanmar),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
    );
  }

  Widget _settingsTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF222222)),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, LanguageProvider languageProvider, bool isMyanmar) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isMyanmar ? "ဘာသာစကား ရွေးချယ်ရန်" : "Choose Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 20),
              _languageOptionTile(
                title: "မြန်မာ (Myanmar)",
                isSelected: isMyanmar,
                isDark: isDark,
                onTap: () {
                  languageProvider.setLanguage('Myanmar');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              _languageOptionTile(
                title: "English",
                isSelected: !isMyanmar,
                isDark: isDark,
                onTap: () {
                  languageProvider.setLanguage('English');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOptionTile({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryGreen.withOpacity(0.12)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryGreen : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? _primaryGreen
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _primaryGreen, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFontSizeBottomSheet(BuildContext context, bool isMyanmar) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        double tempScale = _fontScale;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isMyanmar ? "စာသားအရွယ်အစား ချိန်ညှိရန်" : "Adjust Font Size",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMyanmar ? "အက်ပ်တစ်ခုလုံးရှိ စာသားအရွယ်အစားကို ပြောင်းလဲနိုင်သည်" : "Scale text size dynamically across the app",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("A", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${(tempScale * 100).toInt()}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _primaryGreen,
                          ),
                        ),
                      ),
                      Text("A", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _primaryGreen,
                      inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      thumbColor: _primaryGreen,
                      overlayColor: _primaryGreen.withOpacity(0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: tempScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      onChanged: (value) {
                        setModalState(() => tempScale = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isMyanmar ? "ပယ်ဖျက်မည်" : "Cancel",
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _saveFontScale(tempScale);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isMyanmar ? "အတည်ပြုမည်" : "Apply",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminSection(bool isDark, Color surfaceColor, bool isMyanmar) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // 🔹 .env ထဲမှ ADMIN_EMAIL ကို လှမ်းဆွဲစစ်ဆေးခြင်း
        final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? '';

        if (user != null && user.email == adminEmail) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _sectionTitle(isMyanmar ? "စီမံခန့်ခွဲမှု" : "ADMINISTRATION"),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.03),
                  ),
                ),
                child: Column(
                  children: [
                    // ၁။ စပါးဈေးနှုန်းများ စီမံရန် (Admin Panel)
                    _settingsTile(
                      title: isMyanmar ? "စပါးဈေးနှုန်းများ စီမံရန်" : "Manage Rice Prices",
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: const Color(0xFFE91E63),
                      isDark: isDark,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPanelScreen(),
                          ),
                        );
                      },
                    ),
                    _divider(isDark),
                    // ၂။ အသုံးပြုသူများ၏ အကြံပြုချက်များ ကြည့်ရန် (Admin Suggestions Screen)
                    _settingsTile(
                      title: isMyanmar ? "အသုံးပြုသူများ၏ အကြံပြုချက်များ" : "View User Suggestions",
                      icon: Icons.message_rounded,
                      iconColor: const Color(0xFF00ACC1),
                      isDark: isDark,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminSuggestionsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileSection(bool isDark, Color surfaceColor, bool isMyanmar) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03),
            ),
          ),
          child: user != null
              ? Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? "User",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/greatestofalltime.jpg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isMyanmar ? "Argolens မှ ကြိုဆိုပါတယ်" : "Welcome to Argolens",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMyanmar ? "သင်၏ အချက်အလက်များကို သိမ်းဆည်းရန် ဝင်ရောက်ပါ" : "Sign in to sync your farm data & records",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(
                    isMyanmar ? "Google ဖြင့် ဝင်မည်" : "Sign in with Google",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _primaryGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _authService.signInWithGoogle(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, bool isMyanmar) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        title: Text(
          isMyanmar ? "အကောင့်ထွက်ရန်" : "Sign Out",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          isMyanmar ? "အကောင့်မှ ထွက်ရန် သေချာပါသလား။" : "Are you sure you want to sign out?",
          style: TextStyle(fontSize: 14.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: Text(
              isMyanmar ? "ပယ်ဖျက်မည်" : "Cancel",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _authService.signOut();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isMyanmar ? "ထွက်မည်" : "Sign Out",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}