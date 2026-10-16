import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart'; // 📌 သင့်ပရောဂျက်ရှိရာ Path အတိုင်း ပြင်ရန်

class AdminSuggestionsScreen extends StatefulWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  State<AdminSuggestionsScreen> createState() => _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends State<AdminSuggestionsScreen> {
  List<dynamic> _suggestions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
    _fetchSuggestions();
  }

  // 📌 Font Size ကို SharedPreferences မှ ရယူရန်
  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
      });
    }
  }

  // 1. Admin ဘက်မှ အကြံပြုချက်များ လှမ်းယူရန် (GET)
  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://192.168.1.5:3000';
      final response = await http.get(
        Uri.parse('$baseUrl/api/rice-suggestions'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _suggestions = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'ဒေတာရယူ၍မရပါ (Server Error: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ချိတ်ဆက်မှု အမှားအယွင်းရှိသည်: $e';
        _isLoading = false;
      });
    }
  }

  // 2. Admin ဘက်မှ အကြံပြုချက်ကို ဖျက်ရန် (DELETE)
  Future<void> _deleteSuggestion(String id, bool isMm) async {
    try {
      final baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://192.168.1.5:3000';
      final response = await http.delete(
        Uri.parse('$baseUrl/api/rice-suggestions/$id'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _suggestions.removeWhere((item) => item['_id'] == id);
        });
        _showSnackBar(
          isMm ? '🗑️ အောင်မြင်စွာ ဖျက်လိုက်ပါပြီ' : '🗑️ Deleted successfully',
          Colors.grey.shade700,
        );
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      _showSnackBar('Error deleting: $e', Colors.redAccent);
    }
  }

  // 3. ဖျက်ရန် သေချာလား မေးသော Dialog
  void _confirmDelete(String id, String varietyName, bool isMm) {
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
          isMm ? '"$varietyName" အကြံပြုချက်ကို ဖျက်မှာ သေချာပါသလား?' : 'Are you sure you want to delete "$varietyName"?',
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
              _deleteSuggestion(id, isMm);
            },
            child: Text(isMm ? 'ဖျက်မည်' : 'Delete', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    // 📌 Language Provider ချိတ်ဆက်ခြင်း
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isMm = languageProvider.isMyanmar;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9F8),
        appBar: AppBar(
          title: Text(
            isMm ? "Admin - ရောက်ရှိလာသော အကြံပြုချက်များ" : "Admin - Rice Suggestions",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          backgroundColor: primaryColor,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                  onPressed: _fetchSuggestions,
                  child: Text(isMm ? 'ပြန်ကြိုးစားမည်' : 'Retry'),
                ),
              ],
            ),
          ),
        )
            : _suggestions.isEmpty
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
                child: Icon(Icons.mark_email_unread_outlined, size: 48, color: primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                isMm ? "အကြံပြုချက်များ မရှိသေးပါ။" : "No suggestions available.",
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: _suggestions.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final item = _suggestions[index];
            final id = item['_id'] ?? '';
            final varietyName = item['variety_name'] ?? '';
            final userEmail = item['user_email'] ?? 'Guest';
            final createdAt = item['createdAt'];

            String formattedDate = '';
            if (createdAt != null) {
              final date = DateTime.parse(createdAt);
              formattedDate = DateFormat('yyyy-MM-dd • hh:mm a').format(date);
            }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => _confirmDelete(id, varietyName, isMm),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.all(8),
                        ),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    varietyName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}