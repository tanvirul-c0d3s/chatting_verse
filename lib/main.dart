import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/services/notification_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<NotificationService>()) {
        await Get.find<NotificationService>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatVerse',
      initialRoute: AppRoutes.splash,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B5FEF),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}