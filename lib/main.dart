import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';

// Geçici Ana Ekran
class ScaffoldPlaceholder extends StatelessWidget {
  final String title;
  const ScaffoldPlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Kat 0 Başarılı: Proje İskeleti Kuruldu!'),
      ),
    );
  }
}

// Yönlendirme (Router)
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const ScaffoldPlaceholder(title: 'Ders Notu Platformu'),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ortam değişkenlerini (.env) yükle
  await dotenv.load(fileName: ".env");

  // Supabase'i başlat
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ders Notu Platformu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Cihaz temasına göre otomatik değişir
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
