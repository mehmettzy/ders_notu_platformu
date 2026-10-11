import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';

// VARSAYILAN TEMA ARTIK DOĞRUDAN DARK MODE
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ortam değişkenlerini (.env) yükle
  await dotenv.load(fileName: ".env");

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);

    // GoRouter yerine standart MaterialApp kullanıyoruz (Çökme ve atma sorunu çözüldü)
    return MaterialApp(
      title: 'Ders Notu Platformu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(), // Başlangıç ekranımız
    );
  }
}
