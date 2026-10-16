import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AuthService {
  static Map<String, dynamic>? currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- Getters ---
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- အသစ်ထည့်လိုက်သည့် Method (NoteService အတွက် လိုအပ်သည်) ---
  Future<String?> getIdToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // --- Sign In Logic ---
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        return await _syncWithBackend(idToken);
      }
      return false;
    } catch (e) {
      print("[-] Google Sign-In Error: $e");
      return false;
    }
  }

  // --- Backend Sync Logic ---
  Future<bool> _syncWithBackend(String idToken) async {
    try {
      final String? baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl == null) {
        print("[-] Error: BACKEND_URL not found in .env");
        return false;
      }

      final url = Uri.parse("$baseUrl/auth/sync");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        currentUser = jsonDecode(response.body);
        print("[+] Sync Success");
        return true;
      } else {
        print("[-] Sync Failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("[-] Sync Exception: $e");
      return false;
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    currentUser = null;
  }
}