import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _universities = [];
  List<Map<String, dynamic>> _departments = [];

  String? _selectedUniversityId;
  String? _selectedDepartmentId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUniversities();
  }

  // Üniversiteleri Çek
  Future<void> _fetchUniversities() async {
    try {
      final response =
          await _supabase.from('universities').select('id, name').order('name');
      setState(() {
        _universities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _showError('Üniversiteler yüklenirken hata oluştu: $e');
    }
  }

  // Seçilen Üniversiteye Göre Bölümleri Çek
  Future<void> _fetchDepartments(String universityId) async {
    setState(() {
      _selectedDepartmentId = null;
      _departments = [];
    });
    try {
      final response = await _supabase
          .from('departments')
          .select('id, name')
          .eq('university_id', universityId)
          .order('name');
      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showError('Bölümler yüklenirken hata oluştu: $e');
    }
  }

  // Profili Kaydet
  Future<void> _saveProfile() async {
    if (_selectedUniversityId == null || _selectedDepartmentId == null) {
      _showError('Lütfen üniversite ve bölüm seçiniz.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('profiles').update({
          'university_id': _selectedUniversityId,
          'department_id': _selectedDepartmentId,
        }).eq('id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profiliniz başarıyla güncellendi!')),
          );
        }
      }
    } catch (e) {
      _showError('Kaydedilirken hata oluştu: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilini Tamamla')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Akademik Bilgileriniz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Üniversite Seçimi Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedUniversityId,
                    hint: const Text('Üniversite Seçiniz'),
                    items: _universities.map((uni) {
                      return DropdownMenuItem<String>(
                        value: uni['id'].toString(),
                        child: Text(uni['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedUniversityId = val);
                        _fetchDepartments(val);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bölüm Seçimi Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedDepartmentId,
                    hint: const Text('Bölüm Seçiniz'),
                    items: _departments.map((dep) {
                      return DropdownMenuItem<String>(
                        value: dep['id'].toString(),
                        child: Text(dep['name']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDepartmentId = val),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kaydet Butonu
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Devam Et ve Kaydet',
                            style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
