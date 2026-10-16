import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWithArgolensScreen extends StatefulWidget {
  const ChatWithArgolensScreen({super.key});

  @override
  State<ChatWithArgolensScreen> createState() => _ChatWithArgolensScreenState();
}

class _ChatWithArgolensScreenState extends State<ChatWithArgolensScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  List<dynamic> _history = [];
  String? _currentChatId;

  final Color _greenTheme = Colors.green.shade700;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
    _fetchHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
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

  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';

  // 📌 Chat History များ ပြန်ဆွဲယူရန်
  Future<void> _fetchHistory() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ History Error: User not logged in");
      return;
    }

    try {
      final url = '$_baseUrl/chat/history?userId=${user.uid}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Backend မှ {'success': true, 'chats': [...]} ဖြင့် ပို့ထားသဖြင့် 'chats' ကို ခွဲထုတ်ခြင်း
          _history = data['chats'] ?? [];
        });
        print("✅ History loaded successfully: ${_history.length} items");
      } else {
        print("❌ Server error while fetching history: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ History Exception: $e");
    }
  }

  // ရွေးလိုက်တဲ့ Chat ရဲ့ Message အဟောင်းတွေကို ပြန်ခေါ်ရန်
  Future<void> _fetchMessagesForChat(String chatId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/chat/messages/$chatId'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _messages.clear();
          _currentChatId = chatId;
          if (data['messages'] != null) {
            for (var msg in data['messages']) {
              _messages.add({"sender": msg['role'], "text": msg['content']});
            }
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("❌ Fetch Messages Error: $e");
    }
  }

  // Chat ကို ဖျက်ရန်
  Future<void> _deleteChat(String chatId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/chat/delete/$chatId'));
      if (response.statusCode == 200) {
        _fetchHistory();
        if (_currentChatId == chatId) {
          setState(() {
            _currentChatId = null;
            _messages.clear();
          });
        }
      }
    } catch (e) {
      print("❌ Delete Error: $e");
    }
  }

  // အောက်ဆုံးသို့ Scroll ဆွဲပေးရန်
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // စာသား ပို့ရန်
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final User? user = FirebaseAuth.instance.currentUser;
    String text = _controller.text;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _controller.clear();
    });
    _scrollToBottom();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chat/send'));
      request.fields['message'] = text;
      request.fields['userId'] = user?.uid ?? 'guest';
      if (_currentChatId != null) request.fields['chatId'] = _currentChatId!;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = json.decode(responseData);
        setState(() {
          _currentChatId = data['chatId'];
          _messages.add({"sender": "assistant", "text": data['response']});
        });
        _scrollToBottom();
        _fetchHistory();
      }
    } catch (e) {
      print("❌ Send Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        appBar: AppBar(
          title: Text(
            "Chat With Argolens",
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _fetchHistory();
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentUser?.displayName ?? "User",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
                    ),
                    Text(currentUser?.email ?? "", style: TextStyle(color: _greenTheme, fontSize: 14)),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ListTile(
                leading: Icon(Icons.add, color: _greenTheme),
                title: Text("New Chat", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() {
                    _currentChatId = null;
                    _messages.clear();
                  });
                  _fetchHistory();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: _history.isEmpty
                    ? Center(
                  child: Text(
                    "History မရှိသေးပါ။",
                    style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                  ),
                )
                    : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.chat_bubble_outline, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    title: Text(
                      _history[index]['title'] ?? "Chat",
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
                        title: Text("Delete Chat", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        content: Text("Delete this chat?", style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              _deleteChat(_history[index]['_id']);
                              Navigator.pop(context);
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      _fetchMessagesForChat(_history[index]['_id']);
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser ? _greenTheme : (isDark ? const Color(0xFF222222) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: "စပါးပင်အကြောင်း မေးမြန်းရန်...",
                          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _greenTheme, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}