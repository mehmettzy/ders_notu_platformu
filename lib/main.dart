import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'package:ders_notu_platformu/features/profile/profile_completion_screen.dart';

// Yönlendirme (Router)
// Yönlendirme (Router)
final _router = GoRouter(
  initialLocation:
      '/profile-completion', // Doğrudan profil tamamlama ekranıyla başlatır
  routes: [
    GoRoute(
      path: '/profile-completion',
      builder: (context, state) => const ProfileCompletionScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthScreen(),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ortam değişkenlerini (.env) yükle
  await dotenv.load(fileName: ".env");

  // Supabase'i başlat
  // Supabase'i başlat
  await Supabase.initialize(
    url: 'https://ujkrkdivjdmnjtgxwtyj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqa3JrZGl2amRtbmp0Z3h3dHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTMzMDgsImV4cCI6MjEwNzEyOTMwOH0.L2qXN-kK3HAkrij_zWE_WQADsHNDaFr0SoP4DQ-kjp8',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ders Notu Platformu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
