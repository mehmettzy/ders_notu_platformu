import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
      ),
      body: Column(
        children: [
          // Üst Kısım: Kullanıcı Bilgileri
          Container(
            padding: const EdgeInsets.all(24.0),
            width: double.infinity,
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Bilinmeyen Kullanıcı',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Yüklediğim Notlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Alt Kısım: Sadece Kullanıcının Yüklediği Notlar
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Sadece giriş yapan kullanıcının ID'sine sahip notları filtreliyoruz
              stream: _supabase
                  .from('notes')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', user!.id)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata oluştu: ${snapshot.error}'));
                }

                final myNotes = snapshot.data;

                if (myNotes == null || myNotes.isEmpty) {
                  return const Center(
                    child: Text('Henüz hiç not yüklemedin.'),
                  );
                }

                return ListView.builder(
                  itemCount: myNotes.length,
                  itemBuilder: (context, index) {
                    final note = myNotes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 16),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.redAccent),
                        title: Text(note['title'] ?? 'Başlıksız'),
                        subtitle: Text(note['course_name'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _supabase
                                .from('notes')
                                .delete()
                                .eq('id', note['id']);
                          },
                        ),
                        onTap: () async {
                          final String? fileUrl = note['file_url'];
                          if (fileUrl != null && fileUrl.isNotEmpty) {
                            final Uri url = Uri.parse(fileUrl);
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
