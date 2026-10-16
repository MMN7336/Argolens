import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';

// 🔔 Background Notification Handler (App ပိတ်ထားစဉ် သို့မဟုတ် Background ရောက်နေစဉ် Noti လက်ခံရန်)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env ဖိုင် ချိတ်ဆက်ခြင်း
  await dotenv.load(fileName: ".env");

  // Firebase စတင်ခြင်း
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background Message Handler ချိတ်ဆက်ခြင်း
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔔 1. Notification Permission တောင်းခံခြင်း (Android 13+ နှင့် iOS အတွက် အရေးကြီးသည်)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission status: ${settings.authorizationStatus}');

  // 🔔 2. စပါးဈေး Noti တွေလက်ခံရရှိရန် Topic သို့ အလိုအလျောက် ဝင်ရောက်ခြင်း (Subscribe)
  try {
    await messaging.subscribeToTopic('rice_updates');
    print("Successfully subscribed to rice_updates topic");
  } catch (e) {
    print("Notification Topic Error: $e");
  }

  // 🔔 3. App ပွင့်နေစဉ် (Foreground) Noti ဝင်လာပါက ဖမ်းယူပြသရန်
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground Message received: ${message.notification?.title}');

    // လိုအပ်ပါက ဤနေရာတွင် User ကို Dialog သို့မဟုတ် SnackBar ဖြင့် ချက်ချင်းပြသပေးနိုင်သည်
    if (message.notification != null) {
      print('Notification Title: ${message.notification!.title}');
      print('Notification Body: ${message.notification!.body}');
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider ကိုသုံးပြီး ThemeProvider ရော LanguageProvider ပါ နှစ်ခုလုံးထည့်ပေးပါ
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const SplashScreen(),
    );
  }
}