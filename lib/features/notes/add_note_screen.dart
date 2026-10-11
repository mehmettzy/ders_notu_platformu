import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _courseController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _selectedFile;
  bool _isUploading = false;

  // Dosya Seçme Fonksiyonu
  Future<void> _pickFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Belgeler ve Görseller',
        extensions: <String>['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      );

      final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file != null) {
        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya seçilmedi veya hata oluştu: $e')),
        );
      }
    }
  }

  // Ders Notunu ve Dosyayı Yükleme
  Future<void> _uploadNote() async {
    if (_titleController.text.trim().isEmpty ||
        _courseController.text.trim().isEmpty ||
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen ders adı, başlık ve bir dosya seçin.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Oturum kontrolü ve Otomatik Giriş Denemesi
      if (_supabase.auth.currentUser == null) {
        try {
          await _supabase.auth.signInWithPassword(
            email: 'mehmettzey@gmail.com',
            password: 'mehmet1805',
          );
        } catch (authError) {
          throw Exception(
              'Giriş yapılamadı: Lütfen Supabase Auth şifrenizi kontrol edin ($authError)');
        }
      }

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu açılamadı.');

      // 2. Kullanıcının profil bilgilerini çek
      final profile = await _supabase
          .from('profiles')
          .select('university_id, department_id')
          .eq('id', user.id)
          .maybeSingle();

      // 3. Dosyayı Supabase Storage 'notes' bucket'ına yükleme
      final fileExtension = _selectedFile!.name.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${user.id}.$fileExtension';
      final filePath = 'uploads/$fileName';

      final fileBytes = File(_selectedFile!.path);
      await _supabase.storage.from('notes').upload(filePath, fileBytes);

      // Public URL alma
      final fileUrl = _supabase.storage.from('notes').getPublicUrl(filePath);

      // 4. Veritabanına Note Kaydı Ekleme
      await _supabase.from('notes').insert({
        'user_id': user.id,
        'university_id': profile != null ? profile['university_id'] : null,
        'department_id': profile != null ? profile['department_id'] : null,
        'title': _titleController.text.trim(),
        'course_name': _courseController.text.trim(),
        'description': _descriptionController.text.trim(),
        'file_url': fileUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ders notu başarıyla yüklendi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Notu Yükle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(
                labelText: 'Ders Adı (Örn: Veri Yapıları)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Not Başlığı (Örn: Vize Öncesi Özet)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama (İsteğe bağlı)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),

            // Dosya Seçme Alanı
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedFile == null
                  ? 'Dosya Seç (PDF, Görsel)'
                  : 'Seçilen: ${_selectedFile!.name}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Yükle Butonu
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadNote,
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Notu Paylaş', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
