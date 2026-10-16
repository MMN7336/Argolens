import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class UserToAdminSuggestScreen extends StatefulWidget {
  final String? suggestedText;
  const UserToAdminSuggestScreen({super.key, this.suggestedText});

  @override
  State<UserToAdminSuggestScreen> createState() => _UserToAdminSuggestScreenState();
}

class _UserToAdminSuggestScreenState extends State<UserToAdminSuggestScreen> {
  late final TextEditingController _suggestionController;
  bool _isLoading = false;
  double _fontScale = 1.0;

  static const Color _primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _suggestionController = TextEditingController(text: widget.suggestedText ?? '');
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

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _sendSuggestion(bool isMm) async {
    final text = _suggestionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isMm ? 'ကျေးဇူးပြု၍ အကြံပြုချက် (သို့) စပါးအမည် ရေးပါ။' : 'Please enter a suggestion or rice name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseUrl = dotenv.env['BACKEND_URL'];
      final url = Uri.parse('$baseUrl/api/rice-suggestions');

      final user = FirebaseAuth.instance.currentUser;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'variety_name': text,
          'user_email': user?.email ?? 'Guest',
          'user_id': user?.uid ?? 'Anonymous',
        }),
      );

      if (response.statusCode == 201) {
        _suggestionController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMm ? 'အကြံပြုချက် ပို့ပြီးပါပြီ။ ကျေးဇူးတင်ပါသည်။' : 'Suggestion sent successfully. Thank you.'),
            backgroundColor: _primaryGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to send suggestion');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isMm ? 'အမှားအယွင်းရှိပါသည်: $e' : 'Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isMm = languageProvider.isMyanmar;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121215) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            isMm ? "Admin ထံ အကြံပြုရန်" : "Suggest to Admin",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          centerTitle: true,
          backgroundColor: _primaryGreen, // 👈 AppBar တွင် အရောင်ထည့်သွင်းပေးခြင်း
          foregroundColor: Colors.white,   // 👈 စာသားနှင့် အိုင်ကွန်များ အရောင် (အဖြူ)
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMm ? "ရှာမတွေ့သော ပစ္စည်းအမည် (သို့မဟုတ်) အကြံပြုချက်" : "Missing item name (or) Suggestion",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _suggestionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isMm ? "ဥပမာ - ပုသိမ်ပေါ်ဆန်း မတွေ့ပါ..." : "e.g., Pathein Paw San not found...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _sendSuggestion(isMm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isMm ? "ပေးပို့မည်" : "Submit",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}