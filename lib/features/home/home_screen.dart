import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notes/add_note_screen.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  // Arama çubuğu için kontrolcü ve aranan kelimeyi tutacağımız değişken
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Notları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
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
        // Arama Çubuğu Tasarımı (AppBar'ın hemen altına eklenir)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ders adı veya not başlığı ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.all(0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery =
                      value; // Kullanıcı yazdıkça arama kelimesini güncelliyoruz
                });
              },
            ),
          ),
        ),
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

          // ARAMA FİLTRESİ BURADA UYGULANIYOR
          final filteredNotes = notes.where((note) {
            final title = (note['title'] ?? '').toString().toLowerCase();
            final courseName =
                (note['course_name'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();

            return title.contains(query) || courseName.contains(query);
          }).toList();

          if (filteredNotes.isEmpty) {
            return const Center(
              child: Text('Aradığınız kritere uygun not bulunamadı.',
                  textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            itemCount: filteredNotes.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final note = filteredNotes[index];

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
