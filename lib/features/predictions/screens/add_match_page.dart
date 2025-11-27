import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';

class AddMatchPage extends StatefulWidget {
  const AddMatchPage({super.key});

  @override
  State<AddMatchPage> createState() => _AddMatchPageState();
}

class _AddMatchPageState extends State<AddMatchPage> {
  final _formKey = GlobalKey<FormState>();
  

  // Form Fields
  String? _selectedTournamentId;
  String? _selectedHomeTeamId;
  String? _selectedAwayTeamId;
  DateTime? _selectedDate;

  // Data
  bool _isLoading = true;
  List<Map<String, dynamic>> _tournaments = [];
  
  // 1. Simpan semua data tim yang dikelompokkan berdasarkan ID Turnamen
  Map<String, List<dynamic>> _teamsByTournament = {};
  
  // 2. List tim yang AKTIF ditampilkan di dropdown (sesuai turnamen yang dipilih)
  List<dynamic> _currentAvailableTeams = [];

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _fetchFormData(request);
  }

  // Fetch data Turnamen dan Tim untuk Dropdown
  Future<void> _fetchFormData(CookieRequest request) async {
    try {
      final response = await request.get(Endpoints.predictionFormData);
      
      // Debug: Cek apa yang diterima dari server
      print("Data diterima: $response");

      setState(() {
        _tournaments = List<Map<String, dynamic>>.from(response['tournaments']);
        
        _teamsByTournament = {};
        var rawData = response['teams_by_tournament'];
        
        if (rawData != null && rawData is Map) {
          rawData.forEach((key, value) {
            // Konversi key ke String ("1", "2") dan value ke List
            _teamsByTournament[key.toString()] = List<dynamic>.from(value);
          });
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data form: $e")),
        );
      }
    }
  }

  void _onTournamentChanged(String? newTournamentId) {
    print("Turnamen diganti ke ID: $newTournamentId");
    
    setState(() {
      _selectedTournamentId = newTournamentId;
      
      // Reset pilihan tim karena turnamen berubah (agar tidak error ID tidak ditemukan)
      _selectedHomeTeamId = null;
      _selectedAwayTeamId = null;
      
      // Update list tim yang tersedia sesuai ID turnamen
      if (newTournamentId != null && _teamsByTournament.containsKey(newTournamentId)) {
        _currentAvailableTeams = _teamsByTournament[newTournamentId]!;
      } else {
        _currentAvailableTeams = [];
      }
    });
  }

  Future<void> _submitMatch(CookieRequest request) async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final response = await request.postJson(
        Endpoints.predictionCreateMatch, 
        jsonEncode({
          'tournament': _selectedTournamentId,
          'home_team': _selectedHomeTeamId,
          'away_team': _selectedAwayTeamId,
          'match_date': _selectedDate!.toIso8601String().substring(0, 10), // YYYY-MM-DD
        }),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pertandingan berhasil dibuat!")),
          );
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${response['message']}")),
          );
        }
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih tanggal pertandingan")),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Pertandingan")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Pilih Turnamen
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Pilih Turnamen",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedTournamentId,
                    items: _tournaments.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'].toString(),
                        child: Text(t['name']),
                      );
                    }).toList(),
                    onChanged: _onTournamentChanged, // Panggil fungsi update tim
                    validator: (val) => val == null ? "Wajib dipilih" : null,
                  ),
                  const SizedBox(height: 16),

                  // Info Helper jika belum pilih turnamen
                  if (_selectedTournamentId == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Pilih turnamen terlebih dahulu untuk melihat daftar tim.",
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),

                  // 2. Pilih Home Team
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Tim Kandang (Home)",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedHomeTeamId,
                    items: _currentAvailableTeams.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'].toString(),
                        child: Text(t['name']),
                      );
                    }).toList(),
                    onChanged: _selectedTournamentId == null 
                        ? null 
                        : (val) => setState(() => _selectedHomeTeamId = val),
                    validator: (val) => val == null ? "Wajib dipilih" : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Pilih Away Team
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Tim Tandang (Away)",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedAwayTeamId,
                    items: _currentAvailableTeams.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'].toString(),
                        child: Text(t['name']),
                      );
                    }).toList(),
                    onChanged: _selectedTournamentId == null 
                        ? null 
                        : (val) => setState(() => _selectedAwayTeamId = val),
                    validator: (val) {
                      if (val == null) return "Wajib dipilih";
                      if (val == _selectedHomeTeamId) return "Tim tidak boleh sama";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Pilih Tanggal
                  ListTile(
                    title: Text(
                      _selectedDate == null
                          ? "Pilih Tanggal Pertandingan"
                          : "Tanggal: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () => _submitMatch(request),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Simpan Pertandingan"),
                  ),
                ],
              ),
            ),
    );
  }
}