import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notes/add_note_screen.dart'; // Dosya yolunun projene uygun olduğundan emin ol

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Notları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              // Çıkış yapınca uygulamanın giriş ekranına yönlendirmesi eklenecek
            },
          )
        ],
      ),
      // Supabase'den verileri gerçek zamanlı çekme
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

          // Notları liste halinde gösterme
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
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    // İleride tıklandığında PDF açma işlemi buraya gelecek
                  },
                ),
              );
            },
          );
        },
      ),
      // Yeni Not Ekleme Butonu
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
