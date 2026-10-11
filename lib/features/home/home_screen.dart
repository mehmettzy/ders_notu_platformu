import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notes/add_note_screen.dart';
import '../auth/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    // KULLANICIYI BURADA TANIMLIYORUZ (Sarı çizgi hatası düzeldi)
    final currentUser = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Notları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('notes')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          }

          final notes = snapshot.data;

          if (notes == null || notes.isEmpty) {
            return const Center(
              child: Text('Henüz hiç not yüklenmemiş.\nİlk notu sen ekle!',
                  textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            itemCount: notes.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final note = notes[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      color: Colors.redAccent, size: 40),
                  title: Text(
                    note['title'] ?? 'Başlıksız Not',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      '${note['course_name']}\n${note['description'] ?? ''}'),
                  isThreeLine: true,
                  // SADECE NOTU YÜKLEYEN KİŞİYE SİLME BUTONU GÖSTERİYORUZ
                  trailing: currentUser != null &&
                          note['user_id'] == currentUser.id
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await _supabase
                                  .from('notes')
                                  .delete()
                                  .eq('id', note['id']);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Not başarıyla silindi.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Silme hatası: $e')),
                                );
                              }
                            }
                          },
                        )
                      : const Icon(Icons.download),
                  onTap: () async {
                    final String? fileUrl = note['file_url'];
                    if (fileUrl != null && fileUrl.isNotEmpty) {
                      final Uri url = Uri.parse(fileUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dosya açılamadı!')),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Dosya linki bulunamadı!')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
