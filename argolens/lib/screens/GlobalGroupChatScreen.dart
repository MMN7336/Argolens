import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class GlobalGroupChatScreen extends StatefulWidget {
  final String userName;

  const GlobalGroupChatScreen({super.key, required this.userName});

  @override
  State<GlobalGroupChatScreen> createState() => _GlobalGroupChatScreenState();
}

class _GlobalGroupChatScreenState extends State<GlobalGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _fontScale = 1.0;
  bool _isTyping = false;

  Map<String, dynamic>? _replyingTo;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
    _setUserOnlineStatus(true);

    _messageController.addListener(() {
      bool isCurrentlyTyping = _messageController.text.trim().isNotEmpty;
      if (_isTyping != isCurrentlyTyping) {
        setState(() {
          _isTyping = isCurrentlyTyping;
        });
        _updateTypingStatus(isCurrentlyTyping);
      }
    });
  }

  @override
  void dispose() {
    _setUserOnlineStatus(false);
    _updateTypingStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
    });
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection('active_users').doc(widget.userName).set({
        'name': widget.userName,
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'isTyping': false,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Online status error: $e");
    }
  }

  Future<void> _updateTypingStatus(bool typing) async {
    try {
      await FirebaseFirestore.instance.collection('active_users').doc(widget.userName).update({
        'isTyping': typing,
      });
    } catch (e) {
      print("Typing status error: $e");
    }
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    _updateTypingStatus(false);

    try {
      if (_editingMessageId != null) {
        await FirebaseFirestore.instance.collection('chat_messages').doc(_editingMessageId).update({
          'message': messageText,
          'isEdited': true,
        });
        setState(() {
          _editingMessageId = null;
        });
      } else {
        await FirebaseFirestore.instance.collection('chat_messages').add({
          'senderName': widget.userName,
          'message': messageText,
          'createdAt': FieldValue.serverTimestamp(),
          'room': 'global_room',
          'replyTo': _replyingTo != null
              ? {
            'id': _replyingTo!['id'],
            'sender': _replyingTo!['sender'],
            'message': _replyingTo!['message'],
          }
              : null,
          'reactions': {},
        });
        setState(() {
          _replyingTo = null;
        });

        // စာပို့ပြီးတာနဲ့ အောက်ဆုံးကို ချက်ချင်းဆင်းရန်
        _scrollToBottom();
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  void _deleteMessage(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('chat_messages').doc(docId).delete();
    } catch (e) {
      print("❌ Error deleting message: $e");
    }
  }

  void _addReaction(String docId, String emoji, Map<String, dynamic>? existingReactions) {
    Map<String, dynamic> reactions = existingReactions != null ? Map.from(existingReactions) : {};

    if (reactions[emoji] != null) {
      List users = List.from(reactions[emoji]);
      if (users.contains(widget.userName)) {
        users.remove(widget.userName);
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }
      } else {
        users.add(widget.userName);
        reactions[emoji] = users;
      }
    } else {
      reactions[emoji] = [widget.userName];
    }

    FirebaseFirestore.instance.collection('chat_messages').doc(docId).update({
      'reactions': reactions,
    });
  }

  void _showOptionsSheet(BuildContext context, DocumentSnapshot doc, bool isMe, bool isDark, bool isMyanmar) {
    final data = doc.data() as Map<String, dynamic>;
    final messageText = data['message'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['❤️', '👍', '😂', '😮', '😢', '🙏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _addReaction(doc.id, emoji, data['reactions']);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Colors.green),
                title: Text(isMyanmar ? "စာပြန်မည် (Reply)" : "Reply", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = {
                      'id': doc.id,
                      'sender': data['senderName'],
                      'message': messageText,
                    };
                  });
                },
              ),
              if (isMe) ...[
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                  title: Text(isMyanmar ? "ပြင်ဆင်မည် (Edit)" : "Edit", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessageId = doc.id;
                      _messageController.text = messageText;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: Text(isMyanmar ? "ဖျက်မည် (Delete)" : "Delete", style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(doc.id);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildAvatar(String name) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
      Colors.blueGrey,
      Colors.pink
    ];
    Color avatarColor = colors[name.hashCode.abs() % colors.length];

    return CircleAvatar(
      radius: 15,
      backgroundColor: avatarColor,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isMyanmar = languageProvider.isMyanmar;
    bool isDark = themeProvider.isDarkMode;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121215) : const Color(0xFFF4F6F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF111111),
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMyanmar ? "တောင်သူများ ဆွေးနွေးခန်း" : "Farmers Discussion",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('active_users')
                        .where('isOnline', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int onlineCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text(
                        isMyanmar ? "အွန်လိုင်း ($onlineCount)" : "Online ($onlineCount)",
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_messages')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  // ပထမအကြိမ် loading ဝိုင်းလည်တာကိုသာ ပြရန် (data ရှိပြီးသားဆိုရင် အဝိုင်းမပြတော့ပါ)
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        isMyanmar ? "စကားပြောဆိုမှု မရှိသေးပါ။ စတင်လိုက်ပါ 🌾" : "No messages yet. Start chatting 🌾",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // စာအသစ်ဝင်လာတိုင်း အောက်ဆုံးသို့ အလိုအလျောက် ရောက်စေရန်
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final senderName = data['senderName'] ?? 'Unknown';
                      final message = data['message'] ?? '';
                      final isEdited = data['isEdited'] ?? false;
                      final replyTo = data['replyTo'] as Map<String, dynamic>?;
                      final reactions = data['reactions'] as Map<String, dynamic>?;

                      String timeString = '';
                      if (data['createdAt'] != null) {
                        Timestamp timestamp = data['createdAt'];
                        DateTime dateTime = timestamp.toDate();
                        timeString = DateFormat('jm').format(dateTime);
                      }

                      bool isMe = senderName == widget.userName;

                      return GestureDetector(
                        onLongPress: () => _showOptionsSheet(context, doc, isMe, isDark, isMyanmar),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                _buildAvatar(senderName),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF2E7D32)
                                            : (isDark ? const Color(0xFF1E1E22) : Colors.white),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isMe) ...[
                                            Text(
                                              senderName,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade400,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          if (replyTo != null) ...[
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.1),
                                                border: Border(
                                                  left: BorderSide(
                                                    color: isMe ? Colors.white : Colors.green,
                                                    width: 3,
                                                  ),
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    replyTo['sender'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isMe ? Colors.white70 : Colors.green.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    replyTo['message'] ?? '',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isMe ? Colors.white60 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          Text(
                                            message,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              color: isMe ? Colors.white : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (isEdited)
                                                Text(
                                                  isMyanmar ? "(ပြင်ဆင်ပြီး) " : "(edited) ",
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontStyle: FontStyle.italic,
                                                    color: isMe ? Colors.white70 : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                                  ),
                                                ),
                                              Text(
                                                timeString,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color: isMe ? Colors.white70 : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (reactions != null && reactions.isNotEmpty)
                                      Positioned(
                                        bottom: -10,
                                        right: isMe ? 8 : null,
                                        left: isMe ? null : 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2A2A2E) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                              )
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: reactions.entries.map((entry) {
                                              return GestureDetector(
                                                onTap: () => _addReaction(doc.id, entry.key, reactions),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                                  child: Text(
                                                    "${entry.key} ${(entry.value as List).length}",
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('active_users')
                  .where('isTyping', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final typingUsers = snapshot.data!.docs
                    .map((doc) => doc['name'] as String)
                    .where((name) => name != widget.userName)
                    .toList();

                if (typingUsers.isEmpty) return const SizedBox.shrink();

                String typingText = typingUsers.length == 1
                    ? "${typingUsers.first} ${isMyanmar ? 'စာရိုက်နေသည်...' : 'is typing...'}"
                    : (isMyanmar ? "အခြားသူများ စာရိုက်နေကြသည်..." : "Multiple people are typing...");

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    typingText,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade200,
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Replying to ${_replyingTo!['sender']}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          Text(
                            _replyingTo!['message'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2E) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade300,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: isMyanmar ? "စာတို ရေးရန်..." : "Type a message...",
                          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: sendMessage,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
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