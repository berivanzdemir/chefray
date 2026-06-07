import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';
import 'providers/user_profile_provider.dart';
import 'providers/theme_provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/supabase_config.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Çevre değişkenlerini yükle ──────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Supabase'i başlat ───────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: true, // Auth hatalarını görmek için açık
  );

  // ── Firebase'i başlat ───────────────────────────────────────────────────
  try {
    await Firebase.initializeApp();
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('✅ Firebase initialized');
    debugPrint('═══════════════════════════════════════════════════════');
  } catch (e) {
    debugPrint('❌ Firebase başlatma hatası: $e');
  }

  // ── FCM bildirim altyapısını kur ────────────────────────────────────────
  try {
    final fcmService = FcmService();
    await fcmService.init();
    await fcmService.requestPermissionAndGetToken();
  } catch (e) {
    debugPrint('❌ FCM servis hatası: $e');
  }

  // ── Sistem UI görünümü ──────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider()..refreshAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const ChefRayApp(),
    ),
  );
}

class ChefRayApp extends StatelessWidget {
  const ChefRayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'ChefRay',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  }
}
