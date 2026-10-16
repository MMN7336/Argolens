import 'package:flutter/material.dart';
import '../../services/note_service.dart';

class NoteScreen extends StatefulWidget {
  final Map<String, dynamic>? note;

  const NoteScreen({super.key, this.note});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final NoteService _noteService = NoteService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!['title'] ?? "";
      _contentController.text = widget.note!['content'] ?? "";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    String titleToSave = _titleController.text.trim().isEmpty
        ? "Untitled Note"
        : _titleController.text;

    setState(() => _isLoading = true);

    try {
      if (widget.note == null) {
        await _noteService.saveNote(
          title: titleToSave,
          content: _contentController.text,
        );
      } else {
        await _noteService.updateNote(
          id: widget.note!['_id'],
          title: titleToSave,
          content: _contentController.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("❌ Save Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteNote() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          title: const Text(
            "Delete Note",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            "ဒီမှတ်စုကို ဖျက်မှာ သေချာပါသလား?\nပြန်ယူလို့ မရတော့ပါဘူး။",
            style: TextStyle(height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await _noteService.deleteNote(id: widget.note!['_id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        print("❌ Delete Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.note != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F7F9),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F7F9),
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? "Edit Note" : "New Note",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isEditing ? "မှတ်စု ပြင်ဆင်နေသည်" : "မှတ်စု အသစ် ရေးသားရန်",
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _isLoading ? null : _deleteNote,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 24,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              tooltip: "Delete",
            ),
          const SizedBox(width: 4),
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
              : Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // Title Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  decoration: InputDecoration(
                    hintText: "Title",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontWeight: FontWeight.w600,
                      fontSize: 21,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),

              const SizedBox(height: 14),

              // Content Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _contentController,
                    style: TextStyle(
                      fontSize: 16.5,
                      height: 1.65,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      letterSpacing: 0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: "Write something beautiful...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black26,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),

              // Bottom status
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? "Editing existing note" : "Creating new note",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
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