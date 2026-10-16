import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'auth_service.dart';

class NoteService {
  final AuthService _auth = AuthService();
  Database? _db;

  // ဒီမှာ get သုံးလိုက်တဲ့အတွက် .env ပြင်လိုက်တာနဲ့ IP အသစ်ကို ချက်ချင်းသိသွားပါမယ်
  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? "http://10.0.2.2:3000";

  // 1. Local Database Setup
  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'notes.db'),
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT)");
      },
      version: 1,
    );
    return _db!;
  }

  // 2. Auth Header
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _auth.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 3. Get Notes
  Future<List<dynamic>> getNotes() async {
    try {
      if (_auth.currentUid != null) {
        print("🔗 Connecting to: $_baseUrl/notes"); // ဘယ် IP ကိုခေါ်နေလဲ Console မှာ စစ်ပါ
        final response = await http.get(
          Uri.parse('$_baseUrl/notes'),
          headers: await _getHeaders(),
        );
        if (response.statusCode == 200) return jsonDecode(response.body);
      } else {
        final db = await _database;
        final List<Map<String, dynamic>> maps = await db.query('notes');
        return maps.map((e) => {
          '_id': e['id'].toString(),
          'title': e['title'],
          'content': e['content']
        }).toList();
      }
    } catch (e) {
      print("❌ Get Notes Error: $e");
    }
    return [];
  }

  // 4. Save Note
  Future<void> saveNote({required String title, required String content}) async {
    try {
      if (_auth.currentUid != null) {
        final response = await http.post(
          Uri.parse('$_baseUrl/notes/save'),
          headers: await _getHeaders(),
          body: jsonEncode({'title': title, 'content': content}),
        );
        if (response.statusCode != 200) throw Exception("Server Error");
      } else {
        final db = await _database;
        await db.insert('notes', {'title': title, 'content': content});
      }
    } catch (e) {
      print("❌ Save Note Error: $e");
      throw e;
    }
  }

  // 5. Update Note
  Future<void> updateNote({required String id, required String title, required String content}) async {
    try {
      if (_auth.currentUid != null) {
        await http.put(
          Uri.parse('$_baseUrl/notes/update/$id'),
          headers: await _getHeaders(),
          body: jsonEncode({'title': title, 'content': content}),
        );
      } else {
        final db = await _database;
        await db.update('notes', {'title': title, 'content': content}, where: 'id = ?', whereArgs: [int.parse(id)]);
      }
    } catch (e) {
      print("❌ Update Note Error: $e");
    }
  }

  // 6. Delete Note
  Future<void> deleteNote({required String id}) async {
    try {
      if (_auth.currentUid != null) {
        await http.delete(
          Uri.parse('$_baseUrl/notes/delete/$id'),
          headers: await _getHeaders(),
        );
      } else {
        final db = await _database;
        await db.delete('notes', where: 'id = ?', whereArgs: [int.parse(id)]);
      }
    } catch (e) {
      print("❌ Delete Note Error: $e");
    }
  }
}